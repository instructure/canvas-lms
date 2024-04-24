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
  let(:account) { account_model }
  let(:inbox_settings) { Inbox::Entities::InboxSettings.new(user_id: user.id, use_signature: true, signature: "John Doe") }
  let(:json_inbox_settings) do
    {
      userId: user.id,
      useSignature: true,
      signature: "John Doe",
      useOutOfOffice: false,
      outOfOfficeFirstDate: nil,
      outOfOfficeLastDate: nil,
      outOfOfficeMessage: nil,
      outOfOfficeSubject: nil
    }
  end

  describe ".new" do
    it "throws an error if no user_id" do
      expect { Inbox::Entities::InboxSettings.new }.to raise_error(ArgumentError, "missing keyword: :user_id")
    end
  end

  describe ".as_json" do
    it "returns json formatted inbox settings" do
      expect(Inbox::Entities::InboxSettings.as_json(inbox_settings:)).to eq(json_inbox_settings)
    end
  end

  describe ".from_json" do
    it "returns inbox settings from json formatted settings" do
      from_json_settings = Inbox::Entities::InboxSettings.from_json(json: json_inbox_settings.with_indifferent_access)
      expect(from_json_settings.to_json).to eq(inbox_settings.to_json)
    end
  end
end
