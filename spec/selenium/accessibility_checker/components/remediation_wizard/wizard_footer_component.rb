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

class WizardFooterComponent
  include SeleniumDependencies

  def skip_button_selector
    "[data-testid='skip-button']"
  end

  def save_and_next_button_selector
    "[data-testid='save-and-next-button']"
  end

  def skip_button
    f(skip_button_selector)
  end

  def save_and_next_button
    f(save_and_next_button_selector)
  end

  def save_and_next_button_exists?
    element_exists?(save_and_next_button_selector)
  end

  def click_skip_button
    button = skip_button
    scroll_to(button)
    driver.action.move_to(button).perform
    wait_for_ajaximations
    button.click
    wait_for_ajaximations
  end

  def click_save_and_next_button
    save_and_next_button.click
    wait_for_ajaximations
  end

  def save_and_next_enabled?
    save_and_next_button_exists? && !save_and_next_button.attribute("disabled")
  end
end
