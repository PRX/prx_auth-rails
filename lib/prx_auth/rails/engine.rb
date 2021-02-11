module PrxAuth
  module Rails
    class Engine < ::Rails::Engine
      config.to_prepare do
        ::ApplicationController.helper_method [:current_user, :account_name_for]
      end
    end
  end
end
