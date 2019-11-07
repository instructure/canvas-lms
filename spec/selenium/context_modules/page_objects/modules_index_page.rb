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

module ModulesIndexPage
    #------------------------------ Selectors -----------------------------

    #------------------------------ Elements ------------------------------
    def module_row(module_id)
      f("#context_module_#{module_id}")
    end

    def manage_module_menu(test_module_id, test_module_name)
      f("button[aria-label='Manage #{test_module_name}']", module_row(test_module_id))
    end

    def module_settings_menu
      f("ul[role='menu']")
    end

    #------------------------------ Actions ------------------------------
    def visit_modules_index_page(course_id)
      get "/courses/#{course_id}/modules"
    end
end