class AddSubmissionsQuizSubmissionsForeignKey < ActiveRecord::Migration
  tag :postdeploy
  disable_ddl_transaction!

  def up
    add_index :submissions, :quiz_submission_id, where: "quiz_submission_id IS NOT NULL", algorithm: :concurrently
    add_foreign_key :submissions, :quiz_submissions, delay_validation: true
  end

  def down
    remove_foreign_key :submissions, :quiz_submissions
    remove_index :submissions, :quiz_submission_id
  end
end
