# frozen_string_literal: true

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

require 'anonymity'

class DueDateCacher
  include Moderation

  thread_mattr_accessor :executing_users, instance_accessor: false

  # These methods allow the caller to specify a user to whom due date
  # changes should be attributed (currently this is used for creating
  # audit events for anonymous or moderated assignments), and are meant
  # to be used when DueDateCacher is invoked in a callback or a similar
  # place where directly specifying an executing user is impractical.
  #
  # DueDateCacher.with_executing_user(a_user) do
  #   # do something to update due dates, like saving an assignment override
  #   # any DDC calls that occur while an executing user is set will
  #   # attribute changes to that user
  # end
  #
  # Users are stored on a stack, so nested calls will work as expected.
  # A value of nil may also be passed to indicate that no user should be
  # credited (in which case audit events will not be recorded).
  #
  # You may also specify a user explicitly when calling the class methods:
  #   DueDateCacher.recompute(assignment, update_grades: true, executing_user: a_user)
  #
  # An explicitly specified user will take precedence over any users specified
  # via with_executing_user, but will not otherwise affect the current "stack"
  # of executing users.
  #
  # If you are calling DueDateCacher in a delayed job of your own making (e.g.,
  # Assignment#run_if_overrides_changed_later!), you should pass a user
  # explicitly rather than relying on the user stored in with_executing_user
  # at the time you create the delayed job.
  def self.with_executing_user(user)
    self.executing_users ||= []
    self.executing_users.push(user)

    begin
      result = yield
    ensure
      self.executing_users.pop
    end
    result
  end

  def self.current_executing_user
    self.executing_users ||= []
    self.executing_users.last
  end

  INFER_SUBMISSION_WORKFLOW_STATE_SQL = <<~SQL_FRAGMENT.freeze
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

  def self.recompute(assignment, update_grades: false, executing_user: nil)
    current_caller = caller(1..1).first
    Rails.logger.debug "DDC.recompute(#{assignment&.id}) - #{current_caller}"
    return unless assignment.persisted? && assignment.active?
    # We use a strand here instead of a singleton because a bunch of
    # assignment updates with upgrade_grades could end up causing
    # score table fights.
    opts = {
      assignments: [assignment.id],
      inst_jobs_opts: {
        strand: "cached_due_date:calculator:Course:Assignments:#{assignment.context.global_id}",
        max_attempts: 10
      },
      update_grades: update_grades,
      original_caller: current_caller,
      executing_user: executing_user
    }

    recompute_course(assignment.context, **opts)
  end

  def self.recompute_course(course, assignments: nil, inst_jobs_opts: {}, run_immediately: false, update_grades: false, original_caller: caller(1..1).first, executing_user: nil)
    Rails.logger.debug "DDC.recompute_course(#{course.inspect}, #{assignments.inspect}, #{inst_jobs_opts.inspect}) - #{original_caller}"
    course = Course.find(course) unless course.is_a?(Course)
    inst_jobs_opts[:max_attempts] ||= 10
    inst_jobs_opts[:singleton] ||= "cached_due_date:calculator:Course:#{course.global_id}" if assignments.nil? && !inst_jobs_opts[:strand]

    assignments_to_recompute = assignments || Assignment.active.where(context: course).pluck(:id)
    return if assignments_to_recompute.empty?

    executing_user ||= self.current_executing_user
    due_date_cacher = new(course, assignments_to_recompute, update_grades: update_grades, original_caller: original_caller, executing_user: executing_user)
    if run_immediately
      due_date_cacher.recompute
    else
      due_date_cacher.delay_if_production(**inst_jobs_opts).recompute
    end
  end

  def self.recompute_users_for_course(user_ids, course, assignments = nil, inst_jobs_opts = {})
    user_ids = Array(user_ids)
    course = Course.find(course) unless course.is_a?(Course)
    inst_jobs_opts[:max_attempts] ||= 10
    if assignments.nil?
      inst_jobs_opts[:singleton] ||= "cached_due_date:calculator:Users:#{course.global_id}:#{Digest::SHA256.hexdigest(user_ids.sort.join(':'))}"
    end
    assignments ||= Assignment.active.where(context: course).pluck(:id)
    return if assignments.empty?

    current_caller = caller(1..1).first
    update_grades = inst_jobs_opts.delete(:update_grades) || false
    executing_user = inst_jobs_opts.delete(:executing_user) || self.current_executing_user
    due_date_cacher = new(course, assignments, user_ids, update_grades: update_grades, original_caller: current_caller, executing_user: executing_user)

    due_date_cacher.delay_if_production(**inst_jobs_opts).recompute
  end

  def initialize(course, assignments, user_ids = [], update_grades: false, original_caller: caller(1..1).first, executing_user: nil)
    @course = course

    @assignment_ids = Array(assignments).map { |a| a.is_a?(Assignment) ? a.id : a }
    @assignments_auditable_by_id = if @assignment_ids.present?
      Set.new(Assignment.auditable.where(id: @assignment_ids).pluck(:id))
    else
      Set.new
    end

    @user_ids = Array(user_ids)
    @update_grades = update_grades
    @original_caller = original_caller

    if executing_user.present?
      @executing_user_id = executing_user.is_a?(User) ? executing_user.id : executing_user
    end
  end

  def recompute
    Rails.logger.debug "DUE DATE CACHER STARTS: #{Time.zone.now.to_i}"
    Rails.logger.debug "DDC#recompute() - original caller: #{@original_caller}"
    Rails.logger.debug "DDC#recompute() - current caller: #{caller(1..1).first}"

    # in a transaction on the correct shard:
    @course.shard.activate do
      values = []

      assignments_by_id = Assignment.find(@assignment_ids).index_by(&:id)

      effective_due_dates.to_hash.each do |assignment_id, student_due_dates|
        students_without_priors = student_due_dates.keys - enrollment_counts.prior_student_ids
        existing_anonymous_ids = existing_anonymous_ids_by_assignment_id[assignment_id]

        create_moderation_selections_for_assignment(assignments_by_id[assignment_id], student_due_dates.keys, @user_ids)

        quiz_lti = quiz_lti_assignments.include?(assignment_id)

        students_without_priors.each do |student_id|
          submission_info = student_due_dates[student_id]
          due_date = submission_info[:due_at] ? "'#{submission_info[:due_at].iso8601}'::timestamptz" : 'NULL'
          grading_period_id = submission_info[:grading_period_id] || 'NULL'

          anonymous_id = Anonymity.generate_id(existing_ids: existing_anonymous_ids)
          existing_anonymous_ids << anonymous_id
          sql_ready_anonymous_id = Submission.connection.quote(anonymous_id)
          values << [assignment_id, student_id, due_date, grading_period_id, sql_ready_anonymous_id, quiz_lti, @course.root_account_id]
        end
      end

      assignments_to_delete_all_submissions_for = []
      # Delete submissions for students who don't have visibility to this assignment anymore
      @assignment_ids.each do |assignment_id|
        assigned_student_ids = effective_due_dates.find_effective_due_dates_for_assignment(assignment_id).keys

        if @user_ids.blank? && assigned_student_ids.blank? && enrollment_counts.prior_student_ids.blank?
          assignments_to_delete_all_submissions_for << assignment_id
        else
          # Delete the users we KNOW we need to delete in batches (it makes the database happier this way)
          deletable_student_ids =
            enrollment_counts.accepted_student_ids - assigned_student_ids - enrollment_counts.prior_student_ids
          deletable_student_ids.each_slice(1000) do |deletable_student_ids_chunk|
            # using this approach instead of using .in_batches because we want to limit the IDs in the IN clause to 1k
            Submission.active.where(assignment_id: assignment_id, user_id: deletable_student_ids_chunk).
              update_all(workflow_state: :deleted, updated_at: Time.zone.now)
          end
          User.clear_cache_keys(deletable_student_ids, :submissions)
        end
      end
      assignments_to_delete_all_submissions_for.each_slice(50) do |assignment_slice|
        subs = Submission.active.where(assignment_id: assignment_slice).limit(1_000)
        while subs.update_all(workflow_state: :deleted, updated_at: Time.zone.now) > 0; end
      end

      # Get any stragglers that might have had their enrollment removed from the course
      # 100 students at a time for 10 assignments each == slice of up to 1K submissions
      enrollment_counts.deleted_student_ids.each_slice(100) do |student_slice|
        @assignment_ids.each_slice(10) do |assignment_ids_slice|
          Submission.active.
            where(assignment_id: assignment_ids_slice, user_id: student_slice).
            update_all(workflow_state: :deleted, updated_at: Time.zone.now)
        end
        User.clear_cache_keys(student_slice, :submissions)
      end

      return if values.empty?

      values = values.sort_by(&:first)
      values.each_slice(1000) do |batch|
        auditable_entries = []
        cached_due_dates_by_submission = {}

        if record_due_date_changed_events?
          auditable_entries = batch.select { |entry| @assignments_auditable_by_id.include?(entry.first) }
          cached_due_dates_by_submission = current_cached_due_dates(auditable_entries)
        end

        # prepare values for SQL interpolation
        batch_values = batch.map { |entry| "(#{entry.join(',')})" }

        perform_submission_upsert(batch_values)

        next unless record_due_date_changed_events? && auditable_entries.present?

        record_due_date_changes_for_auditable_assignments!(
          entries: auditable_entries,
          previous_cached_dates: cached_due_dates_by_submission
        )
      end
      User.clear_cache_keys(values.map{|v| v[1]}, :submissions)
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

      GuardRail.activate(:secondary) do
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

  def current_cached_due_dates(entries)
    return {} if entries.empty?

    entries_for_query = assignment_and_student_id_values(entries: entries)
    submissions_with_due_dates = Submission.where("(assignment_id, user_id) IN (#{entries_for_query.join(',')})").
      where.not(cached_due_date: nil).
      pluck(:id, :cached_due_date)

    submissions_with_due_dates.each_with_object({}) do |(submission_id, cached_due_date), map|
      map[submission_id] = cached_due_date
    end
  end

  def record_due_date_changes_for_auditable_assignments!(entries:, previous_cached_dates:)
    entries_for_query = assignment_and_student_id_values(entries: entries)
    updated_submissions = Submission.where("(assignment_id, user_id) IN (#{entries_for_query.join(',')})").
      pluck(:id, :assignment_id, :cached_due_date)

    timestamp = Time.zone.now
    records_to_insert = updated_submissions.each_with_object([]) do |(submission_id, assignment_id, new_due_date), records|
      old_due_date = previous_cached_dates.fetch(submission_id, nil)

      next if new_due_date == old_due_date

      payload = {due_at: [old_due_date&.iso8601, new_due_date&.iso8601]}

      records << {
        assignment_id: assignment_id,
        submission_id: submission_id,
        user_id: @executing_user_id,
        event_type: 'submission_updated',
        payload: payload.to_json,
        created_at: timestamp,
        updated_at: timestamp
      }
    end

    AnonymousOrModerationEvent.bulk_insert(records_to_insert)
  end

  def assignment_and_student_id_values(entries:)
    entries.map { |(assignment_id, student_id)| "(#{assignment_id}, #{student_id})" }
  end

  def record_due_date_changed_events?
    # Only audit if we have a user and at least one auditable assignment
    @record_due_date_changed_events ||= @executing_user_id.present? && @assignments_auditable_by_id.present?
  end

  def quiz_lti_assignments
    # We only care about quiz LTIs, so we'll only snag those. In fact,
    # we only care if the assignment *is* a quiz, LTI, so we'll just
    # keep a set of those assignment ids.
    @quiz_lti_assignments ||=
      ContentTag.joins("INNER JOIN #{ContextExternalTool.quoted_table_name} ON content_tags.content_type='ContextExternalTool' AND context_external_tools.id = content_tags.content_id").
        merge(ContextExternalTool.quiz_lti).
        where(context_type: 'Assignment', context_id: @assignment_ids).
        where.not(workflow_state: 'deleted').distinct.pluck(:context_id).to_set
  end

  def existing_anonymous_ids_by_assignment_id
    @existing_anonymous_ids_by_assignment_id ||=
      Submission.
        anonymized.
        for_assignment(effective_due_dates.to_hash.keys).
        pluck(:assignment_id, :anonymous_id).
        each_with_object(Hash.new { |h,k| h[k] = [] }) { |data, h| h[data.first] << data.last }
  end

  def perform_submission_upsert(batch_values)
      # Construct upsert statement to update existing Submissions or create them if needed.
      query = <<~SQL
        UPDATE #{Submission.quoted_table_name}
          SET
            cached_due_date = vals.due_date::timestamptz,
            grading_period_id = vals.grading_period_id::integer,
            workflow_state = COALESCE(NULLIF(workflow_state, 'deleted'), (
              #{INFER_SUBMISSION_WORKFLOW_STATE_SQL}
            )),
            anonymous_id = COALESCE(submissions.anonymous_id, vals.anonymous_id),
            cached_quiz_lti = vals.cached_quiz_lti,
            updated_at = now() AT TIME ZONE 'UTC'
          FROM (VALUES #{batch_values.join(',')})
            AS vals(assignment_id, student_id, due_date, grading_period_id, anonymous_id, cached_quiz_lti, root_account_id)
          WHERE submissions.user_id = vals.student_id AND
                submissions.assignment_id = vals.assignment_id AND
                (
                  (submissions.cached_due_date IS DISTINCT FROM vals.due_date::timestamptz) OR
                  (submissions.grading_period_id IS DISTINCT FROM vals.grading_period_id::integer) OR
                  (submissions.workflow_state <> COALESCE(NULLIF(submissions.workflow_state, 'deleted'),
                    (#{INFER_SUBMISSION_WORKFLOW_STATE_SQL})
                  )) OR
                  (submissions.anonymous_id IS DISTINCT FROM COALESCE(submissions.anonymous_id, vals.anonymous_id)) OR
                  (submissions.cached_quiz_lti IS DISTINCT FROM vals.cached_quiz_lti)
                );
        INSERT INTO #{Submission.quoted_table_name}
          (assignment_id, user_id, workflow_state, created_at, updated_at, course_id,
          cached_due_date, grading_period_id, anonymous_id, cached_quiz_lti, root_account_id)
          SELECT
            assignments.id, vals.student_id, 'unsubmitted',
            now() AT TIME ZONE 'UTC', now() AT TIME ZONE 'UTC',
            assignments.context_id, vals.due_date::timestamptz, vals.grading_period_id::integer,
            vals.anonymous_id,
            vals.cached_quiz_lti,
            vals.root_account_id
          FROM (VALUES #{batch_values.join(',')})
            AS vals(assignment_id, student_id, due_date, grading_period_id, anonymous_id, cached_quiz_lti, root_account_id)
          INNER JOIN #{Assignment.quoted_table_name} assignments
            ON assignments.id = vals.assignment_id
          LEFT OUTER JOIN #{Submission.quoted_table_name} submissions
            ON submissions.assignment_id = assignments.id
            AND submissions.user_id = vals.student_id
          WHERE submissions.id IS NULL;
      SQL

    begin
      Submission.transaction do
        Submission.connection.execute(query)
      end
    rescue ActiveRecord::RecordNotUnique => e
      Canvas::Errors.capture_exception(:due_date_cacher, e, :warn)
      raise Delayed::RetriableError, "Unique record violation when creating new submissions"
    rescue ActiveRecord::Deadlocked => e
      Canvas::Errors.capture_exception(:due_date_cacher, e, :warn)
      raise Delayed::RetriableError, "Deadlock when upserting submissions"
    end
  end
end
