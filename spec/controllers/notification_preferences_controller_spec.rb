# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

describe NotificationPreferencesController do
  before :once do
    @sms_notification = Notification.create!(name: "Confirm SMS Communication Channel", category: "Registration")
    @discussion_entry_notification = Notification.create!(name: "New Discussion Entry", category: "DiscussionEntry")
    @discussion_mention_notification = Notification.create!(name: "Discussion Mention", category: "DiscussionMention")
    @reported_reply_notification = Notification.create!(name: "Reported Reply", category: "ReportedReply")
    user_model
    communication_channel_model
    NotificationPolicy.setup_with_default_policies(@user)
  end

  before do
    user_session @user
  end

  describe "update_preferences_by_category" do
    it "works for discussionentry" do
      put :update_preferences_by_category, params: {
        communication_channel_id: @cc.id, category: "discussionentry", notification_preferences: { frequency: "never" }
      }
      expect(@cc.notification_policies.where(notification: @discussion_entry_notification).first.frequency).to eq "never"
    end

    it "works for discussion_mention" do
      put :update_preferences_by_category, params: {
        communication_channel_id: @cc.id, category: "discussion_mention", notification_preferences: { frequency: "never" }
      }
      expect(@cc.notification_policies.where(notification: @discussion_mention_notification).first.frequency).to eq "never"
    end

    it "works for reported_reply" do
      put :update_preferences_by_category, params: {
        communication_channel_id: @cc.id, category: "reported_reply", notification_preferences: { frequency: "never" }
      }
      expect(@cc.notification_policies.where(notification: @reported_reply_notification).first.frequency).to eq "never"
    end

    it "works for registration" do
      put :update_preferences_by_category, params: {
        communication_channel_id: @cc.id, category: "registration", notification_preferences: { frequency: "never" }
      }
      expect(
        @cc.notification_policies.where(notification: @sms_notification).first.frequency
      ).to eq "never"
    end
  end
end
