class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :authenticate_user!, unless: :devise_controller?
  before_action :require_setup_complete!, unless: :devise_controller?

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_url, alert: exception.message
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :terms_and_conditions ])
  end

  def require_setup_complete!
    return unless current_user
    redirect_to onboarding_path(:name) unless current_user.setup_complete?
  end

  def after_sign_in_path_for(user)
    if user.zine_preference.nil?
      onboarding_path(:name)
    else
      authenticated_root_path
    end
  end
end
