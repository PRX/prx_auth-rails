class PrxAuth::Rails::Configuration
  attr_accessor :install_middleware,
                :namespace,
                :prx_client_id,
                :id_host,
                :cert_path

  DEFAULT_ID_HOST = 'id.prx.org'
  DEFAULT_CERT_PATH = 'api/v1/certs'

  def initialize
    @install_middleware = true
    @prx_client_id = nil
    @id_host = DEFAULT_ID_HOST
    @cert_path = DEFAULT_CERT_PATH

    # infer default namespace from app name
    @namespace =
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

        klass_name.underscore.intern
      end
  end
end
