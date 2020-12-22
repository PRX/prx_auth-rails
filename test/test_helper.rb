require 'coveralls'
Coveralls.wear!

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'minitest/autorun'
require 'minitest/spec'
require 'minitest/pride'
require 'action_pack'
require 'action_controller'
require 'action_view'
require 'rails'
require 'rails/generators'
require 'rails/generators/test_case'
# Bundler.require(:default)

class TestApp < Rails::Application
  config.root = File.dirname(__FILE__)
  config.eager_load = false
end

TestApp.initialize!

require 'prx_auth/rails'
