class AddForeignKeys1 < ActiveRecord::Migration
  self.transactional = false
  tag :postdeploy

  def self.up
    if Shard.current.default?
      add_foreign_key_if_not_exists :attachments, :scribd_mime_types, :delay_validation => true
      add_foreign_key_if_not_exists :notification_policies, :notifications, :delay_validation => true
    end

    add_foreign_key_if_not_exists :abstract_courses, :accounts, :delay_validation => true
    add_foreign_key_if_not_exists :abstract_courses, :enrollment_terms, :delay_validation => true
    add_foreign_key_if_not_exists :abstract_courses, :accounts, :column => :root_account_id, :delay_validation => true
    add_foreign_key_if_not_exists :access_tokens, :users, :delay_validation => true
    add_foreign_key_if_not_exists :account_authorization_configs, :accounts, :delay_validation => true
    add_foreign_key_if_not_exists :account_notifications, :accounts, :delay_validation => true
    add_foreign_key_if_not_exists :account_reports, :accounts, :delay_validation => true
    add_foreign_key_if_not_exists :account_reports, :attachments, :delay_validation => true
    add_foreign_key_if_not_exists :account_users, :accounts, :delay_validation => true
    add_foreign_key_if_not_exists :accounts, :accounts, :column => :parent_account_id, :delay_validation => true
    add_foreign_key_if_not_exists :accounts, :accounts, :column => :root_account_id, :delay_validation => true
    add_foreign_key_if_not_exists :alert_criteria, :alerts, :delay_validation => true
  end

  def self.down
    remove_foreign_key_if_exists :alert_criteria, :alerts
    remove_foreign_key_if_exists :accounts, :column => :root_account_id
    remove_foreign_key_if_exists :accounts, :column => :parent_account_id
    remove_foreign_key_if_exists :account_users, :accounts
    remove_foreign_key_if_exists :account_reports, :attachments
    remove_foreign_key_if_exists :account_reports, :accounts
    remove_foreign_key_if_exists :account_notifications, :accounts
    remove_foreign_key_if_exists :account_authorization_configs, :accounts
    remove_foreign_key_if_exists :access_tokens, :users
    remove_foreign_key_if_exists :abstract_courses, :column => :root_account_id
    remove_foreign_key_if_exists :abstract_courses, :enrollment_terms
    remove_foreign_key_if_exists :abstract_courses, :accounts

    if Shard.current.default?
      remove_foreign_key_if_exists :notification_policies, :notifications
      remove_foreign_key_if_exists :attachments, :scribd_mime_types
    end
  end
end
