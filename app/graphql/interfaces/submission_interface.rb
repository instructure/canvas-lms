# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

class UnreadCommentCountLoader < GraphQL::Batch::Loader
  def initialize(current_user)
    super()
    @current_user = current_user
  end

  def load(submission)
    # By default if we pass two submissions with the same id but a different
    # attempt, they will get uniqued into a single submission before they reach
    # the perform method. This breaks submission histories/versionable. Work
    # around this by passing in the submission.id and submission.attempt to
    # the perform method instead.
    super([submission.global_id, submission.attempt])
  end

  def perform(submission_ids_and_attempts)
    submission_ids = submission_ids_and_attempts.map(&:first)

    unread_count_hash =
      Submission
      .where(id: submission_ids)
      .joins(:submission_comments)
      .where.not(
        ViewedSubmissionComment
          .where("viewed_submission_comments.submission_comment_id=submission_comments.id")
          .where(user_id: @current_user)
          .arel.exists
      )
      .group(:submission_id, "submission_comments.attempt")
      .count

    submission_ids_and_attempts.each do |submission_id, attempt|
      relative_submission_id = Shard.relative_id_for(submission_id, Shard.current, Shard.current)

      # Group attempts nil, zero, and one together as one set of unread counts
      count =
        if (attempt || 0) <= 1
          (unread_count_hash[[relative_submission_id, nil]] || 0) +
            (unread_count_hash[[relative_submission_id, 0]] || 0) +
            (unread_count_hash[[relative_submission_id, 1]] || 0)
        else
          unread_count_hash[[relative_submission_id, attempt]] || 0
        end

      fulfill([submission_id, attempt], count)
    end
  end
end

module Types
  class SubmissionRubricAssessmentFilterInputType < Types::BaseInputObject
    graphql_name "SubmissionRubricAssessmentFilterInput"

    argument :for_attempt, Integer, <<~MD, required: false, default_value: nil
      What submission attempt the rubric assessment should be returned for. If not
      specified, it will return the rubric assessment for the current submission
      or submission history.
    MD
    argument :for_all_attempts, Boolean, <<~MD, required: false, default_value: nil
      it will return all rubric assessments for the current submission
      or submission history.
    MD
  end

  class SubmissionCommentsSortOrderType < Types::BaseEnum
    graphql_name "SubmissionCommentsSortOrderType"
    value "asc", value: :asc
    value "desc", value: :desc
  end

  class LatePolicyStatusType < Types::BaseEnum
    graphql_name "LatePolicyStatusType"
    value "late"
    value "missing"
    value "extended"
    value "none"
  end
end

