require 'rails/railtie'
require 'prx_auth/rails/ext/controller'

module PrxAuth
  module Rails
    class Railtie < ::Rails::Railtie
      config.to_prepare do
        ApplicationController.send(:include, PrxAuth::Rails::Controller)
      end

      initializer 'prx_auth.insert_middleware' do |app|
        p app.config.middleware
        app.config.middleware.insert_before ActionDispatch::ParamsParser, 'Rack::PrxAuth'
      end
    end
  end
end
