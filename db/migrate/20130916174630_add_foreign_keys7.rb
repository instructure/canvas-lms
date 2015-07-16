class AddForeignKeys7 < ActiveRecord::Migration
  disable_ddl_transaction!
  tag :postdeploy

  def self.up
    UserAccountAssociation.where("NOT EXISTS (?)", Account.where("account_id=accounts.id")).delete_all
    add_foreign_key_if_not_exists :user_account_associations, :accounts, :delay_validation => true
    UserAccountAssociation.where("NOT EXISTS (?)", User.where("user_id=users.id")).delete_all
    add_foreign_key_if_not_exists :user_account_associations, :users, :delay_validation => true
    add_foreign_key_if_not_exists :user_services, :users, :delay_validation => true
    add_foreign_key_if_not_exists :web_conferences, :users, :delay_validation => true
    add_foreign_key_if_not_exists :wiki_pages, :cloned_items, :delay_validation => true
    add_foreign_key_if_not_exists :wiki_pages, :users, :delay_validation => true
    add_foreign_key_if_not_exists :wiki_pages, :wikis, :delay_validation => true
    add_foreign_key_if_not_exists :zip_file_imports, :attachments, :delay_validation => true
    add_foreign_key_if_not_exists :zip_file_imports, :folders, :delay_validation => true
  end

  def self.down
    remove_foreign_key_if_exists :zip_file_imports, :folders
    remove_foreign_key_if_exists :zip_file_imports, :attachments
    remove_foreign_key_if_exists :wiki_pages, :wikis
    remove_foreign_key_if_exists :wiki_pages, :users
    remove_foreign_key_if_exists :wiki_pages, :cloned_items
    remove_foreign_key_if_exists :web_conferences, :users
    remove_foreign_key_if_exists :user_services, :users
    remove_foreign_key_if_exists :user_account_associations, :users
    remove_foreign_key_if_exists :user_account_associations, :accounts
  end
end
