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

class FiltersPanelComponent
  include SeleniumDependencies

  def apply_filters_button_selector
    "[data-testid='apply-filters-button']"
  end

  def filter_toggle_button_selector
    "[data-testid='filter-resources-toggle']"
  end

  def apply_filters_button
    f(apply_filters_button_selector)
  end

  def apply_filters_button_exists?
    element_exists?(apply_filters_button_selector)
  end

  def filter_toggle_button
    f(filter_toggle_button_selector)
  end

  def apply_filters
    apply_filters_button.click
    wait_for_ajaximations
  end

  def toggle
    filter_toggle_button.click
    wait_for_ajaximations
  end

  def open
    toggle unless visible?
  end

  def visible?
    apply_filters_button_exists?
  end

  def toggle_resource_type(resource_type)
    checkbox_value = map_resource_type_to_value(resource_type)
    uncheck_all_resource_types
    check_resource_type(checkbox_value)
  end

  private

  def map_resource_type_to_value(resource_type)
    type = resource_type.to_s.downcase
    case type
    when "pages" then "wiki_page"
    when "assignments" then "assignment"
    when "discussion_topics", "discussions" then "discussion_topic"
    when "announcements" then "announcement"
    else type
    end
  end

  def uncheck_all_resource_types
    ff("input[name='resource-type-checkbox-group']").each do |checkbox|
      if checkbox.attribute("checked")
        label = checkbox.find_element(:xpath, "..")
        label.click
      end
    end
    wait_for_ajaximations
  end

  def check_resource_type(checkbox_value)
    checkbox = f("input[type='checkbox'][value='#{checkbox_value}']")
    label = checkbox.find_element(:xpath, "..")
    label.click
    wait_for_ajaximations
  end
end