module Interfaces::SubmissionInterface
  include Interfaces::BaseInterface
  include GraphQLHelpers::AnonymousGrading

  description "Types for submission or submission history"

  def submission
    object
  end
  private :submission

  def protect_submission_grades(attr)
    load_association(:assignment).then do
      submission.send(attr) if submission.user_can_read_grade?(current_user, session)
    end
  end
  private :protect_submission_grades

  field :anonymous_id, ID, null: true

  field :assignment, Types::AssignmentType, null: true
  def assignment
    load_association(:assignment)
  end

  field :graded_anonymously, Boolean, null: true

  field :hide_grade_from_student,
        Boolean,
        "hide unpublished grades",
        method: :hide_grade_from_student?,
        null: true

  field :feedback_for_current_attempt, Boolean, null: false
  def feedback_for_current_attempt
    submission.feedback_for_current_attempt?
  end

  field :unread_comment_count, Integer, null: false
  def unread_comment_count
    Promise
      .all([load_association(:content_participations), load_association(:assignment)])
      .then do
        next 0 if object.read?(current_user)

        UnreadCommentCountLoader.for(current_user).load(object)
      end
  end

  field :has_unread_rubric_assessment, Boolean, null: false
  def has_unread_rubric_assessment
    load_association(:content_participations).then do
      submission.content_participations.where(workflow_state: "unread", content_item: "rubric").exists?
    end
  end

  field :user, Types::UserType, null: true
  def user
    unless_hiding_user_for_anonymous_grading { load_association(:user) }
  end

  field :attempt, Integer, null: false
  def attempt
    submission.attempt || 0 # Nil in database, make it 0 here for easier api
  end

  field :comments_connection, Types::SubmissionCommentType.connection_type, null: false do
    argument :filter, Types::SubmissionCommentFilterInputType, required: false, default_value: {}
    argument :sort_order,
             Types::SubmissionCommentsSortOrderType,
             required: false,
             default_value: nil
    argument :include_draft_comments, Boolean, required: false, default_value: false
  end
  def comments_connection(filter:, sort_order:, include_draft_comments:)
    filter = filter.to_h
    filter => all_comments:, for_attempt:, peer_review:

    load_association(:assignment).then do
      load_association(:submission_comments).then do
        comments = include_draft_comments ? submission.comments_including_drafts_for(current_user) : submission.comments_excluding_drafts_for(current_user)

        comments = comments.select { |comment| comment.attempt.in?(attempt_filter(for_attempt)) } unless all_comments
        comments = comments.select { |comment| comment.author == current_user } if peer_review && !all_comments
        comments = comments.sort_by { |comment| [comment.created_at.to_i, comment.id] } if sort_order.present?
        comments.reverse! if sort_order.to_s.casecmp("desc").zero?

        comments.select { |comment| comment.grants_right?(current_user, :read) }
      end
    end
  end

  def attempt_filter(for_attempt)
    target_attempt = for_attempt || submission.attempt || 0
    target_attempt = [nil, 0, 1] if target_attempt <= 1 # Submission 0 and 1 share comments
    target_attempt.is_a?(Array) ? target_attempt : [target_attempt]
  end
  private :attempt_filter

  field :score, Float, null: true
  def score
    protect_submission_grades(:score)
  end

  field :grade, String, null: true
  def grade
    protect_submission_grades(:grade)
  end

  field :entered_score,
        Float,
        "the submission score *before* late policy deductions were applied",
        null: true
  def entered_score
    protect_submission_grades(:entered_score)
  end

  field :entered_grade,
        String,
        "the submission grade *before* late policy deductions were applied",
        null: true
  def entered_grade
    protect_submission_grades(:entered_grade)
  end

  field :deducted_points, Float, "how many points are being deducted due to late policy", null: true
  def deducted_points
    protect_submission_grades(:points_deducted)
  end

  field :sticker, String, null: true
  def sticker
    protect_submission_grades(:sticker)
  end

  field :excused,
        Boolean,
        "excused assignments are ignored when calculating grades",
        method: :excused?,
        null: true

  field :cached_due_date, Types::DateTimeType, null: true
  field :graded_at, Types::DateTimeType, null: true
  field :posted, Boolean, method: :posted?, null: false
  field :posted_at, Types::DateTimeType, null: true
  field :redo_request, Boolean, null: true
  field :seconds_late, Float, null: true
  field :state, Types::SubmissionStateType, method: :workflow_state, null: false
  field :submitted_at, Types::DateTimeType, null: true

  field :has_postable_comments, Boolean, null: false
  def has_postable_comments # rubocop:disable Naming/PredicateName
    Loaders::HasPostableCommentsLoader.load(submission.id)
  end

  field :grade_hidden, Boolean, null: false
  def grade_hidden
    !submission.user_can_read_grade?(current_user, session)
  end

  field :submission_status, String, null: true
  def submission_status
    if submission.submission_type == "online_quiz"
      Loaders::AssociationLoader
        .for(Submission, :quiz_submission)
        .load(submission)
        .then { submission.submission_status }
    else
      submission.submission_status
    end
  end

  field :sub_assignment_submissions, [Types::SubAssignmentSubmissionType], null: true
  def sub_assignment_submissions
    # TODO: remove this antipattern as soon as EGG-1372 is resolved
    # data should not be created while fetching
    # Code to use after EGG-1372 is resolved:
    # Loaders::SubmissionLoaders::SubAssignmentSubmissionsLoader.load(object)

    load_association(:assignment).then do
      next nil unless object.assignment.checkpoints_parent?

      Loaders::AssociationLoader.for(Assignment, :sub_assignments).load(object.assignment).then do |sub_assignments|
        sub_assignments&.map do |sub_assignment|
          sub_assignment.find_or_create_submission(submission.user)
        end
      end
    end
  end

  field :grading_status, Types::SubmissionGradingStatusType, null: true
  field :last_commented_by_user_at, Types::DateTimeType, null: true
  def last_commented_by_user_at
    Loaders::LastCommentedByUserAtLoader.for(current_user:).load(submission.id)
  end

  field :grade_matches_current_submission,
        Boolean,
        "was the grade given on the current submission (resubmission)",
        null: true
  field :late, Boolean, method: :late?
  field :late_policy_status, Types::LatePolicyStatusType, null: true
  field :missing, Boolean, method: :missing?
  field :submission_type, Types::AssignmentSubmissionType, null: true

  field :attachment, Types::FileType, null: true
  def attachment
    load_association(:attachment)
  end

  field :attachments, [Types::FileType], null: true
  def attachments
    Loaders::IDLoader.for(Attachment).load_many(object.attachment_ids_for_version)
  end

  field :body, String, null: true
  def body
    Loaders::AssociationLoader
      .for(Submission, :assignment)
      .load(submission)
      .then do |assignment|
        Loaders::AssociationLoader
          .for(Assignment, :context)
          .load(assignment)
          .then do
            # The "body" of submissions for (old) quiz assignments includes grade
            # information, so exclude it if the caller can't see the grade
            if !assignment.quiz? || submission.user_can_read_grade?(current_user, session)
              Loaders::ApiContentAttachmentLoader
                .for(assignment.context)
                .load(object.body)
                .then do |preloaded_attachments|
                  GraphQLHelpers::UserContent.process(
                    object.body,
                    context: assignment.context,
                    in_app: context[:in_app],
                    request: context[:request],
                    preloaded_attachments:,
                    user: current_user,
                    options: {
                      domain_root_account: context[:domain_root_account],
                    },
                    location: object.asset_string
                  )
                end
            end
          end
      end
  end

  field :custom_grade_status_id, ID, null: true

  field :custom_grade_status, String, null: true
  def custom_grade_status
    load_association(:custom_grade_status).then do |status|
      status&.name.to_s
    end
  end

  field :status, String, null: false
  def status
    Promise.all([load_association(:assignment), load_association(:custom_grade_status)]).then do
      Loaders::AssociationLoader.for(Assignment, :external_tool_tag).load(object.assignment).then do
        object.status
      end
    end
  end

  field :status_tag, Types::SubmissionStatusTagType, null: false
  def status_tag
    load_association(:assignment).then do
      Loaders::AssociationLoader.for(Assignment, :external_tool_tag).load(object.assignment).then do
        object.status_tag
      end
    end
  end

  field :media_object, Types::MediaObjectType, null: true
  def media_object
    Loaders::MediaObjectLoader.load(object.media_comment_id)
  end

  field :has_originality_report, Boolean, null: false
  def has_originality_report
    if submission.submitted_at.nil?
      []
    else
      load_association(:originality_reports).then do |originality_reports|
        originality_reports.any? { |o| originality_report_matches_current_version?(o) }
      end
    end
  end

  field :vericite_data, [Types::VericiteDataType], null: true
  def vericite_data
    return nil unless object.vericite_data(false).present? &&
                      object.grants_right?(current_user, :view_vericite_report) &&
                      object.assignment.vericite_enabled

    promises =
      object.vericite_data
            .except(
              :provider,
              :last_processed_attempt,
              :webhook_info,
              :eula_agreement_timestamp,
              :assignment_error,
              :student_error,
              :status
            )
            .map do |asset_string, data|
        Loaders::AssetStringLoader
          .load(asset_string.to_s)
          .then do |target|
            next if target.nil?

            {
              target:,
              asset_string:,
              report_url: data[:report_url],
              score: data[:similarity_score],
              status: data[:status],
              state: data[:state],
            }
          end
      end
    Promise.all(promises).then(&:compact)
  end

  field :turnitin_data, [Types::TurnitinDataType], null: true
  def turnitin_data
    return nil unless object.grants_right?(current_user, :view_turnitin_report)
    return nil if object.turnitin_data.empty?

    promises =
      object
      .turnitin_data
      .except(
        :last_processed_attempt,
        :webhook_info,
        :eula_agreement_timestamp,
        :assignment_error,
        :provider,
        :student_error,
        :status
      )
      .map do |asset_string, data|
        Loaders::AssetStringLoader
          .load(asset_string.to_s)
          .then do |target|
            next if target.nil?

            {
              target:,
              asset_string:,
              report_url: data[:report_url],
              score: data[:similarity_score],
              status: data[:status],
              state: data[:state]
            }
          end
      end
    Promise.all(promises).then(&:compact)
  end

  field :originality_data, GraphQL::Types::JSON, null: true
  delegate :originality_data, to: :submission

  field :submission_draft, Types::SubmissionDraftType, null: true
  def submission_draft
    # Other users (e.g. Observers) should not be able to see submission drafts
    return nil if submission.user != current_user

    load_association(:submission_drafts).then do |drafts|
      # Submission.attempt can be in either 0 or nil which mean the same thing
      target_attempt = (object.attempt || 0) + 1
      drafts.find { |draft| draft.submission_attempt == target_attempt }
    end
  end

  field :rubric_assessments_connection, Types::RubricAssessmentType.connection_type, null: false do
    argument :filter,
             Types::SubmissionRubricAssessmentFilterInputType,
             required: false,
             default_value: {}
  end
  def rubric_assessments_connection(filter:)
    filter = filter.to_h
    target_attempt = filter[:for_all_attempts] ? nil : (filter[:for_attempt] || object.attempt)

    Promise
      .all([load_association(:assignment), load_association(:rubric_assessments)])
      .then do
        # If the target_attempt is nil, we don't need to preload because visible_rubric_assessments_for
        # will early return and load all rubric assessments for the submission with no version checks
        assessments_needing_versions_loaded = if target_attempt.nil?
                                                []
                                              else
                                                submission.rubric_assessments.reject { |ra| ra.artifact_attempt == target_attempt }
                                              end

        versionable_loader_promise =
          if assessments_needing_versions_loaded.empty?
            Promise.resolve(nil)
          else
            Loaders::AssociationLoader
              .for(RubricAssessment, :versions)
              .load_many(assessments_needing_versions_loaded)
          end

        Promise
          .all(
            [
              versionable_loader_promise,
              Loaders::AssociationLoader
                .for(Assignment, :rubric_association)
                .load(submission.assignment),
              Loaders::AssociationLoader
                .for(RubricAssessment, :rubric_association)
                .load_many(submission.rubric_assessments)
            ]
          )
          .then { submission.visible_rubric_assessments_for(current_user, attempt: target_attempt) }
      end
  end

  field :url, Types::UrlType, null: true

  field :resource_link_lookup_uuid, String, null: true

  field :extra_attempts, Integer, null: true

  field :proxy_submitter_id, ID, null: true

  field :proxy_submitter, String, null: true
  def proxy_submitter
    object.proxy_submitter&.short_name
  end

  field :assigned_assessments, [Types::AssessmentRequestType], null: true
  def assigned_assessments
    load_association(:assigned_assessments)
  end

  field :assignment_id, ID, null: false

  field :external_tool_url, String, null: true

  field :group_id, ID, null: true
  def group_id
    # Unfortunately, we can't use submissions.group_id, since that value is
    # only set once the group has submitted, but not before then. So we have
    # to jump through some hoops to load the correct group ID for a submission.
    Loaders::SubmissionGroupIdLoader.load(object).then { |group_id| group_id }
  end

  field :preview_url, String, "This field is currently under development and its return value is subject to change.", null: true
  def preview_url
    if submission.not_submitted? && !submission.partially_submitted?
      nil
    elsif submission.submission_type == "basic_lti_launch"
      GraphQLHelpers::UrlHelpers.retrieve_course_external_tools_url(
        submission.course_id,
        assignment_id: submission.assignment_id,
        url: submission.external_tool_url(query_params: submission.tool_default_query_params(current_user)),
        display: "borderless",
        host: context[:request].host_with_port
      )
    else
      Loaders::AssociationLoader.for(Submission, :assignment).load(submission).then do |assignment|
        is_discussion_topic = submission.submission_type == "discussion_topic" || submission.partially_submitted?
        show_full_discussion = is_discussion_topic ? { show_full_discussion_immediately: true } : {}
        if assignment.anonymize_students?
          GraphQLHelpers::UrlHelpers.course_assignment_anonymous_submission_url(
            submission.course_id,
            submission.assignment_id,
            submission.anonymous_id,
            host: context[:request].host_with_port,
            preview: 1,
            version: version_query_param(submission),
            **show_full_discussion
          )
        else
          GraphQLHelpers::UrlHelpers.course_assignment_submission_url(
            submission.course_id,
            submission.assignment_id,
            submission.user_id,
            host: context[:request].host_with_port,
            preview: 1,
            version: version_query_param(submission),
            **show_full_discussion
          )
        end
      end
    end
  end

  field :submission_comment_download_url, String, null: true
  def submission_comment_download_url
    "/submissions/#{object.id}/comments.pdf"
  end

  field :word_count, Float, null: true
  delegate :word_count, to: :object

  def version_query_param(submission)
    if submission.attempt.present? && submission.attempt > 0 && submission.submission_type != "online_quiz"
      submission.attempt - 1
    else
      submission.attempt
    end
  end
end
