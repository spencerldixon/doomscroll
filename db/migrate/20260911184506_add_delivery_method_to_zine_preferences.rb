class AddDeliveryMethodToZinePreferences < ActiveRecord::Migration[8.1]
  def change
    add_column :zine_preferences, :delivery_method, :string, default: "email", null: false
    add_column :zine_preferences, :telegram_bot_token, :string
    add_column :zine_preferences, :telegram_chat_id, :string
  end
end
