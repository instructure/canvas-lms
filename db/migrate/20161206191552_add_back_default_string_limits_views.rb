class AddBackDefaultStringLimitsViews < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def up
    remove_override_views

    add_string_limit_if_missing :assignment_overrides, :set_type
    add_string_limit_if_missing :assignment_overrides, :workflow_state

    add_string_limit_if_missing :assignments, :submission_types
    add_string_limit_if_missing :assignments, :workflow_state
    add_string_limit_if_missing :assignments, :context_type

    add_string_limit_if_missing :enrollments, :type
    add_string_limit_if_missing :enrollments, :workflow_state

    add_string_limit_if_missing :group_memberships, :workflow_state

    add_string_limit_if_missing :groups, :workflow_state
    add_string_limit_if_missing :groups, :context_type

    add_string_limit_if_missing :quizzes, :context_type
    add_string_limit_if_missing :quizzes, :workflow_state

    readd_override_views
  end

  def remove_override_views
    self.connection.execute "DROP VIEW #{connection.quote_table_name('assignment_student_visibilities')}"
    self.connection.execute "DROP VIEW #{connection.quote_table_name('quiz_student_visibilities')}"
  end

  def readd_override_views
    self.connection.execute %Q(CREATE VIEW #{connection.quote_table_name('assignment_student_visibilities')} AS
      SELECT DISTINCT a.id as assignment_id,
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

      LEFT JOIN #{GroupMembership.quoted_table_name} gm
        ON gm.user_id = e.user_id
        AND gm.workflow_state = 'accepted'

      LEFT JOIN #{Group.quoted_table_name} g
        ON g.context_type = 'Course'
        AND g.context_id = c.id
        AND g.workflow_state = 'available'
        AND gm.group_id = g.id

      LEFT JOIN #{AssignmentOverrideStudent.quoted_table_name} aos
        ON aos.assignment_id = a.id
        AND aos.user_id = e.user_id

      LEFT JOIN #{AssignmentOverride.quoted_table_name} ao
        ON ao.assignment_id = a.id
        AND ao.workflow_state = 'active'
        AND (
          (ao.set_type = 'CourseSection' AND ao.set_id = cs.id)
          OR (ao.set_type = 'ADHOC' AND ao.set_id IS NULL AND ao.id = aos.assignment_override_id)
          OR (ao.set_type = 'Group' AND ao.set_id = g.id)
        )

      LEFT JOIN #{Submission.quoted_table_name} s
        ON s.user_id = e.user_id
        AND s.assignment_id = a.id
        AND s.score IS NOT NULL

      WHERE a.workflow_state NOT IN ('deleted','unpublished')
        AND(
          ( a.only_visible_to_overrides = 'true' AND (ao.id IS NOT NULL OR s.id IS NOT NULL))
          OR (COALESCE(a.only_visible_to_overrides, 'false') = 'false')
        )
      )

    self.connection.execute %Q(CREATE VIEW #{connection.quote_table_name('quiz_student_visibilities')} AS
      SELECT DISTINCT q.id as quiz_id,
      e.user_id as user_id,
      c.id as course_id

      FROM #{Quizzes::Quiz.quoted_table_name} q

      JOIN #{Course.quoted_table_name} c
        ON q.context_id = c.id
        AND q.context_type = 'Course'

      JOIN #{Enrollment.quoted_table_name} e
        ON e.course_id = c.id
        AND e.type IN ('StudentEnrollment', 'StudentViewEnrollment')
        AND e.workflow_state != 'deleted'

      JOIN #{CourseSection.quoted_table_name} cs
        ON cs.course_id = c.id
        AND e.course_section_id = cs.id

      LEFT JOIN #{AssignmentOverrideStudent.quoted_table_name} aos
        ON aos.quiz_id = q.id
        AND aos.user_id = e.user_id

      LEFT JOIN #{AssignmentOverride.quoted_table_name} ao
        ON ao.quiz_id = q.id
        AND ao.workflow_state = 'active'
        AND (
          (ao.set_type = 'CourseSection' AND ao.set_id = cs.id)
          OR (ao.set_type = 'ADHOC' AND ao.set_id IS NULL AND ao.id = aos.assignment_override_id)
        )

      LEFT JOIN #{Assignment.quoted_table_name} a
        ON a.context_id = q.context_id
        AND a.submission_types LIKE 'online_quiz'
        AND a.id = q.assignment_id

      LEFT JOIN #{Submission.quoted_table_name} s
        ON s.user_id = e.user_id
        AND s.assignment_id = a.id
        AND s.score IS NOT NULL

      WHERE q.workflow_state NOT IN ('deleted','unpublished')
        AND(
          ( q.only_visible_to_overrides = 'true' AND (ao.id IS NOT NULL OR s.id IS NOT NULL))
          OR (COALESCE(q.only_visible_to_overrides, 'false') = 'false')
        )
      )
  end

  def add_string_limit_if_missing(table, column)
    return if column_exists?(table, column, :string, limit: 255)
    change_column table, column, :string, limit: 255
  end
end
