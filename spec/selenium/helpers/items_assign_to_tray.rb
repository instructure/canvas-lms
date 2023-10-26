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

require_relative "../common"

module ItemsAssignToTray
  #------------------------------ Selectors -----------------------------
  def icon_type_selector(icon_type)
    "[name='Icon#{icon_type}']"
  end

  def item_type_text_selector
    "[data-testid='item-type-text']"
  end

  def module_item_edit_tray_selector
    "[data-testid='module-item-edit-tray']"
  end

  #------------------------------ Elements ------------------------------

  def icon_type(icon_type)
    f(icon_type_selector(icon_type))
  end

  def item_type_text
    f(item_type_text_selector)
  end

  def module_item_edit_tray
    f(module_item_edit_tray_selector)
  end

  #------------------------------ Actions ------------------------------

  def icon_type_exists?(icon_type)
    element_exists?(icon_type_selector(icon_type))
  end

  def item_tray_exists?
    element_exists?(module_item_edit_tray_selector)
  end
end
