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

require_relative "../../common"
require_relative "../../helpers/color_common"

module K5ModulesTabPageObject
  include ColorCommon

  #------------------------- Selectors --------------------------

  def add_module_button_selector
    ".add_module_link"
  end

  def add_module_item_button_selector
    ".add_module_item_link"
  end

  def add_module_item_modal_selector
    "#select_context_content_dialog"
  end

  def add_module_modal_selector
    "#add_context_module_form"
  end

  def drag_handle_selector
    "[title='Drag to reorder or move item to another module']"
  end

  def empty_modules_image_selector
    "[data-testid='empty-modules-panda']"
  end

  def expand_collapse_module_selector
    "#expand_collapse_all"
  end

  def module_assignment_selector(module_assignment_title)
    "[title='#{module_assignment_title}']"
  end

  def module_empty_state_button_selector
    ".ic-EmptyStateButton"
  end

  def module_item_selector(module_title)
    "[title='#{module_title}']"
  end

  def no_module_content_selector
    "#no_context_modules_message"
  end

  #------------------------- Elements --------------------------

  def add_module_button
    f(add_module_button_selector)
  end

  def add_module_item_button
    f(add_module_item_button_selector)
  end

  def add_module_item_modal
    f(add_module_item_modal_selector)
  end

  def add_module_modal
    f(add_module_modal_selector)
  end

  def drag_handle
    f(drag_handle_selector)
  end

  def empty_modules_image
    f(empty_modules_image_selector)
  end

  def expand_collapse_module
    f(expand_collapse_module_selector)
  end

  def module_assignment(assignment_title)
    f(module_assignment_selector(assignment_title))
  end

  def module_empty_state_button
    f(module_empty_state_button_selector)
  end

  def module_item(module_title)
    f(module_item_selector(module_title))
  end

  def no_module_content
    f(no_module_content_selector)
  end

  #----------------------- Actions & Methods -------------------------
  #----------------------- Click Items -------------------------------

  def click_add_module_item_button
    add_module_item_button.click
  end

  def click_add_module_button
    add_module_button.click
  end

  def click_expand_collapse
    expand_collapse_module.click
  end

  def click_module_assignment(assignment_title)
    module_assignment(assignment_title).click
  end

  #------------------------------Retrieve Text----------------------#
  #----------------------------Element Management---------------------#

  def module_assignment_exists?(assignment_title)
    element_exists?(module_assignment_selector(assignment_title))
  end
end
