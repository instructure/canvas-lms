class AddDiscussionTopicType < ActiveRecord::Migration[4.2]
  tag :predeploy

  # rubocop:disable Migration/RemoveColumn
  def self.up
    remove_column :discussion_topics, :threaded
    add_column :discussion_topics, :discussion_type, :string
  end

  def self.down
    remove_column :discussion_topics, :discussion_type
    add_column :discussion_topics, :threaded, :boolean
  end
end
