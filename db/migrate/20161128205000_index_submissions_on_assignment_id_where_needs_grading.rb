class IndexSubmissionsOnAssignmentIdWhereNeedsGrading < ActiveRecord::Migration[4.2]
  tag :predeploy
  disable_ddl_transaction!

  def change
    # from Submission.needs_grading_conditions
    conditions = <<-SQL
      submission_type IS NOT NULL
      AND (workflow_state = 'pending_review'
        OR (workflow_state = 'submitted'
          AND (score IS NULL OR NOT grade_matches_current_submission)
        )
      )
    SQL
    add_index :submissions, :assignment_id, where: conditions, algorithm: :concurrently
  end
end
