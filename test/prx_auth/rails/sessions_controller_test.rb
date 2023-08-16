require "test_helper"

module PrxAuth::Rails
  class SessionsControllerTest < ActionController::TestCase
    setup do
      @routes = PrxAuth::Rails::Engine.routes
      @nonce_session_key = SessionsController::ID_NONCE_SESSION_KEY
      @refresh_back_key = SessionsController::PRX_REFRESH_BACK_KEY
      @token_params = {id_token: "idtok", access_token: "accesstok"}
      @stub_claims = {"nonce" => "123", "sub" => "1"}
      @stub_token = PrxAuth::Rails::Token.new(Rack::PrxAuth::TokenData.new)
    end

    test "new creates nonce" do
      nonce = session[@nonce_session_key]
      assert nonce.nil?

      get :new

      nonce = session[@nonce_session_key]
      assert nonce.match(/[a-zA-Z\d]{32}/)
      assert nonce.length == 32
    end

    test "new should should not overwrite the saved nonce" do
      get :new
      nonce1 = session[@nonce_session_key]

      get :new
      nonce2 = session[@nonce_session_key]
      assert nonce1 == nonce2
    end

    test "create should validate a token and set the session variable" do
      session[SessionsController::PRX_JWT_SESSION_KEY] = nil
      @controller.stub(:validate_token, @stub_claims) do
        @controller.stub(:session_token, @stub_token) do
          session[@nonce_session_key] = "123"
          post :create, params: @token_params, format: :json
          assert session[SessionsController::PRX_JWT_SESSION_KEY] == "accesstok"
        end
      end
    end

    test "create should call test_nonce! if upon verification" do
      @controller.stub(:validate_token, {"nonce" => "not matching", "aud" => "1"}) do
        session[@nonce_session_key] = "nonce"
        post :create, params: @token_params, format: :json
        assert session[@nonce_session_key].nil?
      end
    end

    test "create should reset the nonce after consumed" do
      @controller.stub(:validate_token, @stub_claims) do
        @controller.stub(:session_token, @stub_token) do
          session[@nonce_session_key] = "123"
          post :create, params: @token_params, format: :json

          assert session[@nonce_session_key].nil?
          assert response.code == "302"
          assert response.body.match?(/after-sign-in-path/)
        end
      end
    end

    test "redirects to a back-path after refresh" do
      @controller.stub(:validate_token, @stub_claims) do
        @controller.stub(:session_token, @stub_token) do
          session[@nonce_session_key] = "123"
          session[@refresh_back_key] = "/lets/go/here?okay"
          post :create, params: @token_params, format: :json

          # A trailing log of the 'last' page
          assert session[@refresh_back_key] == "/lets/go/here?okay"

          assert response.code == "302"
          assert response.headers["Location"].ends_with?("/lets/go/here?okay")
        end
      end
    end

    test "should respond with redirect to the auth error page / code if the nonce does not match" do
      @controller.stub(:validate_token, @stub_claims) do
        @token_params[:error] = "verification_failed"
        session[@nonce_session_key] = "nonce-does-not-match"
        post :create, params: @token_params, format: :json
        assert response.code == "302"
        assert response.body.match(/auth_error\?error=verification_failed/)
      end
    end

    test "auth_error should return a formatted error message to the user" do
      get :auth_error, params: {error: "error_message"}
      assert response.code == "200"
      assert response.body.match?(/Not authorized/)
    end

    test "auth_error should expect the error param" do
      assert_raises ActionController::ParameterMissing do
        get :auth_error, params: {}
      end
    end

    test "validates that the user id matches in both tokens" do
      @controller.stub(:id_claims, @stub_claims) do
        @controller.stub(:access_claims, @stub_claims.merge("sub" => "444")) do
          @token_params[:error] = "verification_failed"
          session[@nonce_session_key] = "123"
          post :create, params: @token_params, format: :json

          assert response.code == "302"
          assert response.body.match?(/error=verification_failed/)
        end
      end
    end

    test "should clear the user token on sign out" do
      session[SessionsController::PRX_JWT_SESSION_KEY] = "some-token"
      post :destroy
      assert session[SessionsController::PRX_JWT_SESSION_KEY].nil?
    end
  end
end
