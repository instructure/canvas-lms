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
  end
end
