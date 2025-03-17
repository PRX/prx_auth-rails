require "test_helper"
require "pry"

describe PrxAuth::Rails do
  subject { PrxAuth::Rails }

  it "gets a configuration" do
    assert_equal :test_app, subject.configuration.namespace
    assert_equal "1234", subject.configuration.prx_client_id
    assert_equal "id.prx.test", subject.configuration.id_host
    assert_equal "api/v1/certs", subject.configuration.cert_path
  end

  it "installs and configures prx_auth middleware" do
    mw = Minitest::Mock.new
    mw.expect :insert_after, nil do |c1, c2, cert_location:, issuer:|
      assert_equal Rack::Head, c1
      assert_equal Rack::PrxAuth, c2
      assert_equal "https://id.prx.test/api/v1/certs", cert_location
      assert_equal "id.prx.test", issuer
    end

    app = Minitest::Mock.new
    app.expect :middleware, mw

    subject.install_middleware!(app)
    mw.verify
  end

  it "installs middleware after configuration" do
    called = false
    spy = -> { called = true }

    PrxAuth::Rails.stub(:install_middleware!, spy) do
      PrxAuth::Rails.installed_middleware = false

      PrxAuth::Rails.configure do |config|
        config.install_middleware = true
      end

      assert PrxAuth::Rails.installed_middleware
    end

    assert called
  end

  it "allows overriding of the middleware automatic installation" do
    called = false
    spy = -> { called = true }

    PrxAuth::Rails.stub(:install_middleware!, spy) do
      PrxAuth::Rails.installed_middleware = false

      PrxAuth::Rails.configure do |config|
        config.install_middleware = false
      end

      refute PrxAuth::Rails.installed_middleware
    end

    refute called
  end
end
