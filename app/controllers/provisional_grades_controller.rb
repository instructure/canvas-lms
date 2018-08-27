#
# Copyright (C) 2015 - present Instructure, Inc.
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

# @API Moderated Grading
# @subtopic Provisional Grades
# @beta
#
# API for manipulating provisional grades
#
# Provisional grades are created by using the Submissions API endpoint "Grade or comment on a submission" with `provisional=true`.
# They can be viewed by using "List assignment submissions", "Get a single submission", or "List gradeable students" with `include[]=provisional_grades`.
# This API performs other operations on provisional grades for use with the Moderated Grading feature.
#
# @model ProvisionalGrade
#     {
#       "id": "ProvisionalGrade",
#       "description": "",
#       "properties": {
#         "provisional_grade_id": {
#           "description": "The identifier for the provisional grade",
#           "example": 23,
#           "type": "integer"
#         },
#         "score": {
#           "description": "The numeric score",
#           "example": 90,
#           "type": "integer"
#         },
#         "grade": {
#           "description": "The grade",
#           "example": "A-",
#           "type": "string"
#         },
#         "grade_matches_current_submission": {
#           "description": "Whether the grade was applied to the most current submission (false if the student resubmitted after grading)",
#           "example": true,
#           "type": "boolean"
#         },
#         "graded_at": {
#           "description": "When the grade was given",
#           "example": "2015-11-01T00:03:21-06:00",
#           "type": "datetime"
#         },
#         "final": {
#           "description": "Whether this is the 'final' provisional grade created by the moderator",
#           "example": false,
#           "type": "boolean"
#         },
#         "speedgrader_url": {
#           "description": "A link to view this provisional grade in SpeedGrader™",
#           "example": "http://www.example.com/courses/123/gradebook/speed_grader?...",
#           "type": "string"
#         }
#       }
#     }
class ProvisionalGradesController < ProvisionalGradesBaseController
  include Api::V1::Submission

  # @API Bulk select provisional grades
  #
  # Choose which provisional grades will be received by associated students for an assignment.
  # The caller must be the final grader for the assignment or an admin with :select_final_grade rights.
  #
  # @example_response
  #   [{
  #     "assignment_id": 867,
  #     "student_id": 5309,
  #     "selected_provisional_grade_id": 53669
  #   }]
  #
  def bulk_select
    render_unauthorized_action and return unless @assignment.permits_moderation?(@current_user)

    provisional_grade_ids = params[:provisional_grade_ids]
    provisional_grades_by_id = @assignment.provisional_grades.
      where(id: provisional_grade_ids).
      preload(:submission).
      index_by(&:id)

    submissions_by_student_id = provisional_grades_by_id.values.each_with_object({}) do |grade, map|
      map[grade.submission.user_id] = grade.submission
    end

    selections_by_student_id = @assignment.moderated_grading_selections.
      where(student_id: submissions_by_student_id.keys).
      index_by(&:student_id)

    all_by_student_id = provisional_grade_ids.each_with_object({}) do |grade_id, map|
      provisional_grade = provisional_grades_by_id[grade_id.to_i]
      next if provisional_grade.blank?

      student_id = provisional_grade.submission.user_id
      selection = selections_by_student_id[student_id.to_i]

      map[student_id] = {
        provisional_grade_id: provisional_grade.id,
        selection: selection,
        submission: provisional_grade.submission
      }
    end

    json = []
    changed_submission_ids = []

    ModeratedGrading::Selection.transaction do
      all_by_student_id.each_value do |map|
        selection = map[:selection]
        selection.selected_provisional_grade_id = map[:provisional_grade_id]
        next unless selection.selected_provisional_grade_id_changed?

        selection.save!
        changed_submission_ids.push(map[:submission].id)
        selection_json = selection.as_json(include_root: false, only: %w(assignment_id student_id selected_provisional_grade_id))

        unless @assignment.can_view_student_names?(@current_user)
          selection_json.delete(:student_id)
          selection_json[:anonymous_id] = map[:submission].anonymous_id
        end

        json.push(selection_json)
      end

      # When users with visibility of the provisional grades and final grade
      # selection are using SpeedGrader when these selections occur, update the
      # related submissions so that grades are reloaded in SpeedGrader when the
      # related students are selected.
      Submission.where(id: changed_submission_ids).touch_all
    end

    render json: json
  end

  # @API Show provisional grade status for a student
  #
  # Tell whether the student's submission needs one or more provisional grades.
  #
  # @argument student_id [Integer]
  #   The id of the student to show the status for
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/courses/1/assignments/2/provisional_grades/status?student_id=1'
  #
  # @example_response
  #
  #       { "needs_provisional_grade": false }
  #
  def status
    @student = @context.students.find(params.fetch(:student_id))
    super
  end

  # @API Select provisional grade
  #
  # Choose which provisional grade the student should receive for a submission.
  # The caller must be the final grader for the assignment or an admin with :select_final_grade rights.
  #
  # @example_response
  #   {
  #     "assignment_id": 867,
  #     "student_id": 5309,
  #     "selected_provisional_grade_id": 53669
  #   }
  #
  def select
    render_unauthorized_action and return unless @assignment.permits_moderation?(@current_user)

    pg = @assignment.provisional_grades.find(params[:provisional_grade_id])
    submission = pg.submission
    selection = @assignment.moderated_grading_selections.where(student_id: submission.user_id).first
    return render :json => { :message => 'student not in moderation set' }, :status => :bad_request unless selection
    selection.provisional_grade = pg
    selection.save!

    # When users with visibility of the provisional grades and final grade
    # selection are using SpeedGrader when this selection occurs, update the
    # related submission so that grades are reloaded in SpeedGrader when the
    # related student is selected.
    submission.touch

    json = selection.as_json(include_root: false, only: %w(assignment_id student_id selected_provisional_grade_id))
    unless @assignment.can_view_student_names?(@current_user)
      json.delete(:student_id)
      json[:anonymous_id] = submission.anonymous_id
    end
    render json: json
  end

  # @API Copy provisional grade
  #
  # Given a provisional grade, copy the grade (and associated submission comments and rubric assessments)
  # to a "final" mark which can be edited or commented upon by a moderator prior to publication of grades.
  #
  # Notes:
  # * The student must be in the moderation set for the assignment.
  # * The newly created grade will be selected.
  # * The caller must have "Moderate Grades" rights in the course.
  #
  # @returns ProvisionalGrade
  def copy_to_final_mark
    render_unauthorized_action and return unless @assignment.permits_moderation?(@current_user)

    pg = @assignment.provisional_grades.find(params[:provisional_grade_id])
    return render :json => { :message => 'provisional grade is already final' }, :status => :bad_request if pg.final
    selection = @assignment.moderated_grading_selections.where(student_id: pg.submission.user_id).first
    return render :json => { :message => 'student not in moderation set' }, :status => :bad_request unless selection
    final_mark = pg.copy_to_final_mark!(@current_user)
    selection.provisional_grade = final_mark
    selection.save!
    render :json => provisional_grade_json(final_mark, pg.submission, @assignment, @current_user, %w(submission_comments rubric_assessment crocodoc_urls)).merge(:selected => true)
  end

  # @API Publish provisional grades for an assignment
  #
  # Publish the selected provisional grade for all submissions to an assignment.
  # Use the "Select provisional grade" endpoint to choose which provisional grade to publish
  # for a particular submission.
  #
  # Students not in the moderation set will have their one and only provisional grade published.
  #
  # WARNING: This is irreversible. This will overwrite existing grades in the gradebook.
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/courses/1/assignments/2/provisional_grades/publish' \
  #        -X POST
  #
  def publish
    can_manage_grades = @context.grants_right?(@current_user, :manage_grades)
    unless can_manage_grades && @assignment.permits_moderation?(@current_user)
      render_unauthorized_action and return
    end

    unless @assignment.moderated_grading?
      return render :json => { :message => "Assignment does not use moderated grading" }, :status => :bad_request
    end
    if @assignment.grades_published?
      return render :json => { :message => "Assignment grades have already been published" }, :status => :bad_request
    end

    submissions = @assignment.submissions.preload(:all_submission_comments,
                                                  { :provisional_grades => :rubric_assessments })
    selections = @assignment.moderated_grading_selections.index_by(&:student_id)

    graded_submissions = submissions.select do |submission|
      submission.provisional_grades.any?
    end

    grades_to_publish = graded_submissions.map do |submission|
      if (selection = selections[submission.user_id])
        # student in moderation: choose the selected provisional grade
        selected_provisional_grade = submission.provisional_grades.
          detect { |pg| pg.id == selection.selected_provisional_grade_id }
      end

      # either the student is not in moderation, or not all provisional grades were entered
      # choose the first one with a grade (there should only be one)
      unless selected_provisional_grade
        provisional_grades = submission.provisional_grades.
          select { |pg| pg.graded_at.present? }
        selected_provisional_grade = provisional_grades.first if provisional_grades.count == 1
      end

      # We still don't have a provisional grade.  Let's pick up the first blank provisional grade
      # for this submission if it exists.  This will happen as a result of commenting on a
      # submission without grading it
      selected_provisional_grade ||= submission.provisional_grades.detect { |pg| pg.graded_at.nil? }

      unless selected_provisional_grade
        return render json: { message: "All submissions must have a selected grade" },
                      status: :unprocessable_entity
      end

      selected_provisional_grade
    end

    grades_to_publish.each(&:publish!)
    @context.touch_admins_later # just in case nothing got published
    @assignment.update_attribute(:grades_published_at, Time.now.utc)
    render :json => { :message => "OK" }
  end
end
