class PrxAuth::Rails::Configuration
  attr_accessor :install_middleware,
                :namespace,
                :prx_client_id


  def initialize
    @install_middleware = true
    if defined?(::Rails)
      klass = ::Rails.application.class
      klass_name = if klass.try(:parent_name).present?
                     klass.parent_name
                   else
                     klass.name
                   end

      @namespace = klass_name.underscore.intern
      @prx_client_id = nil
    end
  end
end
