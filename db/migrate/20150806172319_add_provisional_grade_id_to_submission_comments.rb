class AddProvisionalGradeIdToSubmissionComments < ActiveRecord::Migration[4.2]
  tag :predeploy

  def up
    add_column :submission_comments, :provisional_grade_id, :integer, :limit => 8
    add_foreign_key :submission_comments, :moderated_grading_provisional_grades, :column => :provisional_grade_id
  end

  def down
    remove_foreign_key :submission_comments, :column => :provisional_grade_id
    remove_column :submission_comments, :provisional_grade_id
  end
end
