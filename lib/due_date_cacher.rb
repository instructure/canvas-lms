#
# Copyright (C) 2013 - present Instructure, Inc.
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

class DueDateCacher
  def self.recompute(assignment)
    recompute_course(assignment.context, [assignment.id],
      singleton: "cached_due_date:calculator:Assignment:#{assignment.global_id}")
  end

  def self.recompute_course(course, assignments = nil, inst_jobs_opts = {})
    course = Course.find(course) unless course.is_a?(Course)
    inst_jobs_opts[:singleton] ||= "cached_due_date:calculator:Course:#{course.global_id}" if assignments.nil?
    assignments ||= Assignment.where(context: course).pluck(:id)
    return if assignments.empty?
    new(course, assignments).send_later_if_production_enqueue_args(:recompute, inst_jobs_opts)
  end

  def initialize(course, assignments)
    @course = course
    @assignments = assignments
  end

  def recompute
    # in a transaction on the correct shard:
    @course.shard.activate do
      # Create dummy submissions for caching due date
      create_missing_submissions

      values = []
      effective_due_dates.each do |assignment_id, students|
        students.each do |student_id, submission_info|
          due_date = submission_info[:due_at] ? "'#{submission_info[:due_at].iso8601}'::timestamptz" : 'NULL'
          grading_period_id = submission_info[:grading_period_id] || 'NULL'
          values << [assignment_id, student_id, due_date, grading_period_id]
        end
      end
      return if values.empty?

      values = values.sort_by(&:first).map { |v| "(#{v.join(',')})" }
      values.each_slice(1000) do |batch|
        query = "UPDATE #{Submission.quoted_table_name}" \
                "  SET" \
                "    cached_due_date = vals.due_date::timestamptz," \
                "    grading_period_id = vals.grading_period_id::integer" \
                "  FROM (" \
                "    VALUES" \
                "      #{batch.join(',')}" \
                "   )" \
                "   AS vals(assignment_id, student_id, due_date, grading_period_id)" \
                "  WHERE submissions.user_id = vals.student_id and " \
                "        submissions.assignment_id = vals.assignment_id"

        Assignment.connection.execute(query)
      end
    end
  end

  private

  def effective_due_dates
    @effective_due_dates ||= EffectiveDueDates.for_course(@course, @assignments).to_hash
  end

  def student_ids
    @students ||= effective_due_dates.map { |_, assignment| assignment.keys }.flatten.uniq
  end

  def create_missing_submissions
    return if student_ids.empty?

    # Create insert scope
    insert_scope = Course
      .select("DISTINCT assignments.id, enrollments.user_id, 'unsubmitted',
               now() AT TIME ZONE 'UTC', now() AT TIME ZONE 'UTC', assignments.context_code, 0")
      .joins("INNER JOIN #{Assignment.quoted_table_name} ON assignments.context_id = courses.id
                AND assignments.context_type = 'Course'
              LEFT OUTER JOIN #{Submission.quoted_table_name} ON submissions.user_id = enrollments.user_id
                AND submissions.assignment_id = assignments.id")
      .joins(:current_enrollments)
      .where("courses.id = ? AND enrollments.user_id IN (?) AND assignments.id IN (?) AND submissions.id IS NULL",
        @course.id, student_ids, @assignments)

    # Create submissions that do not exist yet to calculate due dates for non submitted assignments.
    Assignment.connection.update("INSERT INTO #{Submission.quoted_table_name} (assignment_id,
                                  user_id, workflow_state, created_at, updated_at, context_code,
                                  process_attempts) #{insert_scope.to_sql}")
  end
end
