Rails.application.routes.draw do
  get "index", to: "application#index"
  put "index", to: "application#index"
end
