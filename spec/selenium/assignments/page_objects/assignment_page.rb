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

    def visit_as_student(course, assignment)
      get "/courses/#{course}/assignments/#{assignment}"
    end

    def visit_assignment_edit_page(course, assignment)
      get "/courses/#{course}/assignments/#{assignment}/edit"
    end

    def submission_detail_link
      fj("a:contains('Submission Details')")
    end

    def select_grader_dropdown
      f("select[name='grader-dropdown']")
    end

    def moderate_checkbox
      f("input[type=checkbox][name='moderated_grading']")
    end

    def filter_grader(grader_name)
      fj("option:contains(\"#{grader_name}\")")
    end

    def select_moderate_checkbox
      moderate_checkbox.click
    end

    def select_grader_from_dropdown(grader_name)
      filter_grader(grader_name).click
    end
  end
end
