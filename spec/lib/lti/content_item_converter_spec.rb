# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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
#

module Lti
  describe ContentItemConverter do
    describe "#self.convert_resource_selection" do
      let(:fake_selection) do
        {
          url: "some_file.txt",
          text: "some_file.pdf",
          title: "my title",
          return_type: "fake",
          height: "100",
          width: "200",
        }
      end

      let(:file_selection) do
        file_selection = fake_selection.clone
        file_selection[:return_type] = "file"
        file_selection[:content_type] = "application/json"
        file_selection
      end

      let(:lti_link) do
        file_selection = fake_selection.clone
        file_selection[:return_type] = "lti_launch_url"
        file_selection
      end

      it "creates a ::IMS::LTI::Models::ContentItems::ContentItem" do
        content_item = described_class.convert_resource_selection(fake_selection)
        expect(content_item).to be_a ::IMS::LTI::Models::ContentItems::ContentItem
      end

      it "converts url to id" do
        content_item = described_class.convert_resource_selection(fake_selection)
        expect(content_item.id).to eq fake_selection[:url]
      end

      it "converts url to url" do
        content_item = described_class.convert_resource_selection(fake_selection)
        expect(content_item.url).to eq fake_selection[:url]
      end

      it "converts text to text" do
        content_item = described_class.convert_resource_selection(fake_selection)
        expect(content_item.text).to eq fake_selection[:text]
      end

      it "converts title to title" do
        content_item = described_class.convert_resource_selection(fake_selection)
        expect(content_item.title).to eq fake_selection[:title]
      end

      it "sets media_type to text/html by default" do
        media_type = described_class.convert_resource_selection(fake_selection).media_type
        expect(media_type).to eq "text/html"
      end

      context "placement advice" do
        it "creates placement advice" do
          placement_advice = described_class.convert_resource_selection(fake_selection).placement_advice
          expect(placement_advice).to_not be_nil
        end

        it "converts width to display_width" do
          placement_advice = described_class.convert_resource_selection(fake_selection).placement_advice
          expect(placement_advice.display_width).to eq fake_selection[:width]
        end

        it "converts height to display_height" do
          placement_advice = described_class.convert_resource_selection(fake_selection).placement_advice
          expect(placement_advice.display_height).to eq fake_selection[:height]
        end

        it "sets the presentation_document_target to window by default" do
          placement_advice = described_class.convert_resource_selection(fake_selection).placement_advice
          expect(placement_advice.presentation_document_target).to eq "window"
        end
      end

      context "file_selection" do
        it "creates a ::IMS::LTI::Models::ContentItems::FileItem" do
          content_item = described_class.convert_resource_selection(file_selection)
          expect(content_item).to be_a ::IMS::LTI::Models::ContentItems::FileItem
        end

        it "sets the presentation_document_target to download" do
          content_item = described_class.convert_resource_selection(file_selection)
          expect(content_item.placement_advice.presentation_document_target).to eq "download"
        end

        it "uses the content_type first" do
          content_item = described_class.convert_resource_selection(file_selection)
          expect(content_item.media_type).to eq "application/json"
        end

        it "looks up the mime type from the text first" do
          file_selection[:content_type] = ""
          content_item = described_class.convert_resource_selection(file_selection)
          expect(content_item.media_type).to eq "application/pdf"
        end

        it "looks up the mime type from the url if text fails" do
          file_selection[:content_type] = ""
          file_selection[:text] = ""
          content_item = described_class.convert_resource_selection(file_selection)
          expect(content_item.media_type).to eq "text/plain"
        end

        it "sets the mime type to nil if text and url fails" do
          file_selection[:content_type] = ""
          file_selection[:text] = ""
          file_selection[:url] = ""
          content_item = described_class.convert_resource_selection(file_selection)
          expect(content_item.media_type).to be_nil
        end
      end

      context "lti_link" do
        it "creates a ::IMS::LTI::Models::ContentItems::LtiLinkItem" do
          content_item = described_class.convert_resource_selection(lti_link)
          expect(content_item).to be_a ::IMS::LTI::Models::ContentItems::LtiLinkItem
        end

        it "sets the media_type to application/vnd.ims.lti.v1.ltilink" do
          content_item = described_class.convert_resource_selection(lti_link)
          expect(content_item.media_type).to eq "application/vnd.ims.lti.v1.ltilink"
        end

        it "sets the presentation_document_target to frame" do
          content_item = described_class.convert_resource_selection(lti_link)
          expect(content_item.placement_advice.presentation_document_target).to eq "frame"
        end
      end

      context "url return_type" do
        let(:url_selection) do
          selection = fake_selection.clone
          selection[:return_type] = "url"
          selection
        end

        it "sets the media_type to text/html" do
          content_item = described_class.convert_resource_selection(url_selection)
          expect(content_item.media_type).to eq "text/html"
        end

        it "sets the presentation_document_target to window" do
          content_item = described_class.convert_resource_selection(url_selection)
          expect(content_item.placement_advice.presentation_document_target).to eq "window"
        end
      end

      context "image_url return_type" do
        let(:image_selection) do
          selection = file_selection.clone
          selection[:return_type] = "image_url"
          selection
        end

        it "looks up the mime type from the text first" do
          content_item = described_class.convert_resource_selection(image_selection)
          expect(content_item.media_type).to eq "application/pdf"
        end

        it "looks up the mime type from the url if text fails" do
          file_selection[:text] = ""
          content_item = described_class.convert_resource_selection(image_selection)
          expect(content_item.media_type).to eq "text/plain"
        end

        it "sets the mime type to image if text and url fails" do
          file_selection[:text] = ""
          file_selection[:url] = ""
          content_item = described_class.convert_resource_selection(image_selection)
          expect(content_item.media_type).to eq "image"
        end

        it "sets the presentation_document_target to embed" do
          content_item = described_class.convert_resource_selection(image_selection)
          expect(content_item.placement_advice.presentation_document_target).to eq "embed"
        end
      end

      context "iframe return_type" do
        let(:iframe_selection) do
          selection = fake_selection.clone
          selection[:return_type] = "iframe"
          selection
        end

        it "sets the media_type to text/html" do
          content_item = described_class.convert_resource_selection(iframe_selection)
          expect(content_item.media_type).to eq "text/html"
        end

        it "sets the presentation_document_target to window" do
          content_item = described_class.convert_resource_selection(iframe_selection)
          expect(content_item.placement_advice.presentation_document_target).to eq "iframe"
        end
      end

      context "rich_content return_type" do
        let(:rich_content_selection) do
          selection = fake_selection.clone
          selection[:return_type] = "rich_content"
          selection
        end

        it "sets the media_type to text/html" do
          content_item = described_class.convert_resource_selection(rich_content_selection)
          expect(content_item.media_type).to eq "text/html"
        end

        it "sets the presentation_document_target to window" do
          content_item = described_class.convert_resource_selection(rich_content_selection)
          expect(content_item.placement_advice.presentation_document_target).to eq "embed"
        end
      end
    end

    describe "#self.convert_oembed" do
      let(:photo_oembed) do
        {
          "type" => "photo",
          "url" => "http://example.com/photo",
          "title" => "my title",
          "height" => "100",
          "width" => "200",
        }
      end

      let(:link_oembed) do
        {
          "type" => "link",
          "url" => "http://example.com/link",
          "title" => "my title",
          "text" => "some text",
          "height" => "100",
          "width" => "200",
        }
      end

      let(:video_oembed) do
        {
          "type" => "video",
          "url" => "http://example.com/video",
          "title" => "my title",
          "text" => "some text",
          "height" => "100",
          "html" => "some html",
          "width" => "200",
        }
      end

      let(:rich_oembed) do
        {
          "type" => "video",
          "url" => "http://example.com/rich",
          "html" => "some html",
          "text" => "some text",
          "title" => "my title",
          "height" => "100",
          "width" => "200",
        }
      end

      it "converts url to id" do
        content_item = described_class.convert_oembed(photo_oembed)
        expect(content_item.id).to eq photo_oembed["url"]
      end

      it "converts url to url" do
        content_item = described_class.convert_oembed(photo_oembed)
        expect(content_item.url).to eq photo_oembed["url"]
      end

      it "converts title to title" do
        content_item = described_class.convert_oembed(photo_oembed)
        expect(content_item.title).to eq photo_oembed["title"]
      end

      it "converts the width" do
        placement_advice = described_class.convert_oembed(photo_oembed).placement_advice
        expect(placement_advice.display_width).to eq photo_oembed["width"]
      end

      it "converts the height" do
        placement_advice = described_class.convert_oembed(photo_oembed).placement_advice
        expect(placement_advice.display_height).to eq photo_oembed["height"]
      end

      context "photo" do
        it "converts the title to text" do
          content_item = described_class.convert_oembed(photo_oembed)
          expect(content_item.text).to eq photo_oembed["title"]
        end
      end

      context "link" do
        it "converts the text to text" do
          content_item = described_class.convert_oembed(link_oembed)
          expect(content_item.text).to eq link_oembed["text"]
        end
      end

      context "rich" do
        it "converts the html to text" do
          content_item = described_class.convert_oembed(rich_oembed)
          expect(content_item.text).to eq rich_oembed["html"]
        end
      end
    end
  end
end
