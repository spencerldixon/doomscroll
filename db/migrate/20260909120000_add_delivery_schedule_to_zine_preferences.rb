class AddDeliveryScheduleToZinePreferences < ActiveRecord::Migration[8.1]
  def change
    add_column :zine_preferences, :delivery_frequency, :string, null: false, default: "weekly"
    add_column :zine_preferences, :last_delivered_on, :date
  end
end
