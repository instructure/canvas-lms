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
        ap = Lti::AssetProcessor.where(assignment: assign).first
        expect(ap.id).to equal subject.id
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
      ActionController::Parameters.new({
                                         "context_external_tool_id" => context_external_tool.id,
                                         "url" => "http://example.com",
                                         "title" => "Example Title",
                                         "text" => "Example Text",
                                         "custom" => custom,
                                         "icon" => icon,
                                         "window" => window,
                                         "iframe" => iframe,
                                         "report" => report,
                                       })
    end
    let(:report) do
      {
        "invalid_key" => "value1",
        "url" => "https://example.com/report.png",
        "custom" => { "key" => "value" }
      }
    end
    let(:icon) do
      {
        "extra_field1" => "value1",
        "url" => "https://example.com/icon.png",
        "width" => 20,
      }
    end
    let(:custom) { { "key" => "value" } }
    let(:window) { { "width" => 20, "height" => 10 } }
    let(:iframe) { { "width" => 20, "height" => 10 } }
    let(:context) { context_external_tool.context }

    context "when context_external_tool is found" do
      it "returns a new Lti::AssetProcessor instance with the correct attributes" do
        expect(subject).to be_a(Lti::AssetProcessor)
        expect(subject.context_external_tool).to eq(context_external_tool)
        expect(subject.url).to eq("http://example.com")
        expect(subject.title).to eq("Example Title")
        expect(subject.text).to eq("Example Text")
        expect(subject.custom).to eq({ "key" => "value" })
        expect(subject.icon).to eq({ "width" => 20, "url" => "https://example.com/icon.png" })
        expect(subject.window).to eq({ "height" => 10, "width" => 20 })
        expect(subject.iframe).to eq({ "height" => 10, "width" => 20 })
        expect(subject.report).to eq({
                                       "url" => "https://example.com/report.png",
                                       "custom" => { "key" => "value" }
                                     })
      end

      context "with invalid report in content_item" do
        let(:report) { { "url" => { "invalid_value" => "value1" } } }

        it "raises an error" do
          expect { subject }.to raise_error(Schemas::Base::InvalidSchema)
        end
      end

      context "with invalid custom in content_item" do
        let(:custom) { { "key" => 123 } }

        it "raises an error" do
          expect { subject }.to raise_error(Schemas::Base::InvalidSchema)
        end
      end

      context "with invalid window in content_item" do
        let(:window) { { "width" => [] } }

        it "raises an error" do
          expect { subject }.to raise_error(Schemas::Base::InvalidSchema)
        end
      end

      context "with invalid iframe in content_item" do
        let(:iframe) { { "width" => [] } }

        it "raises an error" do
          expect { subject }.to raise_error(Schemas::Base::InvalidSchema)
        end
      end

      context "with invalid icon in content_item" do
        let(:icon) { { "width" => -2 } }

        it "raises an error" do
          expect { subject }.to raise_error(Schemas::Base::InvalidSchema)
        end
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

  describe ".info_for_display" do
    subject do
      Lti::AssetProcessor.where(assignment_id: assignment.id).info_for_display
    end

    let(:assignment) { assignment_model }

    def make_ap(context_external_tool, num, icon: nil)
      title = "title#{num}"
      text = "text#{num}"
      lti_asset_processor_model(context_external_tool:, assignment:, title:, text:, icon:)
    end

    it "doesn't include deleted asset processors" do
      tool = external_tool_1_3_model
      ap1 = make_ap(tool, 1)
      ap2 = make_ap(tool, 2)
      ap1.destroy!
      expect(subject.map { |ap| ap[:id] }).to eq([ap2.id])
    end

    def set_ap_settings(tool, icon_url: nil, text: nil)
      tool.settings["ActivityAssetProcessor"] = { icon_url:, text: }
      tool.save!
    end

    it "contains the fields needed for the assignment edit page" do
      tool1 = external_tool_1_3_model(opts: { name: "my tool" })
      tool2 = external_tool_1_3_model(opts: { name: "my other tool" })

      # icon from AP (overrides placement icon), text from placement
      set_ap_settings(tool1, icon_url: "https://example.com/placement.png", text: "placement text")
      ap1 = make_ap(tool1, 1, icon: { url: "https://example.com/ap.png" })

      # icon from tool, text from tool's name
      set_ap_settings(tool2, icon_url: "https://example.com/placement-icon.png")
      ap2 = make_ap(tool2, 2)

      expected = [
        {
          id: ap1.id,
          title: "title1",
          text: "text1",
          tool_name: tool1.name,
          tool_id: tool1.id,
          tool_placement_label: "placement text",
          icon_or_tool_icon_url: "https://example.com/ap.png",
          window: ap1.window,
          iframe: ap1.iframe,
        },
        {
          id: ap2.id,
          title: "title2",
          text: "text2",
          tool_name: tool2.name,
          tool_id: tool2.id,
          tool_placement_label: "my other tool",
          icon_or_tool_icon_url: "https://example.com/placement-icon.png",
          window: ap1.window,
          iframe: ap1.iframe,
        }
      ]
      expect(subject).to eq(expected)
    end
  end
end
