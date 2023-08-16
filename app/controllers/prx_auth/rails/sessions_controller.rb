# frozen_string_literal: true

module PrxAuth::Rails
  class SessionsController < ApplicationController
    include PrxAuth::Rails::Engine.routes.url_helpers

    skip_before_action :authenticate!, raise: false

    before_action :set_nonce!, only: [:new, :show]
    before_action :set_after_sign_in_path

    ID_NONCE_SESSION_KEY = "id_prx_openid_nonce"
    DEFAULT_SCOPES = "openid"

    def new
      config = PrxAuth::Rails.configuration

      scope =
        if config.prx_scope.present?
          "#{DEFAULT_SCOPES} #{config.prx_scope}"
        else
          DEFAULT_SCOPES
        end

      id_auth_params = {
        client_id: config.prx_client_id,
        nonce: fetch_nonce,
        response_type: "id_token token",
        scope: scope,
        prompt: "necessary"
      }

      url = "//" + config.id_host + "/authorize?" + id_auth_params.to_query

      redirect_to url, allow_other_host: true
    end

    def show
    end

    def destroy
      sign_out_user
      redirect_to after_sign_out_path
    end

    def auth_error
      @auth_error_message = params.require(:error)
    end

    def create
      valid_and_matching = valid_nonce? && users_match?
      clear_nonce!

      if valid_and_matching
        sign_in_user(access_token)
        redirect_to after_sign_in_path_for(current_user)
      else
        redirect_to auth_error_sessions_path(error: params[:error] || "unknown_error")
      end
    end

    private

    def after_sign_in_path_for(_)
      back_path = after_sign_in_user_redirect
      if back_path.present?
        back_path
      elsif defined?(super)
        super
      else
        "/"
      end
    end

    def after_sign_out_path
      return super if defined?(super)

      "https://#{id_host}/session/sign_out"
    end

    def id_token
      params.require("id_token")
    end

    def access_token
      params.require("access_token")
    end

    def id_claims
      @id_claims ||= validate_token(id_token)
    end

    def access_claims
      @access_claims ||= validate_token(access_token)
    end

    def clear_nonce!
      session.delete(ID_NONCE_SESSION_KEY)
    end

    def set_nonce!
      session[ID_NONCE_SESSION_KEY] ||= SecureRandom.hex
    end

    def fetch_nonce
      session[ID_NONCE_SESSION_KEY]
    end

    def valid_nonce?
      id_claims["nonce"].present? && id_claims["nonce"] == fetch_nonce
    end

    def users_match?
      id_claims["sub"].present? && id_claims["sub"] == access_claims["sub"]
    end

    def validate_token(token)
      prx_auth_cert = Rack::PrxAuth::Certificate.new("https://#{id_host}/api/v1/certs")
      auth_validator = Rack::PrxAuth::AuthValidator.new(token, prx_auth_cert, id_host)
      auth_validator.claims.with_indifferent_access
    end

    def id_host
      PrxAuth::Rails.configuration.id_host
    end
  end
end
