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

require "anonymity"

class SubmissionLifecycleManager
  include Moderation

  MAX_RUNNING_JOBS = 10

  thread_mattr_accessor :executing_users, instance_accessor: false

  # These methods allow the caller to specify a user to whom due date
  # changes should be attributed (currently this is used for creating
  # audit events for anonymous or moderated assignments), and are meant
  # to be used when SubmissionLifecycleManager is invoked in a callback or a similar
  # place where directly specifying an executing user is impractical.
  #
  # SubmissionLifecycleManager.with_executing_user(a_user) do
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
  #   SubmissionLifecycleManager.recompute(assignment, update_grades: true, executing_user: a_user)
  #
  # An explicitly specified user will take precedence over any users specified
  # via with_executing_user, but will not otherwise affect the current "stack"
  # of executing users.
  #
  # If you are calling SubmissionLifecycleManager in a delayed job of your own making (e.g.,
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

  def self.infer_submission_workflow_state_sql
    <<~SQL_FRAGMENT
      CASE
      WHEN submission_type = 'online_quiz' AND quiz_submission_id IS NOT NULL AND (
        SELECT EXISTS (
          SELECT
            *
          FROM
            #{Quizzes::QuizSubmission.quoted_table_name} qs
          WHERE
            quiz_submission_id = qs.id
          AND workflow_state = 'pending_review'
        )
      ) THEN
        'pending_review'
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
  end

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
        singleton: "cached_due_date:calculator:Assignment:#{assignment.global_id}:UpdateGrades:#{update_grades ? 1 : 0}",
        max_attempts: 10
      },
      update_grades:,
      original_caller: current_caller,
      executing_user:
    }

    recompute_course(assignment.context, **opts)
  end

  def self.recompute_course(course, assignments: nil, inst_jobs_opts: {}, run_immediately: false, update_grades: false, original_caller: caller(1..1).first, executing_user: nil, skip_late_policy_applicator: false)
    Rails.logger.debug "DDC.recompute_course(#{course.inspect}, #{assignments.inspect}, #{inst_jobs_opts.inspect}) - #{original_caller}"
    course = Course.find(course) unless course.is_a?(Course)
    inst_jobs_opts[:max_attempts] ||= 10
    inst_jobs_opts[:singleton] ||= "cached_due_date:calculator:Course:#{course.global_id}:UpdateGrades:#{update_grades ? 1 : 0}" if assignments.nil?
    inst_jobs_opts[:strand] ||= "cached_due_date:calculator:Course:#{course.global_id}"

    assignments_to_recompute = assignments || AbstractAssignment.active.where(context: course).pluck(:id)
    return if assignments_to_recompute.empty?

    executing_user ||= current_executing_user
    submission_lifecycle_manager = new(course, assignments_to_recompute, update_grades:, original_caller:, executing_user:, skip_late_policy_applicator:)
    if run_immediately
      submission_lifecycle_manager.recompute
    else
      submission_lifecycle_manager.delay_if_production(**inst_jobs_opts).recompute
    end
  end

  def self.recompute_users_for_course(user_ids, course, assignments = nil, inst_jobs_opts = {})
    opts = inst_jobs_opts.extract!(:update_grades, :executing_user, :sis_import, :require_singleton).reverse_merge(require_singleton: assignments.nil?)
    user_ids = Array(user_ids)
    course = Course.find(course) unless course.is_a?(Course)
    update_grades = opts[:update_grades] || false
    inst_jobs_opts[:max_attempts] ||= 10
    inst_jobs_opts[:strand] ||= "cached_due_date:calculator:Course:#{course.global_id}"
    if opts[:require_singleton]
      inst_jobs_opts[:singleton] ||= "cached_due_date:calculator:Course:#{course.global_id}:Users:#{Digest::SHA256.hexdigest(user_ids.sort.join(":"))}:UpdateGrades:#{update_grades ? 1 : 0}"
    end
    assignments ||= AbstractAssignment.active.where(context: course).pluck(:id)
    return if assignments.empty?

    current_caller = caller(1..1).first
    executing_user = opts[:executing_user] || current_executing_user

    if opts[:sis_import]
      running_jobs_count = Delayed::Job.running.where(shard_id: course.shard.id, tag: "SubmissionLifecycleManager#recompute_for_sis_import").count

      if running_jobs_count >= MAX_RUNNING_JOBS
        # there are too many sis recompute jobs running concurrently now. let's check again in a bit to see if we can run.
        return delay_if_production(
          **inst_jobs_opts,
          run_at: 10.seconds.from_now
        ).recompute_users_for_course(user_ids, course, assignments, opts)
      else
        submission_lifecycle_manager = new(course, assignments, user_ids, update_grades:, original_caller: current_caller, executing_user:)
        return submission_lifecycle_manager.delay_if_production(**inst_jobs_opts).recompute_for_sis_import
      end
    end

    submission_lifecycle_manager = new(course, assignments, user_ids, update_grades:, original_caller: current_caller, executing_user:)
    submission_lifecycle_manager.delay_if_production(**inst_jobs_opts).recompute
  end

  def initialize(course, assignments, user_ids = [], update_grades: false, original_caller: caller(1..1).first, executing_user: nil, skip_late_policy_applicator: false)
    @course = course
    @assignment_ids = Array(assignments).map { |a| a.is_a?(AbstractAssignment) ? a.id : a }

    # ensure we're dealing with local IDs to avoid headaches downstream
    if @assignment_ids.present?
      @course.shard.activate do
        if @assignment_ids.any? { |id| AbstractAssignment.global_id?(id) }
          @assignment_ids = AbstractAssignment.where(id: @assignment_ids).pluck(:id)
        end

        @assignments_auditable_by_id = Set.new(AbstractAssignment.auditable.where(id: @assignment_ids).pluck(:id))
      end
    else
      @assignments_auditable_by_id = Set.new
    end

    @user_ids = Array(user_ids)
    @update_grades = update_grades
    @original_caller = original_caller
    @skip_late_policy_applicator = skip_late_policy_applicator

    if executing_user.present?
      @executing_user_id = executing_user.is_a?(User) ? executing_user.id : executing_user
    end
  end

  # exists so that we can identify (and limit) jobs running specifically for sis imports
  # Delayed::Job.where(tag: "SubmissionLifecycleManager#recompute_for_sis_import")
  def recompute_for_sis_import
    recompute
  end

  def recompute
    Rails.logger.debug "SUBMISSION LIFECYCLE MANAGER STARTS: #{Time.zone.now.to_i}"
    Rails.logger.debug "SLM#recompute() - original caller: #{@original_caller}"
    Rails.logger.debug "SLM#recompute() - current caller: #{caller(1..1).first}"

    # in a transaction on the correct shard:
    @course.shard.activate do
      values = []

      assignments_by_id = AbstractAssignment.find(@assignment_ids).index_by(&:id)

      effective_due_dates.to_hash.each do |assignment_id, student_due_dates|
        existing_anonymous_ids = existing_anonymous_ids_by_assignment_id[assignment_id]

        create_moderation_selections_for_assignment(assignments_by_id[assignment_id], student_due_dates.keys, @user_ids)

        quiz_lti = quiz_lti_assignments.include?(assignment_id)

        student_due_dates.each_key do |student_id|
          submission_info = student_due_dates[student_id]
          due_date = submission_info[:due_at] ? "'#{ActiveRecord::Base.connection.quoted_date(submission_info[:due_at].change(usec: 0))}'::timestamptz" : "NULL"
          grading_period_id = submission_info[:grading_period_id] || "NULL"

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
            Submission.active.where(assignment_id:, user_id: deletable_student_ids_chunk)
                      .update_all(workflow_state: :deleted, updated_at: Time.zone.now)
          end
          User.clear_cache_keys(deletable_student_ids, :submissions)
        end
      end
      assignments_to_delete_all_submissions_for.each_slice(50) do |assignment_slice|
        subs = Submission.active.where(assignment_id: assignment_slice).limit(1_000)
        while subs.update_all(workflow_state: :deleted, updated_at: Time.zone.now) > 0; end
      end

      nq_restore_pending_flag_enabled = Account.site_admin.feature_enabled?(:new_quiz_deleted_workflow_restore_pending_review_state)

      # Get any stragglers that might have had their enrollment removed from the course
      # 100 students at a time for 10 assignments each == slice of up to 1K submissions
      enrollment_counts.deleted_student_ids.each_slice(100) do |student_slice|
        @assignment_ids.each_slice(10) do |assignment_ids_slice|
          Submission.active
                    .where(assignment_id: assignment_ids_slice, user_id: student_slice)
                    .update_all(workflow_state: :deleted, updated_at: Time.zone.now)
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

        if nq_restore_pending_flag_enabled
          handle_lti_deleted_submissions(batch)
        end

        # prepare values for SQL interpolation
        batch_values = batch.map { |entry| "(#{entry.join(",")})" }

        perform_submission_upsert(batch_values)

        next unless record_due_date_changed_events? && auditable_entries.present?

        record_due_date_changes_for_auditable_assignments!(
          entries: auditable_entries,
          previous_cached_dates: cached_due_dates_by_submission
        )
      end
      User.clear_cache_keys(values.pluck(1), :submissions)
    end

    if @update_grades
      @course.recompute_student_scores_without_send_later(@user_ids)
    end

    if @assignment_ids.size == 1 && !@skip_late_policy_applicator
      # Only changes to LatePolicy or (sometimes) AbstractAssignment records can result in a re-calculation
      # of student scores.  No changes to the Course record can trigger such re-calculations so
      # let's ensure this is triggered only when SubmissionLifecycleManager is called for a Assignment-level
      # changes and not for Course-level changes
      assignment = @course.shard.activate { AbstractAssignment.find(@assignment_ids.first) }

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
          "count(nullif(workflow_state not in ('rejected', 'deleted'), false)) as accepted_count",
          "count(nullif(workflow_state in ('completed'), false)) as prior_count",
          "count(nullif(workflow_state in ('rejected', 'deleted'), false)) as deleted_count"
        )
                          .where(course_id: @course, type: ["StudentEnrollment", "StudentViewEnrollment"])
                          .group(:user_id)

        scope = scope.where(user_id: @user_ids) if @user_ids.present?

        scope.find_each do |record|
          if record.accepted_count > 0
            if record.accepted_count == record.prior_count
              counts.prior_student_ids << record.user_id
            else
              counts.accepted_student_ids << record.user_id
            end
          else
            counts.deleted_student_ids << record.user_id
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

    entries_for_query = assignment_and_student_id_values(entries:)
    submissions_with_due_dates = Submission.where("(assignment_id, user_id) IN (#{entries_for_query.join(",")})")
                                           .where.not(cached_due_date: nil)
                                           .pluck(:id, :cached_due_date)

    submissions_with_due_dates.each_with_object({}) do |(submission_id, cached_due_date), map|
      map[submission_id] = cached_due_date
    end
  end

  def record_due_date_changes_for_auditable_assignments!(entries:, previous_cached_dates:)
    entries_for_query = assignment_and_student_id_values(entries:)
    updated_submissions = Submission.where("(assignment_id, user_id) IN (#{entries_for_query.join(",")})")
                                    .pluck(:id, :assignment_id, :cached_due_date)

    timestamp = Time.zone.now
    records_to_insert = updated_submissions.each_with_object([]) do |(submission_id, assignment_id, new_due_date), records|
      old_due_date = previous_cached_dates.fetch(submission_id, nil)

      next if new_due_date == old_due_date

      payload = { due_at: [old_due_date&.iso8601, new_due_date&.iso8601] }

      records << {
        assignment_id:,
        submission_id:,
        user_id: @executing_user_id,
        event_type: "submission_updated",
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
      ContentTag.joins("INNER JOIN #{ContextExternalTool.quoted_table_name} ON content_tags.content_type='ContextExternalTool' AND context_external_tools.id = content_tags.content_id")
                .merge(ContextExternalTool.quiz_lti)
                .where(context_type: "Assignment"). #
      # We're doing the following direct postgres any() rather than .where(context_id: @assignment_ids) on advice
      # from our DBAs that the any is considerably faster in the postgres planner than the "IN ()" statement that
      # AR would have generated.
      where("content_tags.context_id = any('{?}'::int8[])", @assignment_ids)
                .where.not(workflow_state: "deleted").distinct.pluck(:context_id).to_set
  end

  def existing_anonymous_ids_by_assignment_id
    @existing_anonymous_ids_by_assignment_id ||=
      Submission
      .anonymized
      .for_assignment(effective_due_dates.to_hash.keys)
      .pluck(:assignment_id, :anonymous_id)
      .each_with_object(Hash.new { |h, k| h[k] = [] }) { |data, h| h[data.first] << data.last }
  end

  def perform_submission_upsert(batch_values)
    # Construct upsert statement to update existing Submissions or create them if needed.
    query = <<~SQL.squish
      UPDATE #{Submission.quoted_table_name}
        SET
          cached_due_date = vals.due_date::timestamptz,
          grading_period_id = vals.grading_period_id::integer,
          workflow_state = COALESCE(NULLIF(workflow_state, 'deleted'), (
            #{self.class.infer_submission_workflow_state_sql}
          )),
          anonymous_id = COALESCE(submissions.anonymous_id, vals.anonymous_id),
          cached_quiz_lti = vals.cached_quiz_lti,
          updated_at = now() AT TIME ZONE 'UTC'
        FROM (VALUES #{batch_values.join(",")})
          AS vals(assignment_id, student_id, due_date, grading_period_id, anonymous_id, cached_quiz_lti, root_account_id)
        WHERE submissions.user_id = vals.student_id AND
              submissions.assignment_id = vals.assignment_id AND
              (
                (submissions.cached_due_date IS DISTINCT FROM vals.due_date::timestamptz) OR
                (submissions.grading_period_id IS DISTINCT FROM vals.grading_period_id::integer) OR
                (submissions.workflow_state <> COALESCE(NULLIF(submissions.workflow_state, 'deleted'),
                  (#{self.class.infer_submission_workflow_state_sql})
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
        FROM (VALUES #{batch_values.join(",")})
          AS vals(assignment_id, student_id, due_date, grading_period_id, anonymous_id, cached_quiz_lti, root_account_id)
        INNER JOIN #{AbstractAssignment.quoted_table_name} assignments
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
      Canvas::Errors.capture_exception(:submission_lifecycle_manager, e, :warn)
      raise Delayed::RetriableError, "Unique record violation when creating new submissions"
    rescue ActiveRecord::Deadlocked => e
      Canvas::Errors.capture_exception(:submission_lifecycle_manager, e, :warn)
      raise Delayed::RetriableError, "Deadlock when upserting submissions"
    end
  end

  def handle_lti_deleted_submissions(batch)
    quiz_lti_index = 5

    assignments_and_users_query = batch.each_with_object([]) do |entry, memo|
      next unless entry[quiz_lti_index]

      memo << "(#{entry.first}, #{entry.second})"
    end

    return if assignments_and_users_query.empty?

    submission_join_query = <<~SQL.squish
      INNER JOIN (VALUES #{assignments_and_users_query.join(",")})
      AS vals(assignment_id, student_id)
      ON submissions.assignment_id = vals.assignment_id
      AND submissions.user_id = vals.student_id
    SQL

    submission_query = Submission.deleted.joins(submission_join_query)
    submission_versions_to_check = Version
                                   .where(versionable: submission_query)
                                   .order(number: :desc)
                                   .distinct(:versionable_id)
    submissions_in_pending_review = submission_versions_to_check
                                    .select { |version| version.model.workflow_state == "pending_review" }
                                    .pluck(:versionable_id)

    if submissions_in_pending_review.any?
      Submission.where(id: submissions_in_pending_review).update_all(workflow_state: "pending_review")
    end
  end
end
