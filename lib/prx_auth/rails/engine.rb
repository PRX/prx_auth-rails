module PrxAuth
  module Rails
    class Engine < ::Rails::Engine
      config.to_prepare do
        ::ApplicationController.helper_method [
          :current_user, :prx_jwt,
          :account_name_for, :account_for, :accounts_for,
        ]
      end
    end
  end
end
