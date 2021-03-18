require 'prx_auth/rails/token'
require 'open-uri'

module PrxAuth
  module Rails
    module Controller
      PRX_AUTH_ENV_KEY = 'prx.auth'.freeze
      PRX_JWT_SESSION_KEY = 'prx.auth'.freeze
      PRX_ACCOUNT_NAME_MAPPING_KEY = 'prx.account.name.mapping'.freeze

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

      def lookup_and_register_accounts_names
        session[PRX_ACCOUNT_NAME_MAPPING_KEY] =
          lookup_account_names_mapping
      end

      def account_name_for(id)
        id = id.to_i

        session[PRX_ACCOUNT_NAME_MAPPING_KEY] ||= {}

        name =
          if session[PRX_ACCOUNT_NAME_MAPPING_KEY].has_key?(id)
            session[PRX_ACCOUNT_NAME_MAPPING_KEY][id]
          else
            session[PRX_ACCOUNT_NAME_MAPPING_KEY][id] = lookup_account_name_for(id)
          end

        name = "[#{id}] Unknown Account Name" unless name.present?

        name
      end

      def sign_in_user(token)
        session[PRX_JWT_SESSION_KEY] = token
      end

      def sign_out_user
        session.delete(PRX_JWT_SESSION_KEY)
      end

      private

      def lookup_account_name_for(id)
        id = id.to_i

        res = lookup_account_names_mapping([id])
        res[id]
      end

      def lookup_account_names_mapping(ids=current_user.resources)
        id_host = PrxAuth::Rails.configuration.id_host
        ids_param = ids.map(&:to_s).join(',')

        options = {}
        options[:ssl_verify_mode] = OpenSSL::SSL::VERIFY_NONE if ::Rails.env.development?

        accounts = URI.open("https://#{id_host}/api/v1/accounts?account_ids=#{ids_param}", options).read

        mapping = JSON.parse(accounts)['accounts'].map { |acct| [acct['id'], acct['display_name']] }.to_h

        mapping
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
