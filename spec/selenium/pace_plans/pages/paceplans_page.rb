# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

module PacePlansPageObject
  #------------------------- Selectors -------------------------------
  def cancel_button_selector
    "button:contains('Cancel')"
  end

  def duration_field_selector
    "[data-testid='duration-number-input']"
  end

  def module_items_selector
    "[data-testid='pp-title-cell']"
  end

  def pace_plan_table_module_selector
    'h2'
  end

  def publish_button_selector
    "button:contains('Publish')"
  end

  def publish_status_selector
    "[data-testid='publish-status']"
  end

  #------------------------- Elements --------------------------------

  def cancel_button
    fj(cancel_button_selector)
  end

  def duration_field
    f(duration_field_selector)
  end

  def module_items
    ff(module_items_selector)
  end

  def pace_plan_table_module_elements
    ff(pace_plan_table_module_selector)
  end

  def publish_button
    fj(publish_button_selector)
  end

  def publish_status
    f(publish_status_selector)
  end

  #----------------------- Actions & Methods -------------------------
  def visit_pace_plans_page
    get "/courses/#{@course.id}/pace_plans"
  end

  #----------------------- Click Items -------------------------------
  #------------------------------Retrieve Text------------------------
  #
  def module_item_title_text(item_number)
    module_items[item_number].text
  end

  def module_title_text(element_number)
    pace_plan_table_module_elements[element_number].text
  end
  #----------------------------Element Management---------------------

  def module_item_exists?
    element_exists?(module_items_selector)
  end

  def publish_status_exists?
    element_exists?(publish_status_selector)
  end

  def update_module_item_duration(duration)
    duration_field.send_keys([:control, 'a'], :backspace, duration, :tab)
  end
end
