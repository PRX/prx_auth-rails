module PrxAuth::Rails
  module SessionsHelper
    def current_user_app?(name)
      current_user && current_user_app(name).present?
    end

    def current_user_app(name)
      current_user_apps.find { |key, url| key.downcase.include?(name) }&.last
    end

    def current_user_id_profile
      "https://#{PrxAuth::Rails.configuration.id_host}/profile"
    end

    def current_user_id_accounts
      "https://#{PrxAuth::Rails.configuration.id_host}/accounts"
    end

    def current_user_image?
      current_user && current_user_image.present?
    end

    def current_user_image
      current_user_info["image_href"]
    end
  end
end
