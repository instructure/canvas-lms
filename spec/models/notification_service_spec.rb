#
# Copyright (C) 2013 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')
require File.expand_path(File.dirname(__FILE__) + '/../messages/messages_helper')

describe NotificationService do
  before(:once) do
      @au = AccountUser.create(:account => account_model)
      @au.account.root_account.enable_feature!(:notification_service)
      @message = generate_message(:account_user_notification, :email, @au)
      @message.user.account.root_account.enable_feature!(:notification_service)
      @message.save!
  end

  describe "notification Service" do
    it "processes email message type" do
      NotificationService.expects(:process).once
      @message.path_type = "email"
      expect{@message.deliver}.not_to raise_error
    end
    it "processes twitter message type" do
      NotificationService.expects(:process).once
      @message.path_type = "twitter"
      expect{@message.deliver}.not_to raise_error
    end
    it "processes twilio message type" do
      NotificationService.expects(:process).once
      @message.path_type = "sms"
      expect{@message.deliver}.not_to raise_error
    end
    it "processes sms message type" do
      NotificationService.expects(:process).once
      @message.path_type = "sms"
      @message.to = "+18015550100"
      expect{@message.deliver}.not_to raise_error
    end
    it "processes push notification message type" do
      NotificationService.expects(:process).once
      @message.path_type = "push"
      expect{@message.deliver}.not_to raise_error
    end
  end
end
