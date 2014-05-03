class AddForeignKeys10 < ActiveRecord::Migration
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    add_foreign_key_if_not_exists :learning_outcome_results, :users, delay_validation: true
    add_foreign_key_if_not_exists :media_objects, :users, delay_validation: true
    add_foreign_key_if_not_exists :page_comments, :users, delay_validation: true
    add_foreign_key_if_not_exists :page_views, :users, column: :real_user_id, delay_validation: true
    add_foreign_key_if_not_exists :page_views, :users, delay_validation: true
    add_foreign_key_if_not_exists :pseudonyms, :users, delay_validation: true
    add_foreign_key_if_not_exists :quiz_submissions, :users, delay_validation: true
    add_foreign_key_if_not_exists :rubric_assessments, :users, column: :assessor_id, delay_validation: true
    add_foreign_key_if_not_exists :rubric_assessments, :users, delay_validation: true
    add_foreign_key_if_not_exists :rubrics, :users, delay_validation: true
  end

  def self.down
    remove_foreign_key_if_exists :learning_outcome_results, :users
    remove_foreign_key_if_exists :media_objects, :users
    remove_foreign_key_if_exists :page_comments, :users
    remove_foreign_key_if_exists :page_views, column: :real_user_id
    remove_foreign_key_if_exists :page_views, :users
    remove_foreign_key_if_exists :pseudonyms, :users
    remove_foreign_key_if_exists :quiz_submissions, :users
    remove_foreign_key_if_exists :rubric_assessments, column: :assessor_id
    remove_foreign_key_if_exists :rubric_assessments, :users
    remove_foreign_key_if_exists :rubrics, :users
  end
end
