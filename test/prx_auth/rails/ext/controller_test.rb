require 'test_helper'

module PrxAuth::Rails::Ext
  class ControllerTest < ActionController::TestCase

    setup do
      @controller = ApplicationController.new
      @jwt_session_key = ApplicationController::PRX_JWT_SESSION_KEY
      @stub_claims = {'iat' => Time.now.to_i, 'exp' => Time.now.to_i + 3600}
    end

    test 'redirects unless you are authenticated' do
      get :index
      assert_equal response.code, '302'
      assert response.headers['Location'].ends_with?('/sessions/new')
    end

    test 'uses a valid session token' do
      session[@jwt_session_key] = 'some-jwt'
      JSON::JWT.stub(:decode, @stub_claims) do
        get :index
        assert_equal response.code, '200'
        assert response.body.include?('the controller index!')
        assert @controller.current_user.is_a?(PrxAuth::Rails::Token)
      end
    end

    test 'redirects if your token is nearing expiration' do
      session[@jwt_session_key] = 'some-jwt'
      @stub_claims['exp'] = Time.now.to_i + 10
      JSON::JWT.stub(:decode, @stub_claims) do
        get :index
        assert_equal response.code, '302'
        assert response.headers['Location'].ends_with?('/sessions/new')
      end
    end

    test 'does not redirect if your token has expired on a non-GET request' do
      session[@jwt_session_key] = 'some-jwt'
      @stub_claims['exp'] = Time.now.to_i + 10
      JSON::JWT.stub(:decode, @stub_claims) do
        put :index
        assert_equal response.code, '200'
        assert response.body.include?('the controller index!')
      end
    end

  end
end
