class PreferencesController < ApplicationController
  def show
    @zine_preference = current_user.zine_preference
  end

  def update
    @zine_preference = current_user.zine_preference

    if @zine_preference.update(zine_name: params[:zine_name], delivery_day: params[:delivery_day])
      redirect_to preferences_path, notice: "Preferences updated"
    else
      render :show, status: :unprocessable_entity
    end
  end
end
