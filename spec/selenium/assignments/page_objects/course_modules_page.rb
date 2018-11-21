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

module ModulesPage
  include SeleniumDependencies

  # Selectors
  def manage_module_menu_button(module_name)
    f("button[aria-label='Manage #{module_name}']")
  end

  def active_module_menu_container
    f("ul.ui-kyle-menu")
  end

  def manage_module_move_item
    f("li a.move_module_link")
  end

  def move_module_sidebar
    f("span[aria-label='Move Module']")
  end

  def move_module_sidebar_header
    fj("h2:contains('Move Module')")
  end

  def manage_context_module_item_menu_button
    f("a.al-trigger")
  end

  def move_context_module_item_menu
    f('a.move_module_item_link')
  end

  def move_context_module_item_sidebar
    f("span[aria-label='Move Module Item']")
  end

  # Methods & Actions
  def visit_modules_page(course_id)
    get "/courses/#{course_id}/modules"
    # the sidebar is already loading in dom and needs this time before we trigger it's display
    wait_for(method: nil, timeout: 1) {
      move_module_sidebar
    }
  end

  def open_move_module_menu(module_name)
    manage_module_menu_button(module_name).click
    manage_module_move_item.click
  end

  def open_move_context_module_item_menu
    manage_context_module_item_menu_button.click
    move_context_module_item_menu.click
  end
end
