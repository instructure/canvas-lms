class AddForeignKeys9 < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    add_foreign_key_if_not_exists :discussion_entry_participants, :users, delay_validation: true
    add_foreign_key_if_not_exists :discussion_topic_participants, :users, delay_validation: true
    add_foreign_key_if_not_exists :discussion_topics, :users, column: :editor_id, delay_validation: true
    add_foreign_key_if_not_exists :discussion_topics, :users, delay_validation: true
    add_foreign_key_if_not_exists :enrollments, :users, column: :associated_user_id, delay_validation: true
    add_foreign_key_if_not_exists :enrollments, :users, delay_validation: true
    add_foreign_key_if_not_exists :external_feed_entries, :users, delay_validation: true
    add_foreign_key_if_not_exists :external_feeds, :users, delay_validation: true
    add_foreign_key_if_not_exists :grading_standards, :users, delay_validation: true
    add_foreign_key_if_not_exists :group_memberships, :users, delay_validation: true
  end

  def self.down
    remove_foreign_key_if_exists :discussion_entry_participants, :users
    remove_foreign_key_if_exists :discussion_topic_participants, :users
    remove_foreign_key_if_exists :discussion_topics, column: :editor_id
    remove_foreign_key_if_exists :discussion_topics, :users
    remove_foreign_key_if_exists :enrollments, column: :associated_user_id
    remove_foreign_key_if_exists :enrollments, :users
    remove_foreign_key_if_exists :external_feed_entries, :users
    remove_foreign_key_if_exists :external_feeds, :users
    remove_foreign_key_if_exists :grading_standards, :users
    remove_foreign_key_if_exists :group_memberships, :users
  end
end
