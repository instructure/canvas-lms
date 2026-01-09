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

require_relative "../common"
require_relative "pages/canvas_studio_player_page"
require_relative "../rcs/pages/rce_next_page"

EXTERNAL_VIDEO_URL = "https://s3.amazonaws.com/arc-qa/caption_video.mp4"

describe "CanvasStudioPlayer in Wiki Pages", :ignore_js_errors do
  include_context "in-process server selenium tests"
  include CanvasStudioPlayerPage
  include RCENextPage

  it "verifies the test media URL is still accessible using curl" do
    # If this test fails, it means the media URL 'https://s3.amazonaws.com/arc-qa/caption_video.mp4'
    # is no longer working, and will fail the tests in wiki_pages_media_spec.rb
    # The URL is used in the tests to verify CanvasStudioPlayer functionality.

    # Use curl to check the URL accessibility
    curl_output = `curl -s -o /dev/null -w "%{http_code}" "#{EXTERNAL_VIDEO_URL}"`
    http_status = curl_output.strip

    expect(http_status).to eq("200"),
                           "The Teest Media URL #{EXTERNAL_VIDEO_URL} returned HTTP status #{http_status} instead of 200. " \
                           "The wiki_pages_media_spec tests are dependent on this URL to work properly."
  end

  context "teacher" do
    before(:once) do
      Account.site_admin.enable_feature! :consolidated_media_player
      course_with_teacher(active_all: true)

      @root_folder = Folder.root_folders(@course).first
      @attachment = attachment_model(display_name: "studio.mp4", folder: @root_folder, context: @course, media_entry_id: "samplemediaentryid")
      @media_object = MediaObject.create!(attachment_id: @attachment.id, attachment: @attachment, media_id: "samplemediaentryid", title: "studio.mp4", media_type: "video/mp4")
    end

    before do
      allow_any_instance_of(MediaObject).to receive(:grants_right?).with(anything, anything, :add_captions).and_return(true)
      @kaltura = stub_kaltura
      allow(@kaltura).to receive(:media_sources).and_return([{ height: "224", width: "400", bitrate: "316", url: EXTERNAL_VIDEO_URL, src: "http://notorious-web.inseng.test/studio.mp4", size: "3452116", fileExt: "mp4", attachment_id: @attachment.id, content_type: "video/mp4" }])

      @page = @course.wiki_pages.build(title: "CanvasStudioPlayer-test")
      @page.save!
    end

    context "control buttons on video player" do
      before do
        @media_object.media_tracks.create!(kind: "subtitles", locale: "en", media_object: @media_object, content: '0\n00:00:00,000 --> 00:00:05,000\nEnglish sub …This is the first sentence\n\n\n1\n00:00:05,000 --> 00:00:10,000\nEnglish sub and a second...')
        @media_object.media_tracks.create!(kind: "subtitles", locale: "fr", media_object: @media_object, content: '0\n00:00:00,000 --> 00:00:05,000\nFrench sub …This is the first sentence n\n\n1\n00:00:05,000 --> 00:00:10,000\n French sub and a second...')

        @page.body = embedded_video_page_body_html(@attachment.id)
        @page.saving_user = @teacher
        @page.save!

        user_session(@user)
        get "/courses/#{@course.id}/pages/CanvasStudioPlayer-test"
      end

      it "displays the video player" do
        in_frame sample_video_for_test_iframe do
          expect(canvas_studio_player).to be_present
          expect(canvas_studio_player.attribute("data-captions")).to include("English")
          expect(data_media_player.attribute("aria-label")).to eq("Video Player - Video player for studio.mp4")
          expect(data_media_player.attribute("data-media-type")).to eq("video")
          expect(data_media_player.attribute("aria-label")).to include(@attachment.title)
          expect(data_media_player).to contain_css('video track[kind="subtitles"][label="English"]')
          expect(data_media_player).to contain_css('video track[kind="subtitles"][label="French"]')
        end
      end

      it "displays keyboard shortcuts" do
        in_frame sample_video_for_test_iframe do
          expect(canvas_studio_player).to be_present
          expect(kebab_menu_button).to be_present
          kebab_menu_button.click
          expect(kebab_menu_select).to be_present
          expect(kebab_menu_select).to include_text("Keyboard Shortcuts")

          kebab_menu_select.click
          expect(keyboard_shortcuts_overlay).to be_present
          expect(keyboard_shortcuts_overlay.text).to include("Keyboard Shortcuts")
          expect(keyboard_shortcuts_overlay_close_button).to be_present
          keyboard_shortcuts_overlay_close_button.click
        end
      end

      it "plays and pauses the video" do
        in_frame sample_video_for_test_iframe do
          expect(canvas_studio_player).to be_present
          expect(play_button).to be_present

          expect(time_indicator_current.text).to eq("0:00")
          play_button.click
          wait_for_ajaximations
          expect(pause_button).to be_present

          pause_button.click
          wait_for_ajaximations
          expect(play_button).to be_present
        end
      end

      it "mutes and unmutes the video" do
        in_frame sample_video_for_test_iframe do
          expect(canvas_studio_player).to be_present
          expect(volume_slider).to be_present
          expect(volume_slider.attribute("aria-valuenow")).to eq("100")
          expect(mute_button).to be_present
          mute_button.click
          wait_for_ajaximations
          expect(unmute_button).to be_present
          expect(volume_slider.attribute("aria-valuenow")).to eq("0")

          unmute_button.click
          wait_for_ajaximations
          expect(mute_button).to be_present
          expect(volume_slider.attribute("aria-valuenow")).to eq("100")
        end
      end

      it "enables and disables caption" do
        in_frame sample_video_for_test_iframe do
          expect(canvas_studio_player).to be_present
          expect(enable_caption_button).to be_present
          enable_caption_button.click
          wait_for_ajaximations
          expect(disable_caption_button).to be_present

          disable_caption_button.click
          wait_for_ajaximations
          settings_button.click
          wait_for_ajaximations
          expect(video_setting_menu_buttons[1].text).to eq("Captions\nOff")
        end
      end

      it "changes caption language" do
        in_frame sample_video_for_test_iframe do
          expect(canvas_studio_player).to be_present
          expect(enable_caption_button).to be_present
          enable_caption_button.click
          expect(settings_button).to be_present

          settings_button.click
          wait_for_ajaximations
          expect(video_setting_menu_buttons[1].text).to include("Captions")
          video_setting_menu_buttons[1].click # Tap "Captions" on the settings menu

          wait_for_ajaximations
          expect(setting_menu_heading_captions).to be_present
          video_setting_menu_buttons[1].click # Tap "Language" on the captions settings menu

          wait_for_ajaximations
          expect(setting_menu_heading_caption_language).to be_present
          expect(video_setting_menu_buttons[3].text).to eq("French")
          video_setting_menu_buttons[3].click # Select French caption language

          wait_for_ajaximations
          video_setting_menu_buttons[0].click # Go back to main settings menu
          expect(setting_menu_heading_captions).to be_present
          expect(video_setting_menu_buttons[1].text).to include("French")
        end
      end

      it "enters and exits fullscreen mode" do
        in_frame sample_video_for_test_iframe do
          expect(canvas_studio_player).to be_present
          expect(fullscreen_button).to be_present
          fullscreen_button.click

          wait_for_ajaximations
          expect(exit_fullscreen_button).to be_present
          exit_fullscreen_button.click
          wait_for_ajaximations
          expect(fullscreen_button).to be_present
        end
      end

      it "has correct video player UI elements" do
        in_frame sample_video_for_test_iframe do
          expect(canvas_studio_player).to be_present
          expect(kebab_menu_button).to be_present

          # Verify left control buttons
          expect(play_button).to be_present
          expect(mute_button).to be_present
          expect(volume_slider).to be_present
          expect(time_indicator_current.attribute("data-type")).to eq("current")
          expect(time_indicator_duration.attribute("data-type")).to eq("duration")

          # Verify right control buttons
          expect(right_control_buttons[0].attribute("aria-label")).to eq("Captions")
          expect(right_control_buttons[1].attribute("aria-label")).to eq("Settings")
          expect(right_control_buttons[2].attribute("aria-label")).to eq("Fullscreen")

          settings_button.click
          wait_for_ajaximations
        end
      end

      it "has correct playback speed settings menu UI elements" do
        in_frame sample_video_for_test_iframe do
          expect(canvas_studio_player).to be_present
          expect(settings_button).to be_present

          # Verify video settings menu and its default value
          settings_button.click
          wait_for_ajaximations
          expect(video_setting_menu_buttons[0]).to be_present
          expect(video_setting_menu_buttons[0].text).to eq("Playback Speed\n1x")

          # Verify playback speed settings
          video_setting_menu_buttons[0].click
          expect(setting_menu_heading_playback_speed).to be_present
          expect(video_setting_menu_buttons[1].text).to eq("0.5x")
          expect(video_setting_menu_buttons[3].text).to eq("1x")
          expect(video_setting_menu_buttons[3].attribute("aria-checked")).to eq("true")
          expect(video_setting_menu_buttons[6].text).to eq("2x")
          expect(video_setting_menu_buttons.count).to eq(7)
        end
      end

      it "has correct captions settings menu UI elements" do
        in_frame sample_video_for_test_iframe do
          expect(canvas_studio_player).to be_present
          expect(settings_button).to be_present
          settings_button.click
          wait_for_ajaximations

          expect(video_setting_menu_buttons[1]).to be_present
          expect(video_setting_menu_buttons[1].text).to eq("Captions\nOff")

          # Verify captions settings and its default value
          video_setting_menu_buttons[1].click
          expect(setting_menu_heading_captions).to be_present

          expect(video_setting_menu_buttons[1].text).to eq("Language\nOff")
          expect(video_setting_menu_buttons[2].text).to eq("Font Size\n100%")
          expect(video_setting_menu_buttons[3].text).to eq("On Top")
          expect(video_setting_menu_buttons[4].text).to eq("Invert Colors")
          expect(video_setting_menu_buttons[3].attribute("aria-checked")).to eq("false")
          expect(video_setting_menu_buttons[4].attribute("aria-checked")).to eq("false")

          # Verify caption language settings and its default value
          video_setting_menu_buttons[1].click
          expect(setting_menu_heading_caption_language).to be_present
          expect(video_setting_menu_buttons[1].text).to eq("Off")
          expect(video_setting_menu_buttons[1].attribute("aria-checked")).to eq("true")
          expect(video_setting_menu_buttons[2].text).to eq("English")
          expect(video_setting_menu_buttons[3].text).to eq("French")

          video_setting_menu_buttons[0].click # Go back to captions settings menu
          wait_for_ajaximations

          # Verify font size settings and its default value
          video_setting_menu_buttons[2].click
          expect(setting_menu_heading_font_size).to be_present
          expect(video_setting_menu_buttons[1].text).to eq("50%")
          expect(video_setting_menu_buttons[2].text).to eq("100%")
          expect(video_setting_menu_buttons[2].attribute("aria-checked")).to eq("true")
          expect(video_setting_menu_buttons[5].text).to eq("400%")
          expect(video_setting_menu_buttons.count).to eq(6)
        end
      end
    end

    context "video player with editor" do
      before do
        @attachment.uploaded_data = stub_file_data("studio.mp4", "asdf", "video/mp4")
        @attachment.save!

        user_session(@user)
      end

      it "adds course media file on the page" do
        stub_rcs_config
        get "/courses/#{@course.id}/pages/CanvasStudioPlayer-test/edit"
        wait_for_rce

        click_course_media_toolbar_menuitem
        course_media_links[0].click
        save_button.click

        in_frame canvas_studio_player_container do
          expect(canvas_studio_player).to be_present
          expect(data_media_player.attribute("aria-label")).to eq("Video Player - Video player for studio.mp4")
          expect(data_media_player.attribute("data-media-type")).to eq("video")
          expect(data_media_player.attribute("aria-label")).to include(@attachment.title)
        end
      end
    end
  end
end
