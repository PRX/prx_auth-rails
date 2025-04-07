Rails.application.routes.draw do
  scope module: "prx_auth/rails", path: "auth" do
    resource "sessions", except: %w[edit update] do
      get "access_error", to: "sessions#access_error"
      get "auth_error", to: "sessions#auth_error"
      get "logout", to: "sessions#logout"
      get "refresh", to: "sessions#refresh"
    end
  end
end
