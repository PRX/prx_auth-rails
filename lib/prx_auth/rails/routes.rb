module ActionDispatch
  module Routing
    class Mapper
      def prx_auth_routes(path: "auth")
        scope module: "prx_auth/rails", path: path do
          resource "sessions", except: %w[edit update] do
            get "access_error", to: "sessions#access_error"
            get "auth_error", to: "sessions#auth_error"
            get "logout", to: "sessions#logout"
            get "refresh", to: "sessions#refresh"
          end
        end
      end
    end
  end
end
