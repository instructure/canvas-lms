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
require_relative '../../helpers/color_common'

module K5TodoTabPageObject
  include ColorCommon

  #------------------------- Selectors --------------------------

  def empty_todo_panda_selector
    "[data-testid='empty-todos-panda']"
  end

  def todo_delete_selector
    "button"
  end

  def todo_item_selector
    "[data-testid='todo']"
  end

  def todo_tab_selector
    '#tab-tab-todo'
  end

  #------------------------- Elements --------------------------

  def empty_todo_panda
    f(empty_todo_panda_selector)
  end

  def todo_delete
    f(todo_delete_selector)
  end

  def todo_items
    ff(todo_item_selector)
  end

  def todo_tab
    f(todo_tab_selector)
  end

  #----------------------- Actions & Methods -------------------------

  def todo_item_exists?(todo_selector)
    element_exists?(todo_selector)
  end
  #----------------------- Click Items -------------------------------

  def delete_todo_item(item_element)
    find_from_element_css(item_element, todo_delete_selector).click
  end

  def select_todo_tab
    todo_tab.click
  end

  #------------------------------Retrieve Text----------------------#

  #----------------------------Element Management---------------------#
end
