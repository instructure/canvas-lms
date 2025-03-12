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

RSpec.describe Lti::Asset, type: :model do
  describe "validations" do
    subject { lti_asset_model }

    it { is_expected.to be_valid }

    describe "associations" do
      it { is_expected.to validate_presence_of(:attachment) }
      it { is_expected.to validate_presence_of(:submission) }
      it { is_expected.to validate_uniqueness_of(:attachment_id).scoped_to(:submission_id) }
    end
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
end
