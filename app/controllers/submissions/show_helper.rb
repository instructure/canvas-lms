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

module Submissions
  module ShowHelper
    def render_user_not_found
      respond_to do |format|
        format.html do
          if @assignment
            flash[:error] = t("The specified user is not a student in this course")
            redirect_to named_context_url(@context, :context_assignment_url, @assignment.id)
          else
            flash[:error] = t("The specified assignment could not be found")
            redirect_to course_url(@context)
          end
        end
        format.json do
          error = @assignment ?
            t("The specified user (%{id}) is not a student in this course", {id: params[:id]}) :
            t("The specified assignment (%{id}) could not be found", {id: params[:assignment_id]})
          render json: {
            errors: error
          }
        end
      end
    end

    def get_user_considering_section(user_id)
      students = @context.students_visible_to(@current_user, include: :priors)
      if @section
        students = students.where(:enrollments => { :course_section_id => @section })
      end
      api_find(students, user_id)
    end
  end
end
