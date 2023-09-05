# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

describe Lti::Asset do
  before do
    course_model
  end

  describe "opaque_identifier_for" do
    context "when the asset is nil" do
      subject { described_class.opaque_identifier_for asset }

      let(:asset) { nil }

      it { is_expected.to be_nil }
    end

    it "creates lti_context_id for asset" do
      expect(@course.lti_context_id).to be_nil
      context_id = described_class.opaque_identifier_for(@course)
      @course.reload
      expect(@course.lti_context_id).to eq context_id
    end

    it "uses old_id when present" do
      user = user_model
      context_id = described_class.opaque_identifier_for(user)
      UserPastLtiId.create!(user:, context: @course, user_lti_id: @teacher.lti_id, user_lti_context_id: "old_lti_id", user_uuid: "old")
      expect(described_class.opaque_identifier_for(user, context: @course)).to_not eq context_id
      expect(described_class.opaque_identifier_for(user, context: @course)).to eq "old_lti_id"
    end

    it "does not use old_id when not present" do
      user = user_model
      context_id = described_class.opaque_identifier_for(user)
      expect(described_class.opaque_identifier_for(user, context: @course)).to eq context_id
    end

    it "does not create new lti_context for asset if exists" do
      @course.lti_context_id = "dummy_context_id"
      @course.save!
      described_class.opaque_identifier_for(@course)
      @course.reload
      expect(@course.lti_context_id).to eq "dummy_context_id"
    end

    it "attempts to fix duplicate lti_context_ids for assets" do
      old_user = user_model
      new_user = user_model

      allow(new_user).to receive(:global_asset_string).and_return(old_user.global_asset_string)
      context_id = described_class.opaque_identifier_for(old_user)

      expect(described_class.opaque_identifier_for(new_user)).to_not eq(context_id)
      expect(described_class.opaque_identifier_for(new_user)).to be_present
      expect(old_user.reload.lti_context_id).to eq(context_id)
    end

    it "attempts to fix duplicate lti_context_ids for deleted assets" do
      old_user = user_model(workflow_state: "deleted")
      new_user = user_model

      allow(new_user).to receive(:global_asset_string).and_return(old_user.global_asset_string)
      context_id = described_class.opaque_identifier_for(old_user)

      expect(described_class.opaque_identifier_for(new_user)).to eq context_id
      expect(old_user.reload.lti_context_id).to be_nil
    end
  end
end
