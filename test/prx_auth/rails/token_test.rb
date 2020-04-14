require 'test_helper'

describe PrxAuth::Rails::Token do
  let (:aur) { { "123" => "test_app:read other_namespace:write", "*" => "test_app:add" } }
  let (:sub) { "123" }
  let (:scope) { "one two three" }
  let (:token_data) { Rack::PrxAuth::TokenData.new("aur" => aur, "scope" => scope, "sub" => sub)}
  let (:mock_token_data) { Minitest::Mock.new(token_data) }
  let (:token) { PrxAuth::Rails::Token.new(mock_token_data) }

  it 'automatically namespaces requests' do
    mock_token_data.expect(:authorized?, true, ["123", :test_app, :read])
    assert token.authorized?("123", :read)

    mock_token_data.expect(:resources, ["123"], [:test_app, :read])
    assert token.resources(:read) === ['123']

    mock_token_data.expect(:globally_authorized?, true, [:test_app, :add])
    assert token.globally_authorized?(:add) 

    mock_token_data.verify
  end

  it 'allows unscoped calls to authorized?' do
    assert token.authorized?("123")
  end

  it 'allows unscoped calls to resources' do
    assert token.resources == [ "123" ]
  end

  it 'allows manual setting of namespace' do
    assert token.authorized?("123", :other_namespace, :write)
    assert !token.authorized?("123", :other_namespace, :read)

    assert token.resources(:other_namespace, :write) == ["123"]
    assert token.resources(:other_namespace, :read) == []

    assert token.globally_authorized?(:add)
    assert token.globally_authorized?(:test_app, :add)
    assert !token.globally_authorized?(:other_namespace, :add)
  end

  
end