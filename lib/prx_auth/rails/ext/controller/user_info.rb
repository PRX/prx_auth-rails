require "open-uri"

module PrxAuth
  module Rails
    module UserInfo
      PRX_USER_INFO_SESSION_KEY = "prx.auth.info".freeze
      PRX_ADMIN_SCOPE = "prxadmin".freeze

      def current_user
        prx_auth_token
      end

      def current_user_access?(scope = :read_private)
        current_user&.globally_authorized?(scope) || current_user&.authorized_account_ids(scope)&.any?
      end

      def current_user_info
        session[PRX_USER_INFO_SESSION_KEY] ||= begin
          info = fetch_userinfo
          info.slice("name", "preferred_username", "email", "image_href", "apps")
        end
      end

      def current_user_name
        current_user_info["name"] || current_user_info["preferred_username"] || current_user_info["email"]
      end

      def current_user_apps
        apps = (current_user_info.try(:[], "apps") || []).map do |name, url|
          label = name.sub(/^https?:\/\//, "").sub(/\..+/, "").capitalize
          ["PRX #{label}", url]
        end

        # only return entire list in development
        if ::Rails.env.production? || ::Rails.env.staging?
          apps.to_h.select { |k, v| v.match?(/\.(org|tech)/) }
        else
          apps.to_h
        end
      end

      def current_user_admin?
        current_user&.scopes&.include?(PRX_ADMIN_SCOPE)
      end

      def current_user_wildcard?
        current_user&.globally_authorized?(:read_private)
      end

      private

      def fetch_userinfo
        path = "/userinfo?scope=apps+email+profile"
        url = "https://#{PrxAuth::Rails.configuration.id_host}#{path}"
        options = {}
        options[:ssl_verify_mode] = OpenSSL::SSL::VERIFY_NONE if ::Rails.env.development?
        options["Authorization"] = "Bearer #{prx_jwt}"
        JSON.parse(URI.open(url, options).read) # standard:disable Security/Open
      end
    end
  end
end
