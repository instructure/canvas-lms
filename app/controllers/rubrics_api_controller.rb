# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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
#         "data": {
#           "description": "An array with all of this Rubric's grading Criteria",
#           "type": "array",
#           "items": { "$ref": "RubricCriterion" }
#         },
#         "assessments": {
#           "description": "If an assessment type is included in the 'include' parameter, includes an array of rubric assessment objects for a given rubric, based on the assessment type requested. If the user does not request an assessment type this key will be absent.",
#           "type": "array",
#           "items": { "$ref": "RubricAssessment" }
#         },
#         "associations": {
#           "description": "If an association type is included in the 'include' parameter, includes an array of rubric association objects for a given rubric, based on the association type requested. If the user does not request an association type this key will be absent.",
#           "type": "array",
#           "items": { "$ref": "RubricAssociation" }
#         }
#       }
#     }
#
# @model RubricCriterion
#     {
#       "id": "RubricCriterion",
#       "description": "",
#       "properties": {
#         "id": {
#           "description": "the ID of the criterion",
#           "example": "_10",
#           "type": "string"
#         },
#         "description": {
#           "type": "string"
#         },
#         "long_description": {
#           "type": "string"
#         },
#         "points": {
#           "example": "5",
#           "type": "integer"
#         },
#         "criterion_use_range": {
#           "example": "false",
#           "type": "boolean"
#         },
#         "ratings": {
#           "description": "the possible ratings for this Criterion",
#           "type": "array",
#           "items": { "$ref": "RubricRating" }
#         }
#       }
#     }
#
# @model RubricRating
#     {
#       "id": "RubricRating",
#       "properties": {
#         "id": {
#           "example": "name_2",
#           "type": "string"
#         },
#         "criterion_id": {
#           "example": "_10",
#           "type": "string"
#         },
#         "description": {
#           "type": "string"
#         },
#         "long_description": {
#           "type": "string"
#         },
#         "points": {
#           "example": "5",
#           "type": "integer"
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
#           "type": "array",
#           "items": { "type": "object" }
#         },
#         "comments": {
#           "description": "(Optional) If 'comments_only' is included in the 'style' parameter, returned assessments will include only the comments portion of their data hash. If the user does not request a style, this key will be absent.",
#           "type": "array",
#           "items": { "type": "string" }
#         }
#       }
#     }
#
# @model RubricAssociation
#     {
#       "id": "RubricAssociation",
#       "description": "",
#       "properties": {
#         "id": {
#           "description": "the ID of the association",
#           "example": 1,
#           "type": "integer"
#         },
#         "rubric_id": {
#           "description": "the ID of the rubric",
#           "example": "1",
#           "type": "integer"
#         },
#         "association_id": {
#           "description": "the ID of the object this association links to",
#           "example": 1,
#           "type": "integer"
#         },
#         "association_type": {
#           "description": "the type of object this association links to",
#           "example": "Course",
#           "type": "string"
#         },
#         "use_for_grading": {
#           "description": "Whether or not the associated rubric is used for grade calculation",
#           "example": "true",
#           "type": "boolean"
#         },
#         "summary_data": {
#           "example": "",
#           "type": "string"
#         },
#         "purpose": {
#           "description": "Whether or not the association is for grading (and thus linked to an assignment) or if it's to indicate the rubric should appear in its context. Values will be grading or bookmark.",
#           "example": "grading",
#           "type": "string"
#         },
#         "hide_score_total": {
#           "description": "Whether or not the score total is displayed within the rubric. This option is only available if the rubric is not used for grading.",
#           "example": "true",
#           "type": "boolean"
#         },
#         "hide_points": {
#           "example": "true",
#           "type": "boolean"
#         },
#         "hide_outcome_results": {
#           "example": "true",
#           "type": "boolean"
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

  VALID_ASSESSMENT_SCOPES = %w[assessments graded_assessments peer_assessments].freeze
  VALID_ASSOCIATION_SCOPES = %w[associations assignment_associations course_associations account_associations].freeze

  VALID_INCLUDE_PARAMS = (VALID_ASSESSMENT_SCOPES + VALID_ASSOCIATION_SCOPES).freeze

  # @API List rubrics
  # Returns the paginated list of active rubrics for the current context.

  def index
    return unless authorized_action(@context, @current_user, :manage_rubrics)

    rubrics = Api.paginate(@context.rubrics.active, self, rubric_pagination_url)
    render json: rubrics_json(rubrics, @current_user, session) unless performed?
  end

  # @API Get a single rubric
  # Returns the rubric with the given id.
  # @argument include[] [String, "assessments"|"graded_assessments"|"peer_assessments"|"associations"|"assignment_associations"|"course_associations"|"account_associations"]
  #   Related records to include in the response.
  # @argument style [String, "full"|"comments_only"]
  #   Applicable only if assessments are being returned. If included, returns either all criteria data associated with the assessment, or just the comments. If not included, both data and comments are omitted.
  # @returns Rubric

  def show
    return unless authorized_action(@context, @current_user, :manage_rubrics)

    rubric = @context.rubric_associations.bookmarked.find_by(rubric_id: params[:id])&.rubric
    return render json: { message: "Rubric not found" }, status: :not_found unless rubric.present? && !rubric.deleted?

    if @context.errors.present?
      render json: @context.errors, status: :bad_request
    else
      assessments = rubric_assessments(rubric)
      associations = rubric_associations(rubric)
      render json: rubric_json(rubric,
                               @current_user,
                               session,
                               assessments:,
                               associations:,
                               style: params[:style])
    end
  end

  private

  def rubric_assessments(rubric)
    scope = if @context.is_a? Course
              RubricAssessment.for_course_context(@context.id).where(rubric_id: rubric.id)
            else
              RubricAssessment.where(rubric_id: rubric.id)
            end
    case (api_includes & VALID_ASSESSMENT_SCOPES)[0]
    when "assessments"
      scope
    when "graded_assessments"
      scope.where(assessment_type: "grading")
    when "peer_assessments"
      scope.where(assessment_type: "peer_review")
    end
  end

  def rubric_associations(rubric)
    scope = rubric.rubric_associations
    case (api_includes & VALID_ASSOCIATION_SCOPES)[0]
    when "associations"
      scope
    when "assignment_associations"
      scope.where(association_type: "Assignment")
    when "course_associations"
      scope.where(association_type: "Course")
    when "account_associations"
      scope.where(association_type: "Account")
    end
  end

  def validate_args
    errs = {}

    valid_style_args = ["full", "comments_only"]
    if params[:style] && !valid_style_args.include?(params[:style])
      errs["style"] = "invalid style requested. Must be one of the following: #{valid_style_args.join(", ")}"
    end

    if (api_includes - VALID_INCLUDE_PARAMS).present?
      errs["include"] = "invalid include value requested. Must be one of the following: #{VALID_INCLUDE_PARAMS.join(", ")}"
    else
      validate_inclusion_category(VALID_ASSOCIATION_SCOPES, errs, "association")
      include_assessments = validate_inclusion_category(VALID_ASSESSMENT_SCOPES, errs, "assessment").present?
      if params[:style] && !include_assessments
        errs["style"] = "invalid parameters. Style parameter passed without requesting assessments"
      end
    end

    errs.each { |key, msg| @context.errors.add(key, msg, att_name: key) }
  end

  def validate_inclusion_category(category_items, errs, name)
    inclusion_items = api_includes & category_items
    if inclusion_items.count > 1
      errs["include"] = "cannot list multiple #{name} includes. Multiple given: #{inclusion_items.join(", ")}"
    elsif inclusion_items.count == 1
      return inclusion_items[0]
    end
    nil
  end

  def api_includes
    @api_includes ||= Array(params[:include])
  end
end
