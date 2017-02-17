class DropUnusedColumnsFromGroups < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def up
    remove_column :groups, :hashtag
    remove_column :groups, :show_public_context_messages
  end

  def down
    add_column :groups, :hashtag, :string
    add_column :groups, :show_public_context_messages, :boolean
  end
end
