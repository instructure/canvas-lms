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
    def new_page_btn_selector
      '.btn.new_page'
    end

    def edit_menu_item_selector
      '.edit-menu-item'
    end

    def delete_menu_item_selctor
      '.delete-menu-item'
    end

    def duplicate_wiki_page_menu_item_selector
      '.duplicate-wiki-page'
    end

    #------------------------------ Elements ------------------------------
    def page_index_content_container
      f('#content')
    end

    def page_index_new_page_btn
      f(new_page_btn_selector)
    end

    def page_item_row(page_title)
      fj("tr:contains[#{page_title}]")
    end

    def manage_wiki_page_item_button(wiki_page_title)
      f("a[aria-label='Settings for #{wiki_page_title}']")
    end

    def wiki_page_item_settings_menu
      f("ul[role='menu']")
    end

    def page_index_more_options_menu_open
      f('.ui-menu.ui-state-open')
    end

    def page_index_duplicate_wiki_page_menu_item
      f(duplicate_wiki_page_menu_item_selector)
    end

    def copy_to_menu_item
      fj("li:contains('Copy to...')")
    end

    def page_index_menu_link
      fj("a:contains('Pages Settings')")
    end

    def page_index_menu_item_link(item_name)
      fj("a:contains('#{item_name}')")
    end

    def wiki_index_loading_spinner
      f('div.loading')
    end

    def add_new_page_button
      f('a.btn.new_page')
    end

    #------------------------------ Actions ------------------------------
    def visit_course_wiki_index_page(course_id)
      get "/courses/#{course_id}/pages"
    end

    def click_manage_wiki_page_item_button(wiki_page_title)
      f("a[aria-label='Settings for #{wiki_page_title}']").click
      wait_for_ajaximations
    end

    #------------------------------ Methods ------------------------------
    def check_header_focus(attribute)
      f("[data-sort-field='#{attribute}']").click
      wait_for_ajaximations
      check_element_has_focus(f("[data-sort-field='#{attribute}']"))
    end
end