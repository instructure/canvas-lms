#
# Copyright (C) 2011 Instructure, Inc.
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

describe Message do

  describe "parse!" do
    it "should use https when the domain is configured as ssl" do
      pending("switch messages to use url writing, rather than hard-coded strings")
      HostUrl.stubs(:protocol).returns("https")
      @au = AccountUser.create(:account => account_model)
      msg = generate_message(:account_user_notification, :email, @au)
      msg.body.should match(%r{https://www.example.com})
    end
  end

  context "named scopes" do
    it "should be able to get messages in any state" do
      m1 = message_model(:workflow_state => 'bounced', :user => user)
      m2 = message_model(:workflow_state => 'sent', :user => user)
      m3 = message_model(:workflow_state => 'sending', :user => user)
      Message.in_state(:bounced).should eql([m1])
      Message.in_state([:bounced, :sent]).should eql([m1, m2])
      Message.in_state([:bounced, :sent]).should_not be_include(m3)
    end
    
    it "should be able to search on its context" do
      user_model
      message_model
      @message.update_attribute(:context, @user)
      Message.for(@user).should eql([@message])
    end
    
    it "should have a list of messages to dispatch" do
      message_model(:dispatch_at => Time.now - 1, :workflow_state => 'staged', :to => 'somebody', :user => user)
      Message.to_dispatch.should eql([@message])
    end
    
    it "should not have a message to dispatch if the message's delay moves it to the future" do
      message_model(:dispatch_at => Time.now - 1, :to => 'somebody')
      @message.stage
      Message.to_dispatch.should eql([])
    end
    
    it "should filter on notification name" do
      notification_model(:name => 'Some Name')
      message_model(:notification_id => @notification.id)
      Message.by_name('Some Name').should eql([@message])
    end

    it "should offer staged messages (waiting to be dispatched)" do
      message_model(:dispatch_at => Time.now + 100, :user => user)
      Message.staged.should eql([@message])
    end

    it "should go back to the staged state if sending fails" do
      message_model(:dispatch_at => Time.now - 1, :workflow_state => 'sending', :to => 'somebody', :updated_at => Time.now.utc - 11.minutes, :user => user)
      @message.errored_dispatch
      @message.workflow_state.should == 'staged'
      @message.dispatch_at.should > Time.now + 4.minutes
    end

    describe "#deliver" do
      it "should not deliver if canceled" do
        message_model(:dispatch_at => Time.now, :workflow_state => 'staged', :to => 'somebody', :updated_at => Time.now.utc - 11.minutes, :user => user, :path_type => 'email')
        @message.cancel
        @message.expects(:deliver_via_email).never
        Mailer.expects(:deliver_message).never
        @message.deliver.should be_nil
        @message.reload.state.should == :cancelled
      end
    end
  end
end
