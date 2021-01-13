require 'open-uri'

module PrxAuth::Rails
  class SessionsController < ApplicationController
    include PrxAuth::Rails::Engine.routes.url_helpers

    skip_before_action :authenticate!

    before_action :set_nonce!, only: :show

    ID_NONCE_SESSION_KEY = 'id_prx_openid_nonce'.freeze

    def new
      set_nonce! unless fetch_nonce.present?

      config = PrxAuth::Rails.configuration

      id_auth_params = {
        client_id: config.prx_client_id,
        nonce: fetch_nonce,
        response_type: 'id_token token',
        scope: 'openid apps',
        prompt: 'necessary'
      }

      redirect_to '//' + config.id_host + '/authorize?' + id_auth_params.to_query
    end

    def show
    end

    def auth_error
      @auth_error_message = params.require(:error)
    end

    def create
      jwt_id_claims = id_claims
      jwt_access_claims = access_claims

      jwt_access_claims['id_token'] = jwt_id_claims.as_json

      result_path = if valid_nonce?(jwt_id_claims['nonce']) &&
                        users_match?(jwt_id_claims, jwt_access_claims)
                      sign_in_user(jwt_access_claims)
                      after_sign_in_path_for(current_user)
                    else
                      auth_error_sessions_path(error: 'verification_failed')
                    end
      reset_nonce!

      redirect_to result_path
    end

    private

    def after_sign_in_path_for(_)
      return super if defined?(super)

      "/"
    end

    def id_claims
      id_token = params.require('id_token')
      validate_token(id_token)
    end

    def access_claims
      access_token = params.require('access_token')
      validate_token(access_token)
    end

    def reset_nonce!
      session[ID_NONCE_SESSION_KEY] = nil
    end

    def set_nonce!
      n = session[ID_NONCE_SESSION_KEY]
      return n if n.present?

      session[ID_NONCE_SESSION_KEY] = SecureRandom.hex
    end

    def fetch_nonce
      session[ID_NONCE_SESSION_KEY]
    end

    def valid_nonce?(nonce)
      return false if fetch_nonce.nil?

      fetch_nonce == nonce
    end

    def users_match?(claims1, claims2)
      return false if claims1['sub'].nil? || claims2['sub'].nil?

      claims1['sub'] == claims2['sub']
    end

    def validate_token(token)
      id_host = PrxAuth::Rails.configuration.id_host
      prx_auth_cert = Rack::PrxAuth::Certificate.new("https://#{id_host}/api/v1/certs")
      auth_validator = Rack::PrxAuth::AuthValidator.new(token, prx_auth_cert, id_host)
      auth_validator.
        claims.
        with_indifferent_access
    end
  end
end
