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

describe DataFixup::RemoveSyllabusExternalLinkEnhancements do
  specs_require_sharding

  subject(:fixup) { operation_shard.activate { described_class.new } }

  let(:operation_shard) { @shard1 }

  around do |example|
    operation_shard.activate { example.run }
  end

  before do
    allow_any_instance_of(described_class).to receive(:wait_between_jobs)
    allow_any_instance_of(described_class).to receive(:wait_between_processing)
  end

  describe ".fix_html" do
    subject(:fix_html) { described_class.fix_html(html) }

    context "with external link enhancements" do
      let(:html) do
        <<~HTML
          <p>Check out <a class="external" href="https://example.com" target="_blank" rel="noreferrer noopener">
            <span>this link</span>
            <span class="external_link_icon" style="margin-inline-start: 5px; display: inline-block; text-indent: initial;" role="presentation">
              <svg></svg>
              <span class="screenreader-only">Links to an external site.</span>
            </span>
          </a></p>
        HTML
      end

      it "removes external_link_icon spans" do
        expect(fix_html).not_to include("external_link_icon")
      end

      it "removes the external class from anchor tags" do
        expect(fix_html).not_to include('class="external"')
      end

      it "unwraps the inner wrapper span restoring original link text" do
        expect(fix_html).to include("this link")
        expect(fix_html).not_to include("<span>this link</span>")
      end

      it "preserves the href" do
        expect(fix_html).to include('href="https://example.com"')
      end
    end

    context "with file download button enhancements" do
      let(:html) do
        <<~HTML
          <p>
            <span class="instructure_file_holder link_holder instructure_file_link_holder">
              <a class="file_preview_link" href="/courses/1/files/1">document.pdf</a>
              <a class="file_download_btn" role="button" download href="/courses/1/files/1/download?download_frd=1">
                <span class="screenreader-only">Download document.pdf</span>
              </a>
            </span>
          </p>
        HTML
      end

      it "removes file_download_btn anchor tags" do
        expect(fix_html).not_to include("file_download_btn")
      end

      it "unwraps instructure_file_holder spans" do
        expect(fix_html).not_to include("instructure_file_holder")
      end

      it "preserves the original file link" do
        expect(fix_html).to include('class="file_preview_link"')
        expect(fix_html).to include("document.pdf")
      end
    end

    context "with Ally accessibility enhancements" do
      let(:html) do
        <<~HTML
          <p>
            <span class="instructure_file_holder link_holder instructure_file_link_holder ally-file-link-holder">
              <img class="ally-accessibility-score-indicator-image" src="https://prod.ally.ac/static/ally-icon-indicator-low-circle.svg" alt="" />
              <a class="inline_disabled preview_in_overlay" href="/courses/1/files/1?wrap=1">Lecture notes.pdf</a>
            </span>
            <div class="inline-block ally-enhancement ally-user-content-dropdown">
              <a class="al-trigger" role="button" href="#">Actions</a>
              <ul><li><a class="ally-accessible-versions" href="#" data-id="1">Alternative formats</a></li></ul>
            </div>
          </p>
        HTML
      end

      it "removes Ally score indicator images" do
        expect(fix_html).not_to include("ally-accessibility-score-indicator-image")
      end

      it "removes Ally enhancement dropdowns" do
        expect(fix_html).not_to include("ally-enhancement")
        expect(fix_html).not_to include("ally-accessible-versions")
      end

      it "preserves the original file link" do
        expect(fix_html).to include("Lecture notes.pdf")
        expect(fix_html).to include('href="/courses/1/files/1?wrap=1"')
      end
    end

    context "with Ally-only file link holder spans (no instructure_file_holder)" do
      let(:html) do
        <<~HTML
          <p>
            <span class="ally-file-link-holder link_holder">
              <a href="/courses/1/files/1?wrap=1">document.pdf</a>
            </span>
          </p>
          <ul>
            <li><span class="ally-file-link-holder link_holder"><a href="/courses/1/files/1/download">Download</a></span></li>
          </ul>
        HTML
      end

      it "unwraps ally-file-link-holder spans in paragraphs" do
        expect(fix_html).not_to include("ally-file-link-holder")
        expect(fix_html).to include("document.pdf")
      end

      it "removes ally-file-link-holder list items" do
        expect(fix_html).not_to include("Download")
      end
    end

    context "with file preview enhancements" do
      let(:html) do
        <<~HTML
          <p>
            <span class="instructure_file_holder link_holder instructure_file_link_holder">
              <a class="file_preview_link previewable" aria-expanded="false" aria-controls="preview_1" href="/courses/1/files/1?wrap=1">notes.pdf</a>
              <a class="file_download_btn" role="button" download href="/courses/1/files/1/download?download_frd=1">
                <span class="screenreader-only">Download notes.pdf</span>
              </a>
              <div class="preview_container" role="region" id="preview_1" style="display: none;"></div>
            </span>
          </p>
        HTML
      end

      it "removes preview_container divs" do
        expect(fix_html).not_to include("preview_container")
      end

      it "removes previewable class and aria attributes from links" do
        expect(fix_html).not_to include("previewable")
        expect(fix_html).not_to include("aria-expanded")
        expect(fix_html).not_to include("aria-controls")
      end

      it "preserves the file link" do
        expect(fix_html).to include("notes.pdf")
        expect(fix_html).to include('href="/courses/1/files/1?wrap=1"')
      end
    end

    context "with YouTube thumbnail enhancements" do
      let(:html) do
        <<~HTML
          <p>
            <a class="youtubed" href="https://www.youtube.com/watch?v=dQw4w9WgXcQ">Watch this</a>
            <a class="youtubed" href="https://www.youtube.com/watch?v=dQw4w9WgXcQ">
              <img class="media_comment_thumbnail" src="/images/play_overlay.png" alt="" style="background-image: url(//img.youtube.com/vi/dQw4w9WgXcQ/2.jpg);" />
            </a>
          </p>
        HTML
      end

      it "removes the injected thumbnail anchor" do
        expect(fix_html).not_to include("media_comment_thumbnail")
      end

      it "removes youtubed class from the original link" do
        expect(fix_html).not_to include("youtubed")
      end

      it "preserves the original link text and href" do
        expect(fix_html).to include("Watch this")
        expect(fix_html).to include("youtube.com/watch")
      end
    end

    context "with Kaltura media comment thumbnail enhancements" do
      let(:html) do
        <<~HTML
          <p>
            <a class="instructure_inline_media_comment" href="#" data-download="/media_objects/m-abc123" data-media_comment_id="m-abc123">
              <span class="media_comment_thumbnail media_comment_thumbnail-normal" style="background-image: url(https://kaltura.example.com/thumbnail);">
                <span class="media_comment_thumbnail_play_button">
                  <span class="screenreader-only">Play media comment.</span>
                </span>
              </span>
            </a>
          </p>
        HTML
      end

      it "removes the media comment thumbnail span" do
        expect(fix_html).not_to include("media_comment_thumbnail")
      end

      it "removes instructure_inline_media_comment class" do
        expect(fix_html).not_to include("instructure_inline_media_comment")
      end

      it "restores the original href from data-download" do
        expect(fix_html).to include('href="/media_objects/m-abc123"')
        expect(fix_html).not_to include('href="#"')
        expect(fix_html).not_to include("data-download")
      end
    end

    context "with unaffected content" do
      let(:html) { "<p>Hello <a href='/courses/1'>Internal link</a></p>" }

      it "does not modify content without enhancements" do
        expect(fix_html).to include('<a href="/courses/1">Internal link</a>')
      end
    end

    context "with nil content" do
      let(:html) { nil }

      it { is_expected.to be_nil }
    end

    context "with blank content" do
      let(:html) { "" }

      it { is_expected.to eq("") }
    end
  end

  describe "#run" do
    def execute_fixup
      fixup.run
      run_jobs
    end

    let(:enhanced_syllabus) do
      <<~HTML
        <p>Visit <a class="external" href="https://example.com" target="_blank" rel="noreferrer noopener">
          <span>example.com</span>
          <span class="external_link_icon" style="margin-inline-start: 5px;" role="presentation">
            <svg></svg>
            <span class="screenreader-only">Links to an external site.</span>
          </span>
        </a></p>
      HTML
    end

    before do
      operation_shard.activate do
        @account = account_model
        @course = Course.create!(account: @account, syllabus_body: enhanced_syllabus)
      end
    end

    it "removes external link enhancements from syllabus_body" do
      execute_fixup
      syllabus = @course.reload.syllabus_body
      expect(syllabus).not_to include("external_link_icon")
      expect(syllabus).not_to include('class="external"')
    end

    it "does not modify courses without enhancements" do
      clean_course = nil
      operation_shard.activate do
        clean_course = Course.create!(account: @account, syllabus_body: "<p>Clean syllabus</p>")
      end

      expect { execute_fixup }.not_to(change { clean_course.reload.syllabus_body })
    end
  end
end
