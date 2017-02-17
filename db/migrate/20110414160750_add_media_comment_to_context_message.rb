class AddMediaCommentToContextMessage < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :context_messages, :media_comment_id, :string
    add_column :context_messages, :media_comment_type, :string
  end

  def self.down
    remove_column :context_messages, :media_comment_type
    remove_column :context_messages, :media_comment_id
  end
end
