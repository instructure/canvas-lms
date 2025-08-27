# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

##
# Shared concern for handling observer module information across controllers
#
module ObserverModuleInfo
  extend ActiveSupport::Concern

  private

  def observer_module_info
    observer_enrollments = @context.observer_enrollments.for_user(@current_user).active_or_pending
    is_observer = observer_enrollments.exists?

    if is_observer
      # Get all observed students in the course - only students this observer is authorized to observe
      observed_students = observer_enrollments.preload(:associated_user).filter_map do |enrollment|
        associated_user = enrollment.associated_user
        # Verify observer is authorized to view this student and student is enrolled in course
        if associated_user && enrollment.associated_user_id &&
           @context.enrollments.where(user_id: associated_user.id, workflow_state: ["active", "completed"]).exists?
          { id: associated_user.id.to_s, name: associated_user.name }
        end
      end

      # Determine currently observed student using Canvas's existing cookie mechanism
      observed_student = if observed_students.any?
                           observed_user_cookie_name = "k5_observed_user_for_#{@current_user.id}"
                           selected_user_id = cookies[observed_user_cookie_name]

                           # Find the selected student or default to first
                           if selected_user_id
                             observed_students.find { |student| student[:id] == selected_user_id } || observed_students.first
                           else
                             observed_students.first
                           end
                         end
    else
      observed_student = nil
    end

    {
      isObserver: is_observer,
      observedStudent: observed_student,
      courseName: @context.name
    }
  end
end
