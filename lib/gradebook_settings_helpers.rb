#
# Copyright (C) 2016 Instructure, Inc.
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

module GradebookSettingsHelpers
  private

  def gradebook_includes
    @gradebook_includes ||= begin
      course_id = @course.id
      gb_settings = @user.preferences.fetch(:gradebook_settings, {}).fetch(course_id, {})

      includes = []
      includes << :inactive if gb_settings.fetch('show_inactive_enrollments', "false") == "true"
      if gb_settings.fetch('show_concluded_enrollments', "false") == "true" || @course.concluded?
        includes << :completed
      end
      includes
    end
  end

  def gradebook_enrollment_scope(course = @course)
    scope = course.all_accepted_student_enrollments
    scope = scope.where("enrollments.workflow_state <> 'inactive'") unless gradebook_includes.include?(:inactive)
    scope = scope.where("enrollments.workflow_state <> 'completed'") unless gradebook_includes.include?(:completed)
    scope
  end

end
