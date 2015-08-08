class SubmissionHasAdminComment < ActiveRecord::Migration
  def self.up
    add_column :submissions, :has_admin_comment, :boolean, :default => false, :null => false
    update <<-SQL
      UPDATE #{Submission.quoted_table_name} SET has_admin_comment=EXISTS(
        SELECT 1 FROM #{SubmissionComment.quoted_table_name} AS sc, assignments AS a, courses AS c, enrollments AS e
        WHERE sc.submission_id=submissions.id AND a.id = submissions.assignment_id
          AND c.id = a.context_id AND a.context_type = 'Course' AND e.course_id = c.id
          AND e.user_id = sc.author_id AND e.workflow_state = 'active'
          AND e.type IN ('TeacherEnrollment', 'TaEnrollment'))
    SQL
  end

  def self.down
    remove_column :submissions, :has_admin_comment
  end
end
