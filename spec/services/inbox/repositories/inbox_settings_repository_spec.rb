# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

describe Inbox::Repositories::InboxSettingsRepository do
  let(:user) { user_model }
  let(:user_id) { user.id.to_s }
  let(:new_user_id) { "99999" }
  let(:account) { account_model }
  let(:root_account_id) { account.id }
  let(:inbox_settings_repo) { Inbox::Repositories::InboxSettingsRepository }
  let(:inbox_settings_entity) { Inbox::Entities::InboxSettings }
  let(:inbox_settings_record) { Inbox::Repositories::InboxSettingsRepository::InboxSettingsRecord }

  # exclude record timestamps from comparison
  def expect_entities_equal(ent_a, ent_b)
    expect(ent_a.id).to eq ent_b.id
    expect(ent_a.user_id).to eq ent_b.user_id
    expect(ent_a.root_account_id).to eq ent_b.root_account_id
    expect(ent_a.use_signature).to eq ent_b.use_signature
    expect(ent_a.signature).to eq ent_b.signature
    expect(ent_a.use_out_of_office).to eq ent_b.use_out_of_office
    expect(ent_a.out_of_office_first_date).to eq ent_b.out_of_office_first_date
    expect(ent_a.out_of_office_last_date).to eq ent_b.out_of_office_last_date
    expect(ent_a.out_of_office_subject).to eq ent_b.out_of_office_subject
    expect(ent_a.out_of_office_message).to eq ent_b.out_of_office_message
  end

  def inbox_settings_entity_for_user(
    id:,
    user_id:,
    root_account_id:,
    use_signature: false,
    signature: nil,
    use_out_of_office: false,
    out_of_office_first_date: nil,
    out_of_office_last_date: nil,
    out_of_office_subject: nil,
    out_of_office_message: nil
  )
    inbox_settings_entity.new(
      id:,
      user_id:,
      root_account_id:,
      use_signature:,
      signature:,
      use_out_of_office:,
      out_of_office_first_date:,
      out_of_office_last_date:,
      out_of_office_subject:,
      out_of_office_message:
    )
  end

  describe ".get_inbox_settings" do
    context "when there are no inbox settings for user" do
      it "returns nil" do
        expect(inbox_settings_repo.get_inbox_settings(user_id:, root_account_id:)).to be_nil
      end
    end

    context "when there are inbox settings for user" do
      before do
        inbox_settings_record.new(user_id:, root_account_id:).save!
      end

      it "returns inbox settings" do
        record_id = inbox_settings_record.find_by(user_id:, root_account_id:).id
        inbox_settings_for_user = inbox_settings_repo.get_inbox_settings(user_id:, root_account_id:)
        expect_entities_equal(inbox_settings_for_user, inbox_settings_entity_for_user(id: record_id, user_id:, root_account_id:))
      end
    end
  end

  describe ".update_inbox_settings" do
    context "when there are no inbox settings for user" do
      it "creates new record with default values" do
        new_user_inbox_settings = inbox_settings_repo.save_inbox_settings(
          user_id: new_user_id,
          root_account_id:,
          use_signature: false,
          signature: nil,
          use_out_of_office: false,
          out_of_office_first_date: nil,
          out_of_office_last_date: nil,
          out_of_office_subject: nil,
          out_of_office_message: nil
        )
        inbox_settings_with_default_values = inbox_settings_entity.new(id: new_user_inbox_settings.id, user_id: new_user_id, root_account_id:)
        expect_entities_equal(new_user_inbox_settings, inbox_settings_with_default_values)
      end
    end

    context "when there are inbox settings for user" do
      before do
        inbox_settings_record.new(user_id:, root_account_id:).save!
      end

      it "updates record" do
        updated_user_inbox_settings = inbox_settings_repo.save_inbox_settings(
          user_id:,
          root_account_id:,
          use_signature: true,
          signature: "John Doe",
          use_out_of_office: false,
          out_of_office_first_date: nil,
          out_of_office_last_date: nil,
          out_of_office_subject: nil,
          out_of_office_message: nil
        )
        expect_entities_equal(updated_user_inbox_settings, inbox_settings_entity_for_user(
                                                             id: updated_user_inbox_settings.id,
                                                             user_id:,
                                                             root_account_id:,
                                                             use_signature: true,
                                                             signature: "John Doe"
                                                           ))
      end
    end
  end

  describe ".get_users_out_of_office" do
    it "returns settings for user if they are out of office" do
      user_settings = inbox_settings_repo.save_inbox_settings(
        user_id:,
        root_account_id:,
        use_signature: true,
        signature: "John Doe",
        use_out_of_office: true,
        out_of_office_first_date: Time.zone.today,
        out_of_office_last_date: Time.zone.tomorrow,
        out_of_office_subject: "OOO",
        out_of_office_message: "Out of Office"
      )
      users_ooo = inbox_settings_repo.get_users_out_of_office(
        user_ids: [user_id],
        root_account_id:,
        date: Time.zone.today
      )
      expect_entities_equal(user_settings, users_ooo.first)
    end

    it "returns nothing is user is not out of office" do
      inbox_settings_repo.save_inbox_settings(
        user_id:,
        root_account_id:,
        use_signature: true,
        signature: "John Doe",
        use_out_of_office: false,
        out_of_office_first_date: Time.zone.today,
        out_of_office_last_date: Time.zone.tomorrow,
        out_of_office_subject: "OOO",
        out_of_office_message: "Out of Office"
      )
      users_ooo = inbox_settings_repo.get_users_out_of_office(
        user_ids: [user_id],
        root_account_id:,
        date: Time.zone.today
      )
      expect(users_ooo.empty?).to be_truthy
    end

    it "does not return users if current date is beyond OOO settings" do
      inbox_settings_repo.save_inbox_settings(
        user_id:,
        root_account_id:,
        use_signature: true,
        signature: "John Doe",
        use_out_of_office: true,
        out_of_office_first_date: Time.zone.today,
        out_of_office_last_date: Time.zone.tomorrow,
        out_of_office_subject: "OOO",
        out_of_office_message: "Out of Office"
      )

      # Move out of date range
      Timecop.travel(3.days) do
        users_ooo = inbox_settings_repo.get_users_out_of_office(
          user_ids: [user_id],
          root_account_id:,
          date: Time.zone.today
        )
        expect(users_ooo.empty?).to be_truthy
      end
    end
  end

  describe ".create_inbox_setting_ooo_snapshot" do
    it "hash snapshot is consistent" do
      inbox_settings_repo.save_inbox_settings(
        user_id:,
        root_account_id:,
        use_signature: true,
        signature: "John Doe",
        use_out_of_office: true,
        out_of_office_first_date: Time.zone.today,
        out_of_office_last_date: Time.zone.tomorrow,
        out_of_office_subject: "OOO",
        out_of_office_message: "Out of Office"
      )
      first_snapshot = inbox_settings_repo.create_inbox_settings_ooo_hash(user_id:, root_account_id:)
      second_snapshot = inbox_settings_repo.create_inbox_settings_ooo_hash(user_id:, root_account_id:)

      expect(first_snapshot == second_snapshot).to be_truthy
    end

    it "hash snapshot changes when editing relevant settings" do
      inbox_settings_repo.save_inbox_settings(
        user_id:,
        root_account_id:,
        use_signature: true,
        signature: "John Doe",
        use_out_of_office: true,
        out_of_office_first_date: Time.zone.today,
        out_of_office_last_date: Time.zone.tomorrow,
        out_of_office_subject: "OOO",
        out_of_office_message: "Out of Office"
      )
      first_snapshot = inbox_settings_repo.create_inbox_settings_ooo_hash(user_id:, root_account_id:)

      # Change a relevant field in the settings
      inbox_settings_repo.save_inbox_settings(
        user_id:,
        root_account_id:,
        use_signature: true,
        signature: "John Doe",
        use_out_of_office: true,
        out_of_office_first_date: Time.zone.today,
        out_of_office_last_date: Time.zone.tomorrow,
        out_of_office_subject: "OOO - Updated",
        out_of_office_message: "Out of Office"
      )
      second_snapshot = inbox_settings_repo.create_inbox_settings_ooo_hash(user_id:, root_account_id:)

      expect(first_snapshot != second_snapshot).to be_truthy
    end

    it "hash snapshot does not change when editing non-relevant settings" do
      inbox_settings_repo.save_inbox_settings(
        user_id:,
        root_account_id:,
        use_signature: true,
        signature: "John Doe",
        use_out_of_office: true,
        out_of_office_first_date: Time.zone.today,
        out_of_office_last_date: Time.zone.tomorrow,
        out_of_office_subject: "OOO",
        out_of_office_message: "Out of Office"
      )
      first_snapshot = inbox_settings_repo.create_inbox_settings_ooo_hash(user_id:, root_account_id:)

      # Change the signature (not relevant to OOO settings snapshot)
      inbox_settings_repo.save_inbox_settings(
        user_id:,
        root_account_id:,
        use_signature: true,
        signature: "New Person",
        use_out_of_office: true,
        out_of_office_first_date: Time.zone.today,
        out_of_office_last_date: Time.zone.tomorrow,
        out_of_office_subject: "OOO",
        out_of_office_message: "Out of Office"
      )
      second_snapshot = inbox_settings_repo.create_inbox_settings_ooo_hash(user_id:, root_account_id:)

      expect(first_snapshot == second_snapshot).to be_truthy
    end

    it "hash snapshot returns nil if settings are not present" do
      expect(inbox_settings_repo.create_inbox_settings_ooo_hash(user_id:, root_account_id:)).to be_nil
    end
  end
end
