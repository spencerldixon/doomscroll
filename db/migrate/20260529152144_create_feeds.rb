class CreateFeeds < ActiveRecord::Migration[8.1]
  def change
    create_table :feeds do |t|
      t.string :name
      t.string :url
      t.text :description
      t.string :icon_url

      t.timestamps
    end
  end
end
