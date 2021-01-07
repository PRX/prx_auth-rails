Rails.application.routes.draw do
  mount PrxAuth::Rails::Engine => "/prx_auth-rails"
end
