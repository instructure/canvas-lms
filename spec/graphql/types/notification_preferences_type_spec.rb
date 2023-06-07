# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

require_relative "../graphql_spec_helper"

describe Types::NotificationPreferencesType do
  let(:user) { student_in_course.user }
  let(:preferences_type) { GraphQLTypeTester.new(user, current_user: user) }
  let!(:email_channel) { communication_channel(user, { username: "email@email.com", path_type: CommunicationChannel::TYPE_EMAIL }) }
  let!(:push_channel) { communication_channel(user, { username: "push", path_type: CommunicationChannel::TYPE_PUSH }) }
  let!(:sms_channel) { communication_channel(user, { username: "sms", path_type: CommunicationChannel::TYPE_SMS }) }

  describe "channels" do
    it "returns the user's supported channels" do
      result = preferences_type.resolve("notificationPreferences { channels { path } }", domain_root_account: Account.default)
      # sms is not considered a supported communication channel
      expect(result).to_not include sms_channel.path
      expect(result).to match_array [email_channel.path, push_channel.path]
    end

    context "push notifications are disabled on the account" do
      before do
        allow(Account.default).to receive(:enable_push_notifications?).and_return false
      end

      it "does not return push channels" do
        result = preferences_type.resolve("notificationPreferences { channels { path } }", domain_root_account: Account.default)
        expect(result).to_not include push_channel.path
        expect(result).to match_array [email_channel.path]
      end
    end

    context "a channel_id is provided" do
      it "returns only the specified channel" do
        result = preferences_type.resolve("notificationPreferences { channels(channelId: \"#{email_channel.id}\") { path } }", domain_root_account: Account.default)
        expect(result).to match_array [email_channel.path]
      end

      context "the channel_id is invalid" do
        it "returns an empty array" do
          result = preferences_type.resolve("notificationPreferences { channels(channelId: \"0\") { path } }", domain_root_account: Account.default)
          expect(result).to be_empty
        end
      end
    end
  end
end
