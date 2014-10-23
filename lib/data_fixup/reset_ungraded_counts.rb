module DataFixup::ResetUngradedCounts
  def self.run
    Assignment.find_ids_in_batches(batch_size: 100) do |ids|
      Assignment.connection.execute(Assignment.send(:sanitize_sql_array, [<<-SQL, ids]))
        UPDATE assignments SET needs_grading_count = COALESCE((
          SELECT COUNT(DISTINCT s.id)
          FROM submissions s
          INNER JOIN enrollments e ON e.user_id = s.user_id
          WHERE s.assignment_id = assignments.id
            AND e.course_id = assignments.context_id
            AND e.type IN ('StudentEnrollment', 'StudentViewEnrollment')
            AND e.workflow_state = 'active'
            AND s.submission_type IS NOT NULL
            AND (s.workflow_state = 'pending_review'
              OR (s.workflow_state = 'submitted' 
                AND (s.score IS NULL OR NOT s.grade_matches_current_submission)
              )
            )
          ), 0)
        WHERE id IN (?)
        SQL
    end
  end
end
