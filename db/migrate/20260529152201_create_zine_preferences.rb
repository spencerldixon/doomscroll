class CreateZinePreferences < ActiveRecord::Migration[8.1]
  def change
    create_table :zine_preferences do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :zine_name
      t.integer :delivery_day

      t.timestamps
    end
  end
end
