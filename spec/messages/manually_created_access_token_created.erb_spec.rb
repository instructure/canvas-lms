# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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
#

require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")
require File.expand_path(File.dirname(__FILE__) + "/messages_helper")

describe "manually_created_access_token_created" do
  before :once do
    user_model
    enable_default_developer_key!
    @token = @user.access_tokens.create!(purpose: "test")
  end

  let(:asset) { @token }
  let(:message_data) do
    { user: @user }
  end
  let(:notification_name) { :manually_created_access_token_created }

  include_examples "a message"

  it "removes notification settings url link" do
    msg = generate_message(notification_name, :email, asset, message_data)
    expect(msg.html_body).to include "Manage User Settings"
    expect(msg.html_body).not_to include "Update your notification settings"
  end
end
