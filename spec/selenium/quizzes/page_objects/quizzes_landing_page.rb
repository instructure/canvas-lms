# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

require_relative "../../common"

# Note that this is old quizzes in Canvas

module QuizzesLandingPage
  #------------------------------ Selectors -----------------------------
  def quiz_assign_to_button_selector
    "button.assign-to-link"
  end

  #------------------------------ Elements ------------------------------
  def quiz_assign_to_button
    f(quiz_assign_to_button_selector)
  end
  #------------------------------ Actions ------------------------------

  def click_quiz_assign_to_button
    quiz_assign_to_button.click
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
