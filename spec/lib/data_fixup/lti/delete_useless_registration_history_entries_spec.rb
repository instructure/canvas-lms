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

RSpec.describe DataFixup::Lti::DeleteUselessRegistrationHistoryEntries do
  subject { described_class.run }

  let_once(:root_account) { account_model }
  let_once(:user) { user_model }
  let_once(:registration) { lti_registration_model(account: root_account) }

  describe "#run" do
    it "deletes entries with diff = {context_controls: []}" do
      useless_entry = lti_registration_history_entry_model(
        lti_registration: registration,
        root_account:,
        created_by: user,
        diff: { context_controls: [] },
        update_type: "control_edit"
      )

      expect { subject }.to change(Lti::RegistrationHistoryEntry, :count).by(-1)
      expect { useless_entry.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "preserves entries with non-empty diff containing registration changes" do
      entry_with_data = lti_registration_history_entry_model(
        lti_registration: registration,
        root_account:,
        created_by: user,
        diff: { registration: [["+", ["name"], "New Name"]] },
        update_type: "manual_edit"
      )

      expect { subject }.not_to change(Lti::RegistrationHistoryEntry, :count)
      expect { entry_with_data.reload }.not_to raise_error
    end

    it "preserves entries with non-empty diff containing internal_lti_configuration changes" do
      entry_with_config = lti_registration_history_entry_model(
        lti_registration: registration,
        root_account:,
        created_by: user,
        diff: { internal_lti_configuration: [["~", ["title"], "Old Title", "New Title"]] },
        update_type: "manual_edit"
      )

      expect { subject }.not_to change(Lti::RegistrationHistoryEntry, :count)
      expect { entry_with_config.reload }.not_to raise_error
    end

    it "preserves entries with non-empty diff containing developer_key changes" do
      entry_with_key = lti_registration_history_entry_model(
        lti_registration: registration,
        root_account:,
        created_by: user,
        diff: { developer_key: [["-", ["scopes"], ["url:GET|/api/v1/accounts"]]] },
        update_type: "manual_edit"
      )

      expect { subject }.not_to change(Lti::RegistrationHistoryEntry, :count)
      expect { entry_with_key.reload }.not_to raise_error
    end

    it "preserves entries with non-empty diff containing overlay changes" do
      entry_with_overlay = lti_registration_history_entry_model(
        lti_registration: registration,
        root_account:,
        created_by: user,
        diff: { overlay: [["+", ["custom_fields", "field1"], "value1"]] },
        update_type: "manual_edit"
      )

      expect { subject }.not_to change(Lti::RegistrationHistoryEntry, :count)
      expect { entry_with_overlay.reload }.not_to raise_error
    end

    it "preserves entries with non-empty diff containing context_controls changes" do
      entry_with_controls = lti_registration_history_entry_model(
        lti_registration: registration,
        root_account:,
        created_by: user,
        diff: { context_controls: [["+", [123, "visible"], true]] },
        update_type: "control_edit"
      )

      expect { subject }.not_to change(Lti::RegistrationHistoryEntry, :count)
      expect { entry_with_controls.reload }.not_to raise_error
    end

    it "preserves entries with multiple keys in diff" do
      entry_with_multiple = lti_registration_history_entry_model(
        lti_registration: registration,
        root_account:,
        created_by: user,
        diff: {
          registration: [["+", ["name"], "New Name"]],
          overlay: [["+", ["custom_fields", "field1"], "value1"]]
        },
        update_type: "manual_edit"
      )

      expect { subject }.not_to change(Lti::RegistrationHistoryEntry, :count)
      expect { entry_with_multiple.reload }.not_to raise_error
    end

    it "deletes multiple entries with diff = {context_controls: []}" do
      3.times do
        lti_registration_history_entry_model(
          lti_registration: registration,
          root_account:,
          created_by: user,
          diff: { context_controls: [] },
          update_type: "control_edit"
        )
      end

      expect { subject }.to change(Lti::RegistrationHistoryEntry, :count).by(-3)
    end

    it "handles mixed entries correctly" do
      useless1 = lti_registration_history_entry_model(
        lti_registration: registration,
        root_account:,
        created_by: user,
        diff: { context_controls: [] },
        update_type: "control_edit"
      )

      useless2 = lti_registration_history_entry_model(
        lti_registration: registration,
        root_account:,
        created_by: user,
        diff: { context_controls: [] },
        update_type: "control_edit"
      )

      valid1 = lti_registration_history_entry_model(
        lti_registration: registration,
        root_account:,
        created_by: user,
        diff: { registration: [["+", ["name"], "Name"]] },
        update_type: "manual_edit"
      )
      valid2 = lti_registration_history_entry_model(
        lti_registration: registration,
        root_account:,
        created_by: user,
        diff: { overlay: [["+", ["field"], "value"]] },
        update_type: "manual_edit"
      )

      expect { subject }.to change(Lti::RegistrationHistoryEntry, :count).by(-2)

      expect { useless1.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { useless2.reload }.to raise_error(ActiveRecord::RecordNotFound)

      expect { valid1.reload }.not_to raise_error
      expect { valid2.reload }.not_to raise_error
    end

    it "handles entries across multiple registrations" do
      other_registration = lti_registration_model(account: root_account)

      useless1 = lti_registration_history_entry_model(
        lti_registration: registration,
        root_account:,
        created_by: user,
        diff: { context_controls: [] },
        update_type: "control_edit"
      )

      useless2 = lti_registration_history_entry_model(
        lti_registration: other_registration,
        root_account:,
        created_by: user,
        diff: { context_controls: [] },
        update_type: "control_edit"
      )
      valid = lti_registration_history_entry_model(
        lti_registration: other_registration,
        root_account:,
        created_by: user,
        diff: { registration: [["+", ["name"], "Name"]] },
        update_type: "manual_edit"
      )

      expect { subject }.to change(Lti::RegistrationHistoryEntry, :count).by(-2)

      expect { useless1.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { useless2.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { valid.reload }.not_to raise_error
    end

    it "handles entries with nil created_by" do
      useless_entry = Lti::RegistrationHistoryEntry.create!(
        lti_registration: registration,
        root_account:,
        created_by: nil,
        diff: { context_controls: [] },
        update_type: "control_edit"
      )

      expect { subject }.to change(Lti::RegistrationHistoryEntry, :count).by(-1)
      expect { useless_entry.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "reports errors to Sentry with batch IDs when deletion fails" do
      entries = Array.new(3) do
        lti_registration_history_entry_model(
          lti_registration: registration,
          root_account:,
          created_by: user,
          diff: { context_controls: [] },
          update_type: "control_edit"
        )
      end

      entry_ids = entries.map(&:id)

      error_relation = Lti::RegistrationHistoryEntry.where(id: entry_ids)
      allow(Lti::RegistrationHistoryEntry).to receive(:where).with("diff = '{\"context_controls\": []}'::jsonb")
                                                             .and_return(error_relation)

      allow(error_relation).to receive(:delete_all).and_raise(StandardError.new("Database error"))

      expect(Sentry).to receive(:with_scope).and_yield(instance_double(Sentry::Scope).tap do |scope|
        expect(scope).to receive(:set_context).with(
          "DataFixup::Lti::DeleteUselessRegistrationHistoryEntries",
          hash_including(
            batch_ids: match_array(entry_ids)
          )
        )
      end)
      expect(Sentry).to receive(:capture_exception).with(instance_of(StandardError))

      subject

      entries.each do |entry|
        expect { entry.reload }.not_to raise_error
      end
    end
  end
end
