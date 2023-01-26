require 'test_helper'

describe PrxAuth::Rails::Configuration do

  subject { PrxAuth::Rails::Configuration.new }

  it 'initializes with defaults' do
    assert subject.install_middleware
    assert_nil subject.prx_client_id
    assert_nil subject.prx_scope
    assert_equal 'id.prx.org', subject.id_host
    assert_equal 'api/v1/certs', subject.cert_path
  end

  it 'infers the default namespace from the rails app name' do
    assert_equal :dummy, subject.namespace
  end

  it 'is updated by the prxauth configure block' do
    PrxAuth::Rails.stub(:configuration, subject) do
      PrxAuth::Rails.configure do |config|
        config.install_middleware = false
        config.prx_client_id = 'some-id'
        config.prx_scope = 'appname:*'
        config.id_host = 'id.prx.blah'
        config.cert_path = 'cert/path'
        config.namespace = :new_test
      end
    end

    refute subject.install_middleware
    assert_equal 'some-id', subject.prx_client_id
    assert_equal 'appname:*', subject.prx_scope
    assert_equal 'id.prx.blah', subject.id_host
    assert_equal 'cert/path', subject.cert_path
    assert_equal :new_test, subject.namespace
  end
end
