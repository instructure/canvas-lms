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

require "hashdiff"

RSpec.describe DataFixup::Lti::BackfillLtiRegistrationHistoryEntryStateColumns do
  subject { described_class.run }

  let_once(:root_account) { account_model }
  let_once(:user) { user_model }
  let_once(:registration) { lti_registration_with_tool(account: root_account, created_by: user) }

  describe "#run" do
    context "with registration attribute changes" do
      it "stores an accurate snapshot" do
        entry = Lti::RegistrationHistoryEntry.create!(
          lti_registration: registration,
          root_account:,
          created_by: user,
          update_type: "manual_edit",
          diff: {
            registration: [
              ["~", ["admin_nickname"], "Old Name", "New Name"]
            ]
          }
        )

        # Get to the appropriate final state
        registration.update!(admin_nickname: "New Name")

        subject

        entry.reload
        expect(entry.old_configuration["registration"]).to eq(
          {
            "admin_nickname" => "Old Name",
            "name" => registration.name,
            "vendor" => registration.vendor,
            "workflow_state" => registration.workflow_state,
            "description" => registration.description
          }
        )
        expect(entry.new_configuration["registration"]).to eq(
          {
            "admin_nickname" => "New Name",
            "name" => registration.name,
            "vendor" => registration.vendor,
            "workflow_state" => registration.workflow_state,
            "description" => registration.description
          }
        )

        expect(entry.old_configuration["internal_config"]).to eq(entry.new_configuration["internal_config"])
        expect(entry.old_configuration["developer_key"]).to eq(entry.new_configuration["developer_key"])
        expect(entry.old_configuration["overlay"]).to eq(entry.new_configuration["overlay"])
      end
    end

    context "with developer key attribute changes" do
      it "stores an accurate snapshot" do
        entry = Lti::RegistrationHistoryEntry.create!(
          lti_registration: registration,
          root_account:,
          created_by: user,
          update_type: "manual_edit",
          diff: {
            developer_key: [
              ["~", ["name"], "Old Key Name", "New Key Name"]
            ]
          }
        )

        registration.developer_key.update!(name: "New Key Name")

        subject

        entry.reload
        expect(entry.old_configuration["developer_key"]["name"]).to eq("Old Key Name")
        expect(entry.new_configuration["developer_key"]["name"]).to eq("New Key Name")

        expect(
          entry.old_configuration.except("developer_key")
        ).to eq(entry.new_configuration.except("developer_key"))
      end
    end

    context "with overlay attribute changes" do
      let_once(:overlay) do
        lti_overlay_model(
          registration:,
          account: root_account,
          data: { title: "New Title", privacy_level: "public" }
        )
      end

      it "stores an accurate snapshot" do
        entry = Lti::RegistrationHistoryEntry.create!(
          lti_registration: registration,
          root_account:,
          created_by: user,
          update_type: "manual_edit",
          diff: {
            overlay: [
              ["~", ["title"], "Old Title", "New Title"]
            ]
          }
        )

        subject

        entry.reload
        expect(entry.old_configuration["overlay"]["title"]).to eq("Old Title")
        expect(entry.new_configuration["overlay"]["title"]).to eq("New Title")
        expect(entry.old_configuration["overlaid_internal_config"]["title"]).to eq("Old Title")
        expect(entry.new_configuration["overlaid_internal_config"]["title"]).to eq("New Title")

        expect(entry.old_configuration.except("overlay", "overlaid_internal_config"))
          .to eq(entry.new_configuration.except("overlay", "overlaid_internal_config"))
      end
    end

    context "with internal_lti_configuration changes" do
      it "stores an accurate snapshot" do
        tool_config = registration.manual_configuration

        tool_config.update!(title: "New Config Title")

        entry = Lti::RegistrationHistoryEntry.create!(
          lti_registration: registration,
          root_account:,
          created_by: user,
          update_type: "manual_edit",
          diff: {
            internal_lti_configuration: [
              ["~", ["title"], "Old Config Title", "New Config Title"]
            ]
          }
        )

        subject

        entry.reload
        expect(entry.old_configuration["internal_config"]["title"]).to eq("Old Config Title")
        expect(entry.new_configuration["internal_config"]["title"]).to eq("New Config Title")
        expect(entry.old_configuration["overlaid_internal_config"]["title"]).to eq("Old Config Title")
        expect(entry.new_configuration["overlaid_internal_config"]["title"]).to eq("New Config Title")

        expect(entry.old_configuration.except("internal_config", "overlaid_internal_config"))
          .to eq(entry.new_configuration.except("internal_config", "overlaid_internal_config"))
      end
    end

    context "with context_controls changes" do
      let_once(:course) { course_model(account: root_account) }
      let_once(:deployment) { registration.new_external_tool(course) }
      let_once(:context_control) do
        Lti::ContextControl.nearest_control_for_registration(course, registration, deployment)
      end
      let_once(:root_control) do
        Lti::ContextControl.find_by(account: root_account, registration:)
      end

      it "backfills old and new context_controls state columns" do
        control_id = context_control.id

        # Update the control to have the new state
        context_control.update!(available: true)

        # Entry for our personal deployment
        new_entry = Lti::RegistrationHistoryEntry.create!(
          lti_registration: registration,
          root_account:,
          created_by: user,
          update_type: "control_edit",
          diff: {
            context_controls: [
              ["~", [control_id, "available"], false, true]
            ]
          }
        )
        # This was the original entry created when the tool was first deployed by lti_registration_with_tool
        original_entry = registration.lti_registration_history_entries.first

        subject

        new_entry.reload
        original_entry.reload
        expect(new_entry.old_context_controls[control_id.to_s]["available"]).to be(false)
        expect(new_entry.new_context_controls[control_id.to_s]["available"]).to be(true)
        expect(new_entry.new_context_controls.length).to be(1)

        expect(original_entry.old_context_controls).to be_empty
        expect(original_entry.new_context_controls.length).to be(1)
        expect(original_entry.new_context_controls[root_control.id.to_s]["available"]).to be(false)
      end

      it "only stores changed context controls across multiple sequential changes" do
        course1 = course_model(account: root_account)
        course2 = course_model(account: root_account)
        course3 = course_model(account: root_account)

        deployment1 = registration.new_external_tool(course1)
        deployment2 = registration.new_external_tool(course2)
        deployment3 = registration.new_external_tool(course3)

        control1 = Lti::ContextControl.nearest_control_for_registration(course1, registration, deployment1)
        control2 = Lti::ContextControl.nearest_control_for_registration(course2, registration, deployment2)
        control3 = Lti::ContextControl.nearest_control_for_registration(course3, registration, deployment3)

        control1.update!(available: true)
        control2.update!(available: true)
        control3.update!(available: true)

        entry1 = Lti::RegistrationHistoryEntry.create!(
          lti_registration: registration,
          root_account:,
          created_by: user,
          update_type: "control_edit",
          diff: {
            context_controls: [
              ["~", [control1.id, "available"], false, true]
            ]
          },
          updated_at: 3.minutes.ago
        )

        entry2 = Lti::RegistrationHistoryEntry.create!(
          lti_registration: registration,
          root_account:,
          created_by: user,
          update_type: "control_edit",
          diff: {
            context_controls: [
              ["~", [control2.id, "available"], false, true]
            ]
          },
          updated_at: 2.minutes.ago
        )

        entry3 = Lti::RegistrationHistoryEntry.create!(
          lti_registration: registration,
          root_account:,
          created_by: user,
          update_type: "control_edit",
          diff: {
            context_controls: [
              ["~", [control3.id, "available"], false, true]
            ]
          },
          updated_at: 1.minute.ago
        )

        subject

        entry1.reload
        expect(entry1.old_context_controls.keys).to contain_exactly(control1.id.to_s)
        expect(entry1.new_context_controls.keys).to contain_exactly(control1.id.to_s)
        expect(entry1.old_context_controls[control1.id.to_s]["available"]).to be(false)
        expect(entry1.new_context_controls[control1.id.to_s]["available"]).to be(true)

        entry2.reload
        expect(entry2.old_context_controls.keys).to contain_exactly(control2.id.to_s)
        expect(entry2.new_context_controls.keys).to contain_exactly(control2.id.to_s)
        expect(entry2.old_context_controls[control2.id.to_s]["available"]).to be(false)
        expect(entry2.new_context_controls[control2.id.to_s]["available"]).to be(true)

        entry3.reload
        expect(entry3.old_context_controls.keys).to contain_exactly(control3.id.to_s)
        expect(entry3.new_context_controls.keys).to contain_exactly(control3.id.to_s)
        expect(entry3.old_context_controls[control3.id.to_s]["available"]).to be(false)
        expect(entry3.new_context_controls[control3.id.to_s]["available"]).to be(true)
      end
    end

    context "with multiple sequential changes" do
      it "correctly reconstructs history by walking backward in time" do
        # Create three sequential changes to admin_nickname
        # Starting state: "Original"
        # Change 1 (3 min ago, oldest): "Original" -> "First Change"
        # Change 2 (2 min ago): "First Change" -> "Second Change"
        # Change 3 (1 min ago, newest): "Second Change" -> "Final Change"

        registration.update!(admin_nickname: "Final Change")

        entry1 = Lti::RegistrationHistoryEntry.create!(
          lti_registration: registration,
          root_account:,
          created_by: user,
          update_type: "manual_edit",
          diff: {
            registration: [
              ["~", ["admin_nickname"], "Original", "First Change"]
            ]
          },
          updated_at: 3.minutes.ago
        )

        entry2 = Lti::RegistrationHistoryEntry.create!(
          lti_registration: registration,
          root_account:,
          created_by: user,
          update_type: "manual_edit",
          diff: {
            registration: [
              ["~", ["admin_nickname"], "First Change", "Second Change"]
            ]
          },
          updated_at: 2.minutes.ago
        )

        entry3 = Lti::RegistrationHistoryEntry.create!(
          lti_registration: registration,
          root_account:,
          created_by: user,
          update_type: "manual_edit",
          diff: {
            registration: [
              ["~", ["admin_nickname"], "Second Change", "Final Change"]
            ]
          },
          updated_at: 1.minute.ago
        )

        subject

        # Verify each entry has the correct old and new states
        entry1.reload
        expect(entry1.old_configuration["registration"]["admin_nickname"]).to eq("Original")
        expect(entry1.new_configuration["registration"]["admin_nickname"]).to eq("First Change")

        entry2.reload
        expect(entry2.old_configuration["registration"]["admin_nickname"]).to eq("First Change")
        expect(entry2.new_configuration["registration"]["admin_nickname"]).to eq("Second Change")

        entry3.reload
        expect(entry3.old_configuration["registration"]["admin_nickname"]).to eq("Second Change")
        expect(entry3.new_configuration["registration"]["admin_nickname"]).to eq("Final Change")
      end
    end

    context "with multiple attribute types changed in single entry" do
      it "backfills all changed attribute state columns" do
        entry = Lti::RegistrationHistoryEntry.create!(
          lti_registration: registration,
          root_account:,
          created_by: user,
          update_type: "manual_edit",
          diff: {
            registration: [
              ["~", ["admin_nickname"], "Old Name", "New Name"]
            ],
            developer_key: [
              ["~", ["name"], "Old Key", "New Key"]
            ]
          }
        )

        registration.update!(admin_nickname: "New Name")
        registration.developer_key.update!(name: "New Key")

        subject

        entry.reload

        expect(entry.old_configuration["registration"]["admin_nickname"]).to eq("Old Name")
        expect(entry.new_configuration["registration"]["admin_nickname"]).to eq("New Name")
        expect(entry.old_configuration["developer_key"]["name"]).to eq("Old Key")
        expect(entry.new_configuration["developer_key"]["name"]).to eq("New Key")
      end
    end

    context "with multiple root accounts" do
      let_once(:root_account2) { account_model }
      let_once(:overlay1) do
        lti_overlay_model(
          registration:,
          account: root_account,
          data: { title: "Account 1 New Title" }
        )
      end
      let_once(:overlay2) do
        lti_overlay_model(
          registration:,
          account: root_account2,
          data: { title: "Account 2 New Title" }
        )
      end

      it "correctly tracks state per root account" do
        entry1 = Lti::RegistrationHistoryEntry.create!(
          lti_registration: registration,
          root_account:,
          created_by: user,
          update_type: "manual_edit",
          diff: {
            overlay: [
              ["~", ["title"], "Account 1 Old Title", "Account 1 New Title"]
            ]
          }
        )

        entry2 = Lti::RegistrationHistoryEntry.create!(
          lti_registration: registration,
          root_account: root_account2,
          created_by: user,
          update_type: "manual_edit",
          diff: {
            overlay: [
              ["~", ["title"], "Account 2 Old Title", "Account 2 New Title"]
            ]
          }
        )

        subject

        entry1.reload
        entry2.reload

        expect(entry1.old_configuration["overlay"]["title"]).to eq("Account 1 Old Title")
        expect(entry1.new_configuration["overlay"]["title"]).to eq("Account 1 New Title")

        expect(entry2.old_configuration["overlay"]["title"]).to eq("Account 2 Old Title")
        expect(entry2.new_configuration["overlay"]["title"]).to eq("Account 2 New Title")
      end
    end

    context "with cross-shard site admin registration" do
      specs_require_sharding

      it "backfills history entries on different shard from site admin registration" do
        # Create a site admin registration on the default shard
        site_admin_registration = nil
        site_admin_user = nil
        Shard.default.activate do
          site_admin_user = user_model
          site_admin_registration = lti_registration_with_tool(
            account: Account.site_admin,
            created_by: site_admin_user
          )
        end

        # Create a root account and user on shard2
        shard2_root_account = @shard2.activate { account_model }
        shard2_user = @shard2.activate { user_model }

        # Create history entries on shard2 for the site admin registration
        entry1 = nil
        entry2 = nil
        @shard2.activate do
          entry1 = Lti::RegistrationHistoryEntry.create!(
            lti_registration: site_admin_registration,
            root_account: shard2_root_account,
            created_by: shard2_user,
            update_type: "manual_edit",
            diff: {
              overlay: [
                ["~", ["title"], "Old Name", "Middle Name"]
              ]
            }
          )
          Lti::Overlay.create!(registration: site_admin_registration, account: shard2_root_account, updated_by: shard2_user, data: {
                                 "title" => "Middle Name"
                               })

          # Test interplay between already backfilled and non-backfilled history entries
          Lti::UpdateRegistrationService.call(id: site_admin_registration.id, account: shard2_root_account, updated_by: shard2_user, overlay_params: {
                                                title: "New Name"
                                              })
          entry2 = Lti::RegistrationHistoryEntry.last
        end

        @shard2.activate do
          subject
          entry1.reload
          entry2.reload

          expect(entry1.old_configuration["overlay"]["title"]).to eq("Old Name")
          expect(entry1.new_configuration["overlay"]["title"]).to eq("Middle Name")

          expect(entry2.old_configuration["overlay"]["title"]).to eq("Middle Name")
          expect(entry2.new_configuration["overlay"]["title"]).to eq("New Name")
        end
      end
    end

    context "with array additions and removals in overlay" do
      let_once(:scope1) { "https://purl.imsglobal.org/spec/lti-ags/scope/lineitem" }
      let_once(:scope2) { "https://purl.imsglobal.org/spec/lti-ags/scope/lineitem.readonly" }
      let_once(:scope3) { "https://purl.imsglobal.org/spec/lti-ags/scope/result.readonly" }

      let_once(:overlay) do
        lti_overlay_model(
          registration:,
          account: root_account,
          data: { disabled_scopes: [scope2, scope3] }
        )
      end

      it "correctly handles array diffs" do
        entry = Lti::RegistrationHistoryEntry.create!(
          lti_registration: registration,
          root_account:,
          created_by: user,
          update_type: "manual_edit",
          diff: {
            overlay: [
              ["+", ["disabled_scopes", 1], scope2],
              ["+", ["disabled_scopes", 2], scope3],
              ["-", ["disabled_scopes", 0], scope1]
            ]
          }
        )

        subject

        entry.reload
        expect(entry.old_configuration["overlay"]["disabled_scopes"]).to eq([scope1])
        expect(entry.new_configuration["overlay"]["disabled_scopes"]).to eq([scope2, scope3])
      end
    end

    context "with entries with a useless diff column column" do
      it "doesn't backfill them or use them in it's calculations" do
        useless_entry = Lti::RegistrationHistoryEntry.create!(
          lti_registration: registration,
          root_account:,
          created_by: user,
          update_type: "bulk_control_create",
          diff: { "context_controls" => [] }
        )

        registration.update!(admin_nickname: "New Name")
        useful_entry = Lti::RegistrationHistoryEntry.create!(
          lti_registration: registration,
          root_account:,
          created_by: user,
          update_type: "manual_edit",
          diff: {
            registration: [
              ["~", ["admin_nickname"], "Old Name", "New Name"]
            ]
          }
        )

        subject

        expect(
          useless_entry.reload.attributes
          .slice("old_configuration", "new_configuration", "old_context_controls", "new_context_controls")
          .compact
        )
          .to be_empty

        expect(useful_entry.reload.new_configuration["registration"]).to eq(registration.current_tracked_attributes)

        expect(useful_entry.old_configuration["registration"])
          .to eq(registration.current_tracked_attributes
            .merge({
                     admin_nickname: "Old Name"
                   }))
      end
    end

    context "with an entry for creating an overlay" do
      it "backfills properly" do
        Lti::RegistrationHistoryEntry.track_changes(lti_registration: registration, current_user: user, context: root_account) do
          # Much easier to create the entry the way we normally would and just make sure the backfill
          # gets us back into the same state.
          Lti::Overlay.create!(
            registration:,
            account: root_account,
            updated_by: user,
            data: {
              title: "foo bar baz",
              disabled_placements: ["course_navigation", "account_navigation"]
            }
          )
        end

        entry = Lti::RegistrationHistoryEntry.last

        old_config = entry.old_configuration
        new_config = entry.new_configuration

        entry.update!(old_configuration: nil, new_configuration: nil)

        subject
        entry.reload

        expect(entry.old_configuration).to eql(old_config)
        expect(entry.new_configuration).to eql(new_config)
      end
    end

    context "with already backfilled entries" do
      it "ignores them" do
        entry = Lti::RegistrationHistoryEntry.create!(
          lti_registration: registration,
          root_account:,
          created_by: user,
          update_type: "manual_edit",
          diff: {
            registration: [
              ["~", ["admin_nickname"], "Old Name", "New Name"]
            ]
          },
          old_configuration: { "internal_config" => registration.internal_lti_configuration(include_overlay: false) },
          new_configuration: { "internal_config" => registration.internal_lti_configuration(include_overlay: false) }
        )

        registration.update!(admin_nickname: "New Name")

        expect { subject }.not_to change { entry.reload }
      end

      it "can backfill non-backfilled entry by walking back through already backfilled entry" do
        registration.update!(admin_nickname: "Initial Name")

        older_entry = Timecop.freeze(2.days.ago) do
          old = Lti::RegistrationHistoryEntry.create!(
            lti_registration: registration,
            root_account:,
            created_by: user,
            update_type: "manual_edit",
            diff: {
              registration: [
                ["~", ["admin_nickname"], "Initial Name", "Middle Name"]
              ]
            },
            updated_at: 2.days.ago
          )
          # Get to the intermediate state so we record things properly
          registration.update!(admin_nickname: "Middle Name")
          old
        end

        Timecop.freeze(1.day.from_now) do
          Lti::UpdateRegistrationService.call(
            id: registration.id,
            account: root_account,
            updated_by: user,
            registration_params: { admin_nickname: "Final Name" }
          )
        end

        # Set registration to final state
        registration.update!(admin_nickname: "Final Name")

        expect { subject }
          .to change {
                older_entry.reload
                           .old_configuration&.[]("registration")&.[]("admin_nickname")
              }
          .from(nil).to("Initial Name")
                    .and change {
                           older_entry.reload
                                      .new_configuration&.[]("registration")&.[]("admin_nickname")
                         }
          .from(nil).to("Middle Name")
      end
    end
  end
end
