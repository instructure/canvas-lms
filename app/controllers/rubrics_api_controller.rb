#
# Copyright (C) 2016 Instructure, Inc.
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
# @beta
#
# API for accessing rubric information.
#
# @model Rubric
#     {
#       "id": "Rubric",
#       "description": "",
#       "properties": {
#         "id": {
#           "description": "the ID of the rubric",
#           "example": 1,
#           "type": "integer"
#         },
#         "title": {
#           "description": "title of the rubric",
#           "example": "some title",
#           "type": "string"
#         },
#         "context_id": {
#           "description": "the context owning the rubric",
#           "example": 1,
#           "type": "integer"
#         },
#         "context_type": {
#           "example": "Course",
#           "type": "string"
#         },
#         "points_possible": {
#           "example": "10.0",
#           "type": "integer"
#         },
#         "reusable": {
#           "example": "false",
#           "type": "boolean"
#         },
#         "read_only": {
#           "example": "true",
#           "type": "boolean"
#         },
#         "free_form_criterion_comments": {
#           "description": "whether or not free-form comments are used",
#           "example": "true",
#           "type": "boolean"
#         },
#         "hide_score_total": {
#           "example": "true",
#           "type": "boolean"
#         },
#         "assessments": {
#           "description": "If an assessment type is included in the 'include' parameter, includes an array of rubric assessment objects for a given rubric, based on the assessment type requested. If the user does not request an assessment type this key will be absent.",
#           "type": "array",
#           "$ref": "RubricAssessment"
#         }
#       }
#     }
#
# @model RubricAssessment
#     {
#       "id": "RubricAssessment",
#       "description": "",
#       "properties": {
#         "id": {
#           "description": "the ID of the rubric",
#           "example": 1,
#           "type": "integer"
#         },
#         "rubric_id": {
#           "description": "the rubric the assessment belongs to",
#           "example": 1,
#           "type": "integer"
#         },
#         "rubric_association_id": {
#           "example": "2",
#           "type": "integer"
#         },
#         "score": {
#           "example": "5.0",
#           "type": "integer"
#         },
#         "artifact_type": {
#           "description": "the object of the assessment",
#           "example": "Submission",
#           "type": "string"
#         },
#         "artifact_id": {
#           "description": "the id of the object of the assessment",
#           "example": "3",
#           "type": "integer"
#         },
#         "artifact_attempt": {
#           "description": "the current number of attempts made on the object of the assessment",
#           "example": "2",
#           "type": "integer"
#         },
#         "assessment_type": {
#           "description": "the type of assessment. values will be either 'grading', 'peer_review', or 'provisional_grade'",
#           "example": "grading",
#           "type": "string"
#         },
#         "assessor_id": {
#           "description": "user id of the person who made the assessment",
#           "example": "6",
#           "type": "integer"
#         },
#         "data": {
#           "description": "(Optional) If 'full' is included in the 'style' parameter, returned assessments will have their full details contained in their data hash. If the user does not request a style, this key will be absent.",
#           "type": "array"
#         },
#         "comments": {
#           "description": "(Optional) If 'comments_only' is included in the 'style' parameter, returned assessments will include only the comments portion of their data hash. If the user does not request a style, this key will be absent.",
#           "type": "array"
#         }
#       }
#     }
#
class RubricsApiController < ApplicationController
  include Api::V1::Rubric
  include Api::V1::RubricAssessment

  before_action :require_user
  before_action :require_context
  before_action :validate_args
  before_action :find_rubric, only: [:show]

  # @API List rubrics
  # Returns the paginated list of active rubrics for the current context.

  def index
    return unless authorized_action(@context, @current_user, :manage_rubrics)
    rubrics = Api.paginate(@context.rubrics.active, self, rubric_pagination_url)
    render json: rubrics_json(rubrics, @current_user, session) unless performed?
  end

  # @API Get a single rubric
  # Returns the rubric with the given id.
  # @argument include [String, "assessments"|"graded_assessments"|"peer_assessments"]
  #   If included, the type of associated rubric assessments to return. If not included, assessments will be omitted.
  # @argument style [String, "full"|"comments_only"]
  #   Applicable only if assessments are being returned. If included, returns either all criteria data associated with the assessment, or just the comments. If not included, both data and comments are omitted.
  # @returns Rubric

  def show
    return unless authorized_action(@context, @current_user, :manage_rubrics)
    if !@context.errors.present?
      assessments = get_rubric_assessment(params[:include])
      render json: rubric_json(@rubric, @current_user, session,
                  assessments: assessments, style: params[:style])
    else
      render json: @context.errors, status: :bad_request
    end
  end

  private

  def find_rubric
    @rubric = Rubric.find(params[:id])
  end

  def get_rubric_assessment(type)
    case type
      when 'assessments'
        RubricAssessment.where(rubric_id: @rubric.id)
      when 'graded_assessments'
        RubricAssessment.where(rubric_id: @rubric.id, assessment_type: 'grading')
      when 'peer_assessments'
        RubricAssessment.where(rubric_id: @rubric.id, assessment_type: 'peer_review')
    end
  end

  def validate_args
    errs = {}
    valid_assessment_args = ['assessments', 'graded_assessments', 'peer_assessments']
    valid_style_args = ['full', 'comments_only']
    if params[:include] && !valid_assessment_args.include?(params[:include])
      errs['include'] = "invalid assessment type requested. Must be one of the following: #{valid_assessment_args.join(", ")}"
    end
    if params[:style] && !valid_style_args.include?(params[:style])
      errs['style'] = "invalid style requested. Must be one of the following: #{valid_style_args.join(", ")}"
    end
    if params[:style] && !params[:include]
      errs['style'] = "invalid parameters. Style parameter passed without requesting assessments"
    end
    errs.each{|key, msg| @context.errors.add(key, msg, att_name: key)}
  end
end

