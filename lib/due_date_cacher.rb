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
  INFER_SUBMISSION_WORKFLOW_STATE_SQL = <<~SQL_FRAGMENT
    CASE
    WHEN grade IS NOT NULL OR excused IS TRUE THEN
      'graded'
    WHEN submission_type = 'online_quiz' AND quiz_submission_id IS NOT NULL THEN
      'pending_review'
    WHEN submission_type IS NOT NULL AND submitted_at IS NOT NULL THEN
      'submitted'
    ELSE
      'unsubmitted'
    END
  SQL_FRAGMENT

  def self.recompute(assignment, update_grades: false)
    current_caller = caller(1..1).first
    Rails.logger.debug "DDC.recompute(#{assignment&.id}) - #{current_caller}"
    return unless assignment.active?
    opts = {
      assignments: [assignment.id],
      inst_jobs_opts: {
        singleton: "cached_due_date:calculator:Assignment:#{assignment.global_id}"
      },
      update_grades: update_grades,
      original_caller: current_caller
    }

    recompute_course(assignment.context, opts)
  end

  def self.recompute_course(course, assignments: nil, inst_jobs_opts: {}, run_immediately: false, update_grades: false, original_caller: caller(1..1).first)
    Rails.logger.debug "DDC.recompute_course(#{course.inspect}, #{assignments.inspect}, #{inst_jobs_opts.inspect}) - #{original_caller}"
    course = Course.find(course) unless course.is_a?(Course)
    inst_jobs_opts[:singleton] ||= "cached_due_date:calculator:Course:#{course.global_id}" if assignments.nil?

    assignments_to_recompute = assignments || Assignment.active.where(context: course).pluck(:id)
    return if assignments_to_recompute.empty?

    due_date_cacher = new(course, assignments_to_recompute, update_grades: update_grades, original_caller: original_caller)
    if run_immediately
      due_date_cacher.recompute
    else
      due_date_cacher.send_later_if_production_enqueue_args(:recompute, inst_jobs_opts)
    end
  end

  def self.recompute_users_for_course(user_ids, course, assignments = nil, inst_jobs_opts = {})
    user_ids = Array(user_ids)
    course = Course.find(course) unless course.is_a?(Course)
    if assignments.nil?
      inst_jobs_opts[:singleton] ||= "cached_due_date:calculator:Users:#{course.global_id}:#{Digest::MD5.hexdigest(user_ids.sort.join(':'))}"
    end
    assignments ||= Assignment.active.where(context: course).pluck(:id)
    return if assignments.empty?

    current_caller = caller(1..1).first
    update_grades = inst_jobs_opts.delete(:update_grades) || false
    due_date_cacher = new(course, assignments, user_ids, update_grades: update_grades, original_caller: current_caller)

    run_immediately = inst_jobs_opts.delete(:run_immediately) || false
    if run_immediately
      due_date_cacher.recompute
    else
      due_date_cacher.send_later_if_production_enqueue_args(:recompute, inst_jobs_opts)
    end
  end

  def initialize(course, assignments, user_ids = [], update_grades: false, original_caller: caller(1..1).first)
    @course = course
    @assignment_ids = Array(assignments).map { |a| a.is_a?(Assignment) ? a.id : a }
    @user_ids = Array(user_ids)
    @update_grades = update_grades
    @original_caller = original_caller
  end

  def recompute
    Rails.logger.debug "DUE DATE CACHER STARTS: #{Time.zone.now.to_i}"
    Rails.logger.debug "DDC#recompute() - original caller: #{@original_caller}"
    Rails.logger.debug "DDC#recompute() - current caller: #{caller(1..1).first}"

    # in a transaction on the correct shard:
    @course.shard.activate do
      values = []
      effective_due_dates.to_hash.each do |assignment_id, student_due_dates|
        students_without_priors = student_due_dates.keys - enrollment_counts.prior_student_ids
        existing_anonymous_ids = Submission.where.not(user: nil).
          where(user: students_without_priors).
          anonymous_ids_for(assignment_id)

        students_without_priors.each do |student_id|
          submission_info = student_due_dates[student_id]
          due_date = submission_info[:due_at] ? "'#{submission_info[:due_at].iso8601}'::timestamptz" : 'NULL'
          grading_period_id = submission_info[:grading_period_id] || 'NULL'

          anonymous_id = Submission.generate_unique_anonymous_id(
            assignment: assignment_id,
            existing_anonymous_ids: existing_anonymous_ids
          )
          existing_anonymous_ids << anonymous_id
          sql_ready_anonymous_id = Submission.connection.quote(anonymous_id)
          values << [assignment_id, student_id, due_date, grading_period_id, sql_ready_anonymous_id]
        end
      end

      # Delete submissions for students who don't have visibility to this assignment anymore
      @assignment_ids.each do |assignment_id|
        assigned_student_ids = effective_due_dates.find_effective_due_dates_for_assignment(assignment_id).keys
        submission_scope = Submission.active.where(assignment_id: assignment_id)

        if @user_ids.blank? && assigned_student_ids.blank? && enrollment_counts.prior_student_ids.blank?
          submission_scope.in_batches.update_all(workflow_state: :deleted)
        else
          # Delete the users we KNOW we need to delete in batches (it makes the database happier this way)
          deletable_student_ids =
            enrollment_counts.accepted_student_ids - assigned_student_ids - enrollment_counts.prior_student_ids
          deletable_student_ids.each_slice(1000) do |deletable_student_ids_chunk|
            # using this approach instead of using .in_batches because we want to limit the IDs in the IN clause to 1k
            submission_scope.where(user_id: deletable_student_ids_chunk).update_all(workflow_state: :deleted)
          end
        end
      end

      # Get any stragglers that might have had their enrollment removed from the course
      # 100 students at a time for 10 assignments each == slice of up to 1K submissions
      enrollment_counts.deleted_student_ids.each_slice(100) do |student_slice|
        @assignment_ids.each_slice(10) do |assignment_ids_slice|
          Submission.active.
            where(assignment_id: assignment_ids_slice, user_id: student_slice).
            update_all(workflow_state: :deleted)
        end
      end

      return if values.empty?

      # prepare values for SQL interpolation
      values = values.sort_by(&:first).map { |v| "(#{v.join(',')})" }
      values.each_slice(1000) do |batch|
        # Construct upsert statement to update existing Submissions or create them if needed.
        query = <<~SQL
          UPDATE #{Submission.quoted_table_name}
            SET
              cached_due_date = vals.due_date::timestamptz,
              grading_period_id = vals.grading_period_id::integer,
              workflow_state = COALESCE(NULLIF(workflow_state, 'deleted'), (
                #{INFER_SUBMISSION_WORKFLOW_STATE_SQL}
              )),
              anonymous_id = COALESCE(submissions.anonymous_id, vals.anonymous_id)
            FROM (VALUES #{batch.join(',')})
              AS vals(assignment_id, student_id, due_date, grading_period_id, anonymous_id)
            WHERE submissions.user_id = vals.student_id AND
                  submissions.assignment_id = vals.assignment_id;
          INSERT INTO #{Submission.quoted_table_name}
            (assignment_id, user_id, workflow_state, created_at, updated_at, context_code, process_attempts,
            cached_due_date, grading_period_id, anonymous_id)
            SELECT
              assignments.id, vals.student_id, 'unsubmitted',
              now() AT TIME ZONE 'UTC', now() AT TIME ZONE 'UTC',
              assignments.context_code, 0, vals.due_date::timestamptz, vals.grading_period_id::integer,
              vals.anonymous_id
            FROM (VALUES #{batch.join(',')})
              AS vals(assignment_id, student_id, due_date, grading_period_id, anonymous_id)
            INNER JOIN #{Assignment.quoted_table_name} assignments
              ON assignments.id = vals.assignment_id
            LEFT OUTER JOIN #{Submission.quoted_table_name} submissions
              ON submissions.assignment_id = assignments.id
              AND submissions.user_id = vals.student_id
            WHERE submissions.id IS NULL;
        SQL

        Assignment.connection.execute(query)
      end
    end

    if @update_grades
      @course.recompute_student_scores_without_send_later(@user_ids)
    end

    if @assignment_ids.size == 1
      # Only changes to LatePolicy or (sometimes) Assignment records can result in a re-calculation
      # of student scores.  No changes to the Course record can trigger such re-calculations so
      # let's ensure this is triggered only when DueDateCacher is called for a Assignment-level
      # changes and not for Course-level changes
      assignment = Assignment.find(@assignment_ids.first)

      LatePolicyApplicator.for_assignment(assignment)
    end
  end

  private

  EnrollmentCounts = Struct.new(:accepted_student_ids, :prior_student_ids, :deleted_student_ids)
  def enrollment_counts
    @enrollment_counts ||= begin
      counts = EnrollmentCounts.new([], [], [])

      Shackles.activate(:slave) do
        # The various workflow states below try to mimic similarly named scopes off of course
        scope = Enrollment.select(
          :user_id,
          "count(nullif(workflow_state not in ('rejected', 'deleted', 'completed'), false)) as accepted_count",
          "count(nullif(workflow_state in ('completed'), false)) as prior_count",
          "count(nullif(workflow_state in ('rejected', 'deleted'), false)) as deleted_count"
        ).
          where(course_id: @course, type: ['StudentEnrollment', 'StudentViewEnrollment']).
          group(:user_id)

        scope = scope.where(user_id: @user_ids) if @user_ids.present?

        scope.find_each do |record|
          if record.accepted_count == 0 && record.deleted_count > 0
            counts.deleted_student_ids << record.user_id
          elsif record.accepted_count == 0 && record.prior_count > 0
            counts.prior_student_ids << record.user_id
          elsif record.accepted_count > 0
            counts.accepted_student_ids << record.user_id
          else
            raise "Unknown enrollment state: #{record.accepted_count}, #{record.prior_count}, #{record.deleted_count}"
          end
        end
      end
      counts
    end
  end

  def effective_due_dates
    @effective_due_dates ||= begin
      edd = EffectiveDueDates.for_course(@course, @assignment_ids)
      edd.filter_students_to(@user_ids) if @user_ids.present?
      edd
    end
  end
end
