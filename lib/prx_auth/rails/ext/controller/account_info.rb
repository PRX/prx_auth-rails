require "open-uri"

module PrxAuth
  module Rails
    module AccountInfo
      PRX_ACCOUNT_MAPPING_SESSION_KEY = "prx.auth.account.mapping".freeze

      def account_name_for(account_id)
        account_for(account_id).try(:[], "name")
      end

      def account_for(account_id)
        lookup_accounts([account_id]).first
      end

      def accounts_for(account_ids)
        lookup_accounts(account_ids)
      end

      private

      def lookup_accounts(ids)
        return fetch_accounts(ids) unless defined?(session)

        session[PRX_ACCOUNT_MAPPING_SESSION_KEY] ||= {}

        # fetch any accounts we don't have yet
        missing = ids - session[PRX_ACCOUNT_MAPPING_SESSION_KEY].keys
        if missing.present?
          fetch_accounts(missing).each do |account|
            minimal = account.slice("name", "type")
            session[PRX_ACCOUNT_MAPPING_SESSION_KEY][account["id"]] = minimal
          end
        end

        ids.map { |id| session[PRX_ACCOUNT_MAPPING_SESSION_KEY][id] }
      end

      def fetch_accounts(ids)
        ids_param = ids.map(&:to_s).join(",")
        path = "/api/v1/accounts?account_ids=#{ids_param}"
        url = "https://#{PrxAuth::Rails.configuration.id_host}#{path}"

        options = {}
        options[:ssl_verify_mode] = OpenSSL::SSL::VERIFY_NONE if ::Rails.env.development?
        resp = JSON.parse(URI.open(url, options).read) # standard:disable Security/Open
        resp.try(:[], "_embedded").try(:[], "prx:items") || []
      end
    end
  end
end
