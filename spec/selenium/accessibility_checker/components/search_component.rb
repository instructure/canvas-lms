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

require_relative "../../common"

class SearchComponent
  include SeleniumDependencies

  def search_container_selector
    "[role='search']"
  end

  def search_input_selector
    "[data-testid='issue-search-input']"
  end

  def search_clear_button_selector
    "[data-testid='clear-search-button']"
  end

  def search_container_exists?
    element_exists?(search_container_selector)
  end

  def search_input
    f(search_input_selector)
  end

  def search_clear_button
    f(search_clear_button_selector)
  end

  def search_clear_button_exists?
    element_exists?(search_clear_button_selector)
  end

  def visible?
    search_container_exists?
  end

  def search(query)
    search_input.clear
    search_input.send_keys(query)
    wait_for_ajaximations
  end

  def clear
    if search_clear_button_exists?
      search_clear_button.click
    else
      search_input.clear
    end
    wait_for_ajaximations
  end
end
