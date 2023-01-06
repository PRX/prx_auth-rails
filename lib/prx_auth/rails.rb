require "prx_auth/rails/version"
require "prx_auth/rails/configuration"
require "prx_auth/rails/railtie" if defined?(Rails)
require "prx_auth/rails/engine" if defined?(Rails)

module PrxAuth
  module Rails
    class << self
      attr_accessor :configuration, :installed_middleware

      def configure
        yield configuration if block_given?

        # only install from first call to configure block
        if configuration.install_middleware && !installed_middleware
          install_middleware!
          self.installed_middleware = true
        end
      end

      def install_middleware!(app = nil)
        app ||= ::Rails.application if defined?(::Rails)

        return false unless app

        # guess protocol from host
        host = configuration.id_host
        path = configuration.cert_path
        protocol =
          if host.include?('localhost') || host.include?('127.0.0.1')
            'http'
          else
            'https'
          end

        app.middleware.insert_after Rack::Head, Rack::PrxAuth,
          cert_location: "#{protocol}://#{host}/#{path}",
          issuer: host
      end
    end

    self.configuration = Configuration.new
  end
end
