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

module CourseWikiIndexPage
    #------------------------------ Selectors -----------------------------

    #------------------------------ Elements ------------------------------
    def page_item_row(page_title)
      fj("tr:contains[#{page_title}]")
    end

    def manage_wiki_page_item_button(wiki_page_title)
      f("a[aria-label='Settings for #{wiki_page_title}']")
    end

    def wiki_page_item_settings_menu
      f("ul[role='menu']")
    end

    #------------------------------ Actions ------------------------------
    def visit_course_wiki_index_page(course_id)
      get "/courses/#{course_id}/pages"
    end
end