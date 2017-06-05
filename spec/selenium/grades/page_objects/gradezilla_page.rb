#
# Copyright (C) 2016 - present Instructure, Inc.
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

class Gradezilla
  class << self
    include SeleniumDependencies

    # Assignment Headings
    ASSIGNMENT_HEADER_SELECTOR = '.slick-header-column'.freeze
    ASSIGNMENT_HEADER_MENU_SELECTOR = '.gradebook-header-drop'.freeze
    ASSIGNMENT_HEADER_MENU_ITEM_SELECTOR = 'ul.gradebook-header-menu li.ui-menu-item'.freeze

    # Student Headings
    STUDENT_COLUMN_MENU_SELECTOR = '.container_0 .Gradebook__ColumnHeaderAction'.freeze

    # Gradebook Menu
    GRADEBOOK_MENU_SELECTOR = '[data-component="GradebookMenu"]'.freeze

    # Action Menu
    ACTION_MENU_SELECTOR = '[data-component="ActionMenu"]'.freeze
    ACTION_MENU_ITEM_SELECTOR = '[data-menu-id="%s"]'.freeze

    # Menu Items
    MENU_ITEM_SELECTOR = 'span [data-menu-item-id="%s"]'.freeze

    def gradebook_settings_cog
      f('#gradebook_settings')
    end

    def gradebook_view_options_menu
      f('[data-component="ViewOptionsMenu"] button')
    end

    def notes_option
      f('span [data-menu-item-id="show-notes-column"]')
    end

    def save_button
      fj('button span:contains("Save")')
    end

    def ungradable_selector
      ".cannot_edit"
    end

    def assignment_header(name)
      f(assignment_header_selector(name))
    end

    def assignment_header_menu(name)
      f(assignment_header_menu_selector(name))
    end

    def assignment_header_menu_item(name)
      parent_element = ff(ASSIGNMENT_HEADER_MENU_ITEM_SELECTOR).find { |el| el.text == name }

      f('a', parent_element)
    end

    def menu_container(container_id)
      selector = '[aria-expanded=true][role=menu]'
      selector += "[aria-labelledby=#{container_id}]" if container_id

      f(selector)
    end

    def gradebook_menu_group(name, container: nil)
      menu_group = ff('[id*=MenuItemGroup]', container).find { |el| el.text.strip =~ /#{name}/ }
      return unless menu_group

      menu_group_id = menu_group.attribute('id')
      f("[role=group][aria-labelledby=#{menu_group_id}]", container)
    end

    def student_names
      ff('#gradebook_grid .student-name').map(&:text)
    end

    def gradebook_menu_options(container)
      ff('[role*=menuitem]', container)
    end

    def gradebook_menu(name)
      ff(".gradebook-menus [data-component]").find { |el| el.text.strip =~ /#{name}/ }
    end

    def student_column_menu
      f(STUDENT_COLUMN_MENU_SELECTOR)
    end

    def menu_item(name)
      f(MENU_ITEM_SELECTOR % name)
    end

    def action_menu_item(name)
      f(action_menu_item_selector(name))
    end

    def action_menu_item_selector(name)
      ACTION_MENU_ITEM_SELECTOR % name
    end

    def action_menu
      f(ACTION_MENU_SELECTOR)
    end

    def gradebook_dropdown_menu
      fj(GRADEBOOK_MENU_SELECTOR + ':visible')
    end

    def gp_dropdown
      f(".grading-period-select-button")
    end

    def gp_menu_list
      ff("#grading-period-to-show-menu li")
    end

    def grade_input(cell)
      f(".grade", cell)
    end

    def assignment_header_selector(name)
      return ASSIGNMENT_HEADER_SELECTOR unless name

      ASSIGNMENT_HEADER_SELECTOR + "[title=\"#{name}\"]"
    end

    def assignment_header_menu_selector(name)
      [assignment_header_selector(name), ASSIGNMENT_HEADER_MENU_SELECTOR].join(' ')
    end

    # actions

    def visit(course)
      Account.default.enable_feature!(:new_gradebook)
      get "/courses/#{course.id}/gradebook/change_gradebook_version?version=gradezilla"
      # the pop over menus is too lengthy so make screen bigger
      make_full_screen
    end

    def open_assignment_options_and_select_by(assignment_id:, menu_item_id:)
      column_header = f("#gradebook_grid .slick-header-column[id*='assignment_#{assignment_id}']")
      column_header.find_element(:css, '.Gradebook__ColumnHeaderAction').click
      f("span[data-menu-item-id='#{menu_item_id}']").click
    end

    def select_total_column_option(menu_item_id = nil, already_open: false)
      unless already_open
        total_grade_column_header = f("#gradebook_grid .slick-header-column[id*='total_grade']")
        total_grade_column_header.find_element(:css, '.Gradebook__ColumnHeaderAction').click
      end

      if menu_item_id
        f("span[data-menu-item-id='#{menu_item_id}']").click
      end
    end

    def open_assignment_options(cell_index)
      assignment_cell = ff('#gradebook_grid .container_1 .slick-header-column')[cell_index]
      driver.action.move_to(assignment_cell).perform
      trigger = assignment_cell.find_element(:css, '.Gradebook__ColumnHeaderAction')
      trigger.click
    end

    def grading_cell(x=0, y=0)
      row_idx = y + 1
      col_idx = x + 1
      f(".container_1 .slick-row:nth-child(#{row_idx}) .slick-cell:nth-child(#{col_idx})")
    end

    def total_score_for_row(row)
      grade_grid = f('#gradebook_grid .container_1')
      rows = grade_grid.find_elements(:css, '.slick-row')
      total = f('.total-cell', rows[row])
      total.text
    end

    def select_grading_period(grading_period_id)
      gp_dropdown.click
      period = gp_menu_list.find do |item|
        f('label', item).attribute("for") == "period_option_#{grading_period_id}"
      end
      period.click
      wait_for_animations
    end

    def enter_grade(grade, x_coordinate, y_coordinate)
      cell = grading_cell(x_coordinate, y_coordinate)
      cell.click
      set_value(grade_input(cell), grade)
      grade_input(cell).send_keys(:return)
      wait_for_ajax_requests
    end

    def cell_graded?(grade, x, y)
      cell = f('.gradebook-cell', grading_cell(x, y))
      cell.text == grade
    end

    def open_student_column_menu
      student_column_menu.click
    end

    def open_action_menu
      action_menu.click
    end

    def open_gradebook_dropdown_menu
      gradebook_dropdown_menu.click
    end

    def select_menu_item(name)
      menu_item(name).click
    end

    def select_action_menu_item(name)
      action_menu_item(name).click
    end

    # Semantic Methods for Gradebook Menus

    def open_gradebook_menu(name)
      trigger = f('button', gradebook_menu(name))
      trigger.click

      # return the finder of the popover menu for use elsewhere if needed
      menu_container(trigger.attribute('id'))
    end

    def open_view_menu_and_arrange_by_menu
      view_menu = Gradezilla.open_gradebook_menu('View')
      trigger = ff('button', view_menu).find { |element| element.text == "Arrange By" }
      trigger.click
      view_menu
    end

    def select_gradebook_menu_option(name, container: nil)
      gradebook_menu_option(name, container: container).click
    end

    def gradebook_menu_option(name = nil, container: nil)
      menu_item_name = name
      menu_container = container

      if name =~ /(.+?) > (.+)/
        menu_item_group_name, menu_item_name = Regexp.last_match[1], Regexp.last_match[2]

        menu_container = gradebook_menu_group(menu_item_group_name, container: container)
      end

      gradebook_menu_options(menu_container).find { |el| el.text =~ /#{menu_item_name}/ }
    end

    def settings_cog_select
      gradebook_settings_cog.click
    end

    def popover_menu_item(name)
      popover_menu_items.find do |menu_item|
        menu_item.text == name
      end
    end

    def popover_menu_items
      ff('[role=menu][aria-labelledby*=PopoverMenu] [role=menuitemradio]')
    end

    delegate :click, to: :save_button, prefix: true
  end
end
