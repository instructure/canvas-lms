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

require_relative "../common"
require_relative "pages/video_options_tray_page"

describe "Caption Manager", :ignore_js_errors do
  include_context "in-process server selenium tests"
  include VideoOptionsTrayPage

  before(:once) do
    course_with_teacher(active_all: true)

    @root_folder = Folder.root_folders(@course).first
    @attachment = attachment_model(
      display_name: "lecture.mp4",
      folder: @root_folder,
      context: @course,
      media_entry_id: "test_media_id"
    )
    @media_object = MediaObject.create!(
      attachment_id: @attachment.id,
      attachment: @attachment,
      media_id: "test_media_id",
      title: "lecture.mp4",
      media_type: "video/mp4",
      viewer_restrictions: { show_rolling_transcript: true }
    )
  end

  # Override in any context to seed a caption before navigation.
  # The shared before runs first, so the iframe always loads with fresh DB state.
  let(:initial_caption_locale) { nil }

  before do
    Account.site_admin.enable_feature!(:rce_asr_captioning_improvements)
    allow_any_instance_of(MediaObject)
      .to receive(:grants_right?).with(anything, anything, :add_captions)
      .and_return(true)
    @kaltura = stub_kaltura
    allow(@kaltura).to receive(:media_sources).and_return([{
                                                            height: "224",
                                                            width: "400",
                                                            bitrate: "316",
                                                            url: "https://s3.amazonaws.com/arc-qa/caption_video.mp4",
                                                            src: "http://notorious-web.inseng.test/lecture.mp4",
                                                            size: "3452116",
                                                            fileExt: "mp4",
                                                            attachment_id: @attachment.id,
                                                            content_type: "video/mp4"
                                                          }])

    if initial_caption_locale
      @media_object.media_tracks.create!(
        kind: "subtitles",
        locale: initial_caption_locale,
        content: "WEBVTT\n\n00:00:00.000 --> 00:00:05.000\nHello world."
      )
    end

    @page = @course.wiki_pages.build(title: "caption-test")
    @page.body = embedded_video_page_body_html(@attachment.id)
    @page.saving_user = @teacher
    @page.save!

    user_session(@teacher)
  end

  # ─── Page viewer tests ────────────────────────────────────────────────────

  context "in the page viewer" do
    before do
      get "/courses/#{@course.id}/pages/caption-test"
      wait_for_ajaximations
    end

    it "shows 'no transcript yet' in the player sidebar when there are no captions" do
      in_frame player_video_iframe do
        expect(player_sidebar).to include_text("There is no transcript yet.")
      end
    end

    context "with a pre-existing English caption" do
      let(:initial_caption_locale) { "en" }

      it "shows the transcript in the player sidebar" do
        in_frame player_video_iframe do
          expect(player_sidebar).to include_text("Hello world.")
        end
      end
    end
  end

  # ─── RCE editor tests ─────────────────────────────────────────────────────

  context "in the RCE Video Options Tray" do
    before do
      stub_rcs_config
      get "/courses/#{@course.id}/pages/caption-test/edit"
      wait_for_rce
    end

    context "with a pre-existing English caption" do
      let(:initial_caption_locale) { "en" }

      before do
        # Explicit reset guards against viewer_restrictions being mutated
        # by other tests that share the before(:once) media object.
        @media_object.update!(viewer_restrictions: { show_rolling_transcript: true })
      end

      it "shows pre-existing captions in the Caption Manager when the tray opens" do
        open_video_options_tray
        expect(caption_manager_heading).to be_displayed
        expect(caption_row("English")).to be_displayed
      end

      it "deletes the only caption and returns to the empty state with Add New and Request buttons" do
        open_video_options_tray
        expect(caption_row("English")).to be_displayed

        delete_caption_button("English").click
        wait_for_ajaximations

        expect(add_new_caption_button).to be_displayed
        expect(request_asr_button).to be_displayed
      end

      it "shows both the existing caption and the new ASR caption with Processing state after requesting" do
        allow(@kaltura).to receive(:create_caption_asset).and_return({ id: "c-123" })

        open_video_options_tray
        request_asr_button.click
        select_caption_language("Spanish")
        request_asr_button.click
        wait_for_ajaximations

        expect(caption_row("English")).to be_displayed
        expect(caption_row("Spanish (Automatic)")).to be_displayed
        expect(caption_row("Processing...")).to be_displayed
      end

      it "hides the transcript sidebar after disabling Rolling Transcript in the tray" do
        open_video_options_tray

        rolling_transcript_label.click
        tray_done_button.click
        wait_for_ajaximations

        in_frame rce_page_body_ifr_id do
          in_frame rce_player_iframe do
            expect(element_exists?('[data-testid="sidebar"]')).to be false
          end
        end
      end
    end

    it "shows the Add New and Request buttons when there are no captions" do
      open_video_options_tray
      expect(add_new_caption_button).to be_displayed
      expect(request_asr_button).to be_displayed
    end

    it "uploads a manual caption and shows it in the Caption Manager list" do
      open_video_options_tray
      add_new_caption_button.click

      select_caption_language("English")
      caption_file_upload_input.send_keys(Rails.root.join("spec/fixtures/files/test_captions.vtt").to_s)

      upload_caption_button.click
      wait_for_ajaximations

      expect(caption_row("English")).to be_displayed
    end

    it "requests an ASR caption and shows it in the Caption Manager list with Processing state" do
      allow(@kaltura).to receive(:create_caption_asset).and_return({ id: "c-123" })

      open_video_options_tray
      request_asr_button.click

      select_caption_language("English")
      request_asr_button.click
      wait_for_ajaximations

      expect(caption_row("English (Automatic)")).to be_displayed
      expect(caption_row("Processing...")).to be_displayed
    end
  end

  # ─── Resize + transcript reveal ───────────────────────────────────────────

  context "growing a small embed to reveal the rolling transcript sidebar" do
    let(:initial_caption_locale) { "en" }

    before do
      # viewer_restrictions starts empty so the Rolling Transcript toggle is OFF
      @media_object.update!(viewer_restrictions: {})
      # Override the page body with a narrow embed (sidebar not shown at this width)
      @page.body = embedded_video_page_body_html(@attachment.id, width: 480, height: 318)
      @page.saving_user = @teacher
      @page.save!
      stub_rcs_config
      get "/courses/#{@course.id}/pages/caption-test/edit"
      wait_for_rce
    end

    it "expands the embed and shows the transcript after selecting Extra Large and enabling Rolling Transcript" do
      open_video_options_tray

      select_player_size("Extra Large")
      rolling_transcript_label.click
      tray_done_button.click
      wait_for_ajaximations

      in_frame rce_page_body_ifr_id do
        in_frame rce_player_iframe do
          expect(player_sidebar).to be_displayed
          expect(player_sidebar).to include_text("Hello world.")
        end
      end
    end
  end
end
