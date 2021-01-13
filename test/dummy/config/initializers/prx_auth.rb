 require 'prx_auth/rails'

 PrxAuth::Rails.configure do |config|
   config.install_middleware = true
   config.namespace = :test_app
   config.prx_client_id = '1234'
   config.id_host = 'id.prx.test'
 end
