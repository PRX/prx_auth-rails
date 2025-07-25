require "rack/prx_auth"

class PrxAuth::Rails::Token
  def initialize(token_data)
    @token_data = token_data
    @namespace = PrxAuth::Rails.configuration.namespace
  end

  def authorized?(resource, namespace = nil, scope = nil)
    namespace, scope = @namespace, namespace if scope.nil? && !namespace.nil?
    @token_data.authorized?(resource, namespace, scope)
  end

  def globally_authorized?(namespace, scope = nil)
    namespace, scope = @namespace, namespace if scope.nil?
    @token_data.globally_authorized?(namespace, scope)
  end

  def resources(namespace = nil, scope = nil)
    namespace, scope = @namespace, namespace if scope.nil? && !namespace.nil?
    @token_data.resources(namespace, scope)
  end

  def scopes
    @token_data.scopes
  end

  def user_id
    @token_data.user_id
  end

  def issued_at
    @token_data.issued_at
  end

  def expiration_time
    @token_data.expiration_time
  end

  def authorized_account_ids(scope)
    @token_data.authorized_account_ids(scope)
  end

  def except!(*resources)
    @token_data = @token_data.except(*resources)
    self
  end

  def except(*resources)
    dup.except!(*resources)
  end

  def empty_resources?
    @token_data.empty_resources?
  end
end
