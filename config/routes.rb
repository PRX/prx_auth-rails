PrxAuth::Rails::Engine.routes.draw do
  get 'sessions', to: 'prx_auth/rails/sessions#show'
  post 'sessions', to: 'prx_auth/rails/sessions#create'
  get 'sessions/auth_error', to: 'prx_auth/rails/sessions#auth_error'
end
