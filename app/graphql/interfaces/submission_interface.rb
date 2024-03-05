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
      specified, it will return the rubric assessment for the current submisssion
      or submission history.
    MD
  end

  class SubmissionCommentsSortOrderType < Types::BaseEnum
    graphql_name "SubmissionCommentsSortOrderType"
    value "asc", value: :asc
    value "desc", value: :desc
  end
end

module Interfaces::SubmissionInterface
  include Interfaces::BaseInterface

  description "Types for submission or submission history"

  class LatePolicyStatusType < Types::BaseEnum
    graphql_name "LatePolicyStatusType"
    value "late"
    value "missing"
    value "extended"
    value "none"
  end

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
    load_association(:user)
  end

  field :attempt, Integer, null: false
  def attempt
    submission.attempt || 0 # Nil in database, make it 0 here for easier api
  end

  field :comments_connection, Types::SubmissionCommentType.connection_type, null: true do
    argument :filter, Types::SubmissionCommentFilterInputType, required: false, default_value: {}
    argument :sort_order,
             Types::SubmissionCommentsSortOrderType,
             required: false,
             default_value: nil
  end
  def comments_connection(filter:, sort_order:)
    filter = filter.to_h
    all_comments, for_attempt, peer_review = filter.values_at(:all_comments, :for_attempt, :peer_review)

    load_association(:assignment).then do
      scope = submission.comments_excluding_drafts_for(current_user)
      unless all_comments
        target_attempt = for_attempt || submission.attempt || 0
        if target_attempt <= 1
          target_attempt = [nil, 0, 1] # Submission 0 and 1 share comments
        end
        scope = scope.where(attempt: target_attempt)

        if peer_review
          scope = scope.where(author: current_user)
        end
      end
      scope = scope.reorder(created_at: sort_order) if sort_order
      scope.select { |comment| comment.grants_right?(current_user, :read) }
    end
  end

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

  field :submitted_at, Types::DateTimeType, null: true
  field :graded_at, Types::DateTimeType, null: true
  field :posted_at, Types::DateTimeType, null: true
  field :posted, Boolean, method: :posted?, null: false
  field :state, Types::SubmissionStateType, method: :workflow_state, null: false

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

  field :grading_status, Types::SubmissionGradingStatusType, null: true
  field :late_policy_status, LatePolicyStatusType, null: true
  field :late, Boolean, method: :late?, null: true
  field :missing, Boolean, method: :missing?, null: true
  field :grade_matches_current_submission,
        Boolean,
        "was the grade given on the current submission (resubmission)",
        null: true
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
                    user: current_user
                  )
                end
            end
          end
      end
  end

  field :custom_grade_status, String, null: true
  def custom_grade_status
    submission.custom_grade_status&.name.to_s
  end

  field :media_object, Types::MediaObjectType, null: true
  def media_object
    Loaders::MediaObjectLoader.load(object.media_comment_id)
  end

  field :turnitin_data, [Types::TurnitinDataType], null: true
  def turnitin_data
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
          .load(asset_string)
          .then do |turnitin_context|
            next if turnitin_context.nil?

            {
              target: turnitin_context,
              reportUrl: data[:report_url],
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

  field :rubric_assessments_connection, Types::RubricAssessmentType.connection_type, null: true do
    argument :filter,
             Types::SubmissionRubricAssessmentFilterInputType,
             required: false,
             default_value: {}
  end
  def rubric_assessments_connection(filter:)
    filter = filter.to_h
    target_attempt = filter[:for_attempt] || object.attempt

    Promise
      .all([load_association(:assignment), load_association(:rubric_assessments)])
      .then do
        assessments_needing_versions_loaded =
          submission.rubric_assessments.reject { |ra| ra.artifact_attempt == target_attempt }

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

  field :preview_url, String, null: true
  def preview_url
    Loaders::SubmissionVersionNumberLoader.load(object).then do |version_number|
      GraphQLHelpers::UrlHelpers.course_assignment_submission_url(
        object.course_id,
        object.assignment_id,
        object.user_id,
        host: context[:request].host_with_port,
        preview: 1,
        version: version_number
      )
    end
  end

  field :word_count, Float, null: true
  delegate :word_count, to: :object
end
