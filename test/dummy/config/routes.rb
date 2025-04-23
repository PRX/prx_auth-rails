Rails.application.routes.draw do
  prx_auth_routes
  get "index", to: "application#index"
  put "index", to: "application#index"
end
