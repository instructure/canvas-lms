# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

require_relative "messages_helper"

describe "account_notification" do
  before :once do
    account = Account.create!(name: "some account", settings: { outgoing_email_default_name: "Custom From" })
    @announcement = account_notification(account:)
  end

  let(:notification_name) { :account_notification }
  let(:asset) { @announcement }

  include_examples "a message"

  context ".email" do
    let(:path_type) { :email }

    it "uses the custom From: setting" do
      msg = generate_message(notification_name, path_type, asset)
      msg.save
      expect(msg.from_name).to eq "Custom From"
    end
  end
end
