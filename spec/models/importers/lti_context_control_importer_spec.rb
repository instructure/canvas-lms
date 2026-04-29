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

  let_once(:migration) { ContentMigration.create!(context: destination_course, source_course:, user: teacher) }
  let_once(:teacher) { user_model }
  let_once(:account) { account_model }
  let_once(:source_course) { course_model(account:) }
  let_once(:source_tool) do
    registration.new_external_tool(source_course)
  end
  let_once(:destination_course) { course_model(account:) }
  let_once(:destination_tool) do
    tool = registration.new_external_tool(destination_course)
    tool.update!(migration_id: destination_tool_migration_id)
    tool
  end
  let_once(:destination_tool_migration_id) { "12345" }
  let_once(:registration) do
    lti_registration_with_tool(account:)
  end
  let_once(:tool) do
    registration.deployments.where(context: account)
  end

  context "no lti_context_controls are present" do
    let(:hash) { { "lti_context_controls" => [] } }

    it "does not create any context controls" do
      expect { subject }.not_to change(Lti::ContextControl, :count)
    end
  end

  context "when a context control for the tool in the course already exists" do
    let(:existing_control) { destination_tool.primary_context_control }
    let(:hash) do
      {
        "lti_context_controls" => [
          {
            "migration_id" => "abcd",
            "available" => true,
            "deployment_migration_id" => destination_tool_migration_id
          }
        ]
      }
    end

    before do
      existing_control.update!(available: false)
    end

    it "updates the existing control" do
      expect { subject }.not_to change { Lti::ContextControl.count }
      expect(existing_control.reload.available).to be true
    end

    context "when the existing control is deleted" do
      before do
        existing_control.destroy
      end

      it "restores the deleted control" do
        expect { subject }.not_to change { Lti::ContextControl.count }
        existing_control.reload
        expect(existing_control.workflow_state).to eql("active")
        expect(existing_control.available).to be true
        expect(existing_control.updated_by).to eq(teacher)
      end
    end
  end

  context "when an imported control doesn't point to an imported tool" do
    let(:hash) { { "lti_context_controls" => [control_hash] } }
    let(:control_hash) do
      {
        "migration_id" => "abcd",
        "available" => true,
        "deployment_migration_id" => "nonexistent",
      }
    end

    it "doesn't create a context control" do
      expect { subject }.not_to change(Lti::ContextControl, :count)
    end
  end

  context "when the tool exists but is inactive" do
    let_once(:inactive_tool) do
      tool = registration.new_external_tool(destination_course)
      tool.update!(migration_id: "inactive_tool_id", workflow_state: "deleted")
      tool
    end
    let(:hash) do
      {
        "lti_context_controls" => [
          {
            "migration_id" => "control_for_inactive",
            "available" => true,
            "deployment_migration_id" => "inactive_tool_id"
          }
        ]
      }
    end

    it "doesn't create a context control for inactive tool" do
      expect { subject }.not_to change(Lti::ContextControl, :count)
    end
  end

  context "when doing selective import with a course level tool" do
    let_once(:second_tool) do
      tool = registration.new_external_tool(destination_course)
      tool.update!(migration_id: "67890")
      tool
    end
    let_once(:existing_control) { destination_tool.primary_context_control }
    let_once(:second_control) { second_tool.primary_context_control }
    let(:hash) do
      {
        "lti_context_controls" => [
          {
            "migration_id" => "control1",
            "available" => true,
            "deployment_migration_id" => destination_tool_migration_id
          },
          {
            "migration_id" => "control2",
            "available" => false,
            "deployment_migration_id" => "67890"
          }
        ]
      }
    end

    before do
      migration.migration_settings = {
        migration_ids_to_import: {
          copy: {
            context_external_tools: {
              destination_tool_migration_id => true
            }
          }
        }
      }.with_indifferent_access
      migration.save!
      existing_control.suspend_callbacks { existing_control.destroy_permanently! }
      second_control.suspend_callbacks { second_control.destroy_permanently! }
    end

    it "only copies the control associated with the selected tool" do
      expect { subject }.to change(Lti::ContextControl, :count).by(1)

      expect(Lti::ContextControl.last.deployment).to eql(destination_tool)
      expect(Lti::ContextControl.last.available).to be true
      expect(Lti::ContextControl.where(course: destination_course, deployment: second_tool).count).to be 0
    end
  end

  context "when tool is selected via external_tools key" do
    let_once(:existing_control) { destination_tool.primary_context_control }
    let(:hash) do
      {
        "lti_context_controls" => [
          {
            "migration_id" => "control1",
            "available" => false,
            "deployment_migration_id" => destination_tool_migration_id
          }
        ]
      }
    end

    before do
      migration.migration_settings = {
        migration_ids_to_import: {
          copy: {
            external_tools: {
              destination_tool_migration_id => true
            }
          }
        }
      }.with_indifferent_access
      migration.save!
      existing_control.suspend_callbacks { existing_control.destroy_permanently! }
    end

    it "imports the control when tool is selected via external_tools" do
      expect { subject }.to change(Lti::ContextControl, :count).by(1)

      expect(Lti::ContextControl.last.deployment).to eql(destination_tool)
      expect(Lti::ContextControl.last.available).to be false
    end
  end

  context "when control has no deployment_migration_id" do
    let(:hash) do
      {
        "lti_context_controls" => [
          {
            "migration_id" => "control_without_deployment",
            "available" => true
          }
        ]
      }
    end

    it "doesn't import the control" do
      expect { subject }.not_to change(Lti::ContextControl, :count)
    end
  end
end
