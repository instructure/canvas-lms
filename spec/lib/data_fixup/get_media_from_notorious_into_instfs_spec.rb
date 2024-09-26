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

require "spec_helper"

describe DataFixup::GetMediaFromNotoriousIntoInstfs do
  let(:course) { course_model }

  describe "#run" do
    before { allow(DataFixup::GetMediaFromNotoriousIntoInstfs).to receive(:delay_if_production).at_least(:once).and_return(DataFixup::GetMediaFromNotoriousIntoInstfs) }

    context "using media object dimensions in iframe" do
      it "ignores attachments that already have instfs_uuid or are not media" do
        Attachment.create! context: course, media_entry_id: "m-fromattachment", filename: "whatever.flv", display_name: "whatever.flv", content_type: "audio/webm", instfs_uuid: "something"
        Attachment.create! context: course, media_entry_id: "m-fromattachment", filename: "whatever.flv", display_name: "whatever.flv", content_type: "something/else"
        expect(DataFixup::GetMediaFromNotoriousIntoInstfs).not_to receive(:fix_these)
        DataFixup::GetMediaFromNotoriousIntoInstfs.run
      end

      it "It will attempt to fix attachments without instfs uuid" do
        Attachment.create! context: course, media_entry_id: "m-fromattachment", filename: "whatever.flv", display_name: "whatever.flv", content_type: "audio/webm"
        expect(DataFixup::GetMediaFromNotoriousIntoInstfs).to receive(:fix_these).at_least(:once).with([Attachment.last.id]).and_return(true)
        DataFixup::GetMediaFromNotoriousIntoInstfs.run
      end

      it "It will ignore attachments from before 28th nov 2023" do
        a = Attachment.create! context: course, media_entry_id: "m-fromattachment", filename: "whatever.flv", display_name: "whatever.flv", content_type: "audio/webm"
        a.update_column :created_at, Date.new(2023, 11, 27)
        expect(DataFixup::GetMediaFromNotoriousIntoInstfs).not_to receive(:fix_these)
        DataFixup::GetMediaFromNotoriousIntoInstfs.run
      end
    end
  end

  describe ".fix_these" do
    it "It will log failed attempts due to lack of media id (and knows to use media object info when the attachment lacks it)" do
      a1 = Attachment.create! context: course, media_entry_id: "m-fromattachment-1", filename: "whatever.flv", display_name: "whatever.flv", content_type: "audio/webm"

      a2 = Attachment.create! context: course, filename: "whatever.flv", display_name: "whatever.flv", content_type: "audio/webm"
      MediaObject.create! media_id: "m-frommediaobject-2", data: { extensions: { mp4: { width: 640, height: 400 } } }, attachment_id: Attachment.last.id, media_type: "video/webm"

      a3 = Attachment.create! context: course, filename: "whatever.flv", display_name: "whatever.flv", content_type: "audio/webm"

      expect(Rails.logger).to receive(:info).with("GetMediaFromNotoriousIntoInstfs : Failed for attachment #{a1.id} (m-fromattachment-1)")
      expect(Rails.logger).to receive(:info).with("GetMediaFromNotoriousIntoInstfs : Failed for attachment #{a2.id} (m-frommediaobject-2)")
      expect(Rails.logger).to receive(:info).with("GetMediaFromNotoriousIntoInstfs : No media id for attachment #{a3.id}")

      DataFixup::GetMediaFromNotoriousIntoInstfs.send :fix_these, [a1.id, a2.id, a3.id]
    end
  end

  describe ".get_it_to_instfs" do
    before do
      client = double(CanvasKaltura::ClientV3)
      expect(client).to receive(:startSession).and_return("sessioninfo")
      expect(client).to receive(:flavorAssetGetByEntryId).with("m-frommediaobject-3").and_return([{ id: 11, fileExt: "mp3" }])
      expect(client).to receive(:flavorAssetGetDownloadUrl).with(11).and_return("http://example.com/asset")
      expect(CanvasKaltura::ClientV3).to receive(:new).and_return(client)
    end

    it "downloads from kaltura and cleans up afterward" do
      http_return = double
      expect(http_return).to receive(:body).and_return("request_body")
      expect(CanvasHttp).to receive(:get).with("http://example.com/asset").and_return(http_return)

      expect(InstFS).to receive(:direct_upload).with(file_name: "11.mp3", file_object: anything).and_return(true)

      expect(File.exist?("./11.mp3")).to be(false)
      DataFixup::GetMediaFromNotoriousIntoInstfs.send(:get_it_to_intfs, "m-frommediaobject-3")
      expect(File.exist?("./11.mp3")).to be(false)
    end

    it "can handle failures when fetching media file" do
      expect(CanvasHttp).to receive(:get).with("http://example.com/asset").and_raise ArgumentError
      expect do
        DataFixup::GetMediaFromNotoriousIntoInstfs.send(:get_it_to_intfs, "m-frommediaobject-3")
      end.to_not raise_error
    end
  end
end
