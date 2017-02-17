class AddForeignKeys4 < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!
  tag :postdeploy

  def self.up
    add_foreign_key_if_not_exists :discussion_topic_participants, :discussion_topics, :delay_validation => true
    add_foreign_key_if_not_exists :discussion_topics, :assignments, :delay_validation => true
    DiscussionTopic.where("NOT EXISTS (?)", Attachment.where("attachment_id=attachments.id")).update_all(attachment_id: nil)
    add_foreign_key_if_not_exists :discussion_topics, :attachments, :delay_validation => true
    add_foreign_key_if_not_exists :discussion_topics, :cloned_items, :delay_validation => true
    add_foreign_key_if_not_exists :discussion_topics, :assignments, :column => :old_assignment_id, :delay_validation => true
    add_foreign_key_if_not_exists :discussion_topics, :discussion_topics, :column => :root_topic_id, :delay_validation => true
    add_foreign_key_if_not_exists :enrollment_dates_overrides, :enrollment_terms, :delay_validation => true
    add_foreign_key_if_not_exists :enrollment_terms, :accounts, :column => :root_account_id, :delay_validation => true
    add_foreign_key_if_not_exists :enrollments, :courses, :delay_validation => true
    add_foreign_key_if_not_exists :enrollments, :accounts, :column => :root_account_id, :delay_validation => true
    add_foreign_key_if_not_exists :eportfolio_categories, :eportfolios, :delay_validation => true
    add_foreign_key_if_not_exists :eportfolio_entries, :eportfolio_categories, :delay_validation => true
    add_foreign_key_if_not_exists :eportfolio_entries, :eportfolios, :delay_validation => true
    add_foreign_key_if_not_exists :eportfolios, :users, :delay_validation => true
  end

  def self.down
    remove_foreign_key_if_exists :eportfolios, :users
    remove_foreign_key_if_exists :eportfolio_entries, :eportfolios
    remove_foreign_key_if_exists :eportfolio_entries, :eportfolio_categories
    remove_foreign_key_if_exists :eportfolio_categories, :eportfolios
    remove_foreign_key_if_exists :enrollments, :column => :root_account_id
    remove_foreign_key_if_exists :enrollments, :courses
    remove_foreign_key_if_exists :enrollment_terms, :column => :root_account_id
    remove_foreign_key_if_exists :enrollment_dates_overrides, :enrollment_terms
    remove_foreign_key_if_exists :discussion_topics, :column => :root_topic_id
    remove_foreign_key_if_exists :discussion_topics, :column => :old_assignment_id
    remove_foreign_key_if_exists :discussion_topics, :cloned_items
    remove_foreign_key_if_exists :discussion_topics, :attachments
    remove_foreign_key_if_exists :discussion_topics, :assignments
    remove_foreign_key_if_exists :discussion_topic_participants, :discussion_topics
  end
end
