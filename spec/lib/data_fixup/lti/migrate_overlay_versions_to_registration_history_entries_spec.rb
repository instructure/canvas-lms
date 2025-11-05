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

RSpec.describe DataFixup::Lti::MigrateOverlayVersionsToRegistrationHistoryEntries do
  subject { described_class.run }

  let_once(:root_account) { account_model }
  let_once(:sub_account) { account_model(parent_account: root_account) }
  let_once(:user) { user_model }
  let_once(:registration) { lti_registration_model(account: root_account) }
  let_once(:overlay) do
    lti_overlay_model(registration:, account: root_account, updated_by: user, data:)
  end
  let(:data) do
    {
      title: "Old Title",
      privacy_level: "public",
      custom_fields: {},
      placements: { course_navigation: { enabled: true, text: "LTI Link", default: "disabled" } },
      disabled_scopes: [TokenScopes::LTI_AGS_LINE_ITEM_READ_ONLY_SCOPE],
    }.with_indifferent_access.freeze
  end

  describe "#run" do
    it "migrates overlay versions from root accounts" do
      Timecop.freeze(Time.utc(2025, 9, 20)) do
        new_data = data.deep_dup.tap do |d|
          d["placements"]["course_navigation"]["default"] = "enabled"
          d["title"] = "New Title"
          d["custom_fields"]["test_field"] = "test_value"
          d["disabled_placements"] = ["account_navigation"]
          d["disabled_scopes"] << TokenScopes::LTI_ASSET_READ_ONLY_SCOPE
        end

        # Ensure we can actually handle real Hashdiff data, not just what
        # we think it looks like.
        overlay.update!(data: new_data)

        expect { subject }.to change(Lti::RegistrationHistoryEntry, :count).by(1)

        history_entry = Lti::RegistrationHistoryEntry.last
        expect(history_entry.lti_registration).to eq(registration)
        expect(history_entry.root_account).to eq(root_account)
        expect(history_entry.created_by).to eq(user)
        expect(history_entry.update_type).to eq("manual_edit")

        # Check that the diff has been converted to array paths and wrapped in overlay key
        expected_diff = [
          ["+", ["disabled_scopes", 1], TokenScopes::LTI_ASSET_READ_ONLY_SCOPE],
          ["+", ["disabled_placements"], ["account_navigation"]],
          ["+", ["custom_fields", "test_field"], "test_value"],
          ["~", ["title"], "Old Title", "New Title"],
          ["~", %w[placements course_navigation default], "disabled", "enabled"]
        ]
        expect(history_entry.diff["overlay"]).to match_array(expected_diff)
      end
    end

    it "skips overlay versions from sub-accounts" do
      Lti::OverlayVersion.create!(
        account: sub_account,
        lti_overlay: overlay,
        created_by: user,
        diff: [["+", "test", "value"]]
      )

      expect { subject }.not_to change(Lti::RegistrationHistoryEntry, :count)
    end

    it "handles errors gracefully when overlay registration lookup fails" do
      Lti::OverlayVersion.create!(
        account: root_account,
        lti_overlay: overlay,
        created_by: user,
        diff: [["+", "test", "value"]]
      )

      # Stub the overlay to return nil registration to simulate lookup failure
      allow_any_instance_of(Lti::Overlay).to receive(:registration).and_return(nil)

      expect { subject }.not_to change(Lti::RegistrationHistoryEntry, :count)
    end

    it "preserves timestamps from original overlay version" do
      Timecop.freeze(Time.utc(2025, 9, 20)) do
        created_time = 1.week.ago
        updated_time = 3.days.ago

        Lti::OverlayVersion.create!(
          account: root_account,
          lti_overlay: overlay,
          created_by: user,
          diff: [["+", "test", "value"]],
          created_at: created_time,
          updated_at: updated_time
        )

        subject

        history_entry = Lti::RegistrationHistoryEntry.last
        expect(history_entry.created_at).to be_within(1.second).of(created_time)
        expect(history_entry.updated_at).to be_within(1.second).of(updated_time)
      end
    end
  end

  describe "#convert_path_string_to_array" do
    it "converts simple dot notation" do
      result = described_class.convert_path_string_to_array("foo.bar.baz")
      expect(result).to eq(%w[foo bar baz])
    end

    it "converts array indices" do
      result = described_class.convert_path_string_to_array("foo.bar[0].baz")
      expect(result).to eq(["foo", "bar", 0, "baz"])
    end

    it "converts multiple array indices" do
      result = described_class.convert_path_string_to_array("foo[1].bar[2].baz")
      expect(result).to eq(["foo", 1, "bar", 2, "baz"])
    end

    it "handles complex nested paths" do
      result = described_class.convert_path_string_to_array("placements.course_navigation[0].enabled")
      expect(result).to eq(["placements", "course_navigation", 0, "enabled"])
    end

    it "handles empty string" do
      result = described_class.convert_path_string_to_array("")
      expect(result).to eq([])
    end

    it "handles non-string input" do
      result = described_class.convert_path_string_to_array(["already", "array"])
      expect(result).to eq(["already", "array"])
    end
  end

  describe "#convert_diff_paths" do
    it "converts diff operations with string paths" do
      diff = [
        ["+", "foo.bar[0].baz", "value"],
        ["~", "title", "old", "new"],
        ["-", "enabled", true]
      ]

      result = described_class.convert_diff_paths(diff)

      expect(result).to eq([
                             ["+", ["foo", "bar", 0, "baz"], "value"],
                             ["~", ["title"], "old", "new"],
                             ["-", ["enabled"], true]
                           ])
    end

    it "handles non-array input" do
      result = described_class.convert_diff_paths("not an array")
      expect(result).to eq("not an array")
    end
  end
end
