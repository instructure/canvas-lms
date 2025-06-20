# frozen_string_literal: true

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
#

describe Importers::LtiContextControlImporter do
  subject { described_class.process_migration(hash, migration) }

  let_once(:migration) { ContentMigration.create(context: destination_course, source_course:, user: teacher) }
  let_once(:teacher) { user_model }
  let_once(:account) { account_model }
  let_once(:source_course) { course_model(account:) }
  let_once(:destination_course) { course_model(account:) }
  let_once(:registration) do
    lti_developer_key_model(account:).tap do |key|
      lti_tool_configuration_model(developer_key: key, lti_registration: key.lti_registration)
    end.lti_registration
  end
  let_once(:tool) { registration.new_external_tool(account) }

  context "no lti_context_controls are present" do
    let(:hash) { { "lti_context_controls" => [] } }

    it "does not create any context controls" do
      expect { subject }.not_to change(Lti::ContextControl, :count)
    end
  end

  context "lti_context_controls are present" do
    let(:hash) { { "lti_context_controls" => [control_hash] } }
    let(:control_hash) do
      {
        "deployment_url" => tool.url,
        "available" => true,
        "preferred_deployment_id" => tool.id
      }
    end

    it "creates a context control" do
      expect { subject }.to change(Lti::ContextControl, :count).by(1)
      expect(Lti::ContextControl.last.updated_by).to eq(teacher)
    end

    context "but no tool matches the deployment URL" do
      let(:control_hash) do
        {
          "deployment_url" => "https://example.com/nonexistent_tool",
          "available" => true
        }
      end

      it "does not create a context control and adds a warning" do
        expect { subject }.not_to change(Lti::ContextControl, :count)
        expect(migration.migration_issues.first.error_message).to include("Unable to find a matching tool for the context control")
      end
    end

    context "when a context control for the tool in the course already exists" do
      let_once(:existing_control) do
        Lti::ContextControl.create!(
          course: destination_course,
          deployment: tool,
          registration:,
          available: false
        )
      end

      it "does not create a new context control and adds a warning" do
        expect { subject }.not_to change { Lti::ContextControl.count }
        expect(migration.migration_issues.first.error_message)
          .to include("A context control for the tool with the given URL already exists")
      end

      context "when the existing control is deleted" do
        before(:once) do
          existing_control.destroy
        end

        it "restores the deleted control" do
          expect { subject }.to change { existing_control.reload.workflow_state }
            .to("active")
            .and not_change { Lti::ContextControl.count }
          expect(existing_control.available).to be true
          expect(existing_control.updated_by).to eq(teacher)
        end
      end
    end

    context "when doing selective import with a course level tool" do
      let_once(:dest_course_tool) do
        registration.new_external_tool(destination_course).tap do |tool|
          # Mimic a tool that's been copied to the destination course
          # but doesn't have its context control created yet.
          tool.context_controls.each(&:destroy_permanently!)
        end
      end
      let(:deployment_migration_id) { "12345" }
      let(:hash) do
        {
          "lti_context_controls" => [
            {
              "deployment_url" => tool.url,
              "available" => true,
              "deployment_migration_id" => deployment_migration_id
            },
            {
              "deployment_url" => tool.url,
              "available" => true,
              "deployment_migration_id" => "67890"
            },
            {
              "deployment_url" => tool.url,
              "available" => true,
              "preferred_deployment_id" => tool.id
            }
          ]
        }
      end

      before do
        migration.migration_settings = {
          migration_ids_to_import: {
            copy: {
              context_external_tools: {
                deployment_migration_id => true
              }
            }
          }
        }.with_indifferent_access
        migration.save!
      end

      it "only copies the control associated with the selected tool" do
        expect { subject }.to change(Lti::ContextControl, :count).by(1)

        expect(Lti::ContextControl.last.deployment).to eql(dest_course_tool)
        expect(Lti::ContextControl.where(course: destination_course, deployment: tool).count).to be 0
      end
    end

    context "when doing selective import with a context control not associated with a course level tool" do
      let(:hash) do
        {
          "lti_context_controls" => [
            {
              "deployment_url" => tool.url,
              "available" => true,
              "preferred_deployment_id" => tool.id
            },
            {
              "deployment_url" => "https://foo.bar.com/tool",
              "available" => true,
              "deployment_migration_id" => "12345"
            }
          ]
        }
      end

      before do
        migration.migration_settings = {
          migration_ids_to_import: {
            copy: {
              all_course_settings: true
            }
          }
        }.with_indifferent_access
        migration.save!
      end

      it "only copies controls associated with account-level tools" do
        expect { subject }.to change(Lti::ContextControl, :count).by(1)

        control = Lti::ContextControl.last
        expect(control.deployment).to eql(tool)
        expect(control.available).to be true
        expect(control.updated_by).to eql(teacher)
      end
    end
  end
end
