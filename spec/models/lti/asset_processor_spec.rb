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

describe Lti::AssetProcessor do
  describe "create" do
    context "validations" do
      subject { lti_asset_processor_model }

      it "defaults to workflow_state=active" do
        expect(lti_asset_processor_model(workflow_state: nil).active?).to be_truthy
      end

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

  describe ".build_for_assignment" do
    subject do
      Lti::AssetProcessor.build_for_assignment(content_item:, context:)
    end

    let(:context_external_tool) { external_tool_1_3_model(context: course_model) }

    let(:content_item) do
      {
        "context_external_tool_id" => context_external_tool.id,
        "url" => "http://example.com",
        "title" => "Example Title",
        "text" => "Example Text",
        "custom" => { "key" => "value" },
        "icon" => { "icon_key" => "icon_value" },
        "window" => { "window_key" => "window_value" },
        "iframe" => { "iframe_key" => "iframe_value" },
        "report" => { "report_key" => "report_value" }
      }
    end

    let(:context) { context_external_tool.context }

    context "when context_external_tool is found" do
      it "returns a new Lti::AssetProcessor instance with the correct attributes" do
        expect(subject).to be_a(Lti::AssetProcessor)
        expect(subject.context_external_tool).to eq(context_external_tool)
        expect(subject.url).to eq("http://example.com")
        expect(subject.title).to eq("Example Title")
        expect(subject.text).to eq("Example Text")
        expect(subject.custom).to eq({ "key" => "value" })
        expect(subject.icon).to eq({ "icon_key" => "icon_value" })
        expect(subject.window).to eq({ "window_key" => "window_value" })
        expect(subject.iframe).to eq({ "iframe_key" => "iframe_value" })
        expect(subject.report).to eq({ "report_key" => "report_value" })
      end
    end

    context "when context_external_tool is not found" do
      it "returns nil" do
        content_item["context_external_tool_id"] = ContextExternalTool.maximum(:id) + 1
        expect(subject).to be_nil
      end
    end

    context "when context_external_tool is in the wrong context" do
      let(:context) { course_model }

      it "returns nil" do
        expect(subject).to be_nil
      end
    end
  end

  describe ".processors_info_for_assignment_edit_page" do
    subject do
      Lti::AssetProcessor.processors_info_for_assignment_edit_page(assignment_id: assignment.id)
    end

    let(:assignment) { assignment_model }

    def make_ap(context_external_tool, num)
      icon = { url: "https://example.com/icon#{num}.png" }
      title = "title#{num}"
      text = "text#{num}"
      lti_asset_processor_model(context_external_tool:, assignment:, title:, text:, icon:)
    end

    it "contains the fields needed for the assignment edit page" do
      tool1 = external_tool_1_3_model(opts: { name: "my tool" })
      tool2 = external_tool_1_3_model(opts: { name: "my other tool" })
      ap1 = make_ap(tool1, 1)
      ap2 = make_ap(tool2, 2)
      expect(subject).to eq([{
                              id: ap1.id,
                              title: "title1",
                              text: "text1",
                              icon: ap1.icon,
                              context_external_tool_name: tool1.name,
                              context_external_tool_id: tool1.id,
                            },
                             {
                               id: ap2.id,
                               title: "title2",
                               text: "text2",
                               icon: ap2.icon,
                               context_external_tool_name: tool2.name,
                               context_external_tool_id: tool2.id,
                             }])
    end
  end
end
