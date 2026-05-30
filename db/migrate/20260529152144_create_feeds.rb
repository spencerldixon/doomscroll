class CreateFeeds < ActiveRecord::Migration[8.1]
  def change
    create_table :feeds do |t|
      t.string :name
      t.string :url
      t.text :description
      t.boolean :private, default: true, null: false
      t.string :domain
      t.timestamps
    end

    add_index :feeds, :url, unique: true
    add_index :feeds, :domain
  end
end
