# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

module CanvasStudioPlayerPage
  def canvas_studio_player_container
    f("div.show-content.user_content.clearfix.enhanced p iframe")
  end

  def embedded_video_page_body_html(att_id)
    %(<p id="sample_video_for_test"><iframe style="width: 480px; height: 300px; display: inline-block;" title="Video player for studio.mp4" data-media-type="video" src="/media_attachments_iframe/#{att_id}?type=video&amp;embedded=true" loading="lazy" allowfullscreen="allowfullscreen" allow="fullscreen" data-media-id="samplemediaentryid"></iframe></p>)
  end

  def sample_video_for_test_iframe
    f("p#sample_video_for_test iframe")
  end

  def canvas_studio_player
    f('[data-testid="canvas-studio-player"]')
  end

  def data_media_player
    f('div[data-testid="canvas-studio-player"] [data-media-player]')
  end

  def kebab_menu_button
    f('[id="kebab-menu-button"]')
  end

  def kebab_menu_select
    f('div[id="kebab-menu"]')
  end

  def keyboard_shortcuts_overlay
    f('div[aria-label="Keyboard Shortcuts"]')
  end

  def keyboard_shortcuts_overlay_close_button
    f('div[aria-label="Keyboard Shortcuts"] button[aria-label="Close"]')
  end

  def play_button
    f('button[aria-label="Play"]')
  end

  def pause_button
    f('button[aria-label="Pause"]')
  end

  def mute_button
    f('button[aria-label="Mute"]')
  end

  def unmute_button
    f('button[aria-label="Volume"]')
  end

  def volume_slider
    f('div[role="slider"][aria-label="Volume"]')
  end

  def time_indicator_current
    f("[data-testid='controls-layout'] [data-type='current']")
  end

  def time_indicator_duration
    f("[data-testid='controls-layout'] [data-type='duration']")
  end

  def right_control_buttons
    # right now we don't place any special attribute on right-control div but it'll be always the last div
    ff("[data-testid='controls-layout'] > div:last-child button")
  end

  def caption_button
    f("[data-testid='controls-layout'] button[aria-label='Captions']")
  end

  def disable_caption_button
    f("[data-testid='controls-layout'] button[aria-label='Captions'][aria-pressed='true']")
  end

  def enable_caption_button
    f("[data-testid='controls-layout'] button[aria-label='Captions'][aria-pressed='false']")
  end

  def settings_button
    f("[data-testid='controls-layout'] button[aria-label='Settings']")
  end

  def fullscreen_button
    f("[data-testid='controls-layout'] button[aria-label='Fullscreen'][aria-pressed='false']")
  end

  def exit_fullscreen_button
    f("[data-testid='controls-layout'] button[aria-label='Fullscreen'][aria-pressed='true']")
  end

  def video_setting_menu_buttons
    ff("div[role='menu'] button")
  end

  def setting_menu_heading_captions
    fxpath('//div[@role="menu"][@aria-label="Video Settings"]//strong[@role="presentation" and text()="Captions"]')
  end

  def setting_menu_heading_caption_language
    fxpath('//div[@role="menu"][@aria-label="Video Settings"]//strong[@role="presentation" and text()="Caption Language"]')
  end

  def setting_menu_heading_playback_speed
    fxpath('//div[@role="menu"][@aria-label="Video Settings"]//strong[@role="presentation" and text()="Playback Speed"]')
  end

  def setting_menu_heading_font_size
    fxpath('//div[@role="menu"][@aria-label="Video Settings"]//strong[@role="presentation" and text()="Font Size"]')
  end
end
