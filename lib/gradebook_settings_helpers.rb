# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

  def gradebook_includes(user:, course:)
    @gradebook_includes ||= begin
      course_id = course.global_id
      gb_settings = user.get_preference(:gradebook_settings, course_id) || {}

      includes = []
      includes << :inactive if gb_settings.fetch("show_inactive_enrollments", "false") == "true"
      if gb_settings.fetch("show_concluded_enrollments", "false") == "true" || course.completed?
        includes << :completed
      end
      includes
    end
  end

  def gradebook_enrollment_scope(user:, course:)
    scope = course.all_accepted_student_enrollments

    unless gradebook_includes(user:, course:).include?(:inactive)
      scope = scope.where("enrollments.workflow_state <> 'inactive'")
    end
    unless gradebook_includes(user:, course:).include?(:completed)
      scope = scope.where("enrollments.workflow_state <> 'completed'")
    end

    scope
  end
end
