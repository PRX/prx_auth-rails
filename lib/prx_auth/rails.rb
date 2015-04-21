require "prx_auth/rails/version"
require "prx_auth/rails/railtie" if defined?(Rails)
module PrxAuth
  module Rails
    class << self
      attr_accessor :middleware
    end
    self.middleware = true
  end
end
