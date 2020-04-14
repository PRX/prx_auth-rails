require "prx_auth/rails/version"
require "prx_auth/rails/configuration"
require "prx_auth/rails/railtie" if defined?(Rails)

module PrxAuth
  module Rails
    class << self
      attr_accessor :configuration

      def configure
        yield configuration
      end
    end

    self.configuration = Configuration.new
  end
end
