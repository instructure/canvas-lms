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

require_relative "block_component"
require_relative "../settings_tray/block_settings/text_image_block_settings"

class TextImageBlockComponent < BlockComponent
  BLOCK_TYPE = "Image + text"
  BLOCK_SELECTOR = "[data-testid='imagetext-block-view']"

  attr_reader :block_title

  def initialize(block)
    super
    @block_title = BlockTitleComponent.new(@block)
  end

  def settings
    @settings ||= TextImageBlockSettings.new
  end

  def columns
    f("[data-testid^='imagetext-block']", @block)
  end

  def column(index)
    f("[data-testid^='imagetext-block']>span:nth-child(#{index})", @block)
  end

  def rce_controller_selector
    "textarea"
  end

  def rce_wrapper
    f(".text-edit-wrapper", @block)
  end

  def text_content
    f("p", @block)
  end

  def type(text)
    type_in_tiny(rce_controller_selector, text)
  end

  def image_selector
    "figure img"
  end

  def image_placeholder_selector
    ".image-block-default-preview"
  end

  def add_image_button_selector
    "figure button"
  end

  def image
    f(image_selector, @block)
  end

  def add_image_button
    f(add_image_button_selector, @block)
  end

  def replace_image_button
    f(".image-actions button", @block)
  end

  def image_placeholder
    f(image_placeholder_selector, @block)
  end

  def edit_image_caption_button
    f("[data-testid='edit-block-image']", @block)
  end

  def image_caption
    f("figcaption [class$='text']", @block)
  end

  def upload_image_modal
    UploadModalComponent.new("Upload Image")
  end

  def add_external_image(image_path)
    upload_external_image(add_image_button, image_path)
  end

  def replace_with_external_image(image_path)
    upload_external_image(replace_image_button, image_path)
  end

  def upload_external_image(upload_button, image_path)
    upload_button.click
    wait_for_ajaximations

    upload_image_modal.url_tab.click
    wait_for_ajaximations

    upload_image_modal.url_input.send_keys(image_path)
    upload_image_modal.submit_button.click
  end

  def image_text_ratio(image_element, text_element)
    image_width = image_element.size.width
    text_width = text_element.size.width
    [image_width, text_width].max.to_f / [image_width, text_width].min
  end
end
