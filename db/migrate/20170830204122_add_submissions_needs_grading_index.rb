class AddSubmissionsNeedsGradingIndex < ActiveRecord::Migration[5.0]
  tag :postdeploy
  disable_ddl_transaction!

  def change
    # see Submission.needs_grading; duplicated instead of called directly so the migration doesn't
    # change even if the query does
    add_index :submissions, :assignment_id, name: 'index_submissions_needs_grading', algorithm: :concurrently, where: <<-SQL
      submissions.submission_type IS NOT NULL
      AND (submissions.excused = 'f' OR submissions.excused IS NULL)
      AND (submissions.workflow_state = 'pending_review'
        OR (submissions.workflow_state IN ('submitted', 'graded')
          AND (submissions.score IS NULL OR NOT submissions.grade_matches_current_submission)
        )
      )
    SQL
  end
end
