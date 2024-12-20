PrxAuth::Rails::Engine.routes.draw do
  scope module: "prx_auth/rails" do
    resource "sessions", defaults: {format: "html"} do
      get "auth_error", to: "sessions#auth_error"
    end
  end
end
