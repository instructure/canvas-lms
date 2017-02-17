class AddForeignKeys15 < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    add_foreign_key_if_not_exists :quiz_submissions, :quizzes, delay_validation: true
    add_foreign_key_if_not_exists :quizzes, :assignments, delay_validation: true
    add_foreign_key_if_not_exists :roles, :accounts, column: :root_account_id, delay_validation: true
    add_foreign_key_if_not_exists :stream_item_instances, :users, delay_validation: true
    add_foreign_key_if_not_exists :submission_comments, :submissions, delay_validation: true
    add_foreign_key_if_not_exists :submissions, :assignments, delay_validation: true
    add_foreign_key_if_not_exists :user_observers, :users, column: :observer_id, delay_validation: true
    add_foreign_key_if_not_exists :user_observers, :users, delay_validation: true
    add_foreign_key_if_not_exists :user_profile_links, :user_profiles, delay_validation: true
    add_foreign_key_if_not_exists :user_profiles, :users, delay_validation: true
    add_foreign_key_if_not_exists :web_conference_participants, :web_conferences, delay_validation: true
  end

  def self.down
    remove_foreign_key_if_exists :quiz_submissions, :quizzes
    remove_foreign_key_if_exists :quizzes, :assignments
    remove_foreign_key_if_exists :roles, :accounts, column: :root_account_id
    remove_foreign_key_if_exists :stream_item_instances, :users
    remove_foreign_key_if_exists :submission_comments, :submissions
    remove_foreign_key_if_exists :submissions, :assignments
    remove_foreign_key_if_exists :user_observers, :users, column: :observer_id
    remove_foreign_key_if_exists :user_observers, :users
    remove_foreign_key_if_exists :user_profile_links, :user_profiles
    remove_foreign_key_if_exists :user_profiles, :users
    remove_foreign_key_if_exists :web_conference_participants, :web_conferences
  end
end
