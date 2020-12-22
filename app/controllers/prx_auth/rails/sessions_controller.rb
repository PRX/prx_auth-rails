require 'open-uri'

module PrxAuth::Rails
  class SessionsController < ApplicationController
    skip_before_action :authenticate!

    before_action :set_nonce!, only: :show

    ID_NONCE_SESSION_KEY = :id_prx_openid_nonce

    def show
      @id_host = ENV['ID_HOST']
      @id_auth_params = {
        client_id: ENV['PRX_CLIENT_ID'],
        nonce: fetch_nonce,
        response_type: 'id_token token',
        scope: 'openid apps',
        prompt: 'necessary'
      }.to_query
    end

    def auth_error
      @auth_error_message = params.require(:error)
    end

    def create
      id_token = params.require('id_token')
      jwt_id_tok = validate_token(id_token)

      access_token = params.require('access_token')
      jwt_access_tok = validate_token(access_token)

      jwt_access_tok['id_token'] = jwt_id_tok

      result_path, code = if valid_nonce?(jwt_id_tok[:nonce])
                            sign_in_user(jwt_access_tok)
                            [after_sign_in_path_for(current_user), :ok]
                          else
                            [sessions_auth_error_path(error: 'verification_failed'), :forbidden]
                          end
      reset_nonce!

      respond_to do |format|
        format.json do
          render json: { result_path: result_path }, status: code
        end
      end
    end

    private

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

    def validate_token(token)
      proto = Rails.env.development? ? 'http' : 'https'
      cert_json = URI.parse("#{proto}://#{ENV['ID_HOST']}/api/v1/certs").read
      ecdsa_x509_cert = JSON.parse(cert_json)['certificates'].values.first
      ecdsa_pub_key = OpenSSL::X509::Certificate.new(ecdsa_x509_cert).public_key
      decoded = JWT.decode(token.sub('access_', ''),
                           ecdsa_pub_key,
                           true,
                           algorithm: 'ES256')
      decoded.present? ? decoded.first.with_indifferent_access : decoded

      decoded.first.with_indifferent_access
    end


  end
end
