class Users::RegistrationsController < Devise::RegistrationsController
  before_action :redirect_when_registration_disabled, only: [ :new, :create ]

  private

  def redirect_when_registration_disabled
    return if User.registration_enabled?

    redirect_to new_user_session_path, alert: "Registration is currently disabled."
  end
end
