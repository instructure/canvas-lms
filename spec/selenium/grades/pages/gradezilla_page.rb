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

    private

    # Student Headings
    STUDENT_COLUMN_MENU_SELECTOR = '.container_0 .Gradebook__ColumnHeaderAction'.freeze

    # Gradebook Menu
    GRADEBOOK_MENU_SELECTOR = '[data-component="GradebookMenu"]'.freeze
    INDIVIDUAL_VIEW_ITEM_SELECTOR = 'individual-gradebook'.freeze
    GRADE_HISTORY_ITEM_SELECTOR = 'gradebook-history'.freeze
    LEARING_MASTERY_ITEM_SELECTOR = 'learning-mastery'.freeze

    # Action Menu
    ACTION_MENU_SELECTOR = '[data-component="ActionMenu"]'.freeze
    ACTION_MENU_ITEM_SELECTOR = 'body [data-menu-id="%s"]'.freeze

    # Menu Items
    MENU_ITEM_SELECTOR = 'span[data-menu-item-id="%s"]'.freeze

    def gradebook_settings_cog
      f('#gradebook-settings-button')
    end

    def notes_option
      f('span [data-menu-item-id="show-notes-column"]')
    end

    def save_button
      fj('button span:contains("Save")')
    end

    # ---------------------NEW-----------------------
    # assignment header column elements
    def assignment_header_menu_element(id)
      f(".slick-header-column[id*='assignment_#{id}'] .Gradebook__ColumnHeaderAction [id*='PopoverMenu']")
    end

    def assignment_header_menu_item_element(item_name)
      f("span[data-menu-item-id=#{item_name}]")
    end

    def assignment_header_popover_menu_element(menu_name)
      fj("button:contains('#{menu_name}')")
    end

    def assignment_header_popover_sub_item_element(item)
      fj("span[role=menuitemradio]:contains(#{item})")
    end

    def assignment_header_cell_label_element(title)
      select_assignment_header_cell_element(title).find('.assignment-name')
    end

    # student header column elements
    def student_column_menu
      f("span .Gradebook__ColumnHeaderAction")
    end

    def student_header_menu_main_element(menu)
      fj("[role=menu][aria-labelledby*=PopoverMenu] button:contains('#{menu}')")
    end

    def student_header_submenu_item_element(sub_menu_item)
      fj("[role=menuitemradio]:contains('#{sub_menu_item}')")
    end

    def student_header_show_menu_option(menu_item)
      fj("[role=menuitemcheckbox]:contains(#{menu_item})")
    end

    def student_names
      ff('.student-name')
    end

    def student_column_cell_element(x,y)
      f("div .slick-cell.b#{x}.f#{y}.meta-cell")
    end

    def total_header_options_menu_item_element(menu_item)
      fj("[role=menuitem]:contains('#{menu_item}')")
    end
    # ---------------------END NEW-----------------------

    def menu_container(container_id)
      selector = '[aria-expanded=true][role=menu]'
      selector += "[aria-labelledby=#{container_id}]" if container_id

      f(selector)
    end

    def gradebook_menu(name)
      ff(".gradebook-menus [data-component]").find { |el| el.text.strip =~ /#{name}/ }
    end

    def action_menu_item(name)
      f(action_menu_item_selector(name))
    end

    def gradebook_dropdown_menu
      fj(GRADEBOOK_MENU_SELECTOR + ':visible')
    end

    def grade_input(cell)
      f(".grade", cell)
    end

    def dialog_save_mute_setting
      f("button[data-action$='mute']")
    end

    def link_previous_grade_export
      f('span[data-menu-id="previous-export"]')
    end

    def slick_custom_col_cell
      ff(".slick-cell.custom_column")
    end

    def slick_header
      ff(".container_0 .slick-header-column")
    end

    def gradebook_view_menu_button
      f('[data-component="ViewOptionsMenu"] button')
    end

    def total_cell_mute_icon
      f('.total-cell .icon-muted')
    end

    def total_cell_warning_icon
      ff('.gradebook-cell .icon-warning')
    end

    def gradebook_history
      f('[data-menu-item-id="gradebook-history"]')
    end

    def gradebook_menu_element
      f('.gradebook-menus [data-component="GradebookMenu"]')
    end

    def gradebook_settings_button
      f('#gradebook-settings-button')
    end

    def filters_element
      fj('li:contains(Filters)')
    end

    def show_grading_period_filter_element
      fj('li:contains("Grading Periods")')
    end

    def show_module_filter_element
      fj('li li:contains("Modules")')
    end

    def show_section_filter_element
      fj('li:contains("Sections")')
    end

    def show_unpublished_assignments
      fj('li li:contains("Unpublished Assignments")')
    end

    public

    def body
      f('body')
    end

    def submission_tray_selector
      '.SubmissionTray__Container'
    end

    def submission_tray
      f(submission_tray_selector)
    end

    def expanded_popover_menu_selector
      '[aria-labelledby*="PopoverMenu"][aria-expanded="true"]'
    end

    def expanded_popover_menu
      f(expanded_popover_menu_selector)
    end

    def grades_uploaded_data
      f('#gradebook_upload_uploaded_data')
    end

    def grades_new_upload
      f('#new_gradebook_upload')
    end

    # actions
    def visit(course)
      Account.default.enable_feature!(:new_gradebook)
      get "/courses/#{course.id}/gradebook/change_gradebook_version?version=default"
      # the pop over menus is too lengthy so make screen bigger
      make_full_screen
    end

    def visit_upload(course)
      Account.default.enable_feature!(:new_gradebook)
      get "/courses/#{course.id}/gradebook_uploads/new"
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

    def grading_cell(x = 0, y = 0)
      row_idx = y + 1
      col_idx = x + 1
      f(".container_1 .slick-row:nth-child(#{row_idx}) .slick-cell:nth-child(#{col_idx})")
    end

    def gradebook_cell(x = 0, y = 0)
      grading_cell(x, y).find_element(:css, '.gradebook-cell')
    end

    def gradebook_cell_percentage(x = 0, y = 0)
      gradebook_cell(x, y).find_element(:css, '.percentage')
    end

    def student_cell(y = 0)
      row_idx = y + 1
      f(".container_0 .slick-row:nth-child(#{row_idx}) .slick-cell")
    end

    def student_grades_link(student_cell)
      student_cell.find_element(:css, '.student-grades-link')
    end

    def notes_cell(y = 0)
      row_idx = y + 1
      f(".container_0 .slick-row:nth-child(#{row_idx}) .slick-cell.slick-cell:nth-child(2)")
    end

    def notes_save_button
      fj('button:contains("Save")')
    end

    def select_section(section=nil)
      section = section.name if section.is_a?(CourseSection)
      section ||= ''
      section_dropdown.click
      # section_menu_item = ff('option', section_dropdown).find { |opt| opt.text == section }
      # section_menu_item.click
      filter_menu_item(section).click
      section_dropdown.click
      wait_for_ajaximations
    end

    def select_grading_period(grading_period_name)
      click_option(grading_period_dropdown_selector, grading_period_name, :text)
      wait_for_ajaximations
    end

    def show_notes
      view_menu = open_gradebook_menu('View')
      select_gradebook_menu_option('Notes', container: view_menu, role: 'menuitemcheckbox')
      driver.action.send_keys(:escape).perform
    end

    def add_notes
      notes_cell(0).click
      driver.action.send_keys('B').perform
      driver.action.send_keys(:tab).perform
      driver.action.send_keys(:enter).perform

      driver.action.send_keys('A').perform
      driver.action.send_keys(:tab).perform
      driver.action.send_keys(:enter).perform

      driver.action.send_keys('C').perform
      driver.action.send_keys(:tab).perform
      driver.action.send_keys(:enter).perform
    end

    def open_action_menu
      action_menu.click
    end

    def select_menu_item(name)
      menu_item(name).click
    end

    def action_menu_item_selector(name)
      f(ACTION_MENU_ITEM_SELECTOR % name)
    end

    def action_menu
      f(ACTION_MENU_SELECTOR)
    end

    def select_notes_option
      notes_option.click
    end

    def select_previous_grade_export
      link_previous_grade_export.click
    end

    def header_selector_by_col_index(n)
      f(".container_0 .slick-header-column:nth-child(#{n})")
    end

    # Semantic Methods for Gradebook Menus

    def open_gradebook_menu(name)
      trigger = f('button', gradebook_menu(name))
      trigger.click

      # return the finder of the popover menu for use elsewhere if needed
      menu_container(trigger.attribute('id'))
    end

    def view_options_menu_selector
      gradebook_view_menu_button
    end

    def open_view_gradebook_menu
      trigger = view_options_menu_selector
      trigger.click

      # return the finder of the popover menu for use elsewhere if needed
      menu_container(trigger.attribute('id'))
    end

    def open_view_menu_and_arrange_by_menu
      view_menu = open_gradebook_menu('View')
      hover(view_menu_item("Arrange By"))
      view_menu
    end

    def select_view_dropdown
      view_options_menu_selector.click
    end

    def slick_headers_selector
      slick_header
    end

    def slick_custom_column_cell_selector
      slick_custom_col_cell
    end

    def select_gradebook_menu_option(name, container: nil, role: 'menuitemradio')
      gradebook_menu_option(name, container: container, role: role).click
    end

    def gradebook_menu_options(container, role = 'menuitemradio')
      ff("[role*=#{role}]", container)
    end

    def gradebook_menu_option(name = nil, container: nil, role: 'menuitemradio')
      menu_item_name = name
      menu_container = container

      if name =~ /(.+?) > (.+)/
        menu_item_group_name, menu_item_name = Regexp.last_match[1], Regexp.last_match[2]

        menu_container = gradebook_menu_group(menu_item_group_name, container: container)
      end

      fj("[role*=#{role}] *:contains(#{menu_item_name})", menu_container)
    end

    def gradebook_menu_group(name, container: nil)
      menu_group = ff('[id*=MenuItemGroup]', container).find { |el| el.text.strip =~ /#{name}/ }
      return unless menu_group

      menu_group_id = menu_group.attribute('id')
      f("[role=group][aria-labelledby=#{menu_group_id}]")
    end

    def menu_item(name)
      f(MENU_ITEM_SELECTOR % name)
    end

    def settings_cog_select
      gradebook_settings_cog.click
    end

    def view_arrange_by_submenu_item(name)
      fj("[role=menuitemradio]:contains(#{name})")
    end

    def view_menu_item(name)
      fj("[role=menu] li:contains(#{name})")
    end

    def popover_menu_item_checked?(menu_item_name)
      menu_item = view_arrange_by_submenu_item(menu_item_name)
      menu_item.attribute('aria-checked')
    end

    def total_cell_mute_icon_select
      total_cell_mute_icon
    end

    def total_cell_warning_icon_select
      total_cell_warning_icon
    end

    def content_selector
      f("#content")
    end

    def assignment_header_cell_selector(title)
      ".slick-header-column[title=\"#{title}\"]"
    end

    def grading_period_dropdown_selector
      '#grading-periods-filter-container select'
    end

    def section_dropdown
      f('#sections-filter-container select')
    end

    def module_dropdown
      f('#modules-filter-container select')
    end

    def filter_menu_item(menu_item_name)
      fj("option:contains(\"#{menu_item_name}\")")
    end

    def gradebook_dropdown_item_click(menu_item_name)
      gradebook_menu_element.click

      if menu_item_name == "Individual View"
        menu_item(INDIVIDUAL_VIEW_ITEM_SELECTOR).click
      elsif menu_item_name == "Learning Mastery"
        menu_item(LEARING_MASTERY_ITEM_SELECTOR).click
      elsif menu_item_name == "Gradebook History"
        menu_item(GRADE_HISTORY_ITEM_SELECTOR).click
      end
    end

    def module_dropdown_item_click(menu_item_name)
      module_dropdown.click
      filter_menu_item(menu_item_name).click
    end

    def gradebook_settings_btn_select
      gradebook_settings_button.click
    end

    # -----------------------NEW-----------------------

    # STUDENT COLUMN HEADER OPTIONS
    def student_header_menu_option_select(name)
      student_header_show_menu_option(name).click
    end

    def click_student_menu_sort_by(menu_option)
      student_column_menu.click
      hover(student_header_menu_main_element('Sort by'))
      wait_for_ajaximations

      if menu_option == "A-Z"
        student_header_submenu_item_element('A–Z').click
      elsif menu_option == "Z-A"
        student_header_submenu_item_element('Z–A').click
      end
    end

    def click_student_menu_display_as(menu_option)
      student_column_menu.click
      hover(student_header_menu_main_element("Display as"))

      if menu_option == "First,Last"
        student_header_submenu_item_element('First, Last Name').click
      elsif menu_option == "Last,First"
        student_header_submenu_item_element('Last, First Name').click
      elsif menu_option == "Anonymous"
        student_header_submenu_item_element('Anonymous').click
      end
    end

    def click_student_menu_secondary_info(menu_option)
      student_column_menu.click
      hover(student_header_menu_main_element("Secondary info"))

      if menu_option == "Section"
        student_header_submenu_item_element('Section').click
      elsif menu_option == "SIS"
        student_header_submenu_item_element('SIS ID').click
      elsif menu_option == "Login"
        student_header_submenu_item_element('Login ID').click
      elsif menu_option == "None"
        student_header_submenu_item_element('None').click
      end
    end

    def click_student_header_menu_show_option(name)
      student_column_menu.click
      student_header_show_menu_option(name).click
    end

    def fetch_student_names
      student_names.map(&:text)
    end

    def student_column_cell_select(x,y)
      student_column_cell_element(x,y)
    end

    # ASSIGNMENT COLUMN HEADER OPTIONS
    # css selectors
    def assignment_header_menu_selector(id)
      assignment_header_menu_element(id)
    end

    def assignment_header_cell_element(title)
      f(assignment_header_cell_selector(title))
    end

    def assignment_header_menu_trigger_element(assignment_name)
      assignment_header_cell_element(assignment_name).find_element(:css, '.Gradebook__ColumnHeaderAction button')
    end

    def assignment_header_menu_item_selector(item)
      menu_item_id = ""

      if item =~ /curve(\-?\s?grade)?/i
        menu_item_id = 'curve-grades'
      elsif item =~ /set(\-?\s?default\-?\s?grade)?/i
        menu_item_id = 'set-default-grade'
      end

      assignment_header_menu_item_element(menu_item_id)
    end

    def close_open_dialog
      fj('.ui-dialog-titlebar-close:visible').click
    end

    def select_filters
      filters_element.click
    end

    def select_view_filter(filter)
      if filter == "Grading Periods"
        show_grading_period_filter_element.click
      elsif filter == "Modules"
        show_module_filter_element.click
      elsif filter == "Sections"
        show_section_filter_element.click
      end
    end

    def select_show_unpublished_assignments
      show_unpublished_assignments.click
    end

    def assignment_group_header_options_element(group_name)
      fj("[title='#{group_name}'] .Gradebook__ColumnHeaderAction")
    end

    def click_assignment_header_menu(assignment_id)
      assignment_header_menu_element(assignment_id).click
    end

    def click_assignment_header_menu_element(assignment_id, menuitem)
      assignment_header_menu_element(assignment_id).click
      menu_item_id = ""

      if menuitem =~ /(message(\-?\s?student)?)/i
        menu_item_id = 'message-students-who'
      elsif menuitem =~ /(curve(\-?\s?grade)?)/i
        menu_item_id = 'curve-grades'
      elsif menuitem =~ /(set(\-?\s?default\-?\s?grade)?)/i
        menu_item_id = 'set-default-grade'
      elsif menuitem =~ /(mute)/i
        menu_item_id = 'assignment-muter'
      elsif menuitem =~ /(download(\-?\s?submission)?)/i
        menu_item_id = 'download-submissions'

      end
      assignment_header_menu_item_element(menu_item_id).click
    end

    def click_assignment_popover_sort_by(sort_type)
      hover(assignment_header_popover_menu_element("Sort by"))
      sort_by_item = ""

      if sort_type =~ /(low[\s\-]to[\s\-]high)/i
        sort_by_item = 'Grade - Low to High'
      elsif sort_type =~ /(high[\s\-]to[\s\-]low)/i
        sort_by_item = 'Grade - High to Low'
      elsif sort_type =~ /(missing)/i
        sort_by_item = 'Missing'
      elsif sort_type =~ /(late)/i
        sort_by_item = 'Late'
      elsif sort_type =~ /(unposted)/i
        sort_by_item = 'Unposted'
      end
      assignment_header_popover_sub_item_element(sort_by_item).click
    end

    def click_assignment_popover_enter_grade_as(assignment_id, grade_type)
      assignment_header_menu_element(assignment_id).click
      hover(assignment_header_popover_menu_element("Enter Grades as"))
      assignment_header_popover_sub_item_element(grade_type).click
    end

    def enter_grade_as_popover_menu_item_checked?(grade_type)
      hover(assignment_header_popover_menu_element("Enter Grades as"))
      menu_item = assignment_header_popover_sub_item_element(grade_type)
      menu_item.attribute('aria-checked')
    end

    def select_assignment_header_cell_element(name)
      f(assignment_header_cell_selector(name))
    end

    def select_assignment_header_secondary_label(name)
      fj(assignment_header_cell_selector(name) + " .Gradebook__ColumnHeaderDetail--secondary")
    end

    def select_assignment_header_cell_label_element(name)
      assignment_header_cell_label_element(name)
    end

    # assignment mute toggle
    def toggle_assignment_muting(assignment_id)
      click_assignment_header_menu_element(assignment_id, 'mute')
      dialog_save_mute_setting.click
      wait_for_ajaximations
    end

    def click_assignment_group_header_options(group_name, sort_type)
      assignment_group_header_options_element(group_name).click
      hover(student_header_menu_main_element('Sort by'))

      if sort_type == 'Grade - High to Low'
        student_header_submenu_item_element('Grade - High to Low').click
      elsif sort_type == 'Grade - Low to High'
        student_header_submenu_item_element('Grade - Low to High').click
      end
    end

    def click_total_header_sort_by(sort_type)
      select_total_column_option
      hover(student_header_menu_main_element('Sort by'))

      if sort_type == 'Grade - High to Low'
        student_header_submenu_item_element('Grade - High to Low').click
      elsif sort_type == 'Grade - Low to High'
        student_header_submenu_item_element('Grade - Low to High').click
      end
    end

    def click_total_header_menu_option(main_menu)
      select_total_column_option
      if main_menu == "Move to Front"
        total_header_options_menu_item_element('Move to Front').click
      elsif main_menu == "Move to End"
        total_header_options_menu_item_element('Move to End').click
      elsif main_menu == "Display as Points"
        total_header_options_menu_item_element('Display as Points').click
      end
    end

    def gradebook_slick_header_columns
      ff(".slick-header-column").map(&:text)
    end

    def overlay_info_screen
      fj(".overlay_screen")
    end
    # ----------------------END NEW----------------------------

    delegate :click, to: :save_button, prefix: true
  end
end
