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
  let(:account) { account_model }
  let(:root_account_id) { account.id }
  let(:inbox_settings_entity) { Inbox::Entities::InboxSettings }
  let(:inbox_settings_record) { Inbox::Repositories::InboxSettingsRepository::InboxSettingsRecord }

  def expect_objects_equal(obj_a, obj_b)
    # compare objects by serializing to json
    expect(obj_a.to_json).to eq(obj_b.to_json)
  end

  def inbox_settings_entity_for_user(user_id:, use_signature: false, signature: nil)
    {
      user_id:,
      use_signature:,
      signature:,
      use_out_of_office: false,
      out_of_office_first_date: nil,
      out_of_office_last_date: nil,
      out_of_office_subject: nil,
      out_of_office_message: nil
    }
  end

  describe ".inbox_settings" do
    context "when there are no inbox settings for user" do
      it "returns nil" do
        inbox_settings_repo = Inbox::Repositories::InboxSettingsRepository.new(user_id:, root_account_id:)
        expect(inbox_settings_repo.inbox_settings).to be_nil
      end
    end

    context "when there are inbox settings for user" do
      let(:inbox_settings_for_user) { Inbox::Entities::InboxSettings.new(user_id:) }

      before do
        record = Inbox::Repositories::InboxSettingsRepository::InboxSettingsRecord.new(user_id:, root_account_id:)
        record.save!
      end

      it "returns inbox settings" do
        expect_objects_equal(inbox_settings_for_user, inbox_settings_entity_for_user(user_id:))
      end
    end
  end

  describe ".save_inbox_settings" do
    context "when there are no inbox settings for user" do
      let(:inbox_settings_with_default_values) do
        Inbox::Entities::InboxSettings.new(user_id: "99999")
      end

      it "creates new record with default values" do
        inbox_settings_repo = Inbox::Repositories::InboxSettingsRepository.new(user_id: "99999", root_account_id:)
        new_user_inbox_settings = inbox_settings_repo.save_inbox_settings(
          use_signature: false,
          signature: nil,
          use_out_of_office: false,
          out_of_office_first_date: nil,
          out_of_office_last_date: nil,
          out_of_office_subject: nil,
          out_of_office_message: nil
        )
        expect_objects_equal(new_user_inbox_settings, inbox_settings_with_default_values)
      end
    end

    context "when there are inbox settings for user" do
      before do
        record = Inbox::Repositories::InboxSettingsRepository::InboxSettingsRecord.new(user_id:, root_account_id:)
        record.save!
      end

      it "updates record" do
        inbox_settings_repo = Inbox::Repositories::InboxSettingsRepository.new(user_id:, root_account_id:)
        updated_user_inbox_settings = inbox_settings_repo.save_inbox_settings(
          use_signature: true,
          signature: "John Doe",
          use_out_of_office: false,
          out_of_office_first_date: nil,
          out_of_office_last_date: nil,
          out_of_office_subject: nil,
          out_of_office_message: nil
        )
        expect_objects_equal(updated_user_inbox_settings, inbox_settings_entity_for_user(
                                                            user_id:,
                                                            use_signature: true,
                                                            signature: "John Doe"
                                                          ))
      end
    end
  end
end
