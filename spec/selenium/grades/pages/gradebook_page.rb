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
  class << self
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

    def grading_period_dropdown
      f(".grading-period-select-button")
    end

    def gp_menu_list
      ff("#grading-period-to-show-menu li")
    end

    def grade_input(cell)
      f(".grade", cell)
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

    public

    def student_name_link(student_id)
      f("a[data-student_id='#{student_id}']")
    end

    def assignment_header_label(name)
      assignment_header(name).find('.assignment-name')
    end

    def assignment_header(name)
      f(assignment_header_selector(name))
    end

    def submission_detail_speedgrader_link
      fj("a:contains('More details in the SpeedGrader')")
    end

    def grade_grid
      f('#gradebook_grid .container_1')
    end

    def flash_message_holder
      f('#flash_screenreader_holder')
    end

    # actions
    def visit_gradebook(course)
      get "/courses/#{course.id}/gradebook"
    end

    def total_score_for_row(row)
      f('.total-cell', grade_grid.find_elements(:css, '.slick-row')[row]).text
    end

    def select_grading_period(grading_period_id)
      grading_period_dropdown.click
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

    def cell_hover(x, y)
      hover(grading_cell(x, y))
    end

    def cell_click(x, y)
      grading_cell(x, y).click
    end

    def cell_tooltip(x, y)
      grading_cell(x, y).find('.gradebook-tooltip')
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

    def open_comment_dialog(x=0, y=0)
      cell = f("#gradebook_grid .container_1 .slick-row:nth-child(#{y+1}) .slick-cell:nth-child(#{x+1})")
      hover cell
      fj('.gradebook-cell-comment:visible', cell).click
      # the dialog fetches the comments async after it displays and then innerHTMLs the whole
      # thing again once it has fetched them from the server, completely replacing it
      wait_for_ajax_requests
      fj('.submission_details_dialog:visible')
    end

    def student_grid
      f('#gradebook_grid .container_0')
    end

    def student_row(student)
      rows = student_grid.find_elements(:css, '.slick-row')
      rows.index{|row| row.text.include?(student.name)}
    end

    def grading_cell_content(x,y)
      grading_cell(x, y).find(".cell-content")
    end

    def student_total_grade(student)
      total_score_for_row(student_row(student))
    end
  end
end



