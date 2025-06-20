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

RSpec.describe Lti::Asset do
  describe "validations" do
    subject { lti_asset_model }

    it { is_expected.to be_valid }
  end

  it "generates a uuid" do
    asset1 = lti_asset_model
    asset2 = lti_asset_model
    expect(asset1.uuid).not_to be_nil
    expect(asset2.uuid).not_to be_nil
    expect(asset1.uuid).not_to eq(asset2.uuid)
  end

  it "submission_id is nullified when submission is deleted" do
    asset1 = lti_asset_model

    asset1.submission.destroy

    expect(asset1.reload.submission_id).to be_nil
  end

  it "allows multiple rows with the same attachment_id and empty submission id" do
    attachment = attachment_model
    asset1 = lti_asset_model(attachment:)
    asset2 = lti_asset_model(attachment:)
    expect(asset2.attachment_id).to eq(asset1.attachment_id)

    asset1.submission.destroy
    asset2.submission.destroy

    expect(asset1.reload.submission_id).to be_nil
    expect(asset2.reload.submission_id).to be_nil
  end

  it "soft deleted when attachment is deleted" do
    asset1 = lti_asset_model

    asset1.attachment.destroy

    expect(asset1.reload.workflow_state).to eq("deleted")
  end

  describe "#compatible_with_processor?" do
    describe "for submission-attachment assets" do
      it "is true iff the submission matches the given processor's assignment" do
        asset = lti_asset_model
        processor = lti_asset_processor_model(assignment: asset.submission.assignment)
        expect(asset.compatible_with_processor?(processor)).to be(true)

        expect(asset.compatible_with_processor?(lti_asset_processor_model)).to be(false)
      end
    end
  end

  describe "#calculate_sha256_checksum!" do
    let(:content) { "hello world" }
    let(:attachment) { attachment_model(uploaded_data: stub_file_data("test.txt", content, "text/plain")) }
    let(:asset) { lti_asset_model(attachment:) }

    it "calculates and stores SHA256 checksum" do
      asset.calculate_sha256_checksum!
      expect(asset.reload.sha256_checksum).to eq "uU0nuZNNPgilLlLX2n2r+sSE7+N6U4DukIj3rOLvzek="
    end

    it "does nothing if checksum already exists" do
      asset.update(sha256_checksum: "existing_checksum")
      asset.calculate_sha256_checksum!
      expect(asset.reload.sha256_checksum).to eq "existing_checksum"
    end

    context "text entry submission" do
      let(:asset) { lti_asset_model(submission: submission_model(submission_type: "online_text_entry", body: content)) }

      it "calculates checksum for text entry submissions" do
        asset.calculate_sha256_checksum!
        expect(asset.reload.sha256_checksum).to eq "uU0nuZNNPgilLlLX2n2r+sSE7+N6U4DukIj3rOLvzek="
      end
    end
  end

  describe "#content_size" do
    let(:content) { "hello world" }

    context "with attachment" do
      let(:attachment) { attachment_model(uploaded_data: stub_file_data("test.txt", content, "text/plain")) }
      let(:asset) { lti_asset_model(attachment:) }

      it "returns the size of the attachment content" do
        expect(asset.content_size).to eq(11)
      end
    end

    context "with text entry submission" do
      let(:asset) { lti_asset_model(submission: submission_model(submission_type: "online_text_entry", body: content)) }

      it "returns the size of the text entry content" do
        expect(asset.content_size).to eq(11)
      end
    end
  end
end
