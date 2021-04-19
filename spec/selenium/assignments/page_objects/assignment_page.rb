# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

class AssignmentPage
  class << self
    include SeleniumDependencies

    def visit(course, assignment)
      get "/courses/#{course}/assignments/#{assignment}"
    end

    def assignment_page_body
      f('body')
    end

    def submission_detail_link
      fj("a:contains('Submission Details')")
    end

    def moderate_button
      f("#moderated_grading_button")
    end

    def page_action_list
      f('.page-action-list')
    end

    def assignment_content
      f("#content")
    end

    def assignment_description
      f(".description.user_content")
    end

    def title
      f('.title')
    end

    def student_group_speedgrader_dropdown(group)
      f('select').click
      ff('option').find { |option| option.text == group.name }.click
    end

    def speedgrader_link
      f('a.icon-speed-grader')
    end

    def manage_assignment_button
      fj("button:contains('Manage')")
    end

    def send_to_menuitem
      fj("li:contains('Send To...')")
    end

    def copy_to_menuitem
      fj("li:contains('Copy To...')")
    end

    def allowed_attempts_count
      fj("div.control-group:contains('Allowed Attempts')")
    end
  end
end
