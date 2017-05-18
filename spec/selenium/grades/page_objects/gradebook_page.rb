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
#

require_relative '../../common'

module Gradebook
  class MultipleGradingPeriods
    include SeleniumDependencies

    private

    # Assignment Headings
    ASSIGNMENT_HEADER_SELECTOR = '.slick-header-column'.freeze
    ASSIGNMENT_HEADER_MENU_SELECTOR = '.gradebook-header-drop'.freeze
    ASSIGNMENT_HEADER_MENU_ITEM_SELECTOR = 'ul.gradebook-header-menu li.ui-menu-item'.freeze

    def ungradable_selector
      ".cannot_edit"
    end

    def settings_cog
      f('#gradebook_settings')
    end

    def show_notes
      fj('li a:contains("Show Notes Column")')
    end

    def save_button
      fj('button span:contains("Save")')
    end

    def hide_notes
      f(".hide")
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

    def assignment_header(name)
      f(assignment_header_selector(name))
    end

    def assignment_header_menu(id)
      f("a[data-assignment-id='#{id}']")
    end

    def assignment_menu_toggle_muting
      f("a[data-action='toggleMuting']")
    end

    def save_mute_option
      f("button[data-action$='mute']")
    end

    def grading_cell(x=0, y=0)
      cell = f(".container_1")
      cell = f(".slick-row:nth-child(#{y+1})", cell)
      f(".slick-cell:nth-child(#{x+1})", cell)
    end

    def assignment_header_selector(name)
      return ASSIGNMENT_HEADER_SELECTOR unless name

      ASSIGNMENT_HEADER_SELECTOR + "[title=\"#{name}\"]"
    end

    def assignment_header_menu_item(name)
      parent_element = ff(ASSIGNMENT_HEADER_MENU_ITEM_SELECTOR).find { |el| el.text == name }

      f('a', parent_element)
    end

    # actions
    public

    def visit_gradebook(course, user = nil)
      if user
        user.preferences[:gradebook_version] = '2'
      end
      get "/courses/#{course.id}/gradebook"
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
      wait_for_new_page_load { period.click } or raise "page not loaded"
    end

    def enter_grade(grade, x_coordinate, y_coordinate)
      cell = grading_cell(x_coordinate, y_coordinate)
      cell.click
      set_value(grade_input(cell), grade)
      grade_input(cell).send_keys(:return)
    end

    def cell_graded?(grade, x_coordinate, y_coordinate)
      cell = grading_cell(x_coordinate, y_coordinate)
      if cell.text == grade
        return true
      else
        return false
      end
    end

    def assignment_header_menu_selector(name)
      [assignment_header_selector(name), ASSIGNMENT_HEADER_MENU_SELECTOR].join(' ')
    end

    def gb_settings_cog_select
      settings_cog.click
    end

    def show_notes_select
      show_notes.click
    end

    def hide_notes_select
      hide_notes.click
    end

    def save_button_click
      save_button.click
    end

    def assignment_header_menu_select(id)
      assignment_header_menu(id).click
    end

    def assignment_header_menu_item_find(name)
      assignment_header_menu_item(name)
    end

    def toggle_assignment_mute_option(id)
      assignment_header_menu(id).click
      assignment_menu_toggle_muting.click
      save_mute_option.click
      wait_for_ajaximations
    end

    def grading_cell_attributes(x, y)
      grading_cell(x, y)
    end
  end
end
