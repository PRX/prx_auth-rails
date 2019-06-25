require 'rails/railtie'
require 'prx_auth/rails/ext/controller'
require 'rack/prx_auth'

module PrxAuth::Rails
  class Railtie < ::Rails::Railtie
    config.to_prepare do
      ApplicationController.send(:include, PrxAuth::Rails::Controller)
    end

    initializer 'prx_auth.insert_middleware' do |app|
      if PrxAuth::Rails.middleware
        app.config.middleware.insert_after Rack::Head, Rack::PrxAuth
      end
    end
  end
end
