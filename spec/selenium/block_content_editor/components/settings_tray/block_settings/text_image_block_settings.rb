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

require_relative "../../../../common"
require_relative "../settings_group_component"
require_relative "shared/block_title_toggle"
require_relative "shared/color_settings"
require_relative "../../upload_modal_component"

class TextImageBlockSettings
  include SeleniumDependencies

  attr_reader :block_title_toggle, :color_settings

  def initialize
    @block_title_toggle = BlockTitleToggle.new
    @color_settings = ColorSettings.new
    @image_settings = SettingsGroupComponent.new("Image settings")
    @layout_settings = SettingsGroupComponent.new("Layout settings")
  end

  def upload_image_button
    fj('button:has(*:contains("Add image"))', @image_settings.settings_group)
  end

  def replace_image_button
    fj('button:has(*:contains("Replace image"))', @image_settings.settings_group)
  end

  def upload_image_modal
    UploadModalComponent.new("Upload Image")
  end

  def open_uploaded_image_link
    f("a[href]", @image_settings.settings_group)
  end

  def remove_image_button
    f("[data-testid='remove-image-button']", @image_settings.settings_group)
  end

  def alt_text_input
    fj('label:contains("Alt text") input[type="text"]', @image_settings.settings_group)
  end

  def alt_text_popover
    fj('label:contains("Alt text") button[cursor="pointer"]', @image_settings.settings_group)
  end

  def alt_text_tooltip
    f('span[role="tooltip"]', @image_settings.settings_group)
  end

  def decorative_image_checkbox
    fj('input[type="checkbox"] + label:contains("Decorative image")', @image_settings.settings_group)
  end

  def decorative_image_input
    fj('input[type="checkbox"]:has(+ label:contains("Decorative image"))', @image_settings.settings_group)
  end

  def image_caption_input
    fj('label:contains("Image caption") input[type="text"]', @image_settings.settings_group)
  end

  def use_alt_text_as_caption_checkbox
    fj('input[type="checkbox"] + label:contains("Use alt text as caption")', @image_settings.settings_group)
  end

  def use_alt_text_as_caption_input
    fj('input[type="checkbox"]:has(+ label:contains("Use alt text as caption"))', @image_settings.settings_group)
  end

  def use_alt_text_as_caption_checked?
    use_alt_text_as_caption_input.attribute("checked") == "true"
  end

  def element_arrangement_radio_option(arrangement)
    fj("fieldset[role='radiogroup']:contains('Element arrangement') input[type='radio'] + label:contains('#{arrangement}')", @layout_settings.settings_group)
  end

  def text_to_image_ratio_radio_option(ratio)
    fj("fieldset[role='radiogroup']:contains('Text to image ratio') input[type='radio'] + label:contains('#{ratio}')", @layout_settings.settings_group)
  end
end
