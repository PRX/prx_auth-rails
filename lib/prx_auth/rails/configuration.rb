class PrxAuth::Rails::Configuration
  attr_accessor :install_middleware,
                :namespace,
                :prx_client_id,
                :id_host


  def initialize
    @install_middleware = true
    if defined?(::Rails)
      klass = ::Rails.application.class
      parent_name = if ::Rails::VERSION::MAJOR >= 6
                      klass.module_parent_name
                    else
                      klass.parent_name
                    end
      klass_name = if parent_name.present?
                     parent_name
                   else
                     klass.name
                   end

      @namespace = klass_name.underscore.intern
      @prx_client_id = nil
      @id_host = nil
    end
  end
end
