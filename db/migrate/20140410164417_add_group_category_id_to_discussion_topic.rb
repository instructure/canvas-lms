class AddGroupCategoryIdToDiscussionTopic < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :discussion_topics, :group_category_id, :integer, :limit => 8
    add_foreign_key :discussion_topics, :group_categories
  end

  def self.down
    remove_foreign_key :discussion_topics, :group_categories
    remove_column :discussion_topics, :group_category_id
  end
end
