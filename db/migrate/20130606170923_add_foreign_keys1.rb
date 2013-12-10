class AddForeignKeys1 < ActiveRecord::Migration
  disable_ddl_transaction!
  tag :postdeploy

  def self.up
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
    remove_foreign_key_if_exists :abstract_courses, :accounts
    remove_foreign_key_if_exists :abstract_courses, :enrollment_terms
    remove_foreign_key_if_exists :abstract_courses, :accounts, :column => :root_account_id
    remove_foreign_key_if_exists :access_tokens, :users
    remove_foreign_key_if_exists :account_authorization_configs, :accounts
    remove_foreign_key_if_exists :account_notifications, :accounts
    remove_foreign_key_if_exists :account_reports, :accounts
    remove_foreign_key_if_exists :account_reports, :attachments
    remove_foreign_key_if_exists :account_users, :accounts
    remove_foreign_key_if_exists :accounts, :accounts, :column => :parent_account_id
    remove_foreign_key_if_exists :accounts, :accounts, :column => :root_account_id
    remove_foreign_key_if_exists :alert_criteria, :alerts
  end
end
