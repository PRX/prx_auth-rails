require "rails/railtie"
require "prx_auth/rails/ext/controller"
require "rack/prx_auth"

module PrxAuth::Rails
  class Railtie < ::Rails::Railtie
    config.to_prepare do
      ApplicationController.send(:include, PrxAuth::Rails::Controller)
    end
  end
end
