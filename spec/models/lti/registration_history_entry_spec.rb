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
describe Lti::RegistrationHistoryEntry do
  let_once(:lti_registration) { lti_registration_with_tool(account:) }
  let_once(:account) { account_model }
  let_once(:user) { user_model }

  describe "validations" do
    let(:history_entry) do
      Lti::RegistrationHistoryEntry.new(lti_registration:,
                                        root_account: account,
                                        diff: [["+", "foo.bar", "stuff"]],
                                        # Not actually valid internal config but doesn't matter
                                        old_configuration: { "name" => "Old Name" },
                                        new_configuration: { "name" => "New Name" },
                                        update_type: "manual_edit",
                                        created_by: user)
    end

    it "doesn't require a comment" do
      history_entry.comment = nil
      expect(history_entry).to be_valid
    end

    it "doesn't require a created_by" do
      history_entry.created_by = nil
      expect(history_entry).to be_valid
    end

    it "limits the length of comments" do
      history_entry.comment = "a" * 2001
      expect(history_entry).not_to be_valid
    end

    it "requires a diff" do
      history_entry.diff = nil
      expect(history_entry).not_to be_valid
    end

    it "requires a valid update_type" do
      history_entry.update_type = "invalid type"
      expect(history_entry).not_to be_valid
    end

    it "is invalid if configs are present & update type is for context controls" do
      history_entry.update_type = "control_edit"
      expect(history_entry).not_to be_valid
    end

    it "is invalid if controls are present & update type is for config changes" do
      history_entry.update_type = "manual_edit"
      history_entry.old_context_controls = { "1" => "foo" }
      history_entry.new_context_controls = { "1" => "bar" }
      expect(history_entry).not_to be_valid
    end
  end

  describe "cross-shard associations" do
    specs_require_sharding

    it "allows creating history entries for registrations on different shards" do
      # Create registration on shard1
      registration = nil
      @shard1.activate do
        shard1_account = account_model
        registration = lti_registration_with_tool(account: shard1_account)
      end

      history_entry = @shard2.activate do
        shard2_account = account_model
        created_by = user_model
        Lti::RegistrationHistoryEntry.create!(
          lti_registration: registration,
          root_account: shard2_account,
          diff: [["+", "foo.bar", "stuff"]],
          update_type: "manual_edit",
          created_by:,
          old_configuration: { "name" => "Old Name" },
          new_configuration: { "name" => "New Name" }
        )
      end

      expect(history_entry).to be_persisted
      expect(history_entry.shard).to eq @shard2
      expect(history_entry.lti_registration).to eq registration
      expect(history_entry.lti_registration.shard).to eq @shard1
    end
  end

  describe ".track_changes" do
    let(:context) { account }

    context "with a manual LTI 1.3 install" do
      let(:registration) { lti_registration_with_tool(account:) }
      let(:tool_configuration) { registration.manual_configuration }

      it "creates no history entry when no changes are made" do
        # Ensure we create everything before running the test itself.
        registration
        expect do
          Lti::RegistrationHistoryEntry.track_changes(
            lti_registration: registration,
            current_user: user,
            context:
          ) do
            # No changes made
          end
        end.not_to change(Lti::RegistrationHistoryEntry, :count)
      end

      it "tracks changes to the registration" do
        Lti::RegistrationHistoryEntry.track_changes(
          lti_registration: registration,
          current_user: user,
          context:,
          comment: "Updated registration name"
        ) do
          registration.update!(name: "New Registration Name", vendor: "New Vendor")
        end

        history_entry = Lti::RegistrationHistoryEntry.last
        expect(history_entry).to be_present
        expect(history_entry.diff["registration"]).to include(
          ["~", ["name"], "Test Registration", "New Registration Name"],
          ["~", ["vendor"], "Test Vendor", "New Vendor"]
        )
        expect(history_entry.comment).to eq("Updated registration name")
        expect(history_entry.update_type).to eq("manual_edit")
        expect(history_entry.created_by).to eq(user)
        expect(history_entry.new_configuration["internal_config"])
          .to eql(Schemas::InternalLtiConfiguration.to_sorted(registration.internal_lti_configuration))
      end

      it "tracks changes to the developer key" do
        old_email = registration.developer_key.email
        old_name = registration.developer_key.name
        Lti::RegistrationHistoryEntry.track_changes(
          lti_registration: registration,
          current_user: user,
          context:
        ) do
          registration.developer_key.update!(
            name: "New Dev Key Name",
            email: "new@example.com"
          )
        end

        history_entry = Lti::RegistrationHistoryEntry.last
        expect(history_entry.diff["developer_key"]).to include(
          ["~", ["name"], old_name, "New Dev Key Name"],
          ["~", ["email"], old_email, "new@example.com"]
        )

        # Verify state columns for developer_key
        expect(history_entry.old_configuration["developer_key"]["name"]).to eq(old_name)
        expect(history_entry.old_configuration["developer_key"]["email"]).to eq(old_email)
        expect(history_entry.new_configuration["developer_key"]["name"]).to eq("New Dev Key Name")
        expect(history_entry.new_configuration["developer_key"]["email"]).to eq("new@example.com")
      end

      it "tracks changes to the tool configuration" do
        old_title = tool_configuration.title
        Lti::RegistrationHistoryEntry.track_changes(
          lti_registration: registration,
          current_user: user,
          context:
        ) do
          tool_configuration.update!(title: "Updated Tool Title")
        end

        history_entry = Lti::RegistrationHistoryEntry.last
        expect(history_entry.diff["internal_lti_configuration"]).to be_present
        expect(history_entry.diff["internal_lti_configuration"]).to include(
          ["~", ["title"], old_title, "Updated Tool Title"]
        )

        expect(history_entry.old_configuration["internal_config"]["title"]).to eq(old_title)
        expect(history_entry.new_configuration["internal_config"]["title"]).to eq("Updated Tool Title")
      end

      it "tracks changes to overlays" do
        overlay_data = { "custom_fields" => { "test_field" => "original_value" } }
        lti_overlay_model(
          registration:,
          account: context,
          data: overlay_data,
          updated_by: user
        )

        Lti::RegistrationHistoryEntry.track_changes(
          lti_registration: registration,
          current_user: user,
          context:
        ) do
          overlay = registration.overlay_for(context)
          new_data = overlay_data.deep_dup
          new_data["custom_fields"]["test_field"] = "updated_value"
          overlay.update!(data: new_data)
        end

        history_entry = Lti::RegistrationHistoryEntry.last
        expect(history_entry.diff["overlay"]).to include(
          ["~", ["custom_fields", "test_field"], "original_value", "updated_value"]
        )

        expect(history_entry.old_configuration["overlay"]["custom_fields"]).to eq(overlay_data["custom_fields"])
        expect(history_entry.new_configuration["overlay"]["custom_fields"]).to eq({ "test_field" => "updated_value" })
        expect(history_entry.new_configuration["overlaid_internal_config"]["custom_fields"]).to include({ "test_field" => "updated_value" })
      end

      it "tracks multiple types of changes in a single call" do
        old_reg_name = registration.name
        old_dev_email = registration.developer_key.email

        overlay_data = { "privacy_level" => "anonymous" }
        lti_overlay_model(
          registration:,
          account: context,
          data: overlay_data,
          updated_by: user
        )

        Lti::RegistrationHistoryEntry.track_changes(
          lti_registration: registration,
          current_user: user,
          context:
        ) do
          registration.update!(name: "Multi-Change Test")
          registration.developer_key.update!(email: "multi@example.com")
          overlay = registration.overlay_for(context)
          overlay.update!(data: { "privacy_level" => "public" })
        end

        diff = Lti::RegistrationHistoryEntry.last.diff
        expect(diff.keys).to contain_exactly("registration", "developer_key", "overlay")
        expect(diff["registration"]).to include(
          ["~", ["name"], old_reg_name, "Multi-Change Test"]
        )
        expect(diff["developer_key"]).to include(
          ["~", ["email"], old_dev_email, "multi@example.com"]
        )
        expect(diff["overlay"]).to include(
          ["~", ["privacy_level"], overlay_data["privacy_level"], "public"]
        )

        history_entry = Lti::RegistrationHistoryEntry.last

        # Verify the values
        expect(history_entry.old_configuration["registration"]["name"]).to eq(old_reg_name)
        expect(history_entry.old_configuration["developer_key"]["email"]).to eq(old_dev_email)
        expect(history_entry.old_configuration["overlay"]["privacy_level"]).to eq("anonymous")

        expect(history_entry.new_configuration["registration"]["name"]).to eq("Multi-Change Test")
        expect(history_entry.new_configuration["developer_key"]["email"]).to eq("multi@example.com")
        expect(history_entry.new_configuration["overlay"]["privacy_level"]).to eq("public")
        expect(history_entry.new_configuration["overlaid_internal_config"]["privacy_level"]).to eq("public")
      end

      it "returns the value from the block" do
        result = Lti::RegistrationHistoryEntry.track_changes(
          lti_registration: registration,
          current_user: user,
          context:
        ) do
          registration.update!(name: "Block Return Test")
          "test_return_value"
        end

        expect(result).to eq("test_return_value")
      end
    end

    context "with a dynamic registration install" do
      let(:registration) do
        ims_registration.lti_registration
      end
      let(:ims_registration) do
        lti_ims_registration_model(account:)
      end

      it "tracks changes to the IMS registration" do
        old_client_name = ims_registration.client_name
        Lti::RegistrationHistoryEntry.track_changes(
          lti_registration: registration,
          current_user: user,
          context:
        ) do
          ims_registration.update!(
            client_name: "Updated Dynamic Registration"
          )
        end

        history_entry = Lti::RegistrationHistoryEntry.last
        expect(history_entry.diff["internal_lti_configuration"]).to be_present
        expect(history_entry.diff["internal_lti_configuration"]).to include(
          ["~", ["title"], old_client_name, "Updated Dynamic Registration"]
        )

        expect(history_entry.old_configuration["internal_config"]["title"]).to eq(old_client_name)
        expect(history_entry.new_configuration["internal_config"]["title"]).to eq("Updated Dynamic Registration")
      end

      it "tracks changes to IMS tool configuration" do
        Lti::RegistrationHistoryEntry.track_changes(
          lti_registration: registration,
          current_user: user,
          context:
        ) do
          tool_config = ims_registration.lti_tool_configuration
          tool_config["domain"] = "updated.example.com"
          ims_registration.update!(lti_tool_configuration: tool_config)
        end

        history_entry = Lti::RegistrationHistoryEntry.last
        expect(history_entry.diff["internal_lti_configuration"]).to be_present
        expect(history_entry.diff["internal_lti_configuration"]).to include(
          ["~", ["domain"], "example.com", "updated.example.com"]
        )

        expect(history_entry.old_configuration["internal_config"]["domain"]).to eq("example.com")
        expect(history_entry.new_configuration["internal_config"]["domain"]).to eq("updated.example.com")
      end

      it "tracks changes when overlays are applied to dynamic registrations" do
        overlay_data = {
          "domain" => "different.com",
          "target_link_uri" => "https://different.com/launch",
        }

        lti_overlay_model(
          registration:,
          account: context,
          data: overlay_data,
          updated_by: user
        )

        Lti::RegistrationHistoryEntry.track_changes(
          lti_registration: registration,
          current_user: user,
          context:
        ) do
          overlay = registration.overlay_for(context)
          new_data = overlay_data.deep_dup
          new_data["target_link_uri"] = "https://different.com/updated_launch"
          overlay.update!(data: new_data)
        end

        history_entry = Lti::RegistrationHistoryEntry.last
        expect(history_entry.diff["overlay"]).to include(
          ["~", ["target_link_uri"], "https://different.com/launch", "https://different.com/updated_launch"]
        )

        expect(history_entry.old_configuration["overlay"]["target_link_uri"])
          .to eq("https://different.com/launch")
        expect(history_entry.new_configuration["overlay"]["target_link_uri"])
          .to eq("https://different.com/updated_launch")
        expect(history_entry.old_configuration["overlaid_internal_config"]["target_link_uri"])
          .to eq("https://different.com/launch")
        expect(history_entry.new_configuration["overlaid_internal_config"]["target_link_uri"])
          .to eq("https://different.com/updated_launch")
      end
    end

    context "related models are created or deleted during tracking" do
      let(:registration) { lti_registration_with_tool(account:) }

      it "handles when overlay is deleted during tracking" do
        overlay_data = { "test" => "value" }
        lti_overlay_model(
          registration:,
          account: context,
          data: overlay_data,
          updated_by: user
        )

        Lti::RegistrationHistoryEntry.track_changes(
          lti_registration: registration,
          current_user: user,
          context:
        ) do
          registration.overlay_for(context).destroy_permanently!
        end

        history_entry = Lti::RegistrationHistoryEntry.last
        expect(history_entry.diff["overlay"]).to include(
          ["~", [], { "test" => "value" }, nil]
        )

        expect(history_entry.old_configuration["overlay"]).to eq(overlay_data)
        expect(history_entry.new_configuration["overlay"]).to be_nil
      end

      it "handles when overlay is created during tracking" do
        Lti::RegistrationHistoryEntry.track_changes(
          lti_registration: registration,
          current_user: user,
          context:
        ) do
          lti_overlay_model(
            registration:,
            account: context,
            data: { "new_field" => "new_value" },
            updated_by: user
          )
        end

        history_entry = Lti::RegistrationHistoryEntry.last
        expect(history_entry.diff["overlay"]).to include(
          ["~", [], nil, { "new_field" => "new_value" }]
        )
        expect(history_entry.old_configuration["overlay"]).to be_nil
        expect(history_entry.new_configuration["overlay"]).to eq({ "new_field" => "new_value" })
      end

      it "reloads the registration to ensure accurate tracking" do
        # Simulate external changes that wouldn't be reflected without reload
        original_name = registration.name

        Lti::RegistrationHistoryEntry.track_changes(
          lti_registration: registration,
          current_user: user,
          context:
        ) do
          # Simulate direct database update that bypasses ActiveRecord callbacks/caching
          Lti::Registration.where(id: registration.id).update_all(name: "Externally Updated")
        end

        history_entry = Lti::RegistrationHistoryEntry.last
        expect(history_entry.diff["registration"]).to include(
          ["~", ["name"], original_name, "Externally Updated"]
        )

        expect(history_entry.old_configuration["registration"]["name"]).to eq(original_name)
        expect(history_entry.new_configuration["registration"]["name"]).to eq("Externally Updated")
      end

      it "validates required parameters" do
        expect do
          Lti::RegistrationHistoryEntry.track_changes(
            lti_registration: nil,
            current_user: user,
            context:
          ) do
            # No-op
          end
        end.to raise_error(ArgumentError)

        expect do
          Lti::RegistrationHistoryEntry.track_changes(
            lti_registration: registration,
            current_user: nil,
            context:
          ) do
            # No-op
          end
        end.to raise_error(ArgumentError)
      end
    end
  end
end
