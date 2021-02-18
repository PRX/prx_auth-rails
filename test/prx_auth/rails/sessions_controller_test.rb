require "test_helper"

module PrxAuth::Rails
  class SessionsControllerTest < ActionController::TestCase

    setup do
      @routes = PrxAuth::Rails::Engine.routes
      @nonce_session_key = SessionsController::ID_NONCE_SESSION_KEY
      @token_params = {id_token: 'sometok', access_token: 'othertok'}
      @stub_claims = {'nonce' => '123', 'sub' => '1'}
    end

    test "new creates nonce" do
      nonce = session[@nonce_session_key]
      assert nonce == nil

      get :new

      nonce = session[@nonce_session_key]
      assert nonce.match(/[a-zA-Z\d]{32}/)
      assert nonce.length == 32
    end

    test 'new should should not overwrite the saved nonce' do
      get :new
      nonce1 = session[@nonce_session_key]

      get :new
      nonce2 = session[@nonce_session_key]
      assert nonce1 == nonce2
    end

    test 'create should validate a token and set the session variable' do
      @controller.stub(:validate_token, @stub_claims) do
        @controller.stub(:lookup_and_register_accounts_names, nil) do
          session[@nonce_session_key] = '123'
          post :create, params: @token_params, format: :json
          assert session['prx.auth']['id_token']['nonce'] == '123'
        end
      end
    end

    test 'create should call test_nonce! if upon verification' do
      @controller.stub(:validate_token, {'nonce' => 'not matching', 'aud' => '1'}) do
        session[@nonce_session_key] = 'nonce'
        post :create, params: @token_params, format: :json
        assert session[@nonce_session_key] == nil
      end
    end

    test 'create should reset the nonce after consumed' do
      @controller.stub(:validate_token, @stub_claims) do
        @controller.stub(:lookup_and_register_accounts_names, nil) do
          session[@nonce_session_key] = '123'
          post :create, params: @token_params, format: :json

          assert session[@nonce_session_key] == nil
          assert response.code == '302'
          assert response.body.match?(/after-sign-in-path/)
        end
      end
    end

    test 'should respond with aredirect to the auth error page / code if the nonce does not match' do
      @controller.stub(:validate_token, @stub_claims) do
        session[@nonce_session_key] = 'nonce-does-not-match'
        post :create, params: @token_params, format: :json
        assert response.code == '302'
        assert response.body.match(/auth_error\?error=verification_failed/)
      end
    end

    test 'auth_error should return a formatted error message to the user' do
      get :auth_error, params: {error: 'error_message'}
      assert response.code == '200'
      assert response.body.match?(/Message was: <pre>error_message/)
    end

    test 'auth_error should expect the error param' do
      assert_raises ActionController::ParameterMissing do
        get :auth_error, params: {}
      end
    end

    test 'validates that the user id matches in both tokens' do
      @controller.stub(:id_claims, @stub_claims) do
        @controller.stub(:access_claims, @stub_claims.merge('sub' => '444')) do

        session[@nonce_session_key] = '123'
        post :create, params: @token_params, format: :json

        assert response.code == '302'
        assert response.body.match?(/error=verification_failed/)
      end
      end
    end
  end
end
