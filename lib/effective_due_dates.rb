#
# Copyright (C) 2016 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

class EffectiveDueDates
  attr_reader :context, :filtered_students

  # This class will find the effective due dates for all students
  # and assignments in a course. You can pass it a list of assignments,
  # assignment id's, or a relation, but they MUST be from the same course.
  # Also cross-shard id's won't work.

  # This class does NOT find the effective due dates for ungraded quizzes
  # which can still have due date overrides.  If the logic in this file
  # needs to be changed, please consider updating the logic in the
  # "ungraded_with_user_due_date" quiz scope

  def initialize(context, *assignment_collection)
    raise "Context must be a course" unless context.is_a?(Course)
    raise "Context must have an id" unless context.id

    @context = context
    @assignments = assignment_collection
  end

  # EffectiveDueDates.for_course(...) just reads more
  # like Canvas code than EffectiveDueDates.new(...)
  singleton_class.send :alias_method, :for_course, :new

  def filter_students_to(*students)
    if students.present?
      students.flatten!
      students.map! { |s| Shard.relative_id_for(s.try(:id) || s, Shard.current, @context.shard) }
      students.compact!
      @filtered_students = students
    end

    return self # allows us to chain this method
  end

  def to_hash(included = [])
    return @hash if @hash && included.empty?

    hash = query.each_with_object({}) do |row, hsh|
      assignment_id = row.delete("assignment_id").to_i
      student_id = row.delete("student_id").to_i
      hsh[assignment_id] ||= {}
      attributes = {}
      if include?(included, :due_at)
        attributes[:due_at] = row["due_at"] && DateTime.parse(row["due_at"])
      end
      if include?(included, :grading_period_id)
        attributes[:grading_period_id] = row["grading_period_id"] && row["grading_period_id"].to_i
      end
      if include?(included, :in_closed_grading_period)
        attributes[:in_closed_grading_period] = row["closed"]
      end
      if include?(included, :override_id)
        attributes[:override_id] = row["override_id"] && row["override_id"].to_i
      end
      attributes[:override_source] = row["override_type"] if include?(included, :override_source)
      hsh[assignment_id][student_id] = attributes
    end

    @hash = hash if included.empty?
    hash
  end

  # This iterates through a course's EffectiveDueDate hash with multiple
  # assignments to see if any of them are in a closed grading period.
  def any_in_closed_grading_period?
    return @any_in_closed_grading_period unless @any_in_closed_grading_period.nil?

    @any_in_closed_grading_period = @context.grading_periods? &&
        to_hash.any? do |_, assignment_due_dates|
          any_student_in_closed_grading_period?(assignment_due_dates)
        end
  end

  # This iterates through a single assignment's EffectiveDueDate hash to see
  # if any students in them are in a closed grading period.
  def in_closed_grading_period?(assignment_id, student_or_student_id = nil)
    assignment_id = assignment_id.id if assignment_id.is_a?(Assignment)
    return false if assignment_id.nil?

    # false if there aren't even grading periods set up
    return false unless @context.grading_periods?
    # if we've already checked all assignments and it was false,
    # no need to check this one specifically
    return false if @any_in_closed_grading_period == false

    student_id = student_or_student_id.try(:id) || student_or_student_id
    if student_id.to_i > 0
      find_effective_due_date(student_id, assignment_id).fetch(:in_closed_grading_period, false)
    else
      assignment_due_dates = find_effective_due_dates_for_assignment(assignment_id)
      any_student_in_closed_grading_period?(assignment_due_dates)
    end
  end

  def grading_period_id_for(student_id:, assignment_id:)
    find_effective_due_date(student_id, assignment_id)[:grading_period_id]
  end

  def find_effective_due_date(student_id, assignment_id)
    student_id = Shard.relative_id_for(student_id, Shard.current, @context.shard)
    unless include?(@filtered_students, student_id)
      raise "Student #{student_id} was not included in this query"
    end

    find_effective_due_dates_for_assignment(assignment_id).fetch(student_id, {})
  end

  def find_effective_due_dates_for_assignment(assignment_id)
    to_hash.fetch(Shard.relative_id_for(assignment_id, Shard.current, @context.shard), {})
  end

  private

  def any_student_in_closed_grading_period?(assignment_due_dates)
    return false unless assignment_due_dates
    assignment_due_dates.any? { |_, student| student[:in_closed_grading_period] }
  end

  def include?(included, attribute)
    included.blank? || included.include?(attribute)
  end

  def filter_students_sql(table)
    if @filtered_students.present?
      "AND #{table}.user_id IN (#{filtered_students.join(',')})"
    else
      ''
    end
  end

  # This beauty of a method brings together assignment overrides,
  # due dates, grading periods, course/group enrollments, etc
  # to calculate each student's effective due date and whether or
  # not that due date is in a closed grading period. If a student
  # is not included in this hash, that student cannot see this
  # assignment. The format of the returned hash is:
  # {
  #   assignment_id => {
  #     student_id => {
  #       due_at: some date or nil (if assigned but no explicit due date),
  #       grading_period_id: id or nil,
  #       in_closed_grading_period: true or false
  #     }, ...
  #   }, ...
  # }
  def query
    @query ||= @context.shard.activate do
      # default to all active assignments on this course if nothing is passed
      assignment_collection = @assignments.empty? ? [@context.active_assignments] : @assignments

      if assignment_collection.length == 1 &&
        assignment_collection.first.respond_to?(:to_sql) &&
        !assignment_collection.first.loaded?
        # it's a relation, let's not load it unnecessarily out here
        assignment_collection = assignment_collection.first.except(:order).select(:id).to_sql
      else
        # otherwise, map through the array as necessary to get id's
        assignment_collection.flatten!
        assignment_collection.map!{ |assignment| assignment.try(:id) } if assignment_collection.first.is_a?(Assignment)
        assignment_collection.compact!
        assignment_collection = assignment_collection.join(',')
      end

      if assignment_collection.empty?
        {}
      else
        ActiveRecord::Base.connection.select_all(<<-SQL)
          -- fetch the assignment itself
          WITH models AS (
            SELECT *
            FROM #{Assignment.quoted_table_name}
            WHERE
              id IN (#{assignment_collection}) AND
              workflow_state <> 'deleted' AND
              context_id = #{@context.id} AND context_type = 'Course'
          ),

          -- fetch all overrides for this assignment
          overrides AS (
            SELECT
              o.id,
              o.assignment_id,
              o.set_type,
              o.set_id,
              o.due_at_overridden,
              CASE WHEN o.due_at_overridden IS TRUE THEN o.due_at ELSE a.due_at END AS due_at
            FROM
              models a
            INNER JOIN #{AssignmentOverride.quoted_table_name} o ON o.assignment_id = a.id
            WHERE
              o.workflow_state = 'active'
          ),

          -- fetch all students affected by adhoc overrides
          override_adhoc_students AS (
            SELECT
              os.user_id AS student_id,
              o.assignment_id,
              o.id AS override_id,
              date_trunc('minute', o.due_at) AS trunc_due_at,
              o.due_at,
              o.set_type AS override_type,
              o.due_at_overridden,
              1 AS priority
            FROM
              overrides o
            INNER JOIN #{AssignmentOverrideStudent.quoted_table_name} os ON os.assignment_override_id = o.id AND
              os.workflow_state = 'active'
            WHERE
              o.set_type = 'ADHOC'
              #{filter_students_sql('os')}
          ),

          -- fetch all students affected by group overrides
          override_groups_students AS (
            SELECT
              gm.user_id AS student_id,
              o.assignment_id,
              o.id AS override_id,
              date_trunc('minute', o.due_at) AS trunc_due_at,
              o.due_at,
              o.set_type AS override_type,
              o.due_at_overridden,
              1 AS priority
            FROM
              overrides o
            INNER JOIN #{Group.quoted_table_name} g ON g.id = o.set_id
            INNER JOIN #{GroupMembership.quoted_table_name} gm ON gm.group_id = g.id
            WHERE
              o.set_type = 'Group' AND
              g.workflow_state <> 'deleted' AND
              gm.workflow_state = 'accepted'
              #{filter_students_sql('gm')}
          ),

          -- fetch all students affected by section overrides
          override_sections_students AS (
            SELECT
              e.user_id AS student_id,
              o.assignment_id,
              o.id AS override_id,
              date_trunc('minute', o.due_at) AS trunc_due_at,
              o.due_at,
              o.set_type AS override_type,
              o.due_at_overridden,
              1 AS priority
            FROM
              overrides o
            INNER JOIN #{CourseSection.quoted_table_name} s ON s.id = o.set_id
            INNER JOIN #{Enrollment.quoted_table_name} e ON e.course_section_id = s.id
            WHERE
              o.set_type = 'CourseSection' AND
              s.workflow_state <> 'deleted' AND
              e.workflow_state NOT IN ('rejected', 'deleted', 'inactive') AND
              e.type IN ('StudentEnrollment', 'StudentViewEnrollment')
              #{filter_students_sql('e')}
          ),

          -- fetch all students who have an 'Everyone Else'
          -- due date applied to them from the assignment
          override_everyonelse_students AS (
            SELECT
              e.user_id AS student_id,
              a.id as assignment_id,
              NULL::integer AS override_id,
              date_trunc('minute', a.due_at) AS trunc_due_at,
              a.due_at,
              'Everyone Else'::varchar AS override_type,
              FALSE AS due_at_overridden,
              2 AS priority
            FROM
              models a
            INNER JOIN #{Enrollment.quoted_table_name} e ON e.course_id = a.context_id
            WHERE
              e.workflow_state NOT IN ('rejected', 'deleted') AND
              e.type IN ('StudentEnrollment', 'StudentViewEnrollment') AND
              a.only_visible_to_overrides IS NOT TRUE
              #{filter_students_sql('e')}
          ),

          -- join all these students together into a single table
          override_all_students AS (
            SELECT * FROM override_adhoc_students
            UNION ALL
            SELECT * FROM override_groups_students
            UNION ALL
            SELECT * FROM override_sections_students
            UNION ALL
            SELECT * FROM override_everyonelse_students
          ),

          -- and pick the latest override date as the effective due date
          calculated_overrides AS (
            SELECT DISTINCT ON (student_id, assignment_id)
              *
            FROM override_all_students
            ORDER BY student_id ASC, assignment_id ASC, priority ASC, due_at_overridden DESC, due_at DESC NULLS FIRST
          ),

          -- now find all grading periods, including both
          -- legacy course periods and newer account-level periods
          course_and_account_grading_periods AS (
              SELECT DISTINCT ON (gp.id)
                gp.id,
                date_trunc('minute', gp.start_date) AS start_date,
                date_trunc('minute', gp.end_date) AS end_date,
                date_trunc('minute', gp.close_date) AS close_date,
                gpg.course_id,
                gpg.account_id
              FROM
                models a
              INNER JOIN #{Course.quoted_table_name} c ON c.id = a.context_id
              INNER JOIN #{EnrollmentTerm.quoted_table_name} term ON c.enrollment_term_id = term.id
              LEFT OUTER JOIN #{GradingPeriodGroup.quoted_table_name} gpg ON
                  gpg.course_id = c.id OR gpg.id = term.grading_period_group_id
              LEFT OUTER JOIN #{GradingPeriod.quoted_table_name} gp ON gp.grading_period_group_id = gpg.id
              WHERE
                gpg.workflow_state = 'active' AND
                gp.workflow_state = 'active'
          ),

          -- then filter down to the grading periods we care about:
          -- if legacy periods exist, only return those. Otherwise,
          -- return the account-level periods.
          applied_grading_periods AS (
            SELECT *
            FROM course_and_account_grading_periods
            WHERE
              EXISTS (
                SELECT 1 FROM course_and_account_grading_periods WHERE course_id IS NOT NULL
              ) AND course_id IS NOT NULL
            UNION ALL
            SELECT *
            FROM course_and_account_grading_periods
            WHERE
              NOT EXISTS (
                SELECT 1 FROM course_and_account_grading_periods WHERE course_id IS NOT NULL
              ) AND account_id IS NOT NULL
          ),

          -- infinite due dates are put in the last grading period.
          -- better to fetch it once since we'll likely reference it multiple times below
          last_period AS (
            SELECT id, close_date FROM applied_grading_periods ORDER BY end_date DESC LIMIT 1
          )

          -- finally bring it all together!
          SELECT
            overrides.assignment_id,
            overrides.student_id,
            overrides.due_at,
            overrides.override_type,
            overrides.override_id,
            CASE
              -- check whether or not this due date falls in a closed grading period
              WHEN overrides.due_at IS NOT NULL AND '#{Time.zone.now.iso8601}'::timestamptz >= periods.close_date THEN TRUE
              -- when no explicit due date is provided, we treat it as if it's in the latest grading period
              WHEN overrides.due_at IS NULL AND
                  overrides.override_type <> 'Submission' AND
                  '#{Time.zone.now.iso8601}'::timestamptz >= (SELECT close_date FROM last_period) THEN TRUE
              ELSE FALSE
            END AS closed,
            CASE
              -- if infinite due date, put it in the last grading period
              WHEN overrides.due_at IS NULL AND
                  overrides.override_type <> 'Submission' THEN (SELECT id FROM last_period)
              -- otherwise, put it in whatever grading period id we found for it
              ELSE periods.id
            END AS grading_period_id
          FROM calculated_overrides overrides
          -- match the effective due date with its grading period
          LEFT OUTER JOIN applied_grading_periods periods ON
              periods.start_date < overrides.trunc_due_at AND overrides.trunc_due_at <= periods.end_date
        SQL
      end
    end
  end
end
