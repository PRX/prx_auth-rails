require "prx_auth/rails/version"
require "prx_auth/rails/railtie" if defined?(Rails)
module PrxAuth
  module Rails
    class << self
      attr_accessor :configuration

      def configure
        yield configuration
      end
    end

    class Configuration
      attr_accessor :install_middleware, :namespace

      def initialize
        @install_middleware = true
        @namespace = Rails.application.class.parent_name.underscore
      end
    end

    self.configuration = Configuration.new
  end
end
