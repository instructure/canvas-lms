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
  let(:root_account) { Account.default }
  let(:context_external_tool) { external_tool_1_3_model }
  let(:assignment) { assignment_model }
  let(:asset_processor) do
    Lti::AssetProcessor.create!(root_account:,
                                context_external_tool:,
                                assignment:,
                                url: "http://example.com",
                                title: "title",
                                text: "text",
                                custom: { custom: "custom" },
                                icon: { icon: "icon" },
                                window: { window: "window" },
                                iframe: { iframe: "iframe" },
                                report: { report: "report" })
  end

  describe "create" do
    context "validations" do
      it "without account, it fails" do
        expect { Lti::AssetProcessor.create!(context_external_tool:, assignment:) }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "without CET, it fails" do
        expect { Lti::AssetProcessor.create!(root_account:, assignment:) }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "without assignment, it fails" do
        expect { Lti::AssetProcessor.create!(root_account:, context_external_tool:) }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "is invalid if url exceeds 4 kilobytes" do
        ap = Lti::AssetProcessor.new(root_account:, context_external_tool:, assignment:, url: "a" * (4.kilobytes + 1))
        expect(ap).not_to be_valid
        expect(ap.errors[:url].to_s).to include("is too long")
      end

      it "is invalid if title exceeds 255 characters" do
        ap = Lti::AssetProcessor.new(root_account:, context_external_tool:, assignment:, title: "a" * 256)
        expect(ap).not_to be_valid
        expect(ap.errors[:title].to_s).to include("is too long")
      end

      it "is invalid if text exceeds 255 characters" do
        ap = Lti::AssetProcessor.new(root_account:, context_external_tool:, assignment:, text: "a" * 256)
        expect(ap).not_to be_valid
        expect(ap.errors[:text].to_s).to include("is too long")
      end

      it "with CET, root_account and assignment it succeeds" do
        expect(asset_processor).to be_persisted
        expect(asset_processor.active?).to be_truthy
      end

      it "supports associations" do
        expect(asset_processor.context_external_tool.id).to eq(context_external_tool.id)
        expect(asset_processor.assignment.id).to eq(assignment.id)
        expect(context_external_tool.lti_asset_processor_ids).to include(asset_processor.id)
        expect(assignment.lti_asset_processor_ids).to include(asset_processor.id)
      end

      it "is not deleted when CET is destroyed to be able to attach it again to tool after tool reinstall" do
        expect(asset_processor.context_external_tool.id).to eq(context_external_tool.id)
        context_external_tool.destroy!
        expect(asset_processor.reload.active?).to be_truthy
        expect(context_external_tool.lti_asset_processors.first.id).to equal asset_processor.id
      end

      it "is soft deleted when Assignment is destroyed but foreign key is kept" do
        expect(asset_processor.assignment.id).to eq(assignment.id)
        assignment.destroy!
        expect(asset_processor.reload.active?).not_to be_truthy
        expect(assignment.lti_asset_processors.first.id).to equal asset_processor.id
      end

      it "resolves root account through assignment" do
        expect(asset_processor.root_account).to equal assignment.root_account
      end

      it "validates root account of context external tool" do
        asset_processor.context_external_tool.root_account = account_model
        expect(asset_processor).not_to be_valid
        expect(asset_processor.errors[:context_external_tool].to_s).to include("root account")
      end
    end
  end
end
