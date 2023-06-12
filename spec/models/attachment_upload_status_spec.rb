# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

RSpec.describe AttachmentUploadStatus do
  let(:upload) { AttachmentUploadStatus.new(attachment:, error: "error") }
  let(:progress) { Progress.create!(context: assignment_model, tag: "tag") }
  let(:attachment) { attachment_model }
  let(:memory_store) { ActiveSupport::Cache.lookup_store(:memory_store) }

  before do
    allow(Rails).to receive(:cache).and_return(memory_store)
    Rails.cache.clear
  end

  it { is_expected.to belong_to(:attachment).required }

  it "is valid" do
    expect(upload).to be_valid
  end

  it "saves a valid model" do
    expect(upload.save).to be_truthy
  end

  describe ".pending!" do
    it "sets pending status" do
      described_class.pending!(attachment)
      expect(described_class.upload_status(attachment)).to eq "pending"
    end
  end

  describe ".success!" do
    it "sets success status" do
      described_class.success!(attachment)
      expect(described_class.upload_status(attachment)).to eq "success"
    end
  end

  describe ".failed!" do
    before { described_class.failed!(attachment, "error") }

    it "sets error status" do
      expect(described_class.upload_status(attachment)).to eq "failed"
    end

    it "creates an instance" do
      expect(described_class.where(attachment:)).to be_exist
    end
  end

  describe ".upload_status" do
    context "for pending" do
      it "sets pendings status" do
        described_class.pending!(attachment)
        expect(described_class.upload_status(attachment)).to eq "pending"
      end
    end

    context "for success" do
      it "sets success status" do
        expect(described_class.upload_status(attachment)).to eq "success"
      end
    end

    context "for error" do
      it "sets error status" do
        AttachmentUploadStatus.create!(attachment:, error: "error msg")
        expect(described_class.upload_status(attachment)).to eq "failed"
      end
    end
  end
end
