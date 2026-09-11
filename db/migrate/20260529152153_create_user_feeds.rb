class CreateUserFeeds < ActiveRecord::Migration[8.1]
  def change
    create_table :user_feeds, id: false do |t|
      t.references :user, null: false, foreign_key: true
      t.references :feed, null: false, foreign_key: true
    end

    add_index :user_feeds, [ :user_id, :feed_id ], unique: true
  end
end
