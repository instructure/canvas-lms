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

class MediaBlockSettings
  include SeleniumDependencies

  attr_reader :block_title_toggle, :color_settings

  def initialize
    @block_title_toggle = BlockTitleToggle.new
    @color_settings = ColorSettings.new
    @media_settings = SettingsGroupComponent.new("Media settings")
  end

  def choose_media_button_selector
    "//button[descendant::*[text()='Add media']]"
  end

  def replace_media_button_selector
    "//button[descendant::*[text()='Replace media']]"
  end

  def choose_media_button
    fxpath(choose_media_button_selector, @media_settings.settings_group)
  end

  def replace_media_button
    fxpath(replace_media_button_selector, @media_settings.settings_group)
  end

  def upload_media_modal
    UploadModalComponent.new("Add media")
  end

  def add_external_media_from_settings_tray(video_url)
    upload_external_media(choose_media_button, video_url)
  end

  def replace_with_external_media(video_url)
    upload_external_media(replace_media_button, video_url)
  end

  def upload_external_media(upload_button, video_url)
    upload_button.click
    wait_for_ajaximations

    upload_media_modal.url_tab.click
    wait_for_ajaximations

    upload_media_modal.url_input.send_keys(video_url)
    upload_media_modal.submit_button.click
  end
end
