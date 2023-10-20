# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

module ConditionalRelease
  class StatsController < ApplicationController
    before_action :get_context, :require_user, :require_course_grade_view_permissions, :require_trigger_assignment

    def students_per_range
      rule = get_rule
      include_trend_data = Array.wrap(params[:include]).include? "trends"
      render json: Stats.students_per_range(rule, include_trend_data)
    end

    def student_details
      rule = get_rule
      student_id = params[:student_id]
      unless student_id.present?
        return render json: { message: "student_id required" }, status: :bad_request
      end

      if rule.trigger_assignment&.assigned_students&.find_by(id: student_id)
        return render json: Stats.student_details(rule, student_id)
      end

      render json: { message: "student not assigned to assignment" }, status: :bad_request
    end

    private

    def get_rule
      @context.conditional_release_rules.active.where(trigger_assignment_id: params[:trigger_assignment]).take!
    end

    def require_course_grade_view_permissions
      authorized_action(@context, @current_user, :view_all_grades)
    end

    def require_trigger_assignment
      unless params[:trigger_assignment].present?
        render json: { message: "trigger_assignment required" }, status: :bad_request
      end
    end
  end
end
