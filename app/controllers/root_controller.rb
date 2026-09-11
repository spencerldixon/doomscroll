class RootController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :require_setup_complete!

  def index
    if User.exists?
      redirect_to new_user_session_path
    else
      redirect_to new_user_registration_path
    end
  end
end
