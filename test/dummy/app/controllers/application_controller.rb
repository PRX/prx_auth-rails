class ApplicationController < ActionController::Base

  before_action :authenticate!

  def after_sign_in_path_for(_resource)
    '/after-sign-in-path'
  end
end
