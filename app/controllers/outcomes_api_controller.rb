# frozen_string_literal: true

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
#               "weighted_average",
#               "decaying_average",
#               "n_mastery",
#               "latest",
#               "highest",
#               "average"
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
#           "description": "the id of the aligned assignment (null for live assessments).",
#           "example": 2,
#           "type": "integer"
#         },
#         "assessment_id": {
#           "description": "the id of the aligned live assessment (null for assignments).",
#           "example": 3,
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
  include CanvasOutcomesHelper

  before_action :require_user
  before_action :get_outcome, except: :outcome_alignments
  before_action :require_context, only: :outcome_alignments

  # @API Show an outcome
  #
  # Returns the details of the outcome with the given id.
  #
  # @argument add_defaults [Boolean]
  #   If defaults are requested, then color and mastery level defaults will be
  #   added to outcome ratings in the result. This will only take effect if
  #   the Account Level Mastery Scales FF is DISABLED
  #
  # @returns Outcome
  #
  def show
    if authorized_action(@outcome, @current_user, :read)
      render json: outcome_json(@outcome, @current_user, session)
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
  # @argument calculation_method [String, "weighted_average"|"decaying_average"|"n_mastery"|"latest"|"highest"|"average"]
  #   The new calculation method. If the
  #   Outcomes New Decaying Average Calculation Method FF is ENABLED
  #   then "weighted_average" can be used and it is same as previous "decaying_average"
  #   and new "decaying_average" will have improved version of calculation.
  #
  # @argument calculation_int [Integer]
  #   The new calculation int.  Only applies if the calculation_method is "decaying_average" or "n_mastery"
  #
  # @argument add_defaults [Boolean]
  #   If defaults are requested, then color and mastery level defaults will be
  #   added to outcome ratings in the result. This will only take effect if
  #   the Account Level Mastery Scales FF is DISABLED
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

    if @domain_root_account.feature_enabled?(:account_level_mastery_scales)
      error_msg = nil
      if params[:mastery_points]
        error_msg = t("Individual outcome mastery points cannot be modified.")
      elsif params[:ratings]
        error_msg = t("Individual outcome ratings cannot be modified.")
      elsif params[:calculation_method] || params[:calculation_int]
        error_msg = t("Individual outcome calculation values cannot be modified.")
      end
      if error_msg
        render json: { error: error_msg }, status: :forbidden
        return
      end
    end

    update_outcome_criterion(@outcome) if params[:mastery_points] || params[:ratings]
    if @outcome.update(params.permit(*DIRECT_PARAMS))
      render json: outcome_json(@outcome, @current_user, session)
    else
      render json: @outcome.errors, status: :bad_request
    end
  end

  def add_alignment(course, assignment, outcome_id, associated_asset_id)
    {
      learning_outcome_id: outcome_id,
      title: assignment.title,
      assignment_id: associated_asset_id,
      submission_types: assignment.submission_types,
      url: "#{polymorphic_url([course, :assignments])}/#{associated_asset_id}"
    }
  end

  def find_outcomes_service_assignment_alignments(course, student_id)
    outcomes = ContentTag.active.where(context:).learning_outcome_links
    student_uuid = User.find(student_id).uuid
    assignments = Assignment.active.where(context:).quiz_lti
    return if assignments.nil? || outcomes.nil?

    os_alignments = get_outcome_alignments(context, outcomes.pluck(:content_id).join(","), { includes: "alignments", list_groups: false })
    os_results = get_lmgb_results(context, assignments.pluck(:id).join(","), "canvas.assignment.quizzes", outcomes.pluck(:content_id).join(","), student_uuid)

    # collecting known alignments from results to fill in if asset information
    # is missing from get_outcome_alignments using a composite key of
    # outcomeId_artifactId_artifactType
    os_alignments_from_results = {}
    os_results&.each do |r|
      next if r[:associated_asset_id].nil?

      # using latest attempt to find the aligning question & quiz metadata
      attempt = r[:attempts]&.max_by { |a| a[:submitted_at] || a[:created_at] }
      next if attempt.nil? || attempt[:metadata].blank?

      # capturing artifact alignment
      os_alignments_from_results["#{r[:external_outcome_id]}_#{r[:artifact_id]}_#{r[:artifact_type]}"] = r

      # capturing question alignment(s)
      question_metadata = attempt[:metadata][:question_metadata]
      next if question_metadata.blank?

      question_metadata&.each do |question|
        os_alignments_from_results["#{r[:external_outcome_id]}_#{question[:quiz_item_id]}_quizzes.item"] = r
      end
    end

    outcome_assignment_alignments = []
    os_alignments&.each do |o|
      next if o[:alignments].nil?

      o[:alignments].each do |a|
        # for those artifacts that do not have associated_asset_id (aka Canvas assignment id)
        # populated, try looking for in the lmgb results from outcome service
        if a[:associated_asset_id].nil? && os_alignments_from_results.present?
          alignment_from_results = os_alignments_from_results["#{o[:external_id]}_#{a[:artifact_id]}_#{a[:artifact_type]}"]
          next if alignment_from_results.nil?

          assignment = assignments.find_by(id: alignment_from_results[:associated_asset_id])
          outcome_assignment_alignments.push(add_alignment(course, assignment, o[:external_id], alignment_from_results[:associated_asset_id]))
        else
          assignment = assignments.find_by(id: a[:associated_asset_id])
          next if assignment.nil?

          outcome_assignment_alignments.push(add_alignment(course, assignment, o[:external_id], a[:associated_asset_id]))
        end
      end
    end
    outcome_assignment_alignments.uniq
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
    if params[:student_id]
      course = Course.find(params[:course_id])
      can_manage = course.grants_any_right?(@current_user, session, :manage_grades, :view_all_grades)
      student_id = params[:student_id].to_i
      verify_readable_grade_enrollments([student_id]) unless can_manage

      assignment_states = ["deleted"]
      assignment_states << "unpublished" unless can_manage
      alignments = ActiveRecord::Base.connection.exec_query(ContentTag.active.for_context(course).learning_outcome_alignments
        .select("content_tags.learning_outcome_id, content_tags.title, content_tags.content_id as assignment_id, assignments.submission_types")
        .joins("INNER JOIN #{Assignment.quoted_table_name} assignments ON assignments.id = content_tags.content_id AND content_tags.content_type = 'Assignment'")
        .joins("INNER JOIN #{Submission.quoted_table_name} submissions ON submissions.assignment_id = assignments.id AND submissions.user_id = #{student_id} AND submissions.workflow_state <> 'deleted'")
        .where.not(assignments: { workflow_state: assignment_states })
        .to_sql).to_a
      alignments.each { |a| a[:url] = "#{polymorphic_url([course, :assignments])}/#{a["assignment_id"]}" }

      quizzes = Quizzes::Quiz.active
      quizzes = quizzes.where("quizzes.workflow_state IN ('active', 'available')") unless can_manage
      quizzes = quizzes
                .select(:title, :id, :assignment_id).preload(:quiz_questions)
                .joins(assignment: :submissions)
                .where(context: course)
                .where(submissions: { user_id: student_id })
                .where("submissions.workflow_state <> 'deleted'")
      quiz_alignments = quizzes.map do |quiz|
        bank_ids = quiz.quiz_questions.filter_map { |qq| qq.assessment_question.try(:assessment_question_bank_id) }.uniq
        outcome_ids = ContentTag.active.where(content_id: bank_ids, content_type: "AssessmentQuestionBank", tag: "explicit_mastery").pluck(:learning_outcome_id)
        outcome_ids.map do |id|
          {
            learning_outcome_id: id,
            title: quiz.title,
            assignment_id: quiz.assignment_id,
            submission_types: "online_quiz",
            url: "#{polymorphic_url([course, :quizzes])}/#{quiz.id}"
          }
        end
      end.flatten

      live_assessments = LiveAssessments::Assessment.for_context(context)
                                                    .joins(:submissions)
                                                    .preload(:learning_outcome_alignments)
                                                    .where(live_assessments_submissions: { user_id: student_id })
      magic_marker_alignments = live_assessments.map do |la|
        la.learning_outcome_alignments.map do |loa|
          {
            learning_outcome_id: loa.learning_outcome_id,
            title: loa.title,
            submission_types: "magic_marker",
            assessment_id: la.id
          }
        end
      end.flatten

      # find_outcomes_service_assignment_alignments
      # Returns outcome service aligned assignments for a given course
      # if the outcome_service_results_to_canvas FF is enabled
      os_alignments = find_outcomes_service_assignment_alignments(course, student_id)
      alignments.concat(quiz_alignments, magic_marker_alignments, os_alignments)

      render json: alignments
    else
      render json: { message: "student_id is required" }, status: :bad_request
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
