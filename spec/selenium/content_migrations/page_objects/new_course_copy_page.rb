# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

class NewCourseCopyPage
  class << self
    include SeleniumDependencies

    # Selectors
    def header
      f("#breadcrumbs .home + li a")
    end

    def create_course_button
      fxpath("//button[.//*[contains(text(), 'Create course')]]")
    end

    def body
      f("body")
    end

    def course_name_input
      fxpath("//*[@data-testid = 'course-name']//input")
    end

    def course_code_input
      fxpath("//*[@data-testid = 'course-code']//input")
    end

    def date_adjust_checkbox
      fxpath("//label[../input[@data-testid='date-adjust-checkbox']]")
    end

    def add_day_substitution_button
      f("[data-testid = 'substitution-button']")
    end

    def add_day_containers
      ff("#daySubstitution ul > div")
    end

    def old_start_date_input
      f("[data-testid = 'old_start_date']")
    end

    def old_end_date_input
      f("[data-testid = 'old_end_date']")
    end

    def new_start_date_input
      f("[data-testid = 'new_start_date']")
    end

    def new_end_date_input
      f("[data-testid = 'new_end_date']")
    end

    def course_start_date_input
      f("[data-testid = 'course_start_date']")
    end

    def course_end_date_input
      f("[data-testid = 'course_end_date']")
    end

    def date_remove_option
      fxpath("//label[../input[@data-testid='remove-dates']]")
    end

    def course_copy_link
      f(".copy_course_link")
    end

    def course_start_at_input
      f("[placeholder='Select start date']")
    end

    def course_start_error_message_selector
      "//*[@data-testid = 'course-start-date']//*[text() = 'Start date must be before end date']"
    end

    def course_start_error_message
      fxpath(course_start_error_message_selector)
    end

    def course_end_error_message_selector
      "//*[@data-testid = 'course-end-date']//*[text() = 'End date must be after start date']"
    end

    def course_end_error_message
      fxpath(course_end_error_message_selector)
    end

    def course_conclude_at_input
      f("[placeholder='Select end date']")
    end

    def migration_type_options
      ff("#Selectable___0-list > li")
    end

    def migration_type_options_values
      ff("#Selectable___0-list > li > span")
    end

    def cancel_copy_button
      f("#migrationConverterContainer .cancelBtn")
    end

    def day_substitution_containers
      ff("#daySubstitution ul > div")
    end

    def day_substitution_delete_button
      f("#daySubstitution ul > div a")
    end
  end
end
