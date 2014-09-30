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
require File.expand_path(File.dirname(__FILE__) + '/../sharding_spec_helper')

describe NotificationPolicy do
  it "should create a new instance given valid attributes" do
    notification_policy_model
  end
  
  context "channels" do
    before(:once) do
      @course = factory_with_protected_attributes(Course, :name => "test course", :workflow_state => "available")
      @student = factory_with_protected_attributes(User, :name => "student", :workflow_state => "registered")
      e = @course.enroll_student(@student)
      e.accept!
      Notification.all.each{|n| n.destroy }
      @notif = Notification.create!(:name => "Assignment Created", :subject => "Test", :category => 'TestNever')
    end

    it "should cause message dispatch to specified channel on triggered policies" do
      @default_cc = @student.communication_channels.create(:path => "default@example.com")
      @default_cc.confirm!
      @cc = @student.communication_channels.create(:path => "secondary@example.com")
      @cc.confirm!
      @policy = NotificationPolicy.create(:notification => @notif, :communication_channel => @cc, :frequency => "immediately")
      @assignment = @course.assignments.create!(:title => "test assignment")
      @assignment.messages_sent.should be_include("Assignment Created")
      m = @assignment.messages_sent["Assignment Created"].find{|m| m.to == "default@example.com"}
      m.should be_nil
      m = @assignment.messages_sent["Assignment Created"].find{|m| m.to == "secondary@example.com"}
      m.should_not be_nil
    end
    
    it "should prevent message dispatches if set to 'never' on triggered policies" do
      @cc = @student.communication_channels.create(:path => "secondary@example.com")
      @cc.confirm!
      @policy = NotificationPolicy.create(:notification => @notif, :communication_channel => @cc, :frequency => "never")
      @assignment = @course.assignments.create!(:title => "test assignment")
      m = @assignment.messages_sent["Assignment Created"].find{|m| m.to == "default@example.com"}
      m.should be_nil
      m = @assignment.messages_sent["Assignment Created"].find{|m| m.to == "secondary@example.com"}
      m.should be_nil
    end

    it "should prevent message dispatches if no policy setting exists" do
      @cc = @student.communication_channels.create(:path => "secondary@example.com")
      @cc.confirm!
      NotificationPolicy.where(:notification_id => @notif, :communication_channel_id => @cc).delete_all
      @assignment = @course.assignments.create!(:title => "test assignment")
      m = @assignment.messages_sent["Assignment Created"].find{|m| m.to == "default@example.com"}
      m.should be_nil
      m = @assignment.messages_sent["Assignment Created"].find{|m| m.to == "secondary@example.com"}
      m.should be_nil
    end
  end

  it "should pass 'data' to the message" do
    Notification.create! :name => "Hello",
                         :subject => "Hello",
                         :category => "TestImmediately"
    Message.any_instance.stubs(:get_template).returns("here's a free <%= data.favorite_soda %>")
    class DataTest < ActiveRecord::Base
      self.table_name = :courses
      attr_protected
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
    dt = DataTest.new(account_id: Account.default.id,
                      root_account_id: Account.default.id,
                      enrollment_term_id: Account.default.default_enrollment_term.id,
                      workflow_state: 'created')
    dt.save!
    msg = dt.messages_sent["Hello"].find { |m| m.to == "blarg@example.com" }
    msg.should_not be_nil
    msg.body.should include "mtn dew"
  end
  
  context "named scopes" do
    it "should have a named scope for users" do
      user_with_pseudonym(:active_all => 1)
      notification_policy_model(:communication_channel => @cc)
      NotificationPolicy.for(@user).should == [@notification_policy]
    end

    it "should have a named scope for notifications" do
      notification_model
      notification_policy_model(:notification => @notification)
      NotificationPolicy.for(@notification).should == [@notification_policy]
    end
    
    it "should not slow down from other kinds of input on the *for* named scope" do
      notification_policy_model
      NotificationPolicy.for(:anything_else).should == NotificationPolicy.all
    end
    
    context "by" do
      before :once do
        user_with_pseudonym(:active_all => 1)
        @n1 = notification_policy_model(:frequency => 'immediately', :communication_channel => @cc, notification: notification_model(name: 'N1'))
        @n2 = notification_policy_model(:frequency => 'daily', :communication_channel => @cc, notification: notification_model(name: 'N2'))
        @n3 = notification_policy_model(:frequency => 'weekly', :communication_channel => @cc, notification: notification_model(name: 'N3'))
        @n4 = notification_policy_model(:frequency => 'never', :communication_channel => @cc, notification: notification_model(name: 'N4'))
      end
      
      it "should have a scope to differentiate by frequency" do
        NotificationPolicy.by(:immediately).should == [@n1]
        NotificationPolicy.by(:daily).should == [@n2]
        NotificationPolicy.by(:weekly).should == [@n3]
        NotificationPolicy.by(:never).should == [@n4]
      end
    
      it "should be able to differentiate by several frequencies at once" do
        NotificationPolicy.by([:immediately, :daily]).should be_include(@n1)
        NotificationPolicy.by([:immediately, :daily]).should be_include(@n2)
      end
      
      it "should be able to combine an array of frequencies with a for scope" do
        NotificationPolicy.for(@user).by([:daily, :weekly]).should be_include(@n2)
        NotificationPolicy.for(@user).by([:daily, :weekly]).should be_include(@n3)
        NotificationPolicy.for(@user).by([:daily, :weekly]).should_not be_include(@n1)
      end
    end
    
    it "should find all daily and weekly policies for the user, communication_channel, and notification" do
      user_model
      communication_channel_model
      notification_model

      NotificationPolicy.delete_all
      
      trifecta_opts = {
        :communication_channel => @communication_channel,
        :notification => @notification
      }
      
      n1 = notification_policy_model

      policies = NotificationPolicy.for(@notification).for(@user).for(@communication_channel).by([:daily, :weekly])
      policies.should == []

      n1.update_attribute(:frequency, 'never')
      policies = NotificationPolicy.for(@notification).for(@user).for(@communication_channel).by([:daily, :weekly])
      policies.should == []

      n1.update_attribute(:frequency, 'daily')
      policies = NotificationPolicy.for(@notification).for(@user).for(@communication_channel).by([:daily, :weekly])
      policies.should == [n1]

      n1.update_attribute(:frequency, 'weekly')
      policies = NotificationPolicy.for(@notification).for(@user).for(@communication_channel).by([:daily, :weekly])
      policies.should == [n1]
    end
    
  end
  
  describe "setup_for" do
    it "should not fail when params does not include a user, and the account doesn't allow scores in e-mails" do
      user_model
      communication_channel_model
      notify1 = notification_model(:name => 'Setting 1', :category => 'MultiCategory')
      params = { :channel_id => @communication_channel.id }
      params[:root_account] = Account.default
      params[:root_account].settings[:allow_sending_scores_in_emails] = false
      NotificationPolicy.setup_for(@user, params)
    end

    it "should set all notification entries within the same category" do
      user_model
      communication_channel_model
      notify1 = notification_model(:name => 'Setting 1', :category => 'MultiCategory')
      notify2 = notification_model(:name => 'Setting 2', :category => 'MultiCategory')

      NotificationPolicy.delete_all

      trifecta_opts = {
        :communication_channel => @communication_channel,
        :frequency => Notification::FREQ_NEVER
      }
      n1 = notification_policy_model(trifecta_opts.merge(:notification => notify1) )
      n2 = notification_policy_model(trifecta_opts.merge(:notification => notify2) )
      params = {:category => 'multi_category', :channel_id => @communication_channel.id, :frequency => Notification::FREQ_IMMEDIATELY}
      NotificationPolicy.setup_for(@user, params)
      n1.reload; n2.reload
      n1.frequency.should == Notification::FREQ_IMMEDIATELY
      n2.frequency.should == Notification::FREQ_IMMEDIATELY
    end

    context "sharding" do
      specs_require_sharding

      it "should create records on the correct shard" do
        user_with_pseudonym(active_all: true)
        NotificationPolicy.delete_all
        notification_model
        @shard1.activate do
          @user.notification_policies.scoped.exists?.should be_false
          NotificationPolicy.setup_for(@user, channel_id: @cc.id, frequency: Notification::FREQ_IMMEDIATELY, category: 'test_immediately')
          @user.notification_policies.scoped.exists?.should be_true
        end
      end
    end
  end

  describe "setup_with_default_policies" do
    before :once do
      @user = User.create!
      @communication_channel = @user.communication_channels.create!(path: 'email@example.com')
      @announcement = notification_model(:name => 'Setting 1', :category => 'Announcement')
    end

    before :each do
      Notification.stubs(:all).returns([@notification])
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
      secondary_channel = communication_channel_model(:path => 'secondary@example.com')
      # start out with 0 on primary and secondary
      primary_channel.notification_policies.count.should == 0
      secondary_channel.notification_policies.count.should == 0
      # Load data
      NotificationPolicy.setup_with_default_policies(@user, [@announcement])
      # Primary should have 1 created and secondary should be left alone.
      primary_channel.notification_policies.count.should == 1
      secondary_channel.notification_policies.count.should == 0
    end

    it "should not pull defaults from non-default channels" do
      NotificationPolicy.delete_all
      # Setup the second channel (higher position)
      primary_channel   = @user.communication_channel
      secondary_channel = communication_channel_model(:path => 'secondary@example.com')
      secondary_channel.notification_policies.create!(:notification => @notification, :frequency => Notification::FREQ_NEVER)
      NotificationPolicy.setup_with_default_policies(@user, [@announcement])
      # Primary should have 1 created and secondary should be left alone.
      primary_channel.reload.notification_policies.count.should == 1
      secondary_channel.reload.notification_policies.count.should == 1
    end

    it "should not error if no channel exists" do
      NotificationPolicy.delete_all
      CommunicationChannel.delete_all
      lambda { NotificationPolicy.setup_with_default_policies(@user, [@announcement])}.should_not raise_error
    end

    context "across shards" do
      specs_require_sharding

      it "should find user categories accross shards" do
        @shard1.activate {
          @shard_user = user_model
          @channel = communication_channel_model(:user => @shard_user)
          NotificationPolicy.delete_all
          @policy = @channel.notification_policies.create!(:notification => @notification, :frequency => Notification::FREQ_NEVER)
          NotificationPolicy.setup_with_default_policies(@shard_user, [@announcement])
          @policy.reload.frequency.should == Notification::FREQ_NEVER
        }
      end
    end
  end
end
