class CreateIssues < ActiveRecord::Migration[8.1]
  def change
    create_table :issues do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :number, null: false
      t.datetime :published_at, null: false
      t.string :title, null: false
      t.json :content, default: [], null: false

      t.timestamps
    end

    add_index :issues, [:user_id, :number], unique: true
  end
end
