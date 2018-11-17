#
# Copyright (C) 2012 - present Instructure, Inc.
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

# @API Outcomes
#
# API for accessing learning outcome information.
#
# @model Outcome
#     {
#       "id": "Outcome",
#       "description": "",
#       "properties": {
#         "id": {
#           "description": "the ID of the outcome",
#           "example": 1,
#           "type": "integer"
#         },
#         "url": {
#           "description": "the URL for fetching/updating the outcome. should be treated as opaque",
#           "example": "/api/v1/outcomes/1",
#           "type": "string"
#         },
#         "context_id": {
#           "description": "the context owning the outcome. may be null for global outcomes",
#           "example": 1,
#           "type": "integer"
#         },
#         "context_type": {
#           "example": "Account",
#           "type": "string"
#         },
#         "title": {
#           "description": "title of the outcome",
#           "example": "Outcome title",
#           "type": "string"
#         },
#         "display_name": {
#           "description": "Optional friendly name for reporting",
#           "example": "My Favorite Outcome",
#           "type": "string"
#         },
#         "description": {
#           "description": "description of the outcome. omitted in the abbreviated form.",
#           "example": "Outcome description",
#           "type": "string"
#         },
#         "vendor_guid": {
#           "description": "A custom GUID for the learning standard.",
#           "example": "customid9000",
#           "type": "string"
#         },
#         "points_possible": {
#           "description": "maximum points possible. included only if the outcome embeds a rubric criterion. omitted in the abbreviated form.",
#           "example": 5,
#           "type": "integer"
#         },
#         "mastery_points": {
#           "description": "points necessary to demonstrate mastery outcomes. included only if the outcome embeds a rubric criterion. omitted in the abbreviated form.",
#           "example": 3,
#           "type": "integer"
#         },
#         "calculation_method": {
#           "description": "the method used to calculate a students score",
#           "example": "decaying_average",
#           "type": "string",
#           "allowableValues": {
#             "values": [
#               "decaying_average",
#               "n_mastery",
#               "latest",
#               "highest"
#             ]
#           }
#         },
#         "calculation_int": {
#           "description": "this defines the variable value used by the calculation_method. included only if calculation_method uses it",
#           "example": 65,
#           "type": "integer"
#         },
#         "ratings": {
#           "description": "possible ratings for this outcome. included only if the outcome embeds a rubric criterion. omitted in the abbreviated form.",
#           "type": "array",
#           "items": { "$ref" : "RubricRating" }
#         },
#         "can_edit": {
#           "description": "whether the current user can update the outcome",
#           "example": true,
#           "type": "boolean"
#         },
#         "can_unlink": {
#           "description": "whether the outcome can be unlinked",
#           "example": true,
#           "type": "boolean"
#         },
#         "assessed": {
#           "description": "whether this outcome has been used to assess a student",
#           "example": true,
#           "type": "boolean"
#         },
#         "has_updateable_rubrics": {
#           "description": "whether updates to this outcome will propagate to unassessed rubrics that have imported it",
#           "example": true,
#           "type": "boolean"
#         }
#       }
#     }
#
# @model OutcomeAlignment
#     {
#       "id": "OutcomeAlignment",
#       "description": "",
#       "properties": {
#         "id": {
#           "description": "the id of the aligned learning outcome.",
#           "example": 1,
#           "type": "integer"
#         },
#         "assignment_id": {
#           "description": "the id of the aligned assignment.",
#           "example": 2,
#           "type": "integer"
#         },
#         "submission_types": {
#           "description": "a string representing the different submission types of an aligned assignment.",
#           "example": "online_text_entry,online_url",
#           "type": "string"
#         },
#         "url": {
#           "description": "the URL for the aligned assignment.",
#           "example": "/courses/1/assignments/5",
#           "type": "string"
#         },
#         "title": {
#           "description": "the title of the aligned assignment.",
#           "example": "Unit 1 test",
#           "type": "string"
#         }
#       }
#     }
#
class OutcomesApiController < ApplicationController
  include Api::V1::Outcome
  include Outcomes::Enrollments

  before_action :require_user
  before_action :get_outcome, except: :outcome_alignments
  before_action :require_context, only: :outcome_alignments

  # @API Show an outcome
  #
  # Returns the details of the outcome with the given id.
  #
  # @returns Outcome
  #
  def show
    if authorized_action(@outcome, @current_user, :read)
      render :json => outcome_json(@outcome, @current_user, session)
    end
  end

  # @API Update an outcome
  #
  # Modify an existing outcome. Fields not provided are left as is;
  # unrecognized fields are ignored.
  #
  # If any new ratings are provided, the combination of all new ratings
  # provided completely replace any existing embedded rubric criterion; it is
  # not possible to tweak the ratings of the embedded rubric criterion.
  #
  # A new embedded rubric criterion's mastery_points default to the maximum
  # points in the highest rating if not specified in the mastery_points
  # parameter. Any new ratings lacking a description are given a default of "No
  # description". Any new ratings lacking a point value are given a default of
  # 0.
  #
  # @argument title [String]
  #   The new outcome title.
  #
  # @argument display_name [String]
  #   A friendly name shown in reports for outcomes with cryptic titles,
  #   such as common core standards names.
  #
  # @argument description [String]
  #   The new outcome description.
  #
  # @argument vendor_guid [String]
  #   A custom GUID for the learning standard.
  #
  # @argument mastery_points [Integer]
  #   The new mastery threshold for the embedded rubric criterion.
  #
  # @argument ratings[][description] [String]
  #   The description of a new rating level for the embedded rubric criterion.
  #
  # @argument ratings[][points] [Integer]
  #   The points corresponding to a new rating level for the embedded rubric
  #   criterion.
  #
  # @argument calculation_method [String, "decaying_average"|"n_mastery"|"latest"|"highest"]
  #   The new calculation method.
  #
  # @argument calculation_int [Integer]
  #   The new calculation int.  Only applies if the calculation_method is "decaying_average" or "n_mastery"
  #
  # @returns Outcome
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/outcomes/1.json' \
  #        -X PUT \
  #        -F 'title=Outcome Title' \
  #        -F 'display_name=Title for reporting' \
  #        -F 'description=Outcome description' \
  #        -F 'vendor_guid=customid9001' \
  #        -F 'mastery_points=3' \
  #        -F 'calculation_method=decaying_average' \
  #        -F 'calculation_int=65' \
  #        -F 'ratings[][description]=Exceeds Expectations' \
  #        -F 'ratings[][points]=5' \
  #        -F 'ratings[][description]=Meets Expectations' \
  #        -F 'ratings[][points]=3' \
  #        -F 'ratings[][description]=Does Not Meet Expectations' \
  #        -F 'ratings[][points]=0' \
  #        -F 'ratings[][points]=0' \
  #        -H "Authorization: Bearer <token>"
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/outcomes/1.json' \
  #        -X PUT \
  #        --data-binary '{
  #              "title": "Outcome Title",
  #              "display_name": "Title for reporting",
  #              "description": "Outcome description",
  #              "vendor_guid": "customid9001",
  #              "mastery_points": 3,
  #              "ratings": [
  #                { "description": "Exceeds Expectations", "points": 5 },
  #                { "description": "Meets Expectations", "points": 3 },
  #                { "description": "Does Not Meet Expectations", "points": 0 }
  #              ]
  #            }' \
  #        -H "Content-Type: application/json" \
  #        -H "Authorization: Bearer <token>"
  #
  def update
    return unless authorized_action(@outcome, @current_user, :update)

    update_outcome_criterion(@outcome) if params[:mastery_points] || params[:ratings]
    if @outcome.update_attributes(params.permit(*DIRECT_PARAMS))
      render :json => outcome_json(@outcome, @current_user, session)
    else
      render :json => @outcome.errors, :status => :bad_request
    end
  end

  # @API Get aligned assignments for an outcome in a course for a particular student
  #
  # @argument course_id [Integer]
  #   The id of the course
  #
  # @argument student_id [Integer]
  #   The id of the student
  #
  # @returns [OutcomeAlignment]

  def outcome_alignments
    if !params[:student_id]
      render json: { message: "student_id is required" }, status: :bad_request
    else
      course = Course.find(params[:course_id])
      can_manage = course.grants_any_right?(@current_user, session, :manage_grades, :view_all_grades)
      student_id = params[:student_id].to_i
      verify_readable_grade_enrollments([student_id]) unless can_manage
      alignments = ActiveRecord::Base.connection.exec_query(ContentTag.active.for_context(course).learning_outcome_alignments.
        select("content_tags.learning_outcome_id, content_tags.title, content_tags.content_id as assignment_id, assignments.submission_types").
        joins("INNER JOIN #{Assignment.quoted_table_name} assignments ON assignments.id = content_tags.content_id AND content_tags.content_type = 'Assignment' AND assignments.workflow_state <> 'deleted'").
        joins("INNER JOIN #{Submission.quoted_table_name} submissions ON submissions.assignment_id = assignments.id AND submissions.user_id = #{student_id} AND submissions.workflow_state <> 'deleted'").
        to_sql).to_hash
      alignments.each{|a| a[:url] = "#{polymorphic_url([course, :assignments])}/#{a['assignment_id']}"}

      quizzes = Quizzes::Quiz.active.
        select(:title, :id, :assignment_id).preload(:quiz_questions).
        joins(assignment: :submissions).
        where(context: course).
        where("submissions.user_id = ?", student_id).
        where("submissions.workflow_state <> 'deleted'")
      quiz_alignments = quizzes.map do |quiz|
        bank_ids = quiz.quiz_questions.map{ |qq| qq.assessment_question.try(:assessment_question_bank_id) }.compact.uniq
        outcome_ids = ContentTag.active.where(content_id: bank_ids, content_type: "AssessmentQuestionBank", tag: "explicit_mastery").pluck(:learning_outcome_id)
        outcome_ids.map do |id|
          {
            learning_outcome_id: id,
            title: quiz.title,
            assignment_id: quiz.assignment_id,
            submission_types: 'online_quiz',
            url: "#{polymorphic_url([course, :quizzes])}/#{quiz.id}"
          }
        end
      end.flatten

      alignments.concat(quiz_alignments)

      render :json => alignments
    end
  rescue ActiveRecord::RecordNotFound => e
    render json: { message: e.message }, status: :not_found
  end

  protected

  def get_outcome
    @outcome = LearningOutcome.active.find(params[:id])
  end

  def update_outcome_criterion(outcome)
    criterion = outcome.rubric_criterion
    criterion ||= {}
    if params[:mastery_points]
      criterion[:mastery_points] = params[:mastery_points]
    else
      criterion.delete(:mastery_points)
    end
    if params[:ratings]
      criterion[:ratings] = params[:ratings]
    end
    outcome.rubric_criterion = criterion
  end

  # Direct params are those that have a direct correlation to attrs in the model
  DIRECT_PARAMS = %w[title display_name description vendor_guid calculation_method calculation_int].freeze
end
