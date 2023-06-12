# frozen_string_literal: true

#
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
#

describe Importers::LtiResourceLinkImporter do
  subject { described_class.process_migration(hash, migration) }

  let!(:source_course) { course_model }
  let!(:destination_course) { course_model }
  let!(:migration) { ContentMigration.create(context: destination_course, source_course:) }
  let!(:tool) { external_tool_1_3_model(context: destination_course) }

  context "when `lti_resource_links` is not given" do
    let(:hash) { { lti_resource_links: nil } }

    it "does not import lti resource links" do
      expect(subject).to be false
    end
  end

  context "when `lti_resource_links` is given" do
    let(:custom_params) do
      { "param1" => "value1 " }
    end
    let(:lookup_uuid) { "1b302c1e-c0a2-42dc-88b6-c029699a7c7a" }
    let(:hash) do
      {
        "lti_resource_links" => [
          {
            "custom" => custom_params,
            "lookup_uuid" => lookup_uuid,
            "launch_url" => tool.url
          }
        ]
      }
    end

    context "when the Lti::ResourceLink.context_type is an Assignment" do
      let!(:assignment) do
        destination_course.assignments.create!(
          submission_types: "external_tool",
          external_tool_tag_attributes: { content: tool },
          points_possible: 10
        )
      end
      let!(:resource_link) do
        Lti::ResourceLink.create!(
          context_external_tool: tool,
          context: assignment,
          lookup_uuid:,
          custom: nil,
          url: "http://www.example.com/launch"
        )
      end

      it "update the custom params" do
        expect(resource_link.custom).to be_nil

        expect(subject).to be true

        resource_link.reload

        expect(resource_link.custom).to eq custom_params
      end
    end

    context "when the Lti::ResourceLink.context_type is a Course" do
      context "and the resource link was not recorded" do
        it "create the new resource link" do
          expect(subject).to be true

          expect(destination_course.lti_resource_links.size).to eq 1
          expect(destination_course.lti_resource_links.first.lookup_uuid).to eq lookup_uuid
          expect(destination_course.lti_resource_links.first.custom).to eq custom_params
        end
      end

      context "and the resource link was recorded" do
        before do
          destination_course.lti_resource_links.create!(
            context_external_tool: tool,
            custom: nil,
            lookup_uuid:
          )
        end

        it "update the custom params" do
          expect(subject).to be true

          expect(destination_course.lti_resource_links.size).to eq 1
          expect(destination_course.lti_resource_links.first.lookup_uuid).to eq lookup_uuid
          expect(destination_course.lti_resource_links.first.custom).to eq custom_params
        end
      end
    end
  end
end
