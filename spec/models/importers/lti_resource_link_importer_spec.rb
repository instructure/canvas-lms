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

  let_once(:registration) { lti_registration_with_tool(account: destination_course.root_account, created_by: user_model) }
  let_once(:tool) { registration.deployments.first }

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
          points_possible: 10,
          migration_id: "asdfasdf"
        )
      end
      let!(:resource_link) do
        assignment.lti_resource_links.first.tap do |rl|
          rl.update! lookup_uuid:
        end
      end

      context "when the associated assignment is selected for import" do
        it "update the custom params" do
          expect(resource_link.custom).to be_nil

          expect(subject).to be true

          resource_link.reload

          expect(resource_link.custom).to eq custom_params
        end

        context "with an existing assignment with the same lookup_uuid" do
          let!(:other_assignment) do
            destination_course.assignments.create!(
              submission_types: "external_tool",
              external_tool_tag_attributes: { content: tool },
              points_possible: 10,
              migration_id: "asdf"
            )
          end
          let!(:other_resource_link) do
            other_assignment.lti_resource_links.first.tap do |rl|
              rl.update! lookup_uuid:
            end
          end
          let(:other_custom_params) do
            { "param2" => "value2" }
          end
          let(:hash) do
            {
              "lti_resource_links" => [
                {
                  "custom" => custom_params,
                  "lookup_uuid" => lookup_uuid,
                  "launch_url" => tool.url,
                  "assignment_migration_id" => assignment.migration_id
                },
                {
                  "custom" => other_custom_params,
                  "lookup_uuid" => lookup_uuid,
                  "launch_url" => tool.url,
                  "assignment_migration_id" => other_assignment.migration_id
                }
              ]
            }
          end

          it "sets the right custom params for both resource links" do
            expect(subject).to be true

            resource_link.reload
            other_resource_link.reload

            expect(other_resource_link.custom).to eq other_custom_params
            expect(resource_link.custom).to eq custom_params
          end
        end
      end

      context "when the associated assignment is not selected for import" do
        before do
          allow(Importers::LtiResourceLinkImporter).to receive(:filter_by_assignment_context).and_return([])
        end

        it "does not import lti resource links" do
          expect(subject).to be false
        end
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

  describe "filter_by_assignment_context" do
    subject { Importers::LtiResourceLinkImporter }

    let!(:migration) { Struct.new(:import_object?).new }
    let!(:lookup_uuid) { "1b302c1e-c0a2-42dc-88b6-c029699a7c7a" }
    let!(:assignments) do
      [
        {
          "resource_link_lookup_uuid" => lookup_uuid
        }
      ]
    end

    context "when lti_resource_link has an associated assignment context" do
      let!(:lti_resource_links) do
        [
          {
            "lookup_uuid" => lookup_uuid,
          }
        ]
      end

      context "when assignment selected for import" do
        before do
          allow(migration).to receive_messages(
            import_everything?: false,
            import_object?: true
          )
        end

        it "keeps the associated lti_resource_link" do
          filtered_lti_resource_links = subject.filter_by_assignment_context(lti_resource_links.dup, assignments, migration)
          expect(filtered_lti_resource_links).to include(lti_resource_links.first)
        end
      end

      context "when assignment is not selected for import" do
        before do
          allow(migration).to receive_messages(
            import_everything?: false,
            import_object?: false
          )
        end

        it "removes the associated lti_resource_link" do
          filtered_lti_resource_links = subject.filter_by_assignment_context(lti_resource_links.dup, assignments, migration)
          expect(filtered_lti_resource_links).not_to include(lti_resource_links.first)
        end
      end
    end

    context "when lti_resource_link's context_type is not Assignment (no assignment_migration_id)" do
      let!(:lti_resource_links) do
        [
          {
            "lookup_uuid" => "11111111-2222-1111-2222-111111111111"
          }
        ]
      end

      context "when assignment selected for import" do
        before do
          allow(migration).to receive_messages(
            import_everything?: false,
            import_object?: true
          )
        end

        it "keeps the lti_resource_link" do
          filtered_lti_resource_links = subject.filter_by_assignment_context(lti_resource_links.dup, assignments, migration)
          expect(filtered_lti_resource_links).to include(lti_resource_links.first)
        end
      end

      context "when assignment does not selected for import" do
        before do
          allow(migration).to receive_messages(
            import_everything?: false,
            import_object?: false
          )
        end

        it "keeps the associated lti_resource_link" do
          filtered_lti_resource_links = subject.filter_by_assignment_context(lti_resource_links.dup, assignments, migration)
          expect(filtered_lti_resource_links).to include(lti_resource_links.first)
        end
      end
    end

    context "when multiple assignments have resource links with the same lookup_uuid" do
      let!(:assignment1_migration_id) { "assignment_1" }
      let!(:assignment2_migration_id) { "assignment_2" }
      let!(:assignments) do
        [
          {
            "migration_id" => assignment1_migration_id,
            "resource_link_lookup_uuid" => lookup_uuid
          },
          {
            "migration_id" => assignment2_migration_id,
            "resource_link_lookup_uuid" => lookup_uuid
          }
        ]
      end
      let!(:lti_resource_links) do
        [
          {
            "lookup_uuid" => lookup_uuid,
            "assignment_migration_id" => assignment1_migration_id
          },
          {
            "lookup_uuid" => lookup_uuid,
            "assignment_migration_id" => assignment2_migration_id
          }
        ]
      end

      context "when only one assignment is selected for import" do
        before do
          allow(migration).to receive(:import_everything?).and_return(false)
          allow(migration).to receive(:import_object?) do |_type, migration_id|
            migration_id == assignment1_migration_id
          end
        end

        it "includes only the resource link associated with the imported assignment" do
          filtered_lti_resource_links = subject.filter_by_assignment_context(lti_resource_links.dup, assignments, migration)

          expect(filtered_lti_resource_links.size).to eq 1
          expect(filtered_lti_resource_links.first["assignment_migration_id"]).to eq assignment1_migration_id
          expect(filtered_lti_resource_links).not_to include(
            hash_including("assignment_migration_id" => assignment2_migration_id)
          )
        end
      end
    end

    context "when lti_resource_link has no assignment association and no matching assignment" do
      let!(:lookup_uuid_without_assignment) { "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee" }
      let!(:assignments) { [] }

      context "when resource link has no assignment_migration_id (course-level resource link)" do
        let!(:lti_resource_links) do
          [
            {
              "lookup_uuid" => lookup_uuid_without_assignment,
              "assignment_migration_id" => nil
            }
          ]
        end

        before do
          allow(migration).to receive_messages(
            import_everything?: false,
            import_object?: false
          )
        end

        it "includes the course-level resource link" do
          filtered_lti_resource_links = subject.filter_by_assignment_context(lti_resource_links.dup, assignments, migration)
          expect(filtered_lti_resource_links).to include(lti_resource_links.first)
        end
      end

      context "when resource link has an assignment_migration_id but assignment not selected" do
        let!(:lti_resource_links) do
          [
            {
              "lookup_uuid" => lookup_uuid_without_assignment,
              "assignment_migration_id" => "some_assignment_id"
            }
          ]
        end

        before do
          allow(migration).to receive_messages(
            import_everything?: false,
            import_object?: false
          )
        end

        it "filters out the assignment-level resource link" do
          filtered_lti_resource_links = subject.filter_by_assignment_context(lti_resource_links.dup, assignments, migration)
          expect(filtered_lti_resource_links).not_to include(lti_resource_links.first)
        end
      end
    end
  end
end
