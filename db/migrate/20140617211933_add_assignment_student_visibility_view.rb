class AddAssignmentStudentVisibilityView < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    self.connection.execute %Q(CREATE VIEW #{connection.quote_table_name('assignment_student_visibilities')} AS
      SELECT a.id as assignment_id,
      e.user_id as user_id,
      c.id as course_id

      FROM #{Assignment.quoted_table_name} a

      JOIN #{Course.quoted_table_name} c
        ON a.context_id = c.id
        AND a.context_type = 'Course'

      JOIN #{Enrollment.quoted_table_name} e
        ON e.course_id = c.id
        AND e.type IN ('StudentEnrollment', 'StudentViewEnrollment')
        AND e.workflow_state != 'deleted'

      JOIN #{CourseSection.quoted_table_name} cs
        ON cs.course_id = c.id
        AND e.course_section_id = cs.id

      LEFT JOIN #{AssignmentOverride.quoted_table_name} ao
        ON ao.assignment_id = a.id
        AND ao.workflow_state = 'active'
        AND ao.set_type = 'CourseSection'
        AND ao.set_id = cs.id

      LEFT JOIN #{Submission.quoted_table_name} s
        ON s.user_id = e.user_id
        AND s.assignment_id = a.id
        AND s.score IS NOT NULL

      WHERE a.workflow_state NOT IN ('deleted','unpublished')
        AND ( a.only_visible_to_overrides = 'true'
          AND (ao.id IS NOT NULL
            OR s.id IS NOT NULL
          )
        ) OR (
          COALESCE(a.only_visible_to_overrides, 'false') = 'false'
        )
      )
  end

  def self.down
    self.connection.execute "DROP VIEW #{connection.quote_table_name('assignment_student_visibilities')}"
  end
end
