# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

require_relative "../../../common"

class WizardHeaderComponent
  include SeleniumDependencies

  def header_selector
    "[role='dialog'] header"
  end

  def resource_name_selector
    "[role='dialog'] h2"
  end

  def issue_counter_selector
    "[role='dialog'] h3"
  end

  def close_button_selector
    "[data-testid='wizard-close-button']"
  end

  def header_exists?
    element_exists?(header_selector)
  end

  def resource_name_element
    f(resource_name_selector)
  end

  def issue_counter
    f(issue_counter_selector)
  end

  def close_button
    f(close_button_selector)
  end

  def click_close_button
    close_button.click
    wait_for_ajaximations
  end

  def visible?
    header_exists?
  end

  def resource_name
    resource_name_element.text
  end

  def current_issue_number
    parse_issue_counter[:current]
  end

  def total_issues
    parse_issue_counter[:total]
  end

  private

  def parse_issue_counter
    counter_text = issue_counter.text
    match = counter_text.match(%r{Issue (\d+)/(\d+)})
    return { current: 1, total: 1 } unless match

    { current: match[1].to_i, total: match[2].to_i }
  end
end
