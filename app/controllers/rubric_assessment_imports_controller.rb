# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

class RubricAssessmentImportsController < ApplicationController
  before_action :require_context
  before_action :require_user

  def show
    import = RubricAssessmentImport.find(params[:id])
    return unless authorized_action(import.assignment.rubric_association, @current_user, :view_rubric_assessments)

    import_response = api_json(import, @current_user, session)
    import_response[:user] = user_json(import.user, @current_user, session) if import.user
    import_response[:attachment] = import.attachment.slice(:id, :filename, :size)
    render json: import_response
  end

  def create
    file_obj = params[:attachment]
    if file_obj.nil?
      return render json: { message: I18n.t("No file attached") }, status: :bad_request
    end

    assignment = Assignment.find(params[:assignment_id])

    if !assignment || !assignment.rubric_association
      return render json: { message: I18n.t("Assignment not found or does not have a rubric association") }, status: :bad_request
    end

    return unless authorized_action(assignment.rubric_association, @current_user, :view_rubric_assessments)

    if assignment.anonymize_students?
      return render json: { message: I18n.t("Rubric import is not supported for assignments with anonymous grading") }, status: :bad_request
    end

    begin
      grading_role = assignment.grading_role(@current_user)
      provisional = [:moderator, :provisional_grader].include?(grading_role)

      ensure_adjudication_possible(provisional:) do
        import = RubricAssessmentImport.create_with_attachment(
          assignment, file_obj, @current_user
        )

        import.schedule

        import_response = api_json(import, @current_user, session)
        import_response[:user] = user_json(import.user, @current_user, session) if import.user
        import_response[:attachment] = import.attachment.slice(:id, :filename, :size)
        render json: import_response
      end
    rescue Assignment::GradeError => e
      json = { errors: { base: e.to_s, error_code: e.error_code } }
      render json:, status: e.status_code || :bad_request
    end
  end

  private

  def ensure_adjudication_possible(provisional:, &)
    # Non-assignment association objects crash if they're passed into this
    # controller, since find_asset_for_assessment only exists on assignments.
    # The check here thus serves only to make sure the crash doesn't happen on
    # the call below.
    return yield unless @association_object.is_a?(Assignment)

    @association_object.ensure_grader_can_adjudicate(
      grader: @current_user,
      provisional:,
      occupy_slot: true,
      &
    )
  end
end
