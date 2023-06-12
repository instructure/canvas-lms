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

# @API Rubrics
# @subtopic RubricAssessments
#

class RubricAssessmentsController < ApplicationController
  before_action :require_context
  before_action :require_user

  include Api::V1::SubmissionComment
  # @API Create a single rubric assessment
  #
  # Returns the rubric assessment with the given id.
  # The returned object also provides the information of
  #   :ratings, :assessor_name, :related_group_submissions_and_assessments, :artifact
  #
  #
  # @argument course_id [Integer]
  #   The id of the course
  # @argument rubric_association_id [Integer]
  #   The id of the object with which this rubric assessment is associated
  # @argument provisional [String]
  #   (optional) Indicates whether this assessment is provisional, defaults to false.
  # @argument final [String]
  #   (optional) Indicates a provisional grade will be marked as final. It only takes effect if the provisional param is passed as true. Defaults to false.
  # @argument graded_anonymously [Boolean]
  #   (optional) Defaults to false
  # @argument rubric_assessment [Hash]
  #   A Hash of data to complement the rubric assessment:
  #   The user id that refers to the person being assessed
  #     rubric_assessment[user_id]
  #   Assessment type. There are only three valid types:  'grading', 'peer_review', or 'provisional_grade'
  #     rubric_assessment[assessment_type]
  #   The points awarded for this row.
  #     rubric_assessment[criterion_id][points]
  #   Comments to add for this row.
  #     rubric_assessment[criterion_id][comments]
  #   For each criterion_id, change the id by the criterion number, ex: criterion_123
  #   If the criterion_id is not specified it defaults to false, and nothing is updated.
  def create
    update
  end

  def remind
    @association = @context.rubric_associations.find(params[:rubric_association_id])
    @rubric = @association.rubric
    @request = @association.assessment_requests.find(params[:assessment_request_id])
    if authorized_action(@association, @current_user, :manage)
      @request.send_reminder!
      render json: @request
    end
  end

  # @API Update a single rubric assessment
  #
  # Returns the rubric assessment with the given id.
  # The returned object also provides the information of
  #   :ratings, :assessor_name, :related_group_submissions_and_assessments, :artifact
  #
  #
  # @argument id [Integer]
  #   The id of the rubric assessment
  # @argument course_id [Integer]
  #   The id of the course
  # @argument rubric_association_id [Integer]
  #   The id of the object with which this rubric assessment is associated
  # @argument provisional [String]
  #   (optional) Indicates whether this assessment is provisional, defaults to false.
  # @argument final [String]
  #   (optional) Indicates a provisional grade will be marked as final. It only takes effect if the provisional param is passed as true. Defaults to false.
  # @argument graded_anonymously [Boolean]
  #   (optional) Defaults to false
  # @argument rubric_assessment [Hash]
  #   A Hash of data to complement the rubric assessment:
  #   The user id that refers to the person being assessed
  #     rubric_assessment[user_id]
  #   Assessment type. There are only three valid types:  'grading', 'peer_review', or 'provisional_grade'
  #     rubric_assessment[assessment_type]
  #   The points awarded for this row.
  #     rubric_assessment[criterion_id][points]
  #   Comments to add for this row.
  #     rubric_assessment[criterion_id][comments]
  #   For each criterion_id, change the id by the criterion number, ex: criterion_123
  #   If the criterion_id is not specified it defaults to false, and nothing is updated.
  def update
    @association = @context.rubric_associations.find(params[:rubric_association_id])
    @assessment = @association.rubric_assessments.where(id: params[:id]).first
    @association_object = @association.association_object

    # only check if there's no @assessment object, since that's the only time
    # this param matters (find_asset_for_assessment)
    user_id = @assessment.present? ? @assessment.user_id : resolve_user_id
    raise ActiveRecord::RecordNotFound if user_id.blank?

    # Funky flow to avoid a double-render, re-work it if you like
    if @assessment && !authorized_action(@assessment, @current_user, :update)
      nil
    else
      opts = {}
      provisional = value_to_boolean(params[:provisional])
      if provisional
        opts[:provisional_grader] = @current_user
        opts[:final] = true if mark_provisional_grade_as_final?
      end

      # For a moderated assignment, submitting an assessment claims a grading
      # slot for the submitting provisional grader (or throws an error if no
      # slots remain).
      begin
        ensure_adjudication_possible(provisional:) do
          @asset, @user = @association_object.find_asset_for_assessment(@association, user_id, opts)
          unless @association.user_can_assess_for?(assessor: @current_user, assessee: @user)
            return render_unauthorized_action
          end

          @assessment = @association.assess(
            assessor: @current_user,
            user: @user,
            artifact: @asset,
            assessment: params[:rubric_assessment],
            graded_anonymously: value_to_boolean(params[:graded_anonymously])
          )
          @asset.reload

          artifact_includes =
            case @asset
            when Submission
              { artifact: Submission.json_serialization_full_parameters(except: [:submission_comments]), rubric_association: {} }
            when ModeratedGrading::ProvisionalGrade
              { rubric_association: {} }
            else
              [:artifact, :rubric_association]
            end
          json = @assessment.as_json(
            methods: %i[ratings assessor_name related_group_submissions_and_assessments],
            include: artifact_includes,
            include_root: false
          )

          case @asset
          when Submission
            submission = @asset
          when ModeratedGrading::ProvisionalGrade
            submission = @asset.submission
            json[:artifact] = @asset.submission
                                    .as_json(Submission.json_serialization_full_parameters(except: [:submission_comments], include_root: false))
                                    .merge(@asset.grade_attributes)

            if @association_object.moderated_grading? && !@association_object.can_view_other_grader_identities?(@current_user)
              current_user_moderation_grader = @association_object.moderation_graders.find_by(user: @current_user)
              json[:anonymous_assessor_id] = current_user_moderation_grader.anonymous_id
            end
          end

          if submission.present?
            json[:artifact][:submission_comments] = anonymous_moderated_submission_comments_json(
              assignment: submission.assignment,
              course: submission.assignment.course,
              current_user: @current_user,
              avatars: service_enabled?(:avatars),
              submission_comments: submission.visible_submission_comments_for(@current_user),
              submissions: [submission]
            )
          end

          render json:
        end
      rescue Assignment::GradeError => e
        json = { errors: { base: e.to_s, error_code: e.error_code } }
        render json:, status: e.status_code || :bad_request
      end
    end
  end

  # @API Delete a single rubric assessment
  #
  # Deletes a rubric assessment
  #
  # @returns RubricAssessment
  def destroy
    @association = @context.rubric_associations.find(params[:rubric_association_id])
    @rubric = @association.rubric
    @assessment = @rubric.rubric_assessments.find(params[:id])
    if authorized_action(@assessment, @current_user, :delete)
      if @assessment.destroy
        render json: @assessment
      else
        render json: @assessment.errors, status: :bad_request
      end
    end
  end

  private

  def resolve_user_id
    user_id = params[:rubric_assessment][:user_id]
    if user_id
      Api::ID_REGEX.match?(user_id) ? user_id.to_i : nil
    elsif params[:rubric_assessment][:anonymous_id]
      Submission.find_by!(
        anonymous_id: params[:rubric_assessment][:anonymous_id],
        assignment_id: @association.association_id
      ).user_id
    end
  end

  def mark_provisional_grade_as_final?
    value_to_boolean(params[:final]) && @association_object.permits_moderation?(@current_user)
  end

  def ensure_adjudication_possible(provisional:, &block)
    # Non-assignment association objects crash if they're passed into this
    # controller, since find_asset_for_assessment only exists on assignments.
    # The check here thus serves only to make sure the crash doesn't happen on
    # the call below.
    return yield unless @association_object.is_a?(Assignment)

    @association_object.ensure_grader_can_adjudicate(
      grader: @current_user,
      provisional:,
      occupy_slot: true,
&block
    )
  end
end
