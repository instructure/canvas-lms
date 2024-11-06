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

require_relative "../../common"

class TeacherCreateEditPageV2
  class << self
    include SeleniumDependencies

    # Methods & Actions
    def visit_edit(course, assignment)
      course.account.enable_feature!(:assignment_edit_enhancements_teacher_view)
      get "/courses/#{course.id}/assignments/#{assignment.id}/edit"
    end

    def visit_create(course)
      course.account.enable_feature!(:assignment_edit_enhancements_teacher_view)
      get "/courses/#{course.id}/assignments/new"
    end

    def assignment_title(title)
      fj("h1:contains(#{title})")
    end

    def publish_status(workflow_state)
      fj("span:contains(#{workflow_state.capitalize})")
    end

    def options_button
      f("button[data-testid='assignment-options-button']")
    end

    def delete_assignment_option
      f("button[data-testid='delete-assignment-option']")
    end

    def speedgrader_option
      f("a[data-testid='speedgrader-option']")
    end
  end
end
