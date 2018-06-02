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
class ProvisionalGradesController < ApplicationController
  before_action :require_user
  before_action :load_assignment

  include Api::V1::Submission

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
    if authorized_action(@context, @current_user, [:manage_grades, :view_all_grades])
      unless @assignment.moderated_grading?
        return render :json => { :message => "Assignment does not use moderated grading" }, :status => :bad_request
      end
      if @assignment.grades_published?
        return render :json => { :message => "Assignment grades have already been published" }, :status => :bad_request
      end

      # in theory we could apply visibility here, but for now we would rather be performant
      # e.g. @assignment.students_with_visibility(@context.students_visible_to(@current_user)).find(params[:student_id])
      student = @context.students.find(params[:student_id])
      json = {:needs_provisional_grade => @assignment.student_needs_provisional_grade?(student)}


      if params[:last_updated_at] # check to see if the submission has been updated
        last_updated = Time.zone.parse(params[:last_updated_at]) # this will be nil if there was originally no submission, so it should match a nil submission
        submission = @assignment.submissions.where(:user_id => student).first

        if ((submission && submission.updated_at).to_i != last_updated.to_i)
          if authorized_action(@context, @current_user, :moderate_grades) # only do the permission check if it has changed
            selection = @assignment.moderated_grading_selections.where(:student_id => student).first

            json[:provisional_grades] = []
            submission.provisional_grades.order(:id).each do |pg|
              pg_json = provisional_grade_json(pg, submission, @assignment, @current_user, %w(submission_comments rubric_assessment))
              pg_json[:selected] = !!(selection && selection.selected_provisional_grade_id == pg.id)
              pg_json[:readonly] = !pg.final && (pg.scorer_id != @current_user.id)
              if pg.final
                json[:final_provisional_grade] = pg_json
              else
                json[:provisional_grades] << pg_json
              end
            end
          end
        end
      end

      render :json => json
    end
  end

  # @API Select provisional grade
  #
  # Choose which provisional grade the student should receive for a submission.
  # The caller must have :moderate_grades rights.
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
    selection = @assignment.moderated_grading_selections.where(student_id: pg.submission.user_id).first
    return render :json => { :message => 'student not in moderation set' }, :status => :bad_request unless selection
    selection.provisional_grade = pg
    selection.save!
    pg.submission.touch # so the selection is reloaded for other moderators
    render :json => selection.as_json(:include_root => false, :only => %w(assignment_id student_id selected_provisional_grade_id))
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

  private

  def load_assignment
    @context = api_find(Course, params[:course_id])
    @assignment = @context.assignments.active.find(params[:assignment_id])
  end
end
