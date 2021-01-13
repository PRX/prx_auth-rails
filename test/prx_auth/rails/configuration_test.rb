require 'test_helper'

describe PrxAuth::Rails::Configuration do

  subject { PrxAuth::Rails::Configuration.new }

  it 'initializes with a namespace defined by rails app name' do
    assert subject.namespace == :dummy
  end

  it 'can be reconfigured using the namespace attr' do
    subject.namespace = :new_test

    assert subject.namespace == :new_test
  end

  it 'defaults to enabling the middleware' do
    assert subject.install_middleware
  end

  it 'allows overriding of the middleware automatic installation' do
    subject.install_middleware = false
    assert subject.install_middleware == false
  end
end
