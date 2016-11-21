class AddForeignKeys5 < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!
  tag :postdeploy

  def self.up
    add_foreign_key_if_not_exists :favorites, :users, :delay_validation => true
    add_foreign_key_if_not_exists :folders, :cloned_items, :delay_validation => true
    add_foreign_key_if_not_exists :folders, :folders, :column => :parent_folder_id, :delay_validation => true
    add_foreign_key_if_not_exists :group_memberships, :groups, :delay_validation => true
    add_foreign_key_if_not_exists :groups, :accounts, :delay_validation => true
    add_foreign_key_if_not_exists :groups, :group_categories, :delay_validation => true
    add_foreign_key_if_not_exists :groups, :accounts, :column => :root_account_id, :delay_validation => true
    add_foreign_key_if_not_exists :groups, :wikis, :delay_validation => true
    add_foreign_key_if_not_exists :learning_outcome_groups, :learning_outcome_groups, :delay_validation => true
    add_foreign_key_if_not_exists :learning_outcome_groups, :learning_outcome_groups, :column => :root_learning_outcome_group_id, :delay_validation => true
    add_foreign_key_if_not_exists :learning_outcome_results, :content_tags, :delay_validation => true
    add_foreign_key_if_not_exists :learning_outcome_results, :learning_outcomes, :delay_validation => true
    add_foreign_key_if_not_exists :media_objects, :accounts, :column => :root_account_id, :delay_validation => true
    add_foreign_key_if_not_exists :oauth_requests, :users, :delay_validation => true
  end

  def self.down
    remove_foreign_key_if_exists :oauth_requests, :users
    remove_foreign_key_if_exists :media_objects, :column => :root_account_id
    remove_foreign_key_if_exists :learning_outcome_results, :learning_outcomes
    remove_foreign_key_if_exists :learning_outcome_results, :content_tags
    remove_foreign_key_if_exists :learning_outcome_groups, :column => :root_learning_outcome_group_id
    remove_foreign_key_if_exists :learning_outcome_groups, :learning_outcome_groups
    remove_foreign_key_if_exists :groups, :wikis
    remove_foreign_key_if_exists :groups, :column => :root_account_id
    remove_foreign_key_if_exists :groups, :group_categories
    remove_foreign_key_if_exists :groups, :accounts
    remove_foreign_key_if_exists :group_memberships, :groups
    remove_foreign_key_if_exists :folders, :column => :parent_folder_id
    remove_foreign_key_if_exists :folders, :cloned_items
    remove_foreign_key_if_exists :favorites, :users
  end
end
