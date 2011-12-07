class FixUngradedCounts < ActiveRecord::Migration
  def self.up
    execute <<-SQL
      UPDATE assignments SET needs_grading_count = COALESCE((
        SELECT COUNT(DISTINCT s.id)
        FROM submissions s
        INNER JOIN enrollments e ON e.user_id = s.user_id AND e.workflow_state = 'active'
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
