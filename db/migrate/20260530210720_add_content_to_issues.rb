class AddContentToIssues < ActiveRecord::Migration[8.1]
  def change
    add_column :issues, :content, :jsonb, default: [], null: false
  end
end
