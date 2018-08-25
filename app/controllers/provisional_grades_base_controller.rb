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
#

class ProvisionalGradesBaseController < ApplicationController
  include Api::V1::Submission

  before_action :require_user
  before_action :load_assignment

  def status
    return render_unauthorized_action unless @context.grants_any_right?(@current_user, session, :manage_grades, :view_all_grades)

    unless @assignment.moderated_grading?
      return render json: { message: "Assignment does not use moderated grading" }, status: :bad_request
    end

    if @assignment.grades_published?
      return render json: { message: "Assignment grades have already been published" }, status: :bad_request
    end

    json = {needs_provisional_grade: @assignment.can_be_moderated_grader?(@current_user)}

    return render json: json unless submission_updated?

    # this will be nil if there was originally no submission, so it should match a nil submission
    last_updated = Time.zone.parse(params[:last_updated_at])
    submission = @assignment.submissions.where(user_id: @student).first

    return render json: json if submission&.updated_at.to_i == last_updated.to_i
    return render_unauthorized_action unless @assignment.permits_moderation?(@current_user)

    selection = @assignment.moderated_grading_selections.where(student_id: @student).first

    include_scorer_names = @assignment.can_view_other_grader_identities?(@current_user)
    provisional_grades = submission.provisional_grades
    provisional_grades = provisional_grades.preload(:scorer) if include_scorer_names

    json[:provisional_grades] = []
    provisional_grades.order(:id).each do |pg|
      pg_json = provisional_grade_json(pg, submission, @assignment, @current_user, %w(submission_comments rubric_assessment))
      pg_json[:selected] = !!(selection && selection.selected_provisional_grade_id == pg.id)
      pg_json[:readonly] = !pg.final && (pg.scorer_id != @current_user.id)
      pg_json[:scorer_name] = pg.scorer.name if include_scorer_names

      if pg.final
        json[:final_provisional_grade] = pg_json
      else
        json[:provisional_grades] << pg_json
      end
    end

    render json: json
  end

  private

  def load_assignment
    @context = api_find(Course, params.fetch(:course_id))
    @assignment = @context.assignments.active.find(params.fetch(:assignment_id))
  end

  def submission_updated?
    params[:last_updated_at].present?
  end
end
