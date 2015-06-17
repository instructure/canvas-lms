#
# Copyright (C) 2011 - 2015 Instructure, Inc.
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

# @API Peer Reviews
#
# @model PeerReview
#      {
#        "id": "PeerReview",
#        "description": "",
#        "properties":{
#          "assessor_id": {
#            "description": "The assessors user id",
#            "example": 23,
#            "type": "integer"
#          },
#          "asset_id": {
#            "description": "The id for the asset associated with this Peer Review",
#            "example": 13,
#            "type": "integer"
#          },
#          "asset_type": {
#            "description": "The type of the asset",
#            "example": "Submission",
#            "type": "string"
#          },
#          "id": {
#            "description": "The id of the Peer Review",
#            "example": 1,
#            "type": "integer"
#          },
#          "user_id": {
#            "description": "The user id for the owner of the asset",
#            "example": 7,
#            "type": "integer"
#          },
#          "workflow_state": {
#            "description": "The state of the Peer Review, either 'assigned' or 'completed'",
#            "example": "assigned",
#            "type": "string"
#          },
#          "user": {
#            "description": "the User object for the owner of the asset if the user include parameter is provided (see user API) (optional)",
#            "example": "User",
#            "type": "string"
#          },
#          "assessor": {
#            "description": "The User object for the assessor if the user include parameter is provided (see user API) (optional)",
#            "example": "User",
#            "type": "string"
#          },
#          "submission_comments": {
#            "description": "The submission comments associated with this Peer Review if the submission_comment include parameter is provided (see submissions API) (optional)",
#            "example": "SubmissionComment",
#            "type": "string"
#          }
#        }
#      }
#
class PeerReviewsApiController < ApplicationController
  include Api::V1::AssessmentRequest

  before_filter :get_course_from_section, :require_context, :require_assignment
  before_filter :peer_review_assets, only: [:create, :destroy]

  # @API Get all Peer Reviews
  # Get a list of all Peer Reviews for this assignment
  #
  # @argument include[] [String, "submission_comments"|"user"]
  #   Associations to include with the peer review.
  #
  # @returns [PeerReview]
  def index
    assessment_requests = AssessmentRequest.for_assignment(@assignment.id)
    unless @assignment.grants_any_right?(@current_user, session, :grade)
      assessment_requests = assessment_requests.for_assessee @current_user.id
    end

    if params.key?(:submission_id)
      assessment_requests = assessment_requests.for_asset(params[:submission_id])
    end

    includes = Set.new(Array(params[:include]))

    render :json => assessment_requests_json(assessment_requests, @current_user, session, includes)
  end

  # @API Create Peer Review
  # Create a peer review for the assignment
  #
  # @argument user_id [Required, Integer]
  #   user_id to assign as reviewer on this assignment
  #
  # @returns PeerReview
  def create
    if authorized_action(@assignment, @current_user, :grade)
      assessment_request = @assignment.assign_peer_review(@reviewer, @student)
      includes = Set.new(Array(params[:include]))
      render :json => assessment_request_json(assessment_request, @current_user, session, includes)
    end
  end

  # @API Create Peer Review
  # Delete a peer review for the assignment
  #
  # @argument user_id [Required, Integer]
  #   user_id to delete as reviewer on this assignment
  #
  # @returns PeerReview
  def destroy
    if authorized_action(@assignment, @current_user, :grade)
      assessment_request = AssessmentRequest.for_asset(@submission).
                                             for_assessor(@reviewer).
                                             for_assessee(@student).first
      if assessment_request
        assessment_request.destroy
        render :json => assessment_request_json(assessment_request, @current_user, session, [])
      else
        render :json => {:errors => {:base => t('errors.delete_reminder_failed', "Delete failed")}},
               :status => :bad_request
      end
    end

  end

  private

  def require_assignment
    @assignment = @context.assignments.active.find(params[:assignment_id])
    raise ActiveRecord::RecordNotFound unless @assignment
  end

  def peer_review_assets
    @submission = @assignment.submissions.find(params[:submission_id])
    @reviewer = @context.students_visible_to(@current_user).find params[:user_id]
    @student = @context.students_visible_to(@current_user).find  @submission.user.id
  end

end