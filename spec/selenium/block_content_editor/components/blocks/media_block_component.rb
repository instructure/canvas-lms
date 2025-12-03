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
require_relative "block_title_component"
require_relative "../settings_tray/block_settings/media_block_settings"
require_relative "../upload_modal_component"

class MediaBlockComponent < BlockComponent
  BLOCK_TYPE = "Media"
  BLOCK_SELECTOR = "iframe"

  attr_reader :block_title

  def initialize(block)
    super
    @block_title = BlockTitleComponent.new(@block)
  end

  def settings
    @settings ||= MediaBlockSettings.new
  end

  def media_content_selector
    "iframe[title='Media content']"
  end

  def media_placeholder_selector
    "[aria-label='Placeholder media']"
  end

  def add_media_button_selector
    "[aria-label='Add media']"
  end

  def media_content
    f(media_content_selector, @block)
  end

  def add_media_button
    f(add_media_button_selector, @block)
  end

  def media_placeholder
    f(media_placeholder_selector, @block)
  end

  def upload_media_modal
    UploadModalComponent.new("Add media")
  end

  def add_external_media(video_url)
    add_media_button.click
    wait_for_ajaximations

    upload_media_modal.url_tab.click
    wait_for_ajaximations

    upload_media_modal.url_input.send_keys(video_url)
    upload_media_modal.submit_button.click
  end
end
