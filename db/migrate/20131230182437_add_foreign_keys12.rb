class AddForeignKeys12 < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    add_foreign_key_if_not_exists :content_exports, :attachments, delay_validation: true
    add_foreign_key_if_not_exists :content_migrations, :attachments, delay_validation: true
    add_foreign_key_if_not_exists :conversation_messages, :conversations, delay_validation: true
    add_foreign_key_if_not_exists :course_account_associations, :accounts, delay_validation: true
    add_foreign_key_if_not_exists :course_account_associations, :course_sections, delay_validation: true
    add_foreign_key_if_not_exists :course_account_associations, :courses, delay_validation: true
    add_foreign_key_if_not_exists :courses, :abstract_courses, delay_validation: true
    DelayedMessage.where("NOT EXISTS (?) AND notification_policy_id IS NOT NULL", NotificationPolicy.where("notification_policy_id=notification_policies.id")).delete_all
    add_foreign_key_if_not_exists :delayed_messages, :notification_policies, delay_validation: true
    add_foreign_key_if_not_exists :discussion_entries, :discussion_entries, column: :parent_id, delay_validation: true
    add_foreign_key_if_not_exists :discussion_entries, :discussion_entries, column: :root_entry_id, delay_validation: true
    add_foreign_key_if_not_exists :discussion_topics, :external_feeds, delay_validation: true
    add_foreign_key_if_not_exists :enrollments, :course_sections, delay_validation: true
  end

  def self.down
    remove_foreign_key_if_exists :content_exports, :attachments
    remove_foreign_key_if_exists :content_migrations, :attachments
    remove_foreign_key_if_exists :conversation_messages, :conversations
    remove_foreign_key_if_exists :course_account_associations, :accounts
    remove_foreign_key_if_exists :course_account_associations, :course_sections
    remove_foreign_key_if_exists :course_account_associations, :courses
    remove_foreign_key_if_exists :courses, :abstract_courses
    remove_foreign_key_if_exists :delayed_messages, :notification_policies
    remove_foreign_key_if_exists :discussion_entries, :discussion_entries, column: :parent_id
    remove_foreign_key_if_exists :discussion_entries, :discussion_entries, column: :root_entry_id
    remove_foreign_key_if_exists :discussion_topics, :external_feeds
    remove_foreign_key_if_exists :enrollments, :course_sections
  end
end
