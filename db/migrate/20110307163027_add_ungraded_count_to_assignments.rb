class AddUngradedCountToAssignments < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :assignments, :needs_grading_count, :integer, :default => 0

    update <<-SQL
      UPDATE #{Assignment.quoted_table_name} SET needs_grading_count = COALESCE((
        SELECT COUNT(*)
        FROM #{Submission.quoted_table_name} s
        INNER JOIN #{Enrollment.quoted_table_name} e ON e.user_id = s.user_id AND e.workflow_state = 'active'
        WHERE s.assignment_id = assignments.id
          AND e.course_id = assignments.context_id
          AND (s.score IS NULL
            OR NOT grade_matches_current_submission
            OR s.workflow_state = 'submitted'
            OR s.workflow_state = 'pending_review'
          )
          AND s.submission_type IS NOT NULL
      ), 0)
      SQL
  end

  def self.down
    remove_column :assignments, :needs_grading_count
  end
end
