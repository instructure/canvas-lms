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

describe DelayedMessage do
  it "should create a new instance given valid attributes" do
    delayed_message_model
  end
  
  context "named scopes" do
    
    it "should have scope for :daily" do
      DelayedMessage.delete_all
      delayed_message_model(:frequency => 'daily')
      DelayedMessage.for(:daily).should eql([@delayed_message])
    end
    
    it "should scope for :weekly" do
      DelayedMessage.delete_all
      delayed_message_model(:frequency => 'weekly')
      DelayedMessage.for(:weekly).should eql([@delayed_message])
    end
    
    it "should scope for notification" do
      DelayedMessage.delete_all
      notification_model
      delayed_message_model(:notification_id => @notification.id)
      DelayedMessage.for(@notification).should eql([@delayed_message])
    end
    
    it "should scope for notification_policy" do
      DelayedMessage.delete_all
      notification_policy_model
      delayed_message_model(:notification_policy_id => @notification_policy.id)
      @notification_policy.should be_is_a(NotificationPolicy)
      DelayedMessage.for(@notification_policy).should eql([@delayed_message])
    end
    
    it "should scope for communication_channel" do
      DelayedMessage.delete_all
      communication_channel_model
      delayed_message_model(:communication_channel_id => @communication_channel.id)
      @communication_channel.should be_is_a(CommunicationChannel)
      DelayedMessage.for(@communication_channel).should eql([@delayed_message])
    end
    
    it "should scope for context" do
      delayed_message_model
      @delayed_message.context = assignment_model
      @delayed_message.save!
      DelayedMessage.for(@assignment).should eql([@delayed_message])
    end
    
    # named_scope :in_state, lambda { |state|
    #   { :context => ["workflow_state = ?", state.to_s]}
    # }
    
    it "should have a scope to order the messages by a field" do
      (1..3).inject([]) {|list, e| list << notification_policy_model}
      id1 = delayed_message_model(:notification_policy_id => 3).id
      id2 = delayed_message_model(:notification_policy_id => 2).id
      id3 = delayed_message_model(:notification_policy_id => 1).id
      DelayedMessage.by(:notification_policy_id).map(&:id).should eql([id3, id2, id1])
    end
    
    it "should have a scope to filter by the state" do
      delayed_message_model(:workflow_state => 'pending')
      delayed_message_model(:workflow_state => 'cancelled')
      delayed_message_model(:workflow_state => 'sent')
      DelayedMessage.in_state(:pending).all? { |d| d.state == :pending }.should be_true
      DelayedMessage.in_state(:pending).size.should eql(1)
      DelayedMessage.in_state(:cancelled).all? { |d| d.state == :cancelled }.should be_true
      DelayedMessage.in_state(:cancelled).size.should eql(1)
      DelayedMessage.in_state(:sent).all? { |d| d.state == :sent }.should be_true
      DelayedMessage.in_state(:sent).size.should eql(1)
    end
  end
  
  context "workflow" do
    before do
      delayed_message_model
    end
    
    it "should start the workflow with pending" do
      @delayed_message.state.should eql(:pending)
    end
    
    it "should should be able to go to cancelled from pending" do
      @delayed_message.cancel
      @delayed_message.state.should eql(:cancelled)
    end
    
    it "should be able to be sent from pending" do
      @delayed_message.begin_send
      @delayed_message.state.should eql(:sent)
    end
  end

  it "should use the user's main account domain for links" do
    Canvas::MessageHelper.create_notification('Summary', 'Summaries', 0, '', 'Summaries')
    account = Account.create!(:name => 'new acct')
    user = user_with_pseudonym(:account => account)
    user.pseudonym.update_attribute(:account, account)
    user.pseudonym.account.should == account
    HostUrl.expects(:context_host).with(user.pseudonym.account).at_least(1).returns("dm.dummy.test.host")
    HostUrl.stubs(:default_host).returns("test.host")
    dm = DelayedMessage.create!(:summary => "This is a notification", :context => Account.default, :communication_channel => user.communication_channel, :notification => notification_model)
    DelayedMessage.summarize([dm])
    message = Message.last
    message.body.to_s.should_not match(%r{http://test.host/})
    message.body.to_s.should match(%r{http://dm.dummy.test.host/})
  end
end
