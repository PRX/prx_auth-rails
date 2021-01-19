require 'test_helper'

describe PrxAuth::Rails::Configuration do

  subject { PrxAuth::Rails::Configuration.new }

  it 'initializes with a namespace defined by rails app name' do
    assert subject.namespace == :dummy
  end

  it 'can be reconfigured using the namespace attr' do
    PrxAuth::Rails.stub(:configuration, subject) do
      PrxAuth::Rails.configure do |config|
        config.namespace = :new_test
      end

      assert PrxAuth::Rails.configuration.namespace == :new_test
    end
  end

  it 'defaults to enabling the middleware' do
    PrxAuth::Rails.stub(:configuration, subject) do
      assert PrxAuth::Rails.configuration.install_middleware
    end
  end

  it 'allows overriding of the middleware automatic installation' do
    PrxAuth::Rails.stub(:configuration, subject) do
      PrxAuth::Rails.configure do |config|
        config.install_middleware = false
      end

      assert !PrxAuth::Rails.configuration.install_middleware
    end
  end
end
