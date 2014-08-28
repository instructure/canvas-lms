class AddUniqueIndexOnLtiContextId < ActiveRecord::Migration
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    add_index :accounts, :lti_context_id, :unique => true, algorithm: :concurrently
    add_index :courses, :lti_context_id, :unique => true, algorithm: :concurrently
    add_index :users, :lti_context_id, :unique => true, algorithm: :concurrently
  end

  def self.down
  remove_index :accounts, :lti_context_id
  remove_index :courses, :lti_context_id
  remove_index :users, :lti_context_id
  end
end