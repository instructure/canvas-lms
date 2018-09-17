#
# Copyright (C) 2018 - present Instructure, Inc.
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

module StudentContextTray
    #------------------------------ Selectors -----------------------------

    #------------------------------ Elements ------------------------------
    def student_tray_header
      f(".StudentContextTray-Header")
    end

    def student_avatar_link
      f(".StudentContextTray__Avatar a")
    end

    def student_name_link
      f(".StudentContextTray-Header__NameLink a")
    end

    def todo_tray_course_selector
      f("#to-do-item-course-select")
    end

    def todo_tray_course_suggestions
      fj("ul[role=listbox]:contains('Optional: Add Course')")
    end

    def todo_tray_dropdown_select_course(course_name)
      fj("li[role=option]:contains('#{course_name}')")
    end

    #------------------------ Actions & Methods ---------------------------
    def wait_for_student_tray
      wait_for(method: nil, timeout: 1) { student_name_link.displayed? }
    end

    def todo_tray_select_course_from_dropdown(course_name='Optional: Add Course')
      todo_tray_course_selector.click
      todo_tray_dropdown_select_course(course_name).click
    end
end
