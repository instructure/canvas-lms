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

class ToolbarComponent
  include SeleniumDependencies

  def toolbar
    f(".toolbar-area")
  end

  def toolbar_buttons
    ff("button", toolbar)
  end

  def preview_button_selector
    "[data-testid='preview-button']"
  end

  def undo_button_selector
    "[data-testid='undo-button']"
  end

  def redo_button_selector
    "[data-testid='redo-button']"
  end

  def accessibility_checker_selector
    "[data-testid='accessibility-button']"
  end

  def preview_button
    f(preview_button_selector)
  end

  def undo_button
    f(undo_button_selector)
  end

  def redo_button
    f(redo_button_selector)
  end

  def accessibility_checker_button
    f(accessibility_checker_selector)
  end
end
