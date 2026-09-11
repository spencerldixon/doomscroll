class PreferencesController < ApplicationController
  def show
    @zine_preference = current_user.zine_preference
  end

  def update
    @zine_preference = current_user.zine_preference

    attributes = {
      zine_name: params[:zine_name],
      delivery_day: params[:delivery_day],
      delivery_frequency: params[:delivery_frequency],
      delivery_method: params[:delivery_method] || @zine_preference.delivery_method,
      telegram_bot_token: params[:telegram_bot_token].presence || @zine_preference.telegram_bot_token,
      telegram_chat_id: params[:telegram_chat_id].presence || @zine_preference.telegram_chat_id
    }

    if @zine_preference.update(attributes)
      redirect_to preferences_path, notice: "Preferences updated"
    else
      render :show, status: :unprocessable_entity
    end
  end
end
