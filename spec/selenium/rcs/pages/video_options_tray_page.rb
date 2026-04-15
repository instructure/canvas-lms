# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

module VideoOptionsTrayPage
  # Builds the wiki page body HTML for an embedded video attachment.
  # Default 850x357 includes the rolling transcript side panel.
  # Pass width:/height: to start with a different size (e.g. 480x318).
  def embedded_video_page_body_html(att_id, width: 850, height: 357)
    %(<p id="sample_video_for_test"><iframe style="width: #{width}px; height: #{height}px; display: inline-block;" title="Video player for lecture.mp4" data-media-type="video" src="/media_attachments_iframe/#{att_id}?type=video&amp;embedded=true" loading="lazy" allowfullscreen="allowfullscreen" allow="fullscreen" data-media-id="test_media_id"></iframe></p>)
  end

  def rce_page_body_ifr_id
    f("iframe.tox-edit-area__iframe")["id"]
  end

  # Click the embedded video iframe inside TinyMCE, then the context toolbar
  # button that TinyMCE renders when a video node is selected.
  def click_video_in_rce
    in_frame(rce_page_body_ifr_id) do
      f("iframe[src*='media_attachments_iframe'] + span.mce-shim").click
    end
  end

  # TinyMCE context toolbar — floats in the main document (not in the RCE iframe),
  # inside .tox-pop. The button contains a span with label text.
  def video_options_button
    fj('.tox-pop button:contains("Video Options")')
  end

  def video_options_tray
    f('[role="dialog"][aria-label="Video Options Tray"]')
  end

  def caption_manager_heading
    fj('[aria-label="Video Options Tray"] h3:contains("Caption Manager")')
  end

  def add_new_caption_button
    fj('[data-testid="ClosedCaptionPanel"] button:contains("Add New")')
  end

  def request_asr_button
    fj('[data-testid="ClosedCaptionPanel"] button:contains("Request")')
  end

  # Both ManualCaptionCreator and AutoCaptioning use the same placeholder
  def caption_language_select
    f('[data-testid="ClosedCaptionPanel"] [placeholder="Select Language"]')
  end

  def caption_file_input
    fj('[data-testid="ClosedCaptionPanel"] button:contains("Choose File")')
  end

  # The real file input behind the "Choose File" button — use send_keys(path).
  def caption_file_upload_input
    f('[data-testid="ClosedCaptionPanel"] input[type="file"]')
  end

  def upload_caption_button
    fj('[data-testid="ClosedCaptionPanel"] button:contains("Upload")')
  end

  # Clicks the language combobox open and selects the matching option.
  def select_caption_language(language)
    caption_language_select.click
    fj("[role='option']:contains('#{language}')").click
  end

  def caption_row(language_label)
    fj("[data-testid='ClosedCaptionPanel'] *:contains('#{language_label}')")
  end

  def delete_caption_button(language_label)
    fj("[data-testid='ClosedCaptionPanel'] button:contains('Delete #{language_label}')")
  end

  def tray_done_button
    fj('[aria-label="Video Options Tray"] button:contains("Done")')
  end

  # Media player iframe embedded inside the RCE (TinyMCE body frame).
  # Call this inside an in_frame(rce_page_body_ifr_id) block.
  def rce_player_iframe
    f("iframe[src*='media_attachments_iframe']")
  end

  # View-mode helpers — used when navigating to the page (not the editor)
  def player_video_iframe
    f("p#sample_video_for_test iframe")
  end

  def player_sidebar
    f('[data-testid="sidebar"]')
  end

  # Player layout / size combobox inside the tray.
  def player_size_select
    f("#video-options-tray-size")
  end

  # Clicks the size combobox and selects the option whose text contains +label+.
  def select_player_size(label)
    player_size_select.click
    fj("[role='option']:contains('#{label}')").click
  end

  # Label element for the "Show Rolling Transcript" toggle checkbox.
  def rolling_transcript_label
    fj('[aria-label="Video Options Tray"] label:contains("Show Rolling Transcript")')
  end

  # Wiki page save button — mirrors RCENextPage#save_button.
  def save_wiki_page_button
    find_button("Save")
  end

  # Composite helper used in most tests
  def open_video_options_tray
    click_video_in_rce
    video_options_button.click
    wait_for_ajaximations
    expect(video_options_tray).to be_displayed
  end
end
