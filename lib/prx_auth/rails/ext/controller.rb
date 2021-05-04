require 'prx_auth/rails/token'
require 'open-uri'

module PrxAuth
  module Rails
    module Controller
      class SessionTokenExpiredError < RuntimeError; end

      PRX_AUTH_ENV_KEY = 'prx.auth'.freeze
      PRX_JWT_SESSION_KEY = 'prx.auth.jwt'.freeze
      PRX_JWT_REFRESH_TTL = 300.freeze
      PRX_ACCOUNT_MAPPING_SESSION_KEY = 'prx.auth.account.mapping'.freeze
      PRX_USER_INFO_SESSION_KEY = 'prx.auth.info'.freeze
      PRX_REFRESH_BACK_KEY = 'prx.auth.back'.freeze

      def prx_auth_token
        env_token || session_token
      rescue SessionTokenExpiredError
        reset_session
        session[PRX_REFRESH_BACK_KEY] = request.fullpath
        redirect_to PrxAuth::Rails::Engine.routes.url_helpers.new_sessions_path
      end

      def prx_jwt
        session[PRX_JWT_SESSION_KEY]
      end

      def prx_authenticated?
        !!prx_auth_token
      end

      def authenticate!
        return true if current_user.present?

        redirect_to PrxAuth::Rails::Engine.routes.url_helpers.new_sessions_path
      end

      def prx_auth_needs_refresh?(jwt_ttl)
        request.get? && jwt_ttl < PRX_JWT_REFRESH_TTL
      end

      def current_user
        prx_auth_token
      end

      def current_user_info
        session[PRX_USER_INFO_SESSION_KEY] ||= fetch_userinfo
      end

      def current_user_name
        current_user_info['name'] || current_user_info['preferred_username'] || current_user_info['email']
      end

      def current_user_apps
        apps = (current_user_info.try(:[], 'apps') || []).map do |name, url|
          label = name.sub(/^https?:\/\//, '').sub(/\..+/, '').capitalize
          ["PRX #{label}", url]
        end

        # only return entire list in development
        if ::Rails.env.production? || ::Rails.env.staging?
          apps.to_h.select { |k, v| v.match?(/\.(org|tech)/) }
        else
          apps.to_h
        end
      end

      def sign_in_user(token)
        session[PRX_JWT_SESSION_KEY] = token
        accounts_for(current_user.resources)
      end

      def after_sign_in_user_redirect
        session.delete(PRX_REFRESH_BACK_KEY)
      end

      def sign_out_user
        reset_session
      end

      def account_name_for(account_id)
        account_for(account_id).try(:[], :name)
      end

      def account_for(account_id)
        lookup_accounts([account_id]).first
      end

      def accounts_for(account_ids)
        lookup_accounts(account_ids)
      end

      private

      def lookup_accounts(ids)
        session[PRX_ACCOUNT_MAPPING_SESSION_KEY] ||= {}

        # fetch any accounts we don't have yet
        missing = ids - session[PRX_ACCOUNT_MAPPING_SESSION_KEY].keys
        if missing.present?
          fetch_accounts(missing).each do |account|
            session[PRX_ACCOUNT_MAPPING_SESSION_KEY][account['id']] = account.with_indifferent_access
          end
        end

        ids.map { |id| session[PRX_ACCOUNT_MAPPING_SESSION_KEY][id] }
      end

      def fetch_accounts(ids)
        ids_param = ids.map(&:to_s).join(',')
        fetch("/api/v1/accounts?account_ids=#{ids_param}")['accounts']
      end

      def fetch_userinfo
        fetch("/userinfo?scope=apps+email+profile", prx_jwt)
      end

      def fetch(path, token = nil)
        url = "https://#{PrxAuth::Rails.configuration.id_host}#{path}"
        options = {}
        options[:ssl_verify_mode] = OpenSSL::SSL::VERIFY_NONE if ::Rails.env.development?
        options['Authorization'] = "Bearer #{token}" if token
        JSON.parse(URI.open(url, options).read)
      end

      # token from data set by prx_auth rack middleware
      def env_token
        @env_token_data ||= if request.env[PRX_AUTH_ENV_KEY]
          token_data = request.env[PRX_AUTH_ENV_KEY]
          PrxAuth::Rails::Token.new(token_data)
        end
      end

      # token from jwt stored in session
      def session_token
        @session_prx_auth_token ||= if prx_jwt
          # NOTE: we already validated this jwt - so just decode it
          validator = Rack::PrxAuth::AuthValidator.new(prx_jwt)

          # does this jwt need to be refreshed?
          if prx_auth_needs_refresh?(validator.time_to_live)
            raise SessionTokenExpiredError.new
          end

          # create new data/token from access claims
          token_data = Rack::PrxAuth::TokenData.new(validator.claims)
          PrxAuth::Rails::Token.new(token_data)
        end
      end
    end
  end
end
