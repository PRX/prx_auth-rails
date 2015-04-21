module PrxAuth
  module Rails
    module Controller
      def prx_auth_token
        request.env['prx.auth']
      end

      def prx_authenticated?
        !!prx_auth_token
      end
    end
  end
end
