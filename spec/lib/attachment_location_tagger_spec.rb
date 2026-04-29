# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

describe AttachmentLocationTagger do
  describe ".tag_url" do
    before do
      @location = "account_notification_1"
    end

    context "with simple file URLs" do
      it "tags relative file URLs without query parameters" do
        url = "<p><a href='/files/123'/>Link</p>"
        result = AttachmentLocationTagger.tag_url(url, @location)
        expect(result).to include("/files/123?location=account_notification_1")
      end

      it "tags relative file URLs with existing query parameters" do
        url = "<p><a href='/files/123?download=1'/>Link</p>"
        result = AttachmentLocationTagger.tag_url(url, @location)
        expect(result).to include("/files/123?download=1&location=account_notification_1")
      end

      it "tags file URLs with context paths" do
        url = "<p><a href='/users/2/files/123'/>Link</p>"
        result = AttachmentLocationTagger.tag_url(url, @location)
        expect(result).to include("/users/2/files/123?location=account_notification_1")
      end

      it "tags file URLs with optional filename suffix" do
        url = "<p><a href='/files/123/download'/>Link</p>"
        result = AttachmentLocationTagger.tag_url(url, @location)
        expect(result).to include("/files/123/download?location=account_notification_1")
      end
    end

    context "with past-ID particles" do
      it "tags file URLs with past-ID suffixes" do
        url = "<p><a href='/files/123/download'/>Link</p>"
        result = AttachmentLocationTagger.tag_url(url, @location)
        expect(result).to include("/files/123/download?location=account_notification_1")
      end

      it "tags file URLs with past-ID suffixes and query strings" do
        url = "<p><a href='/files/123/download?foo=bar'/>Link</p>"
        result = AttachmentLocationTagger.tag_url(url, @location)
        expect(result).to include("/files/123/download?foo=bar&location=account_notification_1")
      end
    end

    context "with sharded file IDs" do
      it "tags file URLs with sharded IDs (tilde notation)" do
        url = "<p><a href='/files/123~456'/>Link</p>"
        result = AttachmentLocationTagger.tag_url(url, @location)
        expect(result).to include("/files/123~456?location=account_notification_1")
      end

      it "tags file URLs with sharded context and file ID" do
        url = "<p><a href='/users/100~200/files/123~456'/>Link</p>"
        result = AttachmentLocationTagger.tag_url(url, @location)
        expect(result).to include("/users/100~200/files/123~456?location=account_notification_1")
      end

      it "tags file URLs with sharded ID and existing query params" do
        url = "<p><a href='/files/123~456?wrap=1'/>Link</p>"
        result = AttachmentLocationTagger.tag_url(url, @location)
        expect(result).to include("/files/123~456?wrap=1&location=account_notification_1")
      end
    end

    context "with media attachment URLs" do
      it "tags media_attachments_iframe URLs" do
        url = "<p><iframe src='/media_attachments_iframe/789'></iframe></p>"
        result = AttachmentLocationTagger.tag_url(url, @location)
        expect(result).to include("/media_attachments_iframe/789?location=account_notification_1")
      end

      it "tags media_attachments_iframe URLs with sharded IDs" do
        url = "<p><iframe src='/media_attachments_iframe/789~123'></iframe></p>"
        result = AttachmentLocationTagger.tag_url(url, @location)
        expect(result).to include("/media_attachments_iframe/789~123?location=account_notification_1")
      end

      it "tags media_attachments_iframe URLs with existing query params" do
        url = "<p><iframe src='/media_attachments_iframe/789?type=video'></iframe></p>"
        result = AttachmentLocationTagger.tag_url(url, @location)
        expect(result).to include("/media_attachments_iframe/789?type=video&location=account_notification_1")
      end
    end

    context "with absolute URLs" do
      it "does not tag absolute HTTP URLs" do
        url = "<p><a href='http://example.com/files/123'/>Link</p>"
        result = AttachmentLocationTagger.tag_url(url, @location)
        expect(result).not_to include("location=account_notification_1")
        expect(result).to eq(url)
      end

      it "does not tag absolute HTTPS URLs" do
        url = "<p><a href='https://example.com/files/123'/>Link</p>"
        result = AttachmentLocationTagger.tag_url(url, @location)
        expect(result).not_to include("location=account_notification_1")
        expect(result).to eq(url)
      end
    end

    context "with edge cases" do
      it "tags multiple file URLs in the same content" do
        url = "<p><a href='/files/123'/>First</a> and <a href='/files/456'/>Second</a></p>"
        result = AttachmentLocationTagger.tag_url(url, @location)
        expect(result).to include("/files/123?location=account_notification_1")
        expect(result).to include("/files/456?location=account_notification_1")
      end

      it "does not modify content without file URLs" do
        url = "<p>Some content without attachments</p>"
        result = AttachmentLocationTagger.tag_url(url, @location)
        expect(result).to eq(url)
      end

      it "handles empty strings" do
        url = ""
        result = AttachmentLocationTagger.tag_url(url, @location)
        expect(result).to eq("")
      end

      it "does not tag URLs preceded by protocol characters" do
        url = "<p>ftp://example.com/files/123</p>"
        result = AttachmentLocationTagger.tag_url(url, @location)
        expect(result).not_to include("location=account_notification_1")
      end

      it "handles complex query strings with special characters" do
        url = "<p><a href='/files/123?name=test&foo=bar%20baz#fragma'/>Link</a></p>"
        result = AttachmentLocationTagger.tag_url(url, @location)
        expect(result).to include("/files/123?name=test&foo=bar%20baz&location=account_notification_1#fragma")
      end
    end
  end
end
