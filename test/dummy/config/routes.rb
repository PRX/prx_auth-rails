Rails.application.routes.draw do
  get 'index', to: 'application#index'
  put 'index', to: 'application#index'
  mount PrxAuth::Rails::Engine => "/prx_auth-rails"
end
