require 'prx_auth/rails/token'
require 'open-uri'

module PrxAuth
  module Rails
    module Controller
      PRX_AUTH_ENV_KEY = 'prx.auth'.freeze
      PRX_JWT_SESSION_KEY = 'prx.auth.jwt'.freeze
      PRX_ACCOUNT_MAPPING_SESSION_KEY = 'prx.auth.account.mapping'.freeze

      def prx_auth_token
        env_token || session_token
      end

      def prx_authenticated?
        !!prx_auth_token
      end

      def authenticate!
        return true if current_user.present?

        redirect_to PrxAuth::Rails::Engine.routes.url_helpers.new_sessions_path
      end

      def current_user
        prx_auth_token
      end

      def sign_in_user(token)
        session[PRX_JWT_SESSION_KEY] = token
        accounts_for(current_user.resources)
      end

      def sign_out_user
        reset_session
      end

      def account_name_for(account_id)
        account_for(account_id)[:name]
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
        id_host = PrxAuth::Rails.configuration.id_host
        ids_param = ids.map(&:to_s).join(',')

        options = {}
        options[:ssl_verify_mode] = OpenSSL::SSL::VERIFY_NONE if ::Rails.env.development?

        accounts = URI.open("https://#{id_host}/api/v1/accounts?account_ids=#{ids_param}", options).read

        JSON.parse(accounts)['accounts']
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
        @session_prx_auth_token ||= if session[PRX_JWT_SESSION_KEY]
          jwt = session[PRX_JWT_SESSION_KEY]
          # NOTE: we already validated this jwt - so just decode it
          claims = Rack::PrxAuth::AuthValidator.new(jwt, nil, nil).claims
          token_data = Rack::PrxAuth::TokenData.new(claims)
          PrxAuth::Rails::Token.new(token_data)
        end
      end
    end
  end
end
