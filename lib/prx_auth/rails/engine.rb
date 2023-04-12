module PrxAuth
  module Rails
    class Engine < ::Rails::Engine
      config.to_prepare do
        ::ApplicationController.helper_method [
          :current_user, :prx_jwt,
          :current_user_info, :current_user_name, :current_user_apps,
          :account_name_for, :account_for, :accounts_for
        ]
      end
    end
  end
end
