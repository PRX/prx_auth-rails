require 'rack/prx_auth'

class PrxAuth::Rails::Token
  def initialize(token_data)
    @token_data = token_data
    @namespace = PrxAuth::Rails.configuration.namespace
  end

  def authorized?(resource, scope)
    @token_data.authorized?(resource, @namespace, scope)
  end

  def globally_authorized?(scope)
    @token_data.globally_authorized?(@namespace, scope)
  end

  def resources(scope)
    @token_data.resources(@namespace, scope)
  end

  def scopes
    @token_data.scopes
  end

  def user_id
    @token_data.user_id
  end
end