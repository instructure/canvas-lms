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

require_relative "../../common"

module AccessibilityDrawer
  #------------------------------ Selectors -----------------------------
  def apply_button_selector
    "[data-testid='apply-button']"
  end

  def save_button_selector
    "[data-testid='save-and-next-button']"
  end

  def undo_button_selector
    "[data-testid='undo-button']"
  end

  def spinner_loader_selector
    "[data-testid='spinner-loader']"
  end

  def issue_preview_selector
    "#a11y-issue-preview"
  end

  def radio_button_form_change_heading_level_selector
    "label[for='RadioInput___0']"
  end

  def radio_button_form_remove_heading_selector
    "label[for='RadioInput___1']"
  end

  def text_input_with_checkbox_form_checkbox_selector
    "label[for='Checkbox___0']"
  end

  def text_input_with_checkbox_form_input_selector
    "[data-testid='checkbox-text-input-form']"
  end

  def text_input_form_input_selector
    "[data-testid='text-input-form']"
  end

  def color_picker_form_input_selector
    "#a11y-color-picker"
  end

  #------------------------------ Elements ------------------------------
  def apply_button
    f(apply_button_selector)
  end

  def save_button
    f(save_button_selector)
  end

  def undo_button
    f(undo_button_selector)
  end

  def spinner_loader
    f(spinner_loader_selector)
  end

  def issue_preview(relative_path = "")
    f(issue_preview_selector + relative_path)
  end

  def radio_button_form_remove_heading
    f(radio_button_form_remove_heading_selector)
  end

  def text_input_with_checkbox_form_checkbox
    f(text_input_with_checkbox_form_checkbox_selector)
  end

  def text_input_with_checkbox_form_input
    f(text_input_with_checkbox_form_input_selector)
  end

  def text_input_form_input
    f(text_input_form_input_selector)
  end

  def color_picker_form_input
    f(color_picker_form_input_selector)
  end

  #------------------------------ Actions ------------------------------
end
