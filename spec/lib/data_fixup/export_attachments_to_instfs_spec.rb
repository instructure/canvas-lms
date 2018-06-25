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
#

require "spec_helper"

describe DataFixup::ExportAttachmentsToInstfs do
  before :once do
    course_model
    @class = DataFixup::ExportAttachmentsToInstfs
  end

  before :each do
    allow(Attachment).
      to receive(:s3_storage?).
      and_return(true)

    allow(CanvasHttp).
      to receive(:post).
      and_return(double(
        body: "{\"success\":[{\"storeKey\":\"account_1/attachments/8/dragon-sphere-reflection.jpg\",\"timestamp\":1520378850,\"md5\":\"30fa3f957c53f03ddd90a9c4f4f5bc4e\",\"filename\":\"dragon-sphere-reflection.jpg\",\"displayName\":\"dragon-sphere-reflection.jpg\",\"content_type\":\"image/jpeg\",\"size\":107247,\"user_id\":\"10000000000001\",\"root_account_id\":\"1\",\"storeSpec\":\"s3|https://s3.amazonaws.com|instructure_uploads_engineering\",\"id\":\"039ffc96-c463-4298-afb2-b8cc1787028a\"}]}",
        is_a?: true
      ))

    allow(InstFS).
      to receive(:export_references_url).
      and_return("/files?token=asdf")

    allow(InstFS).
      to receive(:enabled?).
      and_return(true)

    attachment_with_context(@course, md5: "md5")
  end

  describe "run" do
    it "finds attachments, posts to them instfs, and updates them" do
      @class.run(Account.find(@attachment.root_account_id))
      expect(Attachment.find(@attachment.id).instfs_uuid).not_to be_nil
    end

    it "skips attachments without an md5" do
      @attachment.md5 = nil
      @attachment.save!
      expect{ @class.run(Account.find(@attachment.root_account_id)) }.not_to raise_exception
      expect(Attachment.find(@attachment.id).instfs_uuid).to be_nil
    end
  end

  describe "object_store" do
    it "generates a hash with a type==s3" do
      object_store = @class.object_store
      expect(object_store).to be_instance_of(Hash)
      expect(object_store[:type]).to eq("s3")
    end
  end

  describe "reference_from_attachment" do
    it "returns a reference hash" do
      reference = @class.reference_from_attachment(@attachment, 1)
      expect(reference).to be_instance_of(Hash)
      expect(reference[:encoding]).to be(nil)
    end
  end

  describe "post_to_instfs" do
    it "makes a call to instfs" do
      expect(CanvasHttp).to receive(:post)
      @class.post_to_instfs({:sample => "payload"})
    end
  end

  describe "update_attachment" do
    it "updates attachment instfs_uuid" do
      id = "12345"
      ref = { "id" => id }
      @class.update_attachment(@attachment, ref)
      expect(@attachment.instfs_uuid).to eq(id)
    end
  end
end
