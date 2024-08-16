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

module BlockEditorPage
  def stepper_modal_selector
    '[role="dialog"][aria-label="Create a new page"]'
  end

  def stepper_modal
    f(stepper_modal_selector)
  end

  def stepper_start_from_scratch
    fxpath('//button[.//*[@aria-labelledby="start-from-scratch-desc"]]')
  end

  def stepper_start_from_template
    fxpath('//button[.//*[@aria-labelledby="select-a-template-desc"]]')
  end

  def stepper_next_button
    fj('button:contains("Next")')
  end

  def stepper_start_creating_button
    fj('button:contains("Start Creating")')
  end

  def stepper_start_editing_button
    fj('button:contains("Start Editing")')
  end

  def stepper_select_page_sections
    f('[data-testid="stepper-page-sections"]')
  end

  def stepper_hero_section_checkbox
    fxpath('//*[@id="heroWithText"]/..')
  end

  def stepper_select_color_palette
    f('[data-testid="stepper-color-palette"]')
  end

  def stepper_select_font_pirings
    f('[data-testid="stepper-font-pairings"]')
  end

  def block_toolbox_toggle
    f("#toolbox-toggle+label")
  end

  def block_toolbox
    f('[role="dialog"][aria-label="Toolbox"]')
  end

  def block_resize_handle_se
    f(".block-resizer.se")
  end

  def block_toolbar
    f(".block-toolbar")
  end

  def click_block_toolbar_menu_item(menu_button_name, menu_item_name)
    fj("button:contains('#{menu_button_name}')").click
    fj("[role=\"menuitemcheckbox\"]:contains('#{menu_item_name}')").click
  end
end
