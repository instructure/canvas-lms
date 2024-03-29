# frozen_string_literal: true

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

describe Attachments::Storage do
  before do
    @attachment = attachment_model
    @uuid = "1234-abcd"
    allow(InstFS).to receive_messages(direct_upload: @uuid, enabled?: true)
    @file = File.open("public/images/a.png")
  end

  describe "store_for_attachment" do
    it "calls instfs direct upload if inst-fs is enabled" do
      expect(InstFS).to receive(:direct_upload)
      Attachments::Storage.store_for_attachment(@attachment, @file)
      expect(@attachment.md5).to eq "8c1005505bb0b4353992a50533f6108d0c06365b234443d9ccc1190c6acd1d01fa7f8590ac9f46fd83304433b0862dd1c2d18915a8f19aed71903aa2934bdfda"
      expect(@attachment.instfs_uuid).to eq(@uuid)
    end

    it "infers a filename for direct_upload" do
      att = Attachment.new
      expect(InstFS).to receive(:direct_upload).with(file_object: @file, file_name: "a.png")
      Attachments::Storage.store_for_attachment(att, @file)
    end

    it "calls attachment_fu methods if inst-fs is not enabled" do
      allow(InstFS).to receive(:enabled?).and_return(false)
      expect(@attachment).to receive(:uploaded_data=)
      Attachments::Storage.store_for_attachment(@attachment, @file)
    end

    describe "value setting" do
      it "keeps data size if already set" do
        Attachments::Storage.store_for_attachment(@attachment, @file)
        expect(@attachment.size).to eq(100)
      end

      it "sets data size if not already set" do
        @attachment.size = nil
        Attachments::Storage.store_for_attachment(@attachment, @file)
        expect(@attachment.size).to eq(@file.size)
      end
    end
  end

  describe "detect_filename" do
    it "prioritizes original_filename first" do
      allow(@file).to receive_messages(original_filename: "yep", filename: "nope")
      expect(Attachments::Storage.detect_filename(@file)).to eq("yep")
    end

    it "prioritizes filename second" do
      allow(@file).to receive(:filename).and_return("yep")
      expect(Attachments::Storage.detect_filename(@file)).to eq("yep")
    end

    it "uses the base filename last" do
      expect(Attachments::Storage.detect_filename(@file)).to eq("a.png")
    end
  end
end
