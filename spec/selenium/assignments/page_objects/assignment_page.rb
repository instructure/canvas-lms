# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

class AssignmentPage
  class << self
    include SeleniumDependencies

    # Selectors
    def assign_to_button
      f(assign_to_button_selector)
    end

    def course_pacing_notice_selector
      "[data-testid='CoursePacingNotice']"
    end

    def assign_to_button_selector
      "button.assign-to-link"
    end

    def visit(course, assignment)
      get "/courses/#{course}/assignments/#{assignment}"
    end

    def assignment_page_body
      f("body")
    end

    def submission_detail_link
      fj("a:contains('Submission Details')")
    end

    def moderate_button
      f("#moderated_grading_button")
    end

    def page_action_list
      f(".page-action-list")
    end

    def assignment_content
      f("#content")
    end

    def assignment_description
      f(".description.user_content")
    end

    def title
      f(".title")
    end

    def student_group_speedgrader_dropdown(group)
      f("select").click
      ff("option").find { |option| option.text == group.name }.click
    end

    def speedgrader_link
      f("#speed_grader_link_mount_point a.icon-speed-grader")
    end

    def manage_assignment_button
      fj("button:contains('Manage')")
    end

    def send_to_menuitem
      fj("li:contains('Send To...')")
    end

    def copy_to_menuitem
      fj("li:contains('Copy To...')")
    end

    def allowed_attempts_count
      fj("div.control-group:contains('Allowed Attempts')")
    end

    def course_pacing_notice
      f(course_pacing_notice_selector)
    end

    def mastery_path_toggle
      f("[data-testid='MasteryPathToggle'] svg[name='IconCheck'], [data-testid='MasteryPathToggle'] svg[name='IconX']")
    end

    # Methods
    def click_assign_to_button
      assign_to_button.click
    end

    def retrieve_due_date_table_row(row_item)
      row_elements = f(".assignment_dates").find_elements(:tag_name, "tr")
      row_elements.detect { |i| i.text.include?(row_item) }
    end

    def row_elements
      f(".assignment_dates tbody").find_elements(:tag_name, "tr")
    rescue Selenium::WebDriver::Error::NoSuchElementError # rubocop:disable Specs/NoNoSuchElementError
      []
    end

    def retrieve_overrides_count
      row_elements.count
    end

    def retrieve_all_overrides
      overrides = []
      row_elements.map do |row|
        data_cells = row.find_elements(:tag_name, "td")

        values = data_cells.map do |cell|
          inner_span = cell.find_element(:css, 'span[aria-hidden="true"]')
          inner_span.text
        rescue Selenium::WebDriver::Error::NoSuchElementError # rubocop:disable Specs/NoNoSuchElementError
          cell.text
        end
        overrides.push(values)
      end
      overrides
    end

    def retrieve_all_overrides_formatted
      overrides = retrieve_all_overrides
      overrides.map do |override|
        {
          due_at: override[0],
          due_for: override[1],
          unlock_at: override[2],
          lock_at: override[3]
        }
      end
    end
  end
end
