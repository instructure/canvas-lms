# frozen_string_literal: true

#
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

describe Api::V1::Lti::RegistrationHistoryEntry do
  include Api::V1::Lti::RegistrationHistoryEntry

  let_once(:account) { Account.default }
  let_once(:user) { account_admin_user(account:) }
  let_once(:registration) { lti_registration_with_tool(account:) }
  let_once(:deployment) { registration.deployments.first }
  let_once(:sub_account) { account_model(root_account: account, name: "Sub Account") }
  let_once(:course) { course_model(account: sub_account, name: "Test Course") }
  let_once(:session) { {} }
  let_once(:context) { account }

  describe "#lti_registration_history_entry_json" do
    context "with internal configuration changes" do
      let(:history_entry) do
        Lti::RegistrationHistoryEntry.track_changes(
          lti_registration: registration,
          current_user: user,
          context: account,
          comment: "Updated registration name"
        ) do
          registration.update!(name: "New Registration Name")
        end
        Lti::RegistrationHistoryEntry.last
      end

      it "serializes internal config changes correctly" do
        preloaded_data = preload_context_controls_for_entries([history_entry])
        json = lti_registration_history_entry_json(history_entry, user, session, context, preloaded_data:)

        expect(json).to include(
          "id" => history_entry.id,
          "update_type" => "manual_edit",
          "comment" => "Updated registration name"
        )
        expect(json["diff"]).to be_present
        expect(json["old_configuration"]).to be_present
        expect(json["new_configuration"]).to be_present
      end

      it "includes created_by user information" do
        preloaded_data = preload_context_controls_for_entries([history_entry])
        json = lti_registration_history_entry_json(history_entry, user, session, context, preloaded_data:)

        expect(json["created_by"]).to be_present
        expect(json["created_by"]["id"]).to eq(user.id)
      end
    end

    context "with context control changes" do
      let_once(:control) do
        Lti::ContextControl.create!(
          registration:,
          deployment:,
          context: sub_account,
          available: true,
          workflow_state: "active"
        )
      end
      let_once(:history_entry) do
        Lti::RegistrationHistoryEntry.track_control_changes(control:, current_user: user) do
          control.update!(available: false)
        end
        Lti::RegistrationHistoryEntry.last
      end

      it "serializes context controls grouped by deployment" do
        preloaded_data = preload_context_controls_for_entries([history_entry])
        json = lti_registration_history_entry_json(history_entry, user, session, context, preloaded_data:)

        expect(json["old_controls_by_deployment"].length).to eq(1)
        expect(json["new_controls_by_deployment"].length).to eq(1)

        old_deployment = json["old_controls_by_deployment"].first
        expect(old_deployment["deployment_id"]).to eq(deployment.deployment_id)
        expect(old_deployment["context_controls"].length).to eq(1)

        new_deployment = json["new_controls_by_deployment"].first
        expect(new_deployment["deployment_id"]).to eq(deployment.deployment_id)
        expect(new_deployment["context_controls"].length).to eq(1)
      end

      it "includes full deployment details" do
        preloaded_data = preload_context_controls_for_entries([history_entry])
        json = lti_registration_history_entry_json(history_entry, user, session, context, preloaded_data:)

        old_deployment = json["old_controls_by_deployment"].first
        expect(old_deployment).to include(
          "id" => deployment.id,
          "deployment_id" => deployment.deployment_id,
          "context_id" => deployment.context_id,
          "context_type" => deployment.context_type,
          "context_name" => deployment.context.name,
          "registration_id" => registration.id
        )
      end

      it "includes historical attribute overrides in controls" do
        preloaded_data = preload_context_controls_for_entries([history_entry])
        json = lti_registration_history_entry_json(history_entry, user, session, context, preloaded_data:)

        old_control = json["old_controls_by_deployment"].first["context_controls"].first
        expect(old_control["available"]).to be true

        new_control = json["new_controls_by_deployment"].first["context_controls"].first
        expect(new_control["available"]).to be false
      end

      it "includes calculated attributes like display_path and counts" do
        preloaded_data = preload_context_controls_for_entries([history_entry])
        json = lti_registration_history_entry_json(history_entry, user, session, context, preloaded_data:)

        old_control = json["old_controls_by_deployment"].first["context_controls"].first
        expect(old_control.slice("display_path", "depth", "subaccount_count", "course_count", "child_control_count")).to eql(
          {
            "display_path" => [],
            "depth" => 1,
            "subaccount_count" => 0,
            "course_count" => 1,
            "child_control_count" => 0
          }
        )
      end

      it "returns empty array for old_controls_by_deployment when creating a new control" do
        Lti::RegistrationHistoryEntry.track_bulk_control_changes(
          control_params: [{ deployment_id: deployment.id, course_id: course.id }],
          lti_registration: registration,
          root_account: account,
          current_user: user
        ) do
          Lti::ContextControl.create!(
            registration:,
            deployment:,
            context: course,
            available: true,
            workflow_state: "active"
          )
        end
        new_entry = Lti::RegistrationHistoryEntry.last

        preloaded_data = preload_context_controls_for_entries([new_entry])
        json = lti_registration_history_entry_json(new_entry, user, session, context, preloaded_data:)

        expect(json["old_controls_by_deployment"]).to eq([])
        expect(json["new_controls_by_deployment"]).to be_an(Array)
        expect(json["new_controls_by_deployment"].length).to eq(1)
      end
      # As of writing, there's no valid code path in Canvas for both hard-deleting a context
      # control and creating a history entry for said hard-deletion. If that changes, we'll
      # need to modify the serializer code to handle it.
    end

    context "with multiple deployments" do
      let_once(:second_deployment) do
        ContextExternalTool.create!(
          context: account,
          name: "Second Deployment",
          consumer_key: "key2",
          shared_secret: "secret2",
          url: "http://example.com/launch2",
          developer_key: registration.developer_key,
          lti_version: "1.3",
          workflow_state: "public"
        )
      end

      let_once(:control1) do
        Lti::ContextControl.create!(
          registration:,
          deployment:,
          context: sub_account,
          available: true,
          workflow_state: "active"
        )
      end

      let_once(:control2) do
        Lti::ContextControl.create!(
          registration:,
          deployment: second_deployment,
          context: course,
          available: true,
          workflow_state: "active"
        )
      end

      let_once(:history_entry) do
        Lti::RegistrationHistoryEntry.track_bulk_control_changes(
          control_params: [
            { deployment_id: deployment.id, account_id: sub_account.id },
            { deployment_id: second_deployment.id, course_id: course.id }
          ],
          lti_registration: registration,
          root_account: account,
          current_user: user
        ) do
          control1.update!(available: false)
          control2.update!(available: false)
        end
        Lti::RegistrationHistoryEntry.last
      end

      it "groups controls by their respective deployments" do
        preloaded_data = preload_context_controls_for_entries([history_entry])
        json = lti_registration_history_entry_json(history_entry, user, session, context, preloaded_data:)

        expect(json["old_controls_by_deployment"].length).to eq(2)
        expect(json["new_controls_by_deployment"].length).to eq(2)

        old_deployments = json["old_controls_by_deployment"].index_by { |d| d["deployment_id"] }
        expect(old_deployments.keys.sort).to eq([deployment.deployment_id, second_deployment.deployment_id].sort)

        old_deployment1 = old_deployments[deployment.deployment_id]
        expect(old_deployment1["context_controls"].length).to eq(1)
        expect(old_deployment1["context_controls"].first["context_name"]).to eq("Sub Account")

        old_deployment2 = old_deployments[second_deployment.deployment_id]
        expect(old_deployment2["context_controls"].length).to eq(1)
        expect(old_deployment2["context_controls"].first["context_name"]).to eq("Test Course")
      end
    end
  end

  describe "#lti_registration_history_entries_json" do
    it "serializes multiple entries efficiently with preloading" do
      entries = []
      3.times do |i|
        Lti::RegistrationHistoryEntry.track_changes(
          lti_registration: registration,
          current_user: user,
          context: account,
          comment: "Update #{i}"
        ) do
          registration.update!(name: "Name #{i}")
        end
        entries << Lti::RegistrationHistoryEntry.last
      end

      json = lti_registration_history_entries_json(entries, user, session, context)

      expect(json.length).to eq(3)
      json.each_with_index do |entry_json, i|
        expect(entry_json["comment"]).to eq("Update #{i}")
      end
    end

    it "handles multiple types of entries" do
      Lti::RegistrationHistoryEntry.track_changes(
        lti_registration: registration,
        current_user: user,
        context: account
      ) do
        registration.update!(name: "Updated Name")
      end

      control = Lti::ContextControl.create!(
        registration:,
        deployment:,
        context: sub_account,
        available: true,
        workflow_state: "active"
      )
      Lti::RegistrationHistoryEntry.track_control_changes(control:, current_user: user) do
        control.update!(available: false)
      end

      entries = Lti::RegistrationHistoryEntry.where(lti_registration: registration)
                                             .order(created_at: :desc)
                                             .limit(2)

      json = lti_registration_history_entries_json(entries, user, session, context)

      expect(json.length).to eq(2)

      config_entry = json.find { |e| e["old_configuration"].present? }
      control_entry = json.find { |e| e["old_controls_by_deployment"].present? }

      expect(config_entry).to be_present
      expect(control_entry).to be_present
      expect(control_entry["old_controls_by_deployment"]).to be_an(Array)
    end
  end
end
