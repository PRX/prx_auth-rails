require "active_support/concern"
require "prx_auth/rails/token"
require "prx_auth/rails/ext/controller/account_info"
require "prx_auth/rails/ext/controller/user_info"

module PrxAuth
  module Rails
    module Controller
      extend ActiveSupport::Concern
      include PrxAuth::Rails::AccountInfo
      include PrxAuth::Rails::UserInfo

      class SessionTokenExpiredError < RuntimeError; end

      PRX_AUTH_ENV_KEY = "prx.auth".freeze
      PRX_JWT_SESSION_KEY = "prx.auth.jwt".freeze
      PRX_JWT_REFRESH_TTL = 60
      PRX_REFRESH_BACK_KEY = "prx.auth.back".freeze

      included do
        before_action :authenticate!
      end

      def prx_auth_token
        env_token || session_token
      rescue SessionTokenExpiredError
        session.delete(PRX_JWT_SESSION_KEY)
        session.delete(PRX_ACCOUNT_MAPPING_SESSION_KEY)
        session.delete(PRX_USER_INFO_SESSION_KEY)
        nil
      end

      def set_after_sign_in_path(path = nil)
        session[PRX_REFRESH_BACK_KEY] = path || request.fullpath
      end

      def prx_jwt
        session[PRX_JWT_SESSION_KEY]
      end

      def prx_authenticated?
        !!prx_auth_token
      end

      def authenticate!
        if !current_user
          set_after_sign_in_path
          redirect_to new_sessions_path
        elsif !current_user_access?
          redirect_to access_error_sessions_path
        else
          true
        end
      end

      # trigger refresh on a non-turbo GET request, if possible
      def prx_auth_needs_refresh?(jwt_ttl)
        if jwt_ttl < 0
          true
        elsif jwt_ttl < PRX_JWT_REFRESH_TTL
          request.get? && !request.headers["Turbo-Frame"]
        else
          false
        end
      end

      def sign_in_user(token)
        session[PRX_JWT_SESSION_KEY] = token
        accounts_for(current_user.resources)
      end

      def after_sign_in_user_redirect
        session[PRX_REFRESH_BACK_KEY]
      end

      def sign_out_user
        reset_session
      end

      private

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
