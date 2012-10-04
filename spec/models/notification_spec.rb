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

require File.expand_path(File.dirname(__FILE__) + '/../sharding_spec_helper.rb')

describe Notification do

  it "should create a new instance given valid attributes" do
    Notification.create!(notification_valid_attributes)
  end
  
  it "should have a default delay_for" do
    notification_model
    @notification.delay_for.should be >= 0
  end
  
  it "should have a decent state machine" do
    notification_model
    @notification.state.should eql(:active)
    @notification.deactivate
    @notification.state.should eql(:inactive)
    @notification.reactivate
    @notification.state.should eql(:active)
  end
  
  it "should always have some subject and body" do
    n = Notification.create
    n.body.should_not be_nil
    n.subject.should_not be_nil
    n.sms_body.should_not be_nil
  end

  context "by_name" do
    before do
      Notification.create(:name => "foo")
      Notification.create(:name => "bar")
    end

    it "should look up all notifications once and cache them thereafter" do
      Notification.expects(:all).once.returns{ Notification.find(:all) }
      Notification.by_name("foo").should eql(Notification.find_by_name("foo"))
      Notification.by_name("bar").should eql(Notification.find_by_name("bar"))
    end

    it "should give you different object for the same notification" do
      n1 = Notification.by_name("foo")
      n2 = Notification.by_name("foo")
      n1.should eql n2
      n1.should_not equal n2
    end
  end
  
  context "create_message" do
    it "should only send dashboard messages for users with non-validated channels" do
      notification_model
      u1 = create_user_with_cc(:name => "user 1", :workflow_state => "registered")
      u1.communication_channels.create(:path => "user1@example.com")
      u2 = create_user_with_cc(:name => "user 2")
      u2.communication_channels.create(:path => "user2@example.com")
      @a = Assignment.create
      messages = @notification.create_message(@a, [u1, u2])
      messages.length.should eql(2)
      messages.map(&:to).should be_include('dashboard')
    end
    
    it "should not send dispatch messages for pre-registered users" do
      notification_model
      u1 = user_model(:name => "user 2")
      u1.communication_channels.create(:path => "user2@example.com").confirm!
      @a = Assignment.create
      messages = @notification.create_message(@a, u1)
      messages.should be_empty
    end
    
    it "should send registration messages for pre-registered users" do
      notification_set(:user_opts => {:workflow_state => "pre_registered"}, :notification_opts => {:category => "Registration"})
      messages = @notification.create_message(@assignment, @user)
      messages.should_not be_empty
      messages.length.should eql(1)
      messages.first.to.should eql(@communication_channel.path)
    end
    
    it "should send dashboard and dispatch messages for registered users based on default policies" do
      notification_model(:category => 'TestImmediately')
      u1 = user_model(:name => "user 1", :workflow_state => "registered")
      u1.communication_channels.create(:path => "user1@example.com").confirm!
      @a = Assignment.create
      messages = @notification.create_message(@a, u1)
      messages.should_not be_empty
      messages.length.should eql(2)
      messages[0].to.should eql("user1@example.com")
      messages[1].to.should eql("dashboard")
    end
    
    it "should not dispatch non-immediate message based on default policies" do
      notification_model(:category => 'TestDaily', :name => "Show In Feed")
      @notification.default_frequency.should eql("daily")
      u1 = user_model(:name => "user 1", :workflow_state => "registered")
      
      # make the first channel retired, to verify that it'll get an active one
      retired_cc = u1.communication_channels.create(:path => "retired@example.com").retire!
      cc = u1.communication_channels.create(:path => "active@example.com")
      cc.confirm!
      
      @a = Assignment.create
      messages = @notification.create_message(@a, u1)
      messages.should_not be_empty
      messages.length.should eql(1)
      messages[0].to.should eql("dashboard")
      DelayedMessage.all.should_not be_empty
      DelayedMessage.last.should_not be_nil
      DelayedMessage.last.notification_id.should eql(@notification.id)
      DelayedMessage.last.communication_channel_id.should eql(cc.id)
      DelayedMessage.last.send_at.should > Time.now.utc
    end
    
    it "should send dashboard (but not dispatch messages) for registered users based on default policies" do
      notification_model(:category => 'TestNever', :name => "Show In Feed")
      @notification.default_frequency.should eql("never")
      u1 = user_model(:name => "user 1", :workflow_state => "registered")
      u1.communication_channels.create(:path => "user1@example.com").confirm!
      @a = Assignment.create
      messages = @notification.create_message(@a, u1)
      messages.should_not be_empty
      messages.length.should eql(1)
      messages[0].to.should eql("dashboard")
    end

    it "should replace messages when a similar notification occurs" do
      notification_set
      
      all_messages = []
      messages = @notification.create_message(@assignment, @user)
      all_messages += messages
      messages.length.should eql(2)
      m1 = messages.first
      m2 = messages.last
      
      messages = @notification.create_message(@assignment, @user)
      all_messages += messages
      messages.should_not be_empty
      messages.length.should eql(2)
      
      all_messages.select {|m| 
        m.to == m1.to and m.notification == m1.notification and m.communication_channel == m1.communication_channel
      }.length.should eql(2)

      all_messages.select {|m| 
        m.to == m2.to and m.notification == m2.notification and m.communication_channel == m2.communication_channel
      }.length.should eql(2)
    end
    
    it "should create stream items" do
      notification_set(:notification_opts => {:name => "Show In Feed"})
      StreamItem.for_user(@user).count.should eql(0)
      messages = @notification.create_message(@assignment, @user)
      StreamItem.for_user(@user).count.should eql(1)
      si = StreamItem.for_user(@user).first
      si.item_asset_string.should eql("message_")
    end
    
    it "should translate ERB in the notification" do
      notification_set
      messages = @notification.create_message(@assignment, @user)
      messages.each {|m| m.subject.should eql("This is 5!")}
    end

    context "localization" do
      before { notification_set }

      it "should respect browser locales" do
        I18n.backend.store_translations :piglatin, {:messages => {:test_name => {:email => {:subject => "Isthay isay ivefay!"}}}}
        @user.browser_locale = 'piglatin'
        @user.save(false) # the validation was declared before :piglatin was added, so we skip it
        messages = @notification.create_message(@assignment, @user)
        messages.each {|m| m.subject.should eql("Isthay isay ivefay!")}
        I18n.locale.should eql(:en)
      end

      it "should respect user locales" do
        I18n.backend.store_translations :shouty, {:messages => {:test_name => {:email => {:subject => "THIS IS *5*!!!!?!11eleventy1"}}}}
        @user.locale = 'shouty'
        @user.save(false)
        messages = @notification.create_message(@assignment, @user)
        messages.each {|m| m.subject.should eql("THIS IS *5*!!!!?!11eleventy1")}
        I18n.locale.should eql(:en)
      end

      it "should respect course locales" do
        course
        I18n.backend.store_translations :es, { :messages => { :test_name => { :email => { :subject => 'El Tigre Chino' } } } }
        @course.enroll_teacher(@user).accept!
        @course.update_attribute(:locale, 'es')
        messages = @notification.create_message(@course, @user)
        messages.each { |m| m.subject.should eql('El Tigre Chino') }
        I18n.locale.should eql(:en)
      end

      it "should respect account locales" do
        course
        I18n.backend.store_translations :es, { :messages => { :test_name => { :email => { :subject => 'El Tigre Chino' } } } }
        @course.account.update_attribute(:default_locale, 'es')
        @course.enroll_teacher(@user).accept!
        messages = @notification.create_message(@course, @user)
        messages.each { |m| m.subject.should eql('El Tigre Chino') }
        I18n.locale.should eql(:en)
      end
    end

    it "should not get confused with nil values in the to list" do
      notification_set
      messages = @notification.create_message(@assignment, nil)
      messages.should be_empty
    end
    
    it "should not send messages after the user's limit" do
      notification_set
      NotificationPolicy.count.should == 1
      Rails.cache.delete(['recent_messages_for', @user.id].cache_key)
      User.stubs(:max_messages_per_day).returns(1)
      User.max_messages_per_day.times do 
        messages = @notification.create_message(@assignment, @user)
        messages.select{|m| m.to != 'dashboard'}.should_not be_empty
      end
      DelayedMessage.count.should eql(0)
      messages = @notification.create_message(@assignment, @user)
      messages.select{|m| m.to != 'dashboard'}.should be_empty
      DelayedMessage.count.should eql(1)
      NotificationPolicy.count.should == 2
      # should not create more dummy policies
      messages = @notification.create_message(@assignment, @user)
      messages.select{|m| m.to != 'dashboard'}.should be_empty
      NotificationPolicy.count.should == 2
    end
    
    it "should not use notification policies for unconfirmed communication channels" do
      notification_set
      cc = communication_channel_model(:user_id => @user.id, :workflow_state => 'unconfirmed', :path => "nope")
      notification_policy_model(:communication_channel_id => cc.id, :notification_id => @notification.id)
      messages = @notification.create_message(@assignment, @user)
      messages.size.should == 2
      messages.map(&:to).sort.should == ['dashboard', 'value for path']
    end

    it "should force certain categories to send immediately" do
      notification_set(:notification_opts => { :name => "Thing 1", :category => 'Not Migration' })
      @notification_policy.frequency = 'daily'
      @notification_policy.save!
      expect { @notification.create_message(@assignment, @user) }.to change(DelayedMessage, :count).by 1

      notification_set(:notification_opts => { :name => "Thing 2", :category => 'Migration' })
      @notification_policy.frequency = 'daily'
      @notification_policy.save!
      expect { @notification.create_message(@assignment, @user) }.to change(DelayedMessage, :count).by 0
    end

    context "sharding" do
      it_should_behave_like "sharding"

      it "should create the message on the user's shard" do
        notification_set
        @shard1.activate do
          user_with_pseudonym(:active_all => 1)
          messages = @notification.create_message(@assignment, @user)
          messages.length.should >= 1
          messages.each { |m| m.shard.should == @shard1 }
        end
      end
    end
  end

  context "record_delayed_messages" do
    before do
      user_model
      communication_channel_model(:user_id => @user.id)
      @cc.confirm
      notification_model
      # Universal context
      old_user = @user
      assignment_model
      @user = old_user
      @valid_record_delayed_messages_opts = {
        :user => @user,
        :communication_channel => @cc,
        :asset => @assignment
      }
    end
    
    it "should only work when a user is passed to it" do
      lambda{@notification.record_delayed_messages}.should raise_error(ArgumentError, "Must provide a user")
    end
    
    it "should only work when a communication_channel is passed to it" do
      # One without a communication_channel, gets cc explicitly through 
      # :to => cc or implicitly through the user. 
      user_model 
      lambda{@notification.record_delayed_messages(:user => @user)}.should raise_error(ArgumentError, 
        "Must provide an asset")
    end
    
    it "should only work when a context is passed to it" do
      lambda{@notification.record_delayed_messages(:user => @user, :to => @communication_channel)}.should raise_error(ArgumentError, 
        "Must provide an asset")
    end
    
    it "should work with a user, communication_channel, and context" do
      lambda{@notification.record_delayed_messages(@valid_record_delayed_messages_opts)}.should_not raise_error
    end
    
    context "testing that the applicable daily or weekly policies exist" do
      before do
        NotificationPolicy.delete_all

        @trifecta_opts = {
          :communication_channel => @communication_channel,
          :notification => @notification
        }
      end
        
      it "should return false without these policies in place" do
        notification_policy_model
        @notification.record_delayed_messages(@valid_record_delayed_messages_opts).should be_false
      end
      
      it "should return false with the right models and the wrong policies" do
        notification_policy_model({:frequency => "immediately"}.merge(@trifecta_opts) )
        @notification.record_delayed_messages(@valid_record_delayed_messages_opts).should be_false
        
        notification_policy_model({:frequency => "never"}.merge(@trifecta_opts) )
        @notification.record_delayed_messages(@valid_record_delayed_messages_opts).should be_false
      end
      
      it "should return the delayed message model with the right models and the daily policies" do
        notification_policy_model({:frequency => "daily"}.merge(@trifecta_opts) )
        @user.reload
        delayed_messages = @notification.record_delayed_messages(@valid_record_delayed_messages_opts)
        delayed_messages.should be_is_a(Array)
        delayed_messages.size.should eql(1)
        delayed_messages.each {|x| x.should be_is_a(DelayedMessage) }
      end

      it "should return the delayed message model with the right models and the weekly policies" do
        notification_policy_model({:frequency => "weekly"}.merge(@trifecta_opts) )
        @user.reload
        delayed_messages = @notification.record_delayed_messages(@valid_record_delayed_messages_opts)
        delayed_messages.should be_is_a(Array)
        delayed_messages.size.should eql(1)
        delayed_messages.each {|x| x.should be_is_a(DelayedMessage) }
      end
      
      it "should return the delayed message model with the right models and a mix of policies" do
        notification_policy_model({:frequency => "immediately"}.merge(@trifecta_opts) )
        notification_policy_model({:frequency => "never"}.merge(@trifecta_opts) )
        notification_policy_model({:frequency => "daily"}.merge(@trifecta_opts) )
        notification_policy_model({:frequency => "weekly"}.merge(@trifecta_opts) )
        @user.reload
        delayed_messages = @notification.record_delayed_messages(@valid_record_delayed_messages_opts)
        delayed_messages.should be_is_a(Array)
        delayed_messages.size.should eql(2)
        delayed_messages.each {|x| x.should be_is_a(DelayedMessage) }
      end
      
      it "should actually create the DelayedMessage model" do
        i = DelayedMessage.all.size
        notification_policy_model({:frequency => "weekly"}.merge(@trifecta_opts) )
        @user.reload
        @notification.record_delayed_messages(@valid_record_delayed_messages_opts)
        DelayedMessage.all.size.should eql(i + 1)
      end
      
      it "should not send a delayed message to a retired cc" do
        notification_policy_model({:frequency => "weekly"}.merge(@trifecta_opts) )
        @cc.retire!
        communication_channel_model(:user_id => @user.id).confirm!
        notification_policy_model({:frequency => "never",
                                   :communication_channel => @communication_channel,
                                   :notification => @notification})
        @notification.record_delayed_messages(:user => @user,
                                              :communication_channel => @communication_channel,
                                              :asset => @assignment).should be_false
      end
        
    end # testing that the applicable daily or weekly policies exist
  end # delay message
end


def notification_set(opts={})
  user_opts = opts.delete(:user_opts) || {}
  notification_opts = opts.delete(:notification_opts)  || {}
  
  assignment_model
  notification_model({:subject => "<%= t :subject, 'This is 5!' %>", :name => "Test Name"}.merge(notification_opts))
  user_model({:workflow_state => 'registered'}.merge(user_opts))
  communication_channel_model(:user_id => @user).confirm!
  notification_policy_model(
    :notification => @notification,
    :communication_channel => @communication_channel
  )
  @notification.reload
end

# The opts pertain to user only
def create_user_with_cc(opts={})
  user_model(opts)

  if @notification
    communication_channel_model
    @communication_channel.notification_policies.create!(:notification => @notification)
  else
    communication_channel_model
  end

  @user.reload
  @user
end
