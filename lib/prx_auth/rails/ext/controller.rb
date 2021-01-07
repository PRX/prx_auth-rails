require 'prx_auth/rails/token'

module PrxAuth
  module Rails
    module Controller
      def prx_auth_token
        rack_auth_token = env_prx_auth_token
        return rack_auth_token if rack_auth_token.present?

        session['prx.auth'] && Rack::PrxAuth::TokenData.new(session['prx.auth'])
      end

      def prx_authenticated?
        !!prx_auth_token
      end

      def authenticate!
        return true if current_user.present?

        redirect_to PrxAuth::Rails::Engine.routes.url_helpers.sessions_path
      end

      def current_user
        return if prx_auth_token.nil?

        PrxAuth::Rails::Token.new(prx_auth_token)
      end

      def sign_in_user(token)
        session['prx.auth'] = token
      end


      private

      def env_prx_auth_token
        if !defined? @_prx_auth_token
          @_prx_auth_token = request.env['prx.auth'] && PrxAuth::Rails::Token.new(request.env['prx.auth'])
        else
          @_prx_auth_token
        end
      end
    end
  end
end
