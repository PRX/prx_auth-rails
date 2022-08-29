require 'test_helper'

module PrxAuth::Rails::Ext
  class ControllerTest < ActionController::TestCase

    setup do
      @controller = ApplicationController.new
      @jwt_session_key = ApplicationController::PRX_JWT_SESSION_KEY
      @user_info_key = ApplicationController::PRX_USER_INFO_SESSION_KEY
      @account_mapping_key = ApplicationController::PRX_ACCOUNT_MAPPING_SESSION_KEY
      @stub_claims = {'iat' => Time.now.to_i, 'exp' => Time.now.to_i + 3600}
    end

    # stub auth and init controller+session by getting a page
    def with_stubbed_auth(jwt)
      session[@jwt_session_key] = 'some-jwt'
      @controller.stub(:prx_auth_needs_refresh?, false) do
        get :index
        assert_equal response.code, '200'
        yield
      end
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

    test 'fetches current user info' do
      with_stubbed_auth('some-jwt') do
        body = {
          'name' => 'Some Username',
          'apps' => {'publish.prx.test' => 'https://publish.prx.test'},
          'other' => 'stuff'
        }

        id_host = PrxAuth::Rails.configuration.id_host
        stub_request(:get, "https://#{id_host}/userinfo?scope=apps%20email%20profile").
          with(headers: {'Authorization' => 'Bearer some-jwt'}).
          to_return(status: 200, body: JSON.generate(body))

        assert session[@user_info_key] == nil
        assert_equal @controller.current_user_info, body
        refute session[@user_info_key] == nil
        assert_equal @controller.current_user_name, 'Some Username'
        assert_equal @controller.current_user_apps, {'PRX Publish' => 'https://publish.prx.test'}
      end
    end

    test 'has user name fallbacks' do
      with_stubbed_auth('some-jwt') do
        session[@user_info_key] = {'name' => 'one', 'preferred_username' => 'two', 'email' => 'three'}
        assert_equal @controller.current_user_name, 'one'

        session[@user_info_key] = {'preferred_username' => 'two', 'email' => 'three'}
        assert_equal @controller.current_user_name, 'two'

        session[@user_info_key] = {'email' => 'three'}
        assert_equal @controller.current_user_name, 'three'
      end
    end

    test 'filters apps displayed in production' do
      with_stubbed_auth('some-jwt') do
        Rails.env.stub(:production?, true) do
          session[@user_info_key] = {
            'apps' => {
              'localhost stuff' => 'http://localhost:4000/path1',
              'publish.prx.test' => 'https://publish.prx.test/path2',
              'metrics.prx.tech' => 'https://metrics.prx.tech/path3',
              'augury.prx.org' => 'https://augury.prx.org/path4',
            }
          }

          assert_equal @controller.current_user_apps, {
            'PRX Metrics' => 'https://metrics.prx.tech/path3',
            'PRX Augury' => 'https://augury.prx.org/path4',
          }
        end
      end
    end

    test 'fetches accounts' do
      with_stubbed_auth('some-jwt') do
        one = {'id' => 1, 'type' => 'IndividualAccount', 'name' => 'One'}
        three = {'id' => 3, 'type' => 'GroupAccount', 'name' => 'Three'}
        body = {'_embedded' => {'prx:items' => [one, three]}}

        id_host = PrxAuth::Rails.configuration.id_host
        stub_request(:get, "https://#{id_host}/api/v1/accounts?account_ids=1,2,3").
          to_return(status: 200, body: JSON.generate(body))

        assert_nil session[@account_mapping_key]
        assert_equal @controller.accounts_for([1, 2, 3]), [one, nil, three]
        refute_nil session[@account_mapping_key]
        assert_equal @controller.account_for(1), one
        assert_equal @controller.account_for(3), three
        assert_equal @controller.account_name_for(1), 'One'
        assert_equal @controller.account_name_for(3), 'Three'
      end
    end

    test 'handles unknown account ids' do
      with_stubbed_auth('some-jwt') do
        id_host = PrxAuth::Rails.configuration.id_host
        stub_request(:get, "https://#{id_host}/api/v1/accounts?account_ids=2").
          to_return(status: 200, body: JSON.generate({'_embedded' => {'prx:items' => []}})).
          times(3)

        assert_equal @controller.accounts_for([2]), [nil]
        assert_nil @controller.account_for(2)
        assert_nil @controller.account_name_for(2)
      end
    end

    test 'only fetches only missing accounts' do
      with_stubbed_auth('some-jwt') do
        one = {'name' => 'One'}
        two = {'id' => 2, 'type' => 'StationAccount', 'name' => 'Two'}
        three = {'name' => 'Three'}
        session[@account_mapping_key] = {1 => one, 3 => three}
        body = {'_embedded' => {'prx:items' => [two]}}

        id_host = PrxAuth::Rails.configuration.id_host
        stub_request(:get, "https://#{id_host}/api/v1/accounts?account_ids=2").
          to_return(status: 200, body: JSON.generate(body))

        assert_equal @controller.accounts_for([1, 2, 3]), [one, two, three]
        assert_equal @controller.account_for(2), two
        assert_equal @controller.account_name_for(2), 'Two'
      end
    end
  end
end
