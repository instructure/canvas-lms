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

describe NotificationPolicy do
  it "should create a new instance given valid attributes" do
    NotificationPolicy.create!(notification_policy_valid_attributes)
  end
  
  it "should default broadcast to true" do
    notification_policy_model
    @notification_policy.broadcast.should be_true
  end
  
  it "should not have a communication_preference if broadcast is set to false." do
    notification_policy_model(:broadcast => false)
    @notification_policy.communication_preference.should be_nil
  end

  it "should cause message dispatch to specified channel on triggered policies" do
    policy_setup
    @assignment.unpublish!
    @assignment.previously_published = false
    @assignment.save
    @default_cc = @student.communication_channels.create(:path => "default@example.com")
    @default_cc.confirm!
    @cc = @student.communication_channels.create(:path => "secondary@example.com")
    @cc.confirm!
    @policy = NotificationPolicy.create(:user => @student, :notification => @notif, :communication_channel => @cc, :frequency => "immediately")
    @assignment.publish!
    @assignment.messages_sent.should be_include("Assignment Graded")
    m = @assignment.messages_sent["Assignment Graded"].find{|m| m.to == "default@example.com"}
    m.should be_nil
    m = @assignment.messages_sent["Assignment Graded"].find{|m| m.to == "secondary@example.com"}
    m.should_not be_nil
  end
  
  # it "should not send messages immediately if the policy is set to daily" do
  #   policy_setup
  #   @assignment.unpublish!
  #   @cc = @student.communication_channels.create(:path => "secondary@example.com", :workflow_state => "active")
  #   @policy = NotificationPolicy.create(:user => @student, :notification => @notif, :communication_channel => @cc, :frequency => "daily")
  #   @assignment.publish!
  #   @assignment.messages_sent.should_not be_include("Assignment Graded")
  # end
  
  it "should prevent message dispatches if set to 'never' on triggered policies" do
    policy_setup
    @assignment.unpublish!
    @cc = @student.communication_channels.create(:path => "secondary@example.com")
    @cc.confirm!
    @policy = NotificationPolicy.create(:user => @student, :notification => @notif, :communication_channel => @cc, :frequency => "never")
    @assignment.previously_published = false
    @assignment.save
    @assignment.publish!
    m = @assignment.messages_sent["Assignment Graded"].find{|m| m.to == "default@example.com"}
    m.should be_nil
    m = @assignment.messages_sent["Assignment Graded"].find{|m| m.to == "secondary@example.com"}
    m.should be_nil
  end
  
  context "named scopes" do
    it "should have a named scope for users" do
      user_model
      notification_policy_model(:user_id => @user.id)
      NotificationPolicy.for(@user).should eql([@notification_policy])
    end
    
    it "should have a named scope for notifications" do
      notification_model
      notification_policy_model(:notification_id => @notification.id)
      NotificationPolicy.for(@notification).should eql([@notification_policy])
    end
    
    it "should have a named scope for communication_channels" do
      communication_channel_model
      notification_policy_model(:communication_channel_id => @communication_channel.id)
      NotificationPolicy.for(@communication_channel).should eql([@notification_policy])
    end
    
    it "should not slow down from other kinds of input on the *for* named scope" do
      notification_policy_model
      NotificationPolicy.for(:anything_else).should eql(NotificationPolicy.all)
    end
    
    context "by" do
      before do
        @n1 = notification_policy_model(:frequency => 'immediately')
        @n2 = notification_policy_model(:frequency => 'daily')
        @n3 = notification_policy_model(:frequency => 'weekly')
        @n4 = notification_policy_model(:frequency => 'never')
      end
      
      it "should have a scope to differentiate by frequency" do
        NotificationPolicy.by(:immediately).should eql([@n1])
        NotificationPolicy.by(:daily).should eql([@n2])
        NotificationPolicy.by(:weekly).should eql([@n3])
        NotificationPolicy.by(:never).should eql([@n4])
      end
    
      it "should be able to differentiate by several frequencies at once" do
        NotificationPolicy.by([:immediately, :daily]).should be_include(@n1)
        NotificationPolicy.by([:immediately, :daily]).should be_include(@n2)
      end
      
      it "should be able to combine an array of frequencies with a for scope" do
        user_model
        n1 = notification_policy_model(
        :user_id => @user.id,
          :frequency => 'daily'
        )
        n2 = notification_policy_model(
          :user_id => @user.id,
          :frequency => 'weekly'
        )
        n3 = notification_policy_model(:user_id => @user.id)
        NotificationPolicy.for(@user).by([:daily, :weekly]).should be_include(n1)
        NotificationPolicy.for(@user).by([:daily, :weekly]).should be_include(n2)
        NotificationPolicy.for(@user).by([:daily, :weekly]).should_not be_include(n3)
      end
    end
    
    it "should find all daily and weekly policies for the user, communication_channel, and notification" do
      user_model
      communication_channel_model(:user_id => @user.id)
      notification_model

      NotificationPolicy.delete_all
      
      trifecta_opts = {
        :user_id => @user.id, 
        :communication_channel_id => @communication_channel.id, 
        :notification_id => @notification.id
      }
      
      n1 = notification_policy_model
      n2 = notification_policy_model({:frequency => "immediately"}.merge(trifecta_opts) )
      n3 = notification_policy_model({:frequency => "daily"}.merge(trifecta_opts) )
      n4 = notification_policy_model({:frequency => "weekly"}.merge(trifecta_opts) )
      
      policies = NotificationPolicy.for(@notification).for(@user).for(@communication_channel).by([:daily, :weekly])
      policies.should_not be_include(n1)
      policies.should_not be_include(n2)
      policies.should be_include(n3)
      policies.should be_include(n4)
      policies.size.should eql(2)
      
    end
    
  end
  
end

def policy_setup
  @course = factory_with_protected_attributes(Course, :name => "test course", :workflow_state => "available")
  @assignment = @course.assignments.create(:title => "test assignment")
  @student = factory_with_protected_attributes(User, :name => "student", :workflow_state => "registered")
  e = @course.enroll_student(@student)
  e.accept!
  Notification.find(:all).each{|n| n.destroy }
  @notif = Notification.create!(:name => "Assignment Graded", :subject => "Test", :body => "test", :category => 'TestNever')
end

describe NotificationPolicy, "communication_preference" do
  
  before(:each) do
    @cc1 = mock_model(CommunicationChannel)
    @cc2 = mock_model(CommunicationChannel)
    @user = mock_model(User)
    @user.stub!(:communication_channel).and_return(@cc1)
    notification_policy_model
    @notification_policy.stub!(:user).and_return(@user)
  end
  
  it "should use the channel defined, if one is given" do
    @notification_policy.stub!(:communication_channel).and_return(@cc2)
    @notification_policy.communication_preference.should eql(@cc2)
  end

  it "should use the users default communication channel if one isn't given" do
    @notification_policy.communication_preference.should eql(@cc1)
  end
  
end
  
