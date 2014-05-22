class AddLtiContextIdToAccountsCoursesUsers < ActiveRecord::Migration
  tag :predeploy

  def self.up
    add_column :accounts, :lti_context_id, :string
    add_column :courses, :lti_context_id, :string
    add_column :users, :lti_context_id, :string
  end

  def self.down
    remove_column :accounts, :lti_context_id
    remove_column :courses, :lti_context_id
    remove_column :users, :lti_context_id
  end
end
