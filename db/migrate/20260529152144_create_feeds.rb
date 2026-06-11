class CreateFeeds < ActiveRecord::Migration[8.1]
  def change
    create_enum :qualities, %w[unknown empty partial full]

    create_table :feeds do |t|
      t.string :name
      t.string :url
      t.text :description
      t.boolean :public, default: false, null: false
      t.string :domain
      t.enum :quality, enum_type: 'qualities', default: 'unknown', null: false

      t.timestamps
    end

    add_index :feeds, :url, unique: true
    add_index :feeds, :domain
  end
end
