#
# Copyright (C) 2019 - present Instructure, Inc.
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

require_relative '../../common'

module AssignmentsIndexPage
    #------------------------------ Selectors -----------------------------

    #------------------------------ Elements ------------------------------
    def assignment_row(assignment_id)
      f("#assignment_#{assignment_id}")
    end

    def manage_assignment_menu(assignment_id)
      f("#assign_#{assignment_id}_manage_link", assignment_row(assignment_id))
    end

    def assignment_settings_menu(assignment_id)
      f("#assignment_#{assignment_id}_settings_list")
    end

    #------------------------------ Actions ------------------------------
    def visit_assignments_index_page(course_id)
      get "/courses/#{course_id}/assignments"
    end
end