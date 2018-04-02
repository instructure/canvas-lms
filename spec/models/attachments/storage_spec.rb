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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe Attachments::Storage do
  before do
    @attachment = attachment_model
    @uuid = "1234-abcd"
    allow(InstFS).to receive(:direct_upload).and_return(@uuid)
    allow(InstFS).to receive(:enabled?).and_return(true)
    @file = File.open("public/images/a.png")
  end

  describe "store_for_attachment" do
    it "calls instfs direct upload if inst-fs is enabled" do
      expect(InstFS).to receive(:direct_upload)
      Attachments::Storage.store_for_attachment(@attachment, @file)
      expect(@attachment.instfs_uuid).to eq(@uuid)
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
      allow(@file).to receive(:original_filename).and_return("yep")
      allow(@file).to receive(:filename).and_return("nope")
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

  describe "detect_mimetype" do
    it "prioritizes content_type first" do
      allow(@file).to receive(:content_type).and_return("yep")
      expect(Attachments::Storage.detect_mimetype(@file)).to eq("yep")
    end

    it "uses File if content_type is blank" do
      allow(@file).to receive(:content_type).and_return("")
      expect(Attachments::Storage.detect_mimetype(@file)).to eq("image/png")
    end

    it "unknown if there is no content_type" do
      expect(Attachments::Storage.detect_mimetype(@file)).to eq("unknown/unknown")
    end
  end
end
