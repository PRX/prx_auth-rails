require 'coveralls'

Coveralls.wear!

require 'minitest/autorun'
require 'minitest/spec'
require 'minitest/pride'
require 'webmock/minitest'
require 'action_pack'
require 'action_controller'
require 'action_view'
require 'rails'
require 'rails/generators'
require 'rails/generators/test_case'
require 'pry'

require 'prx_auth/rails'

# Configure Rails Environment
ENV["RAILS_ENV"] = "test"
ENV['PRX_CLIENT_ID'] = '12345'


require_relative "../test/dummy/config/environment"
ActiveRecord::Migrator.migrations_paths = [File.expand_path("../test/dummy/db/migrate", __dir__)]
ActiveRecord::Migrator.migrations_paths << File.expand_path('../db/migrate', __dir__)
require "rails/test_help"


# Load fixtures from the engine
if ActiveSupport::TestCase.respond_to?(:fixture_path=)
  ActiveSupport::TestCase.fixture_path = File.expand_path("fixtures", __dir__)
  ActionDispatch::IntegrationTest.fixture_path = ActiveSupport::TestCase.fixture_path
  ActiveSupport::TestCase.file_fixture_path = ActiveSupport::TestCase.fixture_path + "/files"
  ActiveSupport::TestCase.fixtures :all
end
