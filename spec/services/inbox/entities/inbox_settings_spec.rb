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

describe Inbox::Entities::InboxSettings do
  let(:user) { user_model }
  let(:user_id) { user.id.to_s }
  let(:account) { account_model }
  let(:id) { 123 }
  let(:root_account_id) { account.id }
  let(:use_signature) { true }
  let(:use_out_of_office) { true }
  let(:signature) { "John Doe" }
  let(:out_of_office_first_date) { "2024-04-10 00:00:00 UTC" }
  let(:out_of_office_last_date) { "2024-04-11 00:00:00 UTC" }
  let(:out_of_office_subject) { "Out of office" }
  let(:out_of_office_message) { "Out of office for one week" }

  describe ".new" do
    it "creates entity" do
      entity = Inbox::Entities::InboxSettings.new(
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
      expect(entity.id).to eq id
      expect(entity.user_id).to eq user_id
      expect(entity.root_account_id).to eq root_account_id
      expect(entity.use_signature).to eq use_signature
      expect(entity.signature).to eq signature
      expect(entity.use_out_of_office).to eq use_out_of_office
      expect(entity.out_of_office_first_date).to eq out_of_office_first_date
      expect(entity.out_of_office_last_date).to eq out_of_office_last_date
      expect(entity.out_of_office_subject).to eq out_of_office_subject
      expect(entity.out_of_office_message).to eq out_of_office_message
    end

    it "throws an error if no id" do
      expect { Inbox::Entities::InboxSettings.new(user_id:, root_account_id:) }.to raise_error(ArgumentError, "missing keyword: :id")
    end

    it "throws an error if no user_id" do
      expect { Inbox::Entities::InboxSettings.new(id:, root_account_id:) }.to raise_error(ArgumentError, "missing keyword: :user_id")
    end

    it "throws an error if no root_account_id" do
      expect { Inbox::Entities::InboxSettings.new(id:, user_id:) }.to raise_error(ArgumentError, "missing keyword: :root_account_id")
    end
  end
end
