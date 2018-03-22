#
# Copyright (C) 2018 - present Instructure, Inc.
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

module Lti::Ims
  # @API Score
  # @internal
  #
  # TODO: remove internal flags
  #
  # Score API for IMS Assignment and Grade Services
  #
  # @model Score
  #     {
  #       "id": "Score",
  #       "description": "",
  #       "properties": {
  #          "userId": {
  #            "description": "The lti_user_id or the Canvas user_id",
  #            "example": "50 | 'abcasdf'",
  #            "type": "number|string"
  #          },
  #          "scoreGiven": {
  #            "description": "The Current score received in the tool for this line item and user,
  #                            scaled to the scoreMaximum",
  #            "example": "50",
  #            "type": "number"
  #          },
  #          "scoreMaximum": {
  #            "description": "Maximum possible score for this result; it must be present if scoreGiven is present.",
  #            "example": "50",
  #            "type": "number"
  #          },
  #          "comment": {
  #            "description": "Comment visible to the student about this score.",
  #            "type": "string"
  #          },
  #          "timestamp": {
  #            "description": "Date and time when the score was modified in the tool. Should use subsecond precision.",
  #            "example": "2017-04-16T18:54:36.736+00:00",
  #            "type": "string"
  #          }
  #          "activityProgress": {
  #            "description": "Indicate to Canvas the status of the user towards the activity's completion.
  #                            Must be one of Initialized, Started, InProgress, Submitted, Completed",
  #            "example": "Completed",
  #            "type": "string"
  #          }
  #          "gradingProgress": {
  #            "description": "Indicate to Canvas the status of the grading process.
  #                            A value of PendingManual will require intervention by a grader.
  #                            Values of NotReady, Failed, and Pending will cause the scoreGiven to be ignored.
  #                            FullyGraded values will require no action.
  #                            Possible values are NotReady, Failed, Pending, PendingManual, FullyGraded",
  #            "example": "FullyGraded",
  #            "type": "string"
  #          }
  #       }
  #     }
  class ScoresController < ApplicationController
    include Concerns::GradebookServices

    skip_before_action :load_user
    before_action(
      :verify_line_item_in_context,
      :verify_user_in_context,
      :verify_required_params,
      :verify_valid_timestamp,
      :verify_exclusive_key_pairs
    )

    MIME_TYPE = 'application/vnd.ims.lis.v1.score+json'.freeze

    # @API Create a Score
    # @internal
    #
    # Create a new Result from the score params. If this is for the first created line_item for a
    # ltiLinkId, or it is a line item that is not attached to a ltiLinkId, then a submission
    # record will be created for the associated assignment when gradingProgress is set to
    # FullyGraded or PendingManual.
    #
    # The submission score will also be updated when a score object is sent with either of those
    # two values for gradingProgress. If a score object is sent with either of FullyGraded or
    # PendingManual as the value for gradingProgress and scoreGiven is missing, the assignment
    # will not be graded. This also supposes the line_item meets the condition to create a submission.
    #
    # A submission comment with an unknown author will be created when the comment value is included.
    # This also supposes the line_item meets the condition to create a submission.
    #
    # @argument userId [Required, String]
    #   The lti_user_id or the Canvas user_id.
    #   Returns a 412 if user not found in Canvas or is not a student.
    #
    # @argument activityProgress [Required, String]
    #   Indicate to Canvas the status of the user towards the activity's completion.
    #   Must be one of Initialized, Started, InProgress, Submitted, Completed.
    #
    # @argument gradingProgress [Required, String]
    #   Indicate to Canvas the status of the grading process.
    #   A value of PendingManual will require intervention by a grader.
    #   Values of NotReady, Failed, and Pending will cause the scoreGiven to be ignored.
    #   FullyGraded values will require no action.
    #   Possible values are NotReady, Failed, Pending, PendingManual, FullyGraded.
    #
    # @argument timestamp [Required, String]
    #   Date and time when the score was modified in the tool. Should use subsecond precision.
    #   Returns a 400 if the timestamp is earlier than the updated_at time of the Result.
    #
    # @argument scoreGiven [Number]
    #   The Current score received in the tool for this line item and user,
    #   scaled to the scoreMaximum
    #
    # @argument scoreMaximum [Number]
    #   Maximum possible score for this result; it must be present if scoreGiven is present.
    #   Returns 412 if not present when scoreGiven is present.
    #
    # @argument comment [String]
    #   Comment visible to the student about this score.
    #
    # @returns resultUrl [String]
    #   The url to the result that was created.
    def create
      update_or_create_result
      render json: { resultUrl: result_url }
    end

    private

    REQUIRED_PARAMS = %i[userId activityProgress gradingProgress timestamp].freeze
    OPTIONAL_PARAMS = %i[scoreGiven scoreMaximum comment].freeze

    def scores_params
      @_scores_params ||= begin
        update_params = params.permit(REQUIRED_PARAMS + OPTIONAL_PARAMS).transform_keys do |k|
          k.to_s.underscore
        end.except(:timestamp, :user_id, :score_given, :score_maximum)

        return update_params if ignore_score?
        update_params.merge(result_score: params[:scoreGiven], result_maximum: params[:scoreMaximum])
      end
    end

    def verify_required_params
      REQUIRED_PARAMS.each { |param| params.require(param) }
    end

    def verify_valid_timestamp
      if timestamp.nil?
        render_error "Provided timestamp of #{params[:timestamp]} not a valid timestamp", :bad_request
      elsif result.present? && result.updated_at > timestamp
        render_error(
          "Provided timestamp of #{params[:timestamp]} before last updated timestamp " \
          "of #{result.updated_at.iso8601(3)}",
          :bad_request
        )
      end
    end

    def verify_exclusive_key_pairs
      return if ignore_score? || params.key?(:scoreMaximum)
      render_error('ScoreMaximum not supplied when ScoreGiven present.', :unprocessable_entity)
    end

    def score_submission
      return unless !ignore_score? && line_item.assignment_line_item?
      submission = line_item.assignment.grade_student(
        user,
        { score: submission_score, grader_id: -tool.id }
      ).first
      submission.save!
      submission.add_comment(comment: scores_params[:comment], skip_author: true) if scores_params[:comment].present?
      submission
    end

    def update_or_create_result
      submission = score_submission
      if result.nil?
        @_result = line_item.results.create!(
          scores_params.merge(created_at: timestamp, updated_at: timestamp, user: user, submission: submission)
        )
      else
        result.update!(scores_params.merge(updated_at: timestamp))
      end
    end

    def submission_score
      scores_params[:result_score].to_f * line_item_score_maximum_scale
    end

    def line_item_score_maximum_scale
      line_item.score_maximum / scores_params[:result_maximum].to_f
    end

    def ignore_score?
      Lti::Result::ACCEPT_GIVEN_SCORE_TYPES.exclude?(params[:gradingProgress]) || params[:scoreGiven].nil?
    end

    def result
      @_result ||= Lti::Result.where(line_item: line_item, user: user).first
    end

    def timestamp
      @_timestamp = Time.zone.parse(params[:timestamp])
    end

    def result_url
      lti_result_show_url(course_id: context.id, line_item_id: line_item.id, id: result.id)
    end
  end
end
