class PrxAuth::Rails::Configuration
  attr_accessor :install_middleware, :namespace

  def initialize
    @install_middleware = true
    if defined?(::Rails)
      klass = ::Rails.application.class
      klass_name = if klass.parent_name.present?
                     klass.parent_name
                   else
                     klass.name
                   end

      @namespace = klass_name.underscore.intern
    end
  end
end