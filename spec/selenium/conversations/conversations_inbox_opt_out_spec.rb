#
# Copyright (C) 2014 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../helpers/conversations_common')

describe "conversations new" do
  include_context "in-process server selenium tests"
  include ConversationsCommon

  before do
    conversation_setup
  end

  describe 'conversations inbox opt-out option' do
    it "should be hidden a feature flag", priority: "1", test_id: 206028 do
      get "/profile/settings"
      expect(f("#content")).not_to contain_css('#disable_inbox')
    end

    it "should reveal when the feature flag is set", priority: "1", test_id: 138894 do
      @course.root_account.enable_feature!(:allow_opt_out_of_inbox)
      get "/profile/settings"
      expect(ff('#disable_inbox').count).to eq 1
    end

    context "when activated" do
      it "should set the notification preferences for conversations to ASAP, and hide those options", priority: "1", test_id: 207091 do
        @course.root_account.enable_feature!(:allow_opt_out_of_inbox)
        expect(@teacher.reload.disabled_inbox?).to be_falsey
        notification = Notification.create!(workflow_state: "active", name: "Conversation Message",
                             category: "Conversation Message", delay_for: 0)
        policy = NotificationPolicy.create!(notification_id: notification.id, communication_channel_id: @teacher.email_channel.id, frequency: "weekly")
        @teacher.update_attribute(:unread_conversations_count, 3)

        get '/profile/communication'
        expect(ff('td[data-category="conversation_message"]').count).to eq 1
        # make sure the link exists in the global nav
        expect(f('#header')).to contain_css("#global_nav_conversations_link")
        # make sure the little blue circle indicating how many unread messages you have says 3
        expect(f('#global_nav_conversations_link .menu-item__badge')).to include_text('3')

        get "/profile/settings"
        f('#disable_inbox').click

        keep_trying_until { expect(@teacher.reload.disabled_inbox?).to be_truthy }

        get '/profile/communication'
        expect(f("#content")).not_to contain_css('td[data-category="conversation_message"]')
        expect(policy.reload.frequency).to eq "immediately"
        expect(f("#global_nav_conversations_link .menu-item__badge")).not_to be_displayed
      end
    end
  end
end
