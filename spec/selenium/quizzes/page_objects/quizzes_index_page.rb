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

# Note that this is old quizzes in Canvas

module QuizzesIndexPage
    #------------------------------ Selectors -----------------------------

    #------------------------------ Elements ------------------------------
    
    def quiz_index_settings_button
      fj("[role=button]:contains('Quiz Settings')")
    end

    def quiz_index_settings_menu_items
      f("ul[role='menu']")
    end

    def quiz_index_settings_menu_tool_link(tool_text)
      fj("a:contains('#{tool_text}')")
    end

    def quiz_row(quiz_id)
      f("#summary_quiz_#{quiz_id}")
    end

    def manage_quiz_menu(quiz_id)
      f("a[role='button'][aria-owns='ui-id-#{quiz_id}-1']")
    end

    def quiz_settings_menu(quiz_id)
      f("ul[role='menu']#ui-id-#{quiz_id}-1")
    end

    def tool_dialog
      f("div[role='dialog']")
    end

    def tool_dialog_header
      f("div[role='dialog'] h2")
    end

    def tool_dialog_iframe
      tool_dialog.find_element(:css, "iframe")
    end

    #------------------------------ Actions ------------------------------
    def visit_quizzes_index_page(course_id)
      get "/courses/#{course_id}/quizzes"
    end
end