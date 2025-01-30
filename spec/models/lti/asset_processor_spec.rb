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

describe Lti::AssetProcessor, type: :model do
  describe "create" do
    context "validations" do
      subject { lti_asset_processor_model }

      it { is_expected.to be_valid }
      it { is_expected.to validate_length_of(:url).is_at_most(4.kilobytes) }
      it { is_expected.to validate_length_of(:title).is_at_most(255) }
      it { is_expected.to validate_length_of(:text).is_at_most(255) }

      it "defaults to workflow_state=active" do
        expect(lti_asset_processor_model(workflow_state: nil).active?).to be_truthy
      end

      it { is_expected.to belong_to(:context_external_tool).required }
      it { is_expected.to belong_to(:assignment).required }
      it { is_expected.to have_many(:asset_reports).dependent(:destroy) }

      it "supports associations from ContextExternalTool and Assignment" do
        expect(subject.context_external_tool.lti_asset_processor_ids).to include(subject.id)
        expect(subject.assignment.lti_asset_processor_ids).to include(subject.id)
      end

      it "is not deleted when CET is destroyed to be able to attach it again to tool after tool reinstall" do
        cet = subject.context_external_tool
        cet.destroy!
        expect(subject.reload.active?).to be_truthy
        expect(cet.lti_asset_processors.first.id).to equal subject.id
      end

      it "is soft deleted when Assignment is destroyed but foreign key is kept" do
        assign = subject.assignment
        assign.destroy!
        expect(subject.reload.active?).not_to be_truthy
        expect(assign.lti_asset_processors.first.id).to equal subject.id
      end

      it "resolves root account through assignment" do
        expect(subject.root_account_id).to equal subject.assignment.root_account_id
      end

      it "validates root account of context external tool" do
        subject.context_external_tool.root_account = account_model
        expect(subject).not_to be_valid
        expect(subject.errors[:context_external_tool].to_s).to include("root account")
      end
    end
  end

  describe "supported_types" do
    it "returns supported types from the 'report' hash" do
      model = lti_asset_processor_model(report: { "supportedTypes" => ["a", "b"] })
      expect(model.supported_types).to eq(["a", "b"])
    end

    it "returns nil when 'report' is not a present" do
      model = lti_asset_processor_model(report: nil)
      expect(model.supported_types).to be_nil
    end
  end
end
