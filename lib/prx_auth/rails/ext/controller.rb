require 'prx_auth/rails/token'

module PrxAuth
  module Rails
    module Controller
      def prx_auth_token
        if !defined? @_prx_auth_token
          @_prx_auth_token = request.env['prx.auth'] && PrxAuth::Rails::Token.new(request.env['prx.auth'])
        else
          @_prx_auth_token
        end
      end

      def prx_authenticated?
        !!prx_auth_token
      end
    end
  end
end
