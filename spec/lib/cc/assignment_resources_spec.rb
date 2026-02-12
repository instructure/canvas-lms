# frozen_string_literal: true

# Copyright (C) 2021 - present Instructure, Inc.
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

require_relative "cc_spec_helper"

require "nokogiri"

describe CC::AssignmentResources do
  let(:assignment) { assignment_model }
  let(:document) { Builder::XmlMarkup.new(target: xml, indent: 2) }
  let(:xml) { +"" }

  describe "#create_canvas_assignment" do
    subject do
      document.assignment(identifier: SecureRandom.uuid) do |a|
        CC::AssignmentResources.create_canvas_assignment(a, assignment)
      end
      Nokogiri::XML(xml) { |c| c.nonet.strict }
    end

    it "does not set the resource link lookup uuid" do
      expect(subject.at("resource_link_lookup_uuid")).to be_blank
    end

    context "with annotatable document assignments" do
      it "will export assignments with hidden attachments" do
        assignment.update!(
          annotatable_attachment: attachment_model(
            course: assignment.context,
            filename: "some_attachment",
            file_state: "hidden"
          ),
          submission_types: "online_text_entry,student_annotation"
        )
        expect(subject.at("annotatable_attachment_migration_id")).to be_truthy
      end
    end

    context "with time_zone_edited" do
      context "when time_zone_edited is given" do
        let(:expected_time_zone_edited) { "Mountain Time (US & Canada)" }

        before do
          assignment.time_zone_edited = expected_time_zone_edited
          assignment.save!
        end

        it "sets the time_zone_edited" do
          expect(subject.at("time_zone_edited").text).to eq(expected_time_zone_edited)
        end
      end

      context "when time_zone_edited is missing" do
        before do
          assignment.time_zone_edited = nil
          assignment.save!
        end

        it "does not set the time_zone_edited" do
          expect(subject.at("time_zone_edited")).to be_nil
        end
      end
    end

    context "with an associated LTI 1.3 tool" do
      let(:assignment) do
        course.assignments.new(
          name: "test assignment",
          submission_types: "external_tool",
          points_possible: 10
        )
      end

      let(:course) { course_model }
      let(:custom_params) { { foo: "bar " } }
      let(:developer_key) { DeveloperKey.create!(account: course.root_account) }
      let(:tag) { ContentTag.create!(context: assignment, content: tool, url: tool.url) }
      let(:tool) { external_tool_model(context: course, opts: { use_1_3: true }) }

      before do
        tool.update!(developer_key:)
        assignment.external_tool_tag = tag
        assignment.save!
        assignment.primary_resource_link.update!(custom: custom_params)
      end

      it "sets the resource link lookup uuid" do
        expect(subject.at("resource_link_lookup_uuid").text).to eq(
          assignment.primary_resource_link.lookup_uuid
        )
      end

      it "does not set the link_settings" do
        expect(subject.at("external_tool_link_settings_json")).to be_nil
      end

      context "when tag has link_settings" do
        let(:link_settings) { { selection_width: 456, selection_height: 789 } }
        let(:tag) do
          t = super()
          t.link_settings = link_settings
          t.save!
          t
        end

        it "sets the link_settings in json format" do
          expect(subject.at("external_tool_link_settings_json").text).to eq link_settings.to_json
        end
      end
    end

    context "with deleted similarity detection tool" do
      before do
        AssignmentConfigurationToolLookup.create!(
          assignment:,
          tool_type: "Lti::MessageHandler",
          tool_id: 0
        )
        allow(assignment).to receive(:tool_settings_tool).and_return(nil)
      end

      context "when feature flag is enabled" do
        before { Account.site_admin.enable_feature!(:exclude_deleted_lti2_tools_on_assignment_export) }

        it "does not set similarity_detection_tool tag" do
          expect(subject.at("similarity_detection_tool")).to be_nil
        end
      end
    end

    context "export lti_context_id if Asset Processor is attached" do
      let(:root_account) { assignment.root_account }

      it "does not export anything when lti_asset_processor FF is off" do
        root_account.disable_feature!(:lti_asset_processor)
        expect(subject.at("lti_context_id")).to be_nil
      end

      it "does not export anything if no Asset Processor is attached to the assignment" do
        expect(subject.at("lti_context_id")).to be_nil
      end

      it "exports lti_context_id" do
        tool = external_tool_model(context: assignment.context.root_account)
        lti_asset_processor_model(tool:, assignment:, title: "Text Entry AP")

        expect(subject.at("lti_context_id").text).to eq assignment.lti_context_id
      end
    end

    context "export asset processors" do
      let(:root_account) { assignment.root_account }

      it "does not export asset processors when lti_asset_processor FF is off" do
        root_account.disable_feature!(:lti_asset_processor)
        tool = external_tool_model(context: assignment.context.root_account)
        lti_asset_processor_model(tool:, assignment:, title: "Text Entry AP")

        expect(subject.at("asset_processors")).to be_nil
      end

      it "does not export asset processors if none are attached to the assignment" do
        expect(subject.at("asset_processors")).to be_nil
      end

      it "exports asset processors when they are attached" do
        tool = external_tool_model(context: assignment.context.root_account)
        lti_asset_processor_model(tool:, assignment:, title: "Text Entry AP", url: "https://example.com/tool1")
        lti_asset_processor_model(tool:, assignment:, title: "File Upload AP", url: "https://example.com/tool2")

        asset_processors_node = subject.at("asset_processors")
        expect(asset_processors_node).not_to be_nil

        asset_processor_nodes = subject.css("asset_processors asset_processor")
        expect(asset_processor_nodes.size).to eq 2

        ap1_node = asset_processor_nodes.first
        expect(ap1_node.at("url").text).to eq "https://example.com/tool1"
        expect(ap1_node.at("title").text).to eq "Text Entry AP"
        expect(ap1_node["identifier"]).to be_present

        ap2_node = asset_processor_nodes.last
        expect(ap2_node.at("url").text).to eq "https://example.com/tool2"
        expect(ap2_node.at("title").text).to eq "File Upload AP"
        expect(ap2_node["identifier"]).to be_present
      end

      it "exports asset processor with all fields populated" do
        custom_data = { "key1" => "value1" }
        icon_data = { "url" => "https://example.com/icon.png", "width" => 64, "height" => 64 }
        window_data = { "targetName" => "procwin", "width" => 800, "height" => 600, "windowFeatures" => "left=10,top=20" }
        iframe_data = { "width" => 900, "height" => 700 }
        report_data = { "released" => true, "indicator" => false, "url" => "https://example.com/report", "custom" => { "rkey" => "rval" } }
        context_tool = external_tool_model(context: assignment.context.root_account, placements: ["ActivityAssetProcessor"]) # ensure key generation stable

        lti_asset_processor_model(
          tool: context_tool,
          assignment:,
          title: "Rich AP",
          text: "Description text",
          url: "https://example.com/rich-tool",
          custom: custom_data,
          icon: icon_data,
          window: window_data,
          iframe: iframe_data,
          report: report_data
        )

        asset_processor_node = subject.at("asset_processors asset_processor")
        expect(asset_processor_node["identifier"]).to be_present
        expect(asset_processor_node.at("url").text).to eq "https://example.com/rich-tool"
        expect(asset_processor_node.at("title").text).to eq "Rich AP"
        expect(asset_processor_node.at("text").text).to eq "Description text"
        expect(JSON.parse(asset_processor_node.at("custom").text)).to eq custom_data
        expect(JSON.parse(asset_processor_node.at("icon").text)).to eq icon_data
        expect(JSON.parse(asset_processor_node.at("window").text)).to eq window_data
        expect(JSON.parse(asset_processor_node.at("iframe").text)).to eq iframe_data
        expect(JSON.parse(asset_processor_node.at("report").text)).to eq report_data
        expect(asset_processor_node.at("context_external_tool_global_id").text).to eq context_tool.global_id.to_s
        expect(asset_processor_node.at("context_external_tool_url").text).to eq context_tool.url
      end
    end

    context "export new quizzes settings" do
      it "does not export new_quizzes_type when settings are not present" do
        expect(subject.at("new_quizzes_type")).to be_nil
      end

      it "does not export new_quizzes_anonymous_participants when settings are not present" do
        expect(subject.at("new_quizzes_anonymous_participants")).to be_nil
      end

      it "exports new_quizzes_type when present in settings" do
        assignment.settings = { "new_quizzes" => { "type" => "graded_quiz" } }
        assignment.save!
        expect(subject.at("new_quizzes_type").text).to eq("graded_quiz")
      end

      it "exports new_quizzes_anonymous_participants when present in settings" do
        assignment.settings = { "new_quizzes" => { "anonymous_participants" => true } }
        assignment.save!
        expect(subject.at("new_quizzes_anonymous_participants").text).to eq("true")
      end

      it "exports both type and anonymous_participants when both are present" do
        assignment.settings = { "new_quizzes" => { "type" => "graded_survey", "anonymous_participants" => false } }
        assignment.save!
        expect(subject.at("new_quizzes_type").text).to eq("graded_survey")
        expect(subject.at("new_quizzes_anonymous_participants").text).to eq("false")
      end

      it "does not export anonymous_participants when it is nil" do
        assignment.settings = { "new_quizzes" => { "type" => "ungraded_survey", "anonymous_participants" => nil } }
        assignment.save!
        expect(subject.at("new_quizzes_type").text).to eq("ungraded_survey")
        expect(subject.at("new_quizzes_anonymous_participants")).to be_nil
      end
    end
  end
end
