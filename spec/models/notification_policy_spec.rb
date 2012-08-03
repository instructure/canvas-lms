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
    notification_policy_model
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
    @policy = NotificationPolicy.create(:notification => @notif, :communication_channel => @cc, :frequency => "immediately")
    @assignment.publish!
    @assignment.messages_sent.should be_include("Assignment Graded")
    m = @assignment.messages_sent["Assignment Graded"].find{|m| m.to == "default@example.com"}
    m.should be_nil
    m = @assignment.messages_sent["Assignment Graded"].find{|m| m.to == "secondary@example.com"}
    m.should_not be_nil
  end
  
  it "should prevent message dispatches if set to 'never' on triggered policies" do
    policy_setup
    @assignment.unpublish!
    @cc = @student.communication_channels.create(:path => "secondary@example.com")
    @cc.confirm!
    @policy = NotificationPolicy.create(:notification => @notif, :communication_channel => @cc, :frequency => "never")
    @assignment.previously_published = false
    @assignment.save
    @assignment.publish!
    m = @assignment.messages_sent["Assignment Graded"].find{|m| m.to == "default@example.com"}
    m.should be_nil
    m = @assignment.messages_sent["Assignment Graded"].find{|m| m.to == "secondary@example.com"}
    m.should be_nil
  end

  it "should prevent message dispatches if no policy setting exists" do
    policy_setup
    @assignment.unpublish!
    @cc = @student.communication_channels.create(:path => "secondary@example.com")
    @cc.confirm!
    NotificationPolicy.delete_all(:notification_id => @notif.id, :communication_channel_id => @cc.id)
    @assignment.previously_published = false
    @assignment.save
    @assignment.publish!
    m = @assignment.messages_sent["Assignment Graded"].find{|m| m.to == "default@example.com"}
    m.should be_nil
    m = @assignment.messages_sent["Assignment Graded"].find{|m| m.to == "secondary@example.com"}
    m.should be_nil
  end

  it "should pass 'data' to the message" do
    Notification.create! :name => "Hello",
                         :subject => "Hello",
                         :body => "here's a free <%= data.favorite_soda %>",
                         :category => "TestImmediately"
    class DataTest < ActiveRecord::Base
      set_table_name :courses
      attr_accessible :id
      has_a_broadcast_policy
      set_broadcast_policy do
        dispatch :hello
        to {
          u = student_in_course.user
          u.communication_channels.build(
            :path => 'blarg@example.com',
            :path_type => 'email'
          ) { |cc| cc.workflow_state = 'active' }
          u.save!
          u.register
          u
        }
        whenever { true }
        data { {:favorite_soda => 'mtn dew'} }
      end
    end
    dt = DataTest.new
    dt.save!
    msg = dt.messages_sent["Hello"].find { |m| m.to == "blarg@example.com" }
    msg.should_not be_nil
    msg.body.should include "mtn dew"
  end
  
  context "named scopes" do
    it "should have a named scope for users" do
      user_with_pseudonym(:active_all => 1)
      notification_policy_model(:communication_channel => @cc)
      NotificationPolicy.for(@user).should eql([@notification_policy])
    end

    it "should have a named scope for notifications" do
      notification_model
      notification_policy_model(:notification => @notification)
      NotificationPolicy.for(@notification).should eql([@notification_policy])
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
        user_with_pseudonym(:active_all => 1)
        n1 = notification_policy_model(
          :communication_channel => @cc,
          :frequency => 'daily'
        )
        n2 = notification_policy_model(
            :communication_channel => @cc,
          :frequency => 'weekly'
        )
        n3 = notification_policy_model(:communication_channel => @cc)
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
        :communication_channel => @communication_channel,
        :notification => @notification
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
  
  describe "setup_for" do
    it "should not fail when params does not include a user, and the account doesn't allow scores in e-mails" do
      params = {}
      params[:root_account] = Account.default
      params[:root_account].settings[:allow_sending_scores_in_emails] = false
      NotificationPolicy.setup_for(user, params)
    end

    it "should set all notification entries within the same category" do
      user_model
      communication_channel_model(:user_id => @user.id)
      notify1 = notification_model(:name => 'Setting 1', :category => 'MultiCategory')
      notify2 = notification_model(:name => 'Setting 2', :category => 'MultiCategory')

      NotificationPolicy.delete_all

      trifecta_opts = {
        :communication_channel => @communication_channel,
        :frequency => Notification::FREQ_NEVER
      }
      n1 = notification_policy_model(trifecta_opts.merge(:notification => notify1) )
      n2 = notification_policy_model(trifecta_opts.merge(:notification => notify2) )
      params = {:category => 'MultiCategory', :channel_id => @communication_channel.id, :frequency => Notification::FREQ_IMMEDIATELY}
      NotificationPolicy.setup_for(@user, params)
      n1.reload; n2.reload
      n1.frequency.should == Notification::FREQ_IMMEDIATELY
      n2.frequency.should == Notification::FREQ_IMMEDIATELY
    end
  end

  describe "setup_with_default_policies" do
    before :each do
      user_model
      communication_channel_model(:user_id => @user.id)
      @announcement = notification_model(:name => 'Setting 1', :category => 'Announcement')
    end
    it "should create default NotificationPolicy entries if missing" do
      # Ensure no existing policies
      NotificationPolicy.delete_all

      policies = NotificationPolicy.setup_with_default_policies(@user, [@announcement])
      policies.length.should == 1
      policies.first.frequency.should == @announcement.default_frequency
    end
    it "should not overwrite an existing setting with a default" do
      # Create an existing policy entry
      NotificationPolicy.delete_all
      n1 = notification_policy_model({:communication_channel => @communication_channel,
                                      :notification => @announcement,
                                      :frequency => Notification::FREQ_NEVER})

      @announcement.default_frequency.should_not == Notification::FREQ_NEVER # verify that it differs from the default
      policies = NotificationPolicy.setup_with_default_policies(@user, [@announcement])
      policies.length.should == 1
      policies.first.frequency.should == Notification::FREQ_NEVER
    end
    it "should not set defaults on secondary communication channel" do
      NotificationPolicy.delete_all
      # Setup the second channel (higher position)
      primary_channel   = @user.communication_channel
      secondary_channel = communication_channel_model(:user_id => @user.id, :path => 'secondary@example.com')
      # start out with 0 on primary and secondary
      primary_channel.notification_policies.count.should == 0
      secondary_channel.notification_policies.count.should == 0
      # Load data
      NotificationPolicy.setup_with_default_policies(@user, [@announcement])
      # Primary should have 1 created and secondary should be left alone.
      primary_channel.notification_policies.count.should == 1
      secondary_channel.notification_policies.count.should == 0
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
    @cc1 = mock('CommunicationChannel')
    @cc2 = mock('CommunicationChannel')
    @user = mock('User')
    @user.stubs(:communication_channel).returns(@cc1)
    notification_policy_model
    @notification_policy.stubs(:user).returns(@user)
  end
  
  it "should use the channel defined, if one is given" do
    @notification_policy.stubs(:communication_channel).returns(@cc2)
    @notification_policy.communication_preference.should eql(@cc2)
  end

  it "should use the users default communication channel if one isn't given" do
    @notification_policy.stubs(:communication_channel).returns(nil)
    @notification_policy.communication_preference.should eql(@cc1)
  end
  
end
  
