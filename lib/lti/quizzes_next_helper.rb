# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

module Lti
  module QuizzesNextHelper
    def quizzes_next_tool?(tool)
      tool.present? &&
        tool.tool_id == ContextExternalTool::QUIZ_LTI
    end

    module_function :quizzes_next_tool?

    def unavailable_for_students?(context, current_user, tool)
      return false unless quizzes_next_tool?(tool)
      return false unless current_user.roles(context.root_account).exclude?("admin")

      current_user_enrollments = context.enrollments.where(user: current_user)
      scoped_enrollments = current_user_enrollments.where(type: %w[StudentEnrollment StudentViewEnrollment ObserverEnrollment])
      scoped_enrollments = if NewQuizzesFeaturesHelper.results_visible_after_conclusion?(context)
                             scoped_enrollments.where(workflow_state: ["active", "completed"])
                           else
                             scoped_enrollments.active_by_date
                           end
      scoped_enrollments.union(current_user_enrollments.of_admin_type).none?
    end

    module_function :unavailable_for_students?

    def userless_launch?(current_user, tool)
      quizzes_next_tool?(tool) &&
        current_user.blank?
    end

    module_function :userless_launch?
  end
end
