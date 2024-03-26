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

describe Inbox::InboxService do
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

  describe ".user_settings" do
    context "when there are inbox settings for user" do
      let(:inbox_settings_entity_for_user) { inbox_settings_entity.new(user_id:) }

      before do
        record = inbox_settings_record.new(user_id:, root_account_id:)
        record.save!
      end

      it "returns inbox settings for user" do
        inbox_service = Inbox::InboxService.new(user_id:, root_account_id:)
        user_inbox_settings = inbox_service.user_settings
        expect_objects_equal(user_inbox_settings, inbox_settings_entity_for_user)
      end
    end

    context "when there are no inbox settings for user" do
      let(:inbox_settings_entity_for_user) { inbox_settings_entity.new(user_id: "99999") }

      it "returns default inbox settings" do
        inbox_service = Inbox::InboxService.new(user_id: "99999", root_account_id:)
        inbox_settings = inbox_service.user_settings
        expect_objects_equal(inbox_settings, inbox_settings_entity_for_user)
      end
    end
  end

  describe ".update_user_settings" do
    context "when there are no inbox settings for user" do
      let(:new_inbox_settings_entity) do
        inbox_settings_entity.new(user_id: "99999")
      end

      it "creates new inbox settings record" do
        inbox_service = Inbox::InboxService.new(user_id: "99999", root_account_id:)
        user_inbox_settings = inbox_service.update_user_settings(
          use_signature: false,
          signature: nil,
          use_out_of_office: false,
          out_of_office_first_date: nil,
          out_of_office_last_date: nil,
          out_of_office_subject: nil,
          out_of_office_message: nil
        )
        expect_objects_equal(user_inbox_settings, new_inbox_settings_entity)
      end
    end

    context "when there are inbox settings for user" do
      let(:updated_inbox_settings_entity) do
        inbox_settings_entity.new(user_id:, use_signature: true, signature: "John Doe")
      end

      before do
        record = inbox_settings_record.new(user_id:, root_account_id:)
        record.save!
      end

      it "updates inbox settings record" do
        inbox_service = Inbox::InboxService.new(user_id:, root_account_id:)
        updated_user_inbox_settings = inbox_service.update_user_settings(
          use_signature: true,
          signature: "John Doe",
          use_out_of_office: false,
          out_of_office_first_date: nil,
          out_of_office_last_date: nil,
          out_of_office_subject: nil,
          out_of_office_message: nil
        )
        expect_objects_equal(updated_user_inbox_settings, updated_inbox_settings_entity)
      end
    end
  end
end
