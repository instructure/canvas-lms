# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

require_relative "messages_helper"

describe "confirm_sms_communication_channel.sms" do
  include MessagesCommon

  it "renders" do
    user_factory
    @pseudonym = @user.pseudonyms.create!(unique_id: "unique@example.com", password: "password", password_confirmation: "password")
    @object = communication_channel(@user, { username: "bob@example.com" })
    generate_message(:confirm_sms_communication_channel,
                     :sms,
                     @object,
                     data: { root_account_id: @pseudonym.account.global_id,
                             from_host: HostUrl.context_host(@pseudonym.account) })
  end
end
