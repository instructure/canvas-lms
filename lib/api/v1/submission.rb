# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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
#

module Api::V1::Submission
  include Api::V1::Json
  include Api::V1::Assignment
  include Api::V1::Attachment
  include Api::V1::DiscussionTopics
  include Api::V1::Course
  include Api::V1::User
  include Api::V1::SubmissionComment
  include Api::V1::RubricAssessment
  include CoursesHelper

  def submission_json(
    submission,
    assignment,
    current_user,
    session,
    context = nil,
    includes = [],
    params = {},
    avatars = false,
    preloaded_enrollments_by_user_id: nil
  )
    context ||= assignment.context
    hash = submission_attempt_json(submission, assignment, current_user, session, context, params, preloaded_enrollments_by_user_id:)

    # The "body" attribute is intended to store the contents of text-entry
    # submissions, but for quizzes it contains a string that includes grading
    # information. Only return it if the caller has permissions.
    hash["body"] = nil if assignment.quiz? && !submission.user_can_read_grade?(current_user)

    if includes.include?("sub_assignment_submissions") && context.discussion_checkpoints_enabled?
      hash["has_sub_assignment_submissions"] = assignment.has_sub_assignments
      hash["sub_assignment_submissions"] = (assignment.has_sub_assignments &&
                                           assignment.sub_assignments&.map do |sub_assignment|
                                             sub_assignment_submission = sub_assignment.find_or_create_submission(submission.user)
                                             sub_assignnment_submission_json(sub_assignment_submission, sub_assignment_submission.assignment, current_user, session, context, includes, params, avatars)
                                           end) || []
    end

    if includes.include?("submission_history")
      if submission.quiz_submission && assignment.quiz && !assignment.quiz.anonymous_survey?
        hash["submission_history"] =
          submission
          .quiz_submission
          .versions
          .map do |ver|
            ver.model.submission && ver
              .model
              .submission
              .without_versioned_attachments do
                quiz_submission_attempt_json(
                  ver.model,
                  assignment,
                  current_user,
                  session,
                  context,
                  params
                )
              end
          end
      elsif quizzes_next_submission?(submission)
        hash["submission_history"] = quizzes_next_submission_history(submission, current_user)
      else
        histories = submission.submission_history
        ActiveRecord::Associations.preload(histories, :group) if includes.include?("group")
        hash["submission_history"] =
          histories.map do |ver|
            ver.without_versioned_attachments do
              submission_attempt_json(ver, assignment, current_user, session, context, params)
            end
          end
      end
    end

    if current_user && assignment && includes.include?("provisional_grades") &&
       assignment.moderated_grading?
      hash["provisional_grades"] =
        submission_provisional_grades_json(
          course: context,
          assignment:,
          submission:,
          current_user:,
          avatars:,
          includes:
        )
    end

    if includes.include?("has_postable_comments")
      hash["has_postable_comments"] = submission.postable_comments?
    end

    if includes.include?("submission_comments")
      published_comments = submission.comments_excluding_drafts_for(@current_user)
      hash["submission_comments"] = submission_comments_json(published_comments, current_user)
    end

    if includes.include?("submission_html_comments")
      published_comments = submission.comments_excluding_drafts_for(@current_user)
      hash["submission_html_comments"] = submission_comments_json(published_comments, current_user, use_html_comment: true)
    end

    if includes.include?("rubric_assessment") && submission.rubric_assessment &&
       submission.user_can_read_grade?(current_user)
      hash["rubric_assessment"] = indexed_rubric_assessment_json(submission.rubric_assessment)
    end

    if includes.include?("full_rubric_assessment") && submission.rubric_assessment &&
       submission.user_can_read_grade?(current_user)
      hash["full_rubric_assessment"] =
        full_rubric_assessment_json_for_submissions(
          submission.rubric_assessment,
          current_user,
          session
        )
    end

    if includes.include?("assignment")
      hash["assignment"] = assignment_json(assignment, current_user, session)
    end

    if includes.include?("course")
      hash["course"] = course_json(submission.context, current_user, session, ["html_url"], nil)
    end

    if includes.include?("html_url")
      hash["html_url"] =
        if assignment.anonymize_students?
          speed_grader_course_gradebook_url(
            assignment.context,
            assignment_id: assignment.id,
            anonymous_id: submission.anonymous_id
          )
        else
          course_assignment_submission_url(submission.context.id, assignment.id, submission.user.global_id)
        end
    end

    if includes.include?("user") && submission.can_read_submission_user_name?(current_user, session)
      hash["user"] =
        user_json(submission.user, current_user, session, ["avatar_url"], submission.context, nil)
    end

    if assignment && includes.include?("user_summary") &&
       submission.can_read_submission_user_name?(current_user, session)
      hash["user"] = user_display_json(submission.user, assignment.context)
    end

    if includes.include?("visibility")
      hash["assignment_visible"] = submission.assignment_visible_to_user?(submission.user)
    end

    if includes.include?("submission_status")
      hash["submission_status"] = submission.submission_status
    end

    hash["grading_status"] = submission.grading_status if includes.include?("grading_status")

    if includes.include?("read_state")
      # Save the current read state to the hash, then mark as read if needed
      hash["read_state"] = submission.read_state(current_user)
      if hash["read_state"] == "unread"
        GuardRail.activate(:primary) { submission.mark_read(current_user) }
      end
    end

    if params[:anonymize_user_id] || context.account_membership_allows(current_user)
      hash["anonymous_id"] = submission.anonymous_id
    end

    hash
  end

  SUBMISSION_JSON_FIELDS = %w[
    id
    user_id
    url
    score
    grade
    excused
    attempt
    submission_type
    submitted_at
    body
    assignment_id
    graded_at
    grade_matches_current_submission
    grader_id
    workflow_state
    late_policy_status
    points_deducted
    grading_period_id
    cached_due_date
    extra_attempts
    posted_at
    redo_request
    sticker
    custom_grade_status_id
  ].freeze
  SUBMISSION_JSON_METHODS = %w[late missing seconds_late entered_grade entered_score].freeze
  SUBMISSION_OTHER_FIELDS = %w[attachments discussion_entries proxy_submitter].freeze

  def submission_attempt_json(
    attempt,
    assignment,
    user,
    session,
    context = nil,
    params = {},
    quiz_submission_version = nil,
    preloaded_enrollments_by_user_id: nil
  )
    context ||= assignment.context
    includes = Array.wrap(params[:include])

    json_fields = SUBMISSION_JSON_FIELDS
    json_methods = SUBMISSION_JSON_METHODS.dup # dup because AR#to_json modifies the :methods param in-place
    other_fields = SUBMISSION_OTHER_FIELDS

    if params[:response_fields]
      json_fields &= params[:response_fields]
      json_methods &= params[:response_fields]
      other_fields &= params[:response_fields]
    end
    if params[:exclude_response_fields]
      json_fields -= params[:exclude_response_fields]
      json_methods -= params[:exclude_response_fields]
      other_fields -= params[:exclude_response_fields]
    end

    if params[:anonymize_user_id]
      json_fields -= ["user_id"]
      json_fields << "anonymous_id"
    end

    if attempt.checkpoints_needs_grading? && context.discussion_checkpoints_enabled?
      attempt.workflow_state = "pending_review"
      attempt.submission_type = attempt.submission_type || attempt.assignment&.submission_types
    end

    attempt.assignment = assignment
    hash = api_json(attempt, user, session, only: json_fields, methods: json_methods)
    hash["body"] = api_user_content(hash["body"], context, user, location: attempt.asset_string) if hash["body"].present?

    hash["group"] = submission_minimal_group_json(attempt) if includes.include?("group")
    if hash.key?("grade_matches_current_submission")
      hash["grade_matches_current_submission"] = hash["grade_matches_current_submission"] != false
    end

    unless params[:exclude_response_fields]&.include?("preview_url") ||
           assignment.anonymize_students?
      preview_args = { "preview" => "1" }
      preview_args["version"] =
        quiz_submission_version || attempt.quiz_submission_version || attempt.version_number
      hash["preview_url"] =
        course_assignment_submission_url(context, assignment, attempt&.user&.global_id, preview_args)
    end

    unless attempt.media_comment_id.blank?
      hash["media_comment"] =
        media_comment_json(
          media_id: attempt.media_comment_id,
          media_type: attempt.media_comment_type
        )
    end

    hash["has_originality_report"] = true if show_originality_reports?(attempt)

    if (includes.include?("webhook_info") || attempt.originality_data.present?) &&
       attempt.grants_right?(@current_user, :view_turnitin_report)
      hash["turnitin_data"] = attempt.originality_data
      hash["turnitin_data"]["webhook_info"] = attempt.turnitin_data[:webhook_info] if includes
                                                                                      .include?("webhook_info")
    end

    if attempt.vericite_data(false).present? &&
       attempt.can_view_plagiarism_report("vericite", @current_user, session) &&
       attempt.assignment.vericite_enabled?
      vericite_hash = attempt.vericite_data(false).dup
      hash["vericite_data"] = vericite_hash.except(:last_processed_attempt, :webhook_info)
    end

    if other_fields.include?("attachments")
      attachments = attempt.versioned_attachments.dup
      if attempt.attachment && attempt.attachment.context_type == "Submission" &&
         attempt.attachment.context_id == attempt.id
        attachments << attempt.attachment
      end
      unless attachments.blank?
        hash["attachments"] =
          attachments.filter_map do |attachment|
            includes =
              if includes.include?("canvadoc_document_id")
                %w[preview_url canvadoc_document_id]
              else
                ["preview_url"]
              end
            options = {
              anonymous_instructor_annotations: assignment.anonymous_instructor_annotations?,
              enable_annotations: true,
              enrollment_type: user_type(context, user, preloaded_enrollments_by_user_id),
              include: includes,
              moderated_grading_allow_list: attempt.moderated_grading_allow_list(user),
              skip_permission_checks: true,
              submission_id: attempt.id
            }

            attachment_json(attachment, user, {}, options)
          end
      end
    end

    # include the discussion topic entries
    if other_fields.include?("discussion_entries") &&
       assignment.submission_types&.include?("discussion_topic") && assignment.discussion_topic
      # group assignments will have a child topic for each group.
      # it's also possible the student posted in the main topic, as well as the
      # individual group one. so we search far and wide for all student entries.

      entries =
        if assignment.discussion_topic.has_group_category?
          assignment.shard.activate do
            DiscussionEntry
              .active
              .where(discussion_topic_id: assignment.discussion_topic.child_topics.select(:id))
              .for_user(attempt.user_id)
              .to_a
              .sort_by(&:created_at)
          end
        else
          assignment.discussion_topic.discussion_entries.active.for_user(attempt.user_id).to_a
        end
      ActiveRecord::Associations.preload(
        entries,
        :discussion_entry_participants,
        DiscussionEntryParticipant.where(user_id: user)
      )
      hash["discussion_entries"] =
        discussion_entry_api_json(entries, assignment.discussion_topic.context, user, session)
    end

    if other_fields.include?("proxy_submitter") && attempt.proxy_submission?
      hash["proxy_submitter"] = attempt.proxy_submitter.short_name
      hash["proxy_submitter_id"] = attempt.proxy_submitter_id
    end

    if attempt.submission_type == "basic_lti_launch"
      unless params[:exclude_response_fields]&.include?("external_tool_url")
        hash["external_tool_url"] = attempt.external_tool_url
      end

      if json_fields.include?("url")
        hash["url"] =
          retrieve_course_external_tools_url(
            context.id,
            assignment_id: assignment.id,
            url: attempt.external_tool_url
          )
      end
    end

    hash["student_entered_score"] = attempt.student_entered_score if includes.include?("student_entered_score")

    hash
  end

  def submission_minimal_group_json(attempt)
    # If one is including the group in the submission response, we can
    # assume they want the information for identification and sorting
    # issues and not the full group object.
    { id: attempt.group_id, name: attempt.group.try(:name) }
  end

  def quiz_submission_attempt_json(attempt, assignment, user, session, context = nil, params)
    hash =
      submission_attempt_json(
        attempt.submission,
        assignment,
        user,
        session,
        context,
        params,
        attempt.version_number
      )
    hash.each_key { |k| hash[k] = attempt[k] if attempt[k] }
    hash[:submission_data] = attempt[:submission_data]
    hash[:submitted_at] = attempt[:finished_at]
    hash[:body] = nil

    # since it is graded automatically the graded_at date should be the last time the
    # quiz_submission ended
    hash[:graded_at] = attempt[:end_at]

    hash
  end

  def sub_assignnment_submission_json(
    submission,
    assignment,
    current_user,
    session,
    context = nil,
    includes = [],
    params = {},
    avatars = false
  )
    json = submission_json(submission, assignment, current_user, session, context, includes, params, avatars)

    # we want to make a clear distinction between a submission and a sub assignment submission, we will do this by
    # keeping the sub assignment submission json as minimal as possible, only keeping exactly what clients need
    sub_assignment_json = json.slice(
      "seconds_late",
      "custom_grade_status_id",
      "late_policy_status",
      "late",
      "missing",
      "excused",
      "entered_grade",
      "entered_score",
      "grade",
      "score",
      "user_id",
      "grade_matches_current_submission"
    )
    sub_assignment_json["sub_assignment_tag"] = assignment.sub_assignment_tag
    sub_assignment_json["published_grade"] = submission.published_grade
    sub_assignment_json["published_score"] = submission.published_score
    sub_assignment_json
  end

  # Create an attachment with a ZIP archive of an assignment's submissions.
  # The attachment will be re-created if it's 1 hour old, or determined to be
  # "stale". See the argument descriptions for testing the staleness of the attachment.
  #
  # @param [Assignment] assignment
  # The assignment, or an object that implements its interface, for which the
  # submissions will be zipped.
  #
  # @param [DateTime] updated_at
  # A timestamp that marks the latest update to the assignment object which will
  # be used to determine whether the attachment will be re-created.
  #
  # Note that this timestamp will be ignored if the attachment is +submission_zip_ttl_minutes+ old.
  #
  # @return [Attachment] The attachment that contains the archive.
  def submission_zip(assignment, updated_at = nil)
    attachments =
      assignment
      .attachments
      .where(
        {
          display_name: "submissions.zip",
          workflow_state: %w[to_be_zipped zipping zipped errored unattached],
          user_id: @current_user
        }
      )
      .order(:created_at)
      .to_a

    attachment = attachments.pop
    attachments.each(&:destroy_permanently_plus)

    anonymous = assignment.anonymize_students?

    # Remove the earlier attachment and re-create it if it's "stale"
    if attachment
      stale = (attachment.locked != anonymous)
      stale ||=
        (attachment.created_at < 1.day.ago)
      stale ||=
        attachment.created_at <
        (updated_at || assignment.submissions.maximum(:submitted_at) || attachment.created_at)

      stale ||=
        @current_user &&
        (
          enrollment_updated_at =
            assignment.context.enrollments.for_user(@current_user).maximum(:updated_at)
        ) && (attachment.created_at < enrollment_updated_at)

      if stale
        attachment.destroy_permanently_plus
        attachment = nil
      end
    end

    unless attachment
      attachment = assignment.attachments.build(display_name: "submissions.zip")
      attachment.workflow_state = "to_be_zipped"
      attachment.file_state = "0"
      attachment.user = @current_user
      attachment.locked = anonymous
      attachment.save!

      ContentZipper.delay(priority: Delayed::LOW_PRIORITY).process_attachment(attachment)
    end

    attachment
  end

  def provisional_grade_json(
    course:,
    assignment:,
    submission:,
    provisional_grade:,
    current_user:,
    avatars: false,
    includes: []
  )
    speedgrader_url =
      speed_grader_url(submission:, assignment:, current_user:)
    json = provisional_grade.grade_attributes.merge(speedgrader_url:)

    if includes.include?("submission_comments")
      json["submission_comments"] =
        anonymous_moderated_submission_comments_json(
          course:,
          assignment:,
          submissions: [submission],
          submission_comments: provisional_grade.submission_comments,
          current_user:,
          avatars:
        )
    end

    if assignment.can_view_other_grader_identities?(current_user)
      if includes.include?("rubric_assessment")
        json["rubric_assessments"] =
          provisional_grade.rubric_assessments.map do |ra|
            ra.as_json(methods: [:assessor_name], include_root: false)
          end
      end
    else
      json[:anonymous_grader_id] =
        assignment.grader_ids_to_anonymous_ids[json.delete(:scorer_id).to_s]
    end

    if includes.include?("crocodoc_urls") && assignment.can_view_student_names?(current_user)
      json["crocodoc_urls"] =
        submission.versioned_attachments.map do |a|
          provisional_grade.attachment_info(current_user, a)
        end
    end

    json
  end

  def submission_provisional_grades_json(
    course:,
    assignment:,
    submission:,
    current_user:,
    avatars: false,
    includes: []
  )
    provisional_grades = submission.provisional_grades
    provisional_grades =
      if assignment.permits_moderation?(current_user)
        provisional_grades.sort_by { |pg| pg.final ? CanvasSort::Last : pg.created_at }
      else
        provisional_grades.select { |pg| pg.scorer_id == current_user.id }
      end

    provisional_grades.map do |provisional_grade|
      provisional_grade_json(
        course:,
        assignment:,
        submission:,
        provisional_grade:,
        avatars:,
        current_user:,
        includes:
      )
    end
  end

  private

  def show_originality_reports?(submission)
    submission.originality_reports.present?
  end

  def speed_grader_url(submission:, assignment:, current_user:)
    student_or_anonymous_id =
      if assignment.can_view_student_names?(current_user)
        { student_id: submission.user.global_id }
      else
        { anonymous_id: submission.anonymous_id }
      end

    speed_grader_course_gradebook_url(
      { course_id: assignment.context_id, assignment_id: assignment }.merge(student_or_anonymous_id)
    )
  end

  def quizzes_next_submission?(submission)
    assignment = submission.assignment
    assignment.quiz_lti? &&
      assignment.root_account.feature_enabled?(:quizzes_next_submission_history)
  end

  def quizzes_next_submission_history(submission, current_user)
    quiz_lti_submission =
      BasicLTI::QuizzesNextVersionedSubmission.new(submission.assignment, submission.user)
    hide_history_scores_on_manual_posting = !submission.grants_right?(current_user, :read_grade)
    quiz_lti_submission.grade_history(hide_history_scores_on_manual_posting:)
  end
end
