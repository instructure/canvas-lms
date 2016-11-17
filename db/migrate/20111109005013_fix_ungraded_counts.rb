class FixUngradedCounts < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    update <<-SQL
      UPDATE #{Assignment.quoted_table_name} SET needs_grading_count = COALESCE((
        SELECT COUNT(DISTINCT s.id)
        FROM #{Submission.quoted_table_name} s
        INNER JOIN #{Enrollment.quoted_table_name} e ON e.user_id = s.user_id AND e.workflow_state = 'active'
        WHERE s.assignment_id = assignments.id
          AND e.course_id = assignments.context_id
          AND s.submission_type IS NOT NULL
          AND (s.score IS NULL
            OR NOT grade_matches_current_submission
            OR s.workflow_state IN ('submitted', 'pending_review')
          )
      ), 0)
      SQL
  end

  def self.down
  end
end
