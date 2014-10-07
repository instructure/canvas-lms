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
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#

require File.expand_path(File.dirname(__FILE__) + '/../sharding_spec_helper.rb')

## Helpers
def notification_set(opts = {})
  user_opts = opts.delete(:user_opts) || {}
  notification_opts = opts.delete(:notification_opts)  || {}

  assignment_model
  notification_model({:subject => "<%= t :subject, 'This is 5!' %>", :name => "Test Name"}.merge(notification_opts))
  user_model({:workflow_state => 'registered'}.merge(user_opts))
  communication_channel_model.confirm!
  notification_policy_model(:notification => @notification,
                            :communication_channel => @communication_channel)

  @notification.reload
end

# The opts pertain to user only
def create_user_with_cc(opts = {})
  user_model(opts)

  if @notification
    communication_channel_model
    @communication_channel.notification_policies.create!(notification: @notification, frequency: Notification::FREQ_DAILY)
  else
    communication_channel_model
  end

  @user.reload
end

describe NotificationMessageCreator do
  context 'create_message' do
    before(:each) do
      Message.any_instance.stubs(:get_template).returns('template')
    end

    it "should only send dashboard messages for users with non-validated channels" do
      notification_model
      u1 = create_user_with_cc(:name => "user 1", :workflow_state => "registered")
      u1.communication_channels.create(:path => "user1@example.com")
      u2 = create_user_with_cc(:name => "user 2")
      u2.communication_channels.create(:path => "user2@example.com")
      @a = Assignment.create
      messages = NotificationMessageCreator.new(@notification, @a, :to_list => [u1, u2]).create_message
      messages.length.should eql(2)
      messages.map(&:to).should be_include('dashboard')
    end

    it "should only send messages to active communication channels" do
      assignment_model
      user_model(:workflow_state => 'registered')
      a = communication_channel_model(:workflow_state => 'active')
      b = communication_channel_model(:workflow_state => 'active', :path => "path2@example.com")
      c = communication_channel_model(:workflow_state => 'active', :path => "path3@example.com")
      d = communication_channel_model(:path => "path4@example.com")
      notification_model
      [a, b, c, d].each do |channel|
        notification_policy_model(:communication_channel => channel,
                                  :notification => @notification,
                                  :frequency => "immediately")
      end
      @user.reload
      messages = NotificationMessageCreator.new(@notification, @assignment, :to_list => @user).create_message
      paths = messages.collect{ |message| message.to }
      paths.should include(a.path)
      paths.should include(b.path)
      paths.should include(c.path)
      paths.should_not include(d.path)
    end
    
    it "should use the default channel if no policies apply" do
      assignment_model
      user_model(:workflow_state => 'registered')
      a = communication_channel_model(:workflow_state => 'active')
      b = communication_channel_model(:path => "path2@example.com")
      c = communication_channel_model(:path => "path3@example.com")
      a.should be_active
      a.should 
      
      @n = Notification.create(:name => "New Notification")
      a.notification_policies.create!(:notification => @n, :frequency => Notification::FREQ_IMMEDIATELY)
      messages = NotificationMessageCreator.new(@n, @assignment, :to_list => @user).create_message
      messages.count.should eql(1)
      messages.first.communication_channel.should eql(@user.communication_channel)
    end

    it "should not use the default if a policy does apply" do
      assignment_model
      @user = user_model(:workflow_state => 'registered')
      a = @user.communication_channels.create(:path => "a@example.com", :path_type => 'email')
      a.confirm!
      b = @user.communication_channels.create(:path => "b@example.com")
      b.confirm!
      @n = Notification.create!(:name => "New notification", :category => 'TestImmediately')
      messages = NotificationMessageCreator.new(@n, @assignment, :to_list => @user).create_message
      channels = messages.collect(&:communication_channel)
      channels.should include(a)
      channels.should_not include(b)
      
      b.notification_policies.create!(:notification => @n, :frequency => 'immediately')
      messages = NotificationMessageCreator.new(@n, @assignment, :to_list => @user).create_message
      channels = messages.collect(&:communication_channel)
      channels.should include(b)
      channels.should_not include(a)
    end

    it "should not send dispatch messages for pre-registered users" do
      notification_model
      u1 = user_model(:name => "user 2")
      u1.communication_channels.create(:path => "user2@example.com").confirm!
      @a = Assignment.create
      messages = NotificationMessageCreator.new(@notification, @a, :to_list => u1).create_message
      messages.should be_empty
    end

    it "should send registration messages for pre-registered users" do
      notification_set(:user_opts => {:workflow_state => "pre_registered"}, :notification_opts => {:category => "Registration"})
      messages = NotificationMessageCreator.new(@notification, @assignment, :to_list => @user).create_message
      messages.should_not be_empty
      messages.length.should eql(1)
      messages.first.to.should eql(@communication_channel.path)
    end

    it "should send registration messages to the communication channels in the to list" do
      notification_set(:notification_opts => {:category => "Registration"})
      cc = @user.communication_channels.create(:path => 'user1@example.com')
      @user.communication_channels.create(:path => 'user2@example.com').confirm!
      messages = NotificationMessageCreator.new(@notification, @assignment, :to_list => [cc]).create_message
      messages.length.should eql(1)
      messages[0].to.should eql(cc.path)
    end
    
    it "should send dashboard and dispatch messages for registered users based on default policies" do
      notification_model(:category => 'TestImmediately')
      u1 = user_model(:name => "user 1", :workflow_state => "registered")
      u1.communication_channels.create(:path => "user1@example.com").confirm!
      @a = Assignment.create
      messages = NotificationMessageCreator.new(@notification, @a, :to_list => u1).create_message
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

      @a = assignment_model
      messages = NotificationMessageCreator.new(@notification, @a, :to_list => u1).create_message
      messages.should_not be_empty
      messages.length.should eql(1)
      messages[0].to.should eql("dashboard")
      DelayedMessage.all.should_not be_empty
      DelayedMessage.last.should_not be_nil
      DelayedMessage.last.notification_id.should eql(@notification.id)
      DelayedMessage.last.communication_channel_id.should eql(cc.id)
      DelayedMessage.last.root_account_id.should eql Account.default.id
      DelayedMessage.last.send_at.should > Time.now.utc
    end

    it "should make a delayed message for each user policy with a delayed frequency" do
      notification_set
      NotificationPolicy.delete_all
      nps = (1..3).map do |i|
        communication_channel_model(:path => "user#{i}@example.com").confirm!
        notification_policy_model(:notification => @notification,
                                  :communication_channel => @communication_channel,
                                  :frequency => 'immediately')
      end

      expect { NotificationMessageCreator.new(@notification, @assignment, :to_list => @user).create_message }.to change(DelayedMessage, :count).by 0

      nps.each { |np| np.frequency = 'never'; np.save! }
      expect { NotificationMessageCreator.new(@notification, @assignment, :to_list => @user).create_message }.to change(DelayedMessage, :count).by 0

      nps.each { |np| np.frequency = 'daily'; np.save! }
      expect { NotificationMessageCreator.new(@notification, @assignment, :to_list => @user).create_message }.to change(DelayedMessage, :count).by 3

      nps.each { |np| np.frequency = 'weekly'; np.save! }
      expect { NotificationMessageCreator.new(@notification, @assignment, :to_list => @user).create_message }.to change(DelayedMessage, :count).by 3
    end

    it "should make a delayed message for the default channel based on the notification's default frequency when there is no policy on any channel for the notification" do
      notification_set # we get one channel here
      communication_channel_model(:path => 'this one gets a delayed policy').confirm! # this gives us a total of two channels
      NotificationPolicy.delete_all
      @notification.category = 'Discussion' # default frequency of 'Never'
      expect { NotificationMessageCreator.new(@notification, @assignment, :to_list => @user).create_message }.to change(DelayedMessage, :count).by 0
      @notification.category = 'DiscussionEntry' # default frequency of 'Daily'
      expect { NotificationMessageCreator.new(@notification, @assignment, :to_list => @user).create_message }.to change(DelayedMessage, :count).by 1
      DelayedMessage.delete_all
      NotificationPolicy.delete_all # gotta do this because create_message actually creates the default policy
      notification_policy_model(:notification => @notification,
                                :communication_channel => @communication_channel,
                                :frequency => 'immediately')
      expect { NotificationMessageCreator.new(@notification, @assignment, :to_list => @user).create_message }.to change(DelayedMessage, :count).by 0
    end
  
    it "should send dashboard (but not dispatch messages) for registered users based on default policies" do
      notification_model(:category => 'TestNever', :name => "Show In Feed")
      @notification.default_frequency.should eql("never")
      u1 = user_model(:name => "user 1", :workflow_state => "registered")
      u1.communication_channels.create(:path => "user1@example.com").confirm!
      @a = Assignment.create
      messages = NotificationMessageCreator.new(@notification, @a, :to_list => u1).create_message
      messages.should_not be_empty
      messages.length.should eql(1)
      messages[0].to.should eql("dashboard")
    end
    
    it "should not send dashboard messages for non-feed or non-dashboard messages" do
      notification_model(:category => 'TestNever', :name => "Don't Show In Feed")
      @notification.default_frequency.should eql("never")
      u1 = user_model(:name => "user 1", :workflow_state => "registered")
      u1.communication_channels.create(:path => "user1@example.com").confirm!
      @a = Assignment.create
      messages = NotificationMessageCreator.new(@notification, @a, :to_list => u1).create_message
      messages.should be_empty
      @notification.name = "Show In Feed"
      @notification.category = "Summaries"
      messages = NotificationMessageCreator.new(@notification, @a, :to_list => u1).create_message
      messages.should be_empty
    end

    it "should replace messages when a similar notification occurs" do
      notification_set

      all_messages = []
      messages = NotificationMessageCreator.new(@notification, @assignment, :to_list => @user).create_message
      all_messages += messages
      messages.length.should eql(2)
      m1 = messages.first
      m2 = messages.last

      messages = NotificationMessageCreator.new(@notification, @assignment, :to_list => @user).create_message
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
      @user.stream_item_instances.count.should == 0
      messages = NotificationMessageCreator.new(@notification, @assignment, :to_list => @user).create_message
      @user.stream_item_instances.count.should == 1
      si = @user.stream_item_instances.first.stream_item
      si.asset_type.should == 'Message'
      si.asset_id.should be_nil
    end

    it "should not get confused with nil values in the to list" do
      notification_set
      messages = NotificationMessageCreator.new(@notification, @assignment, :to_list => nil).create_message
      messages.should be_empty
    end

    it "should not send messages after the user's limit" do
      notification_set
      NotificationPolicy.count.should == 1
      Rails.cache.delete(['recent_messages_for', @user.id].cache_key)
      User.stubs(:max_messages_per_day).returns(1)
      User.max_messages_per_day.times do 
        messages = NotificationMessageCreator.new(@notification, @assignment, :to_list => @user).create_message
        messages.select{|m| m.to != 'dashboard'}.should_not be_empty
      end
      DelayedMessage.count.should eql(0)
      messages = NotificationMessageCreator.new(@notification, @assignment, :to_list => @user).create_message
      messages.select{|m| m.to != 'dashboard'}.should be_empty
      DelayedMessage.count.should eql(1)
      NotificationPolicy.count.should == 2
      # should not create more dummy policies
      messages = NotificationMessageCreator.new(@notification, @assignment, :to_list => @user).create_message
      messages.select{|m| m.to != 'dashboard'}.should be_empty
      NotificationPolicy.count.should == 2
    end

    it "should not send to bouncing channels" do
      notification_set
      @communication_channel.bounce_count = 1
      @communication_channel.save!
      messages = NotificationMessageCreator.new(@notification, @assignment, :to_list => @user).create_message
      messages.select{|m| m.to == 'value for path'}.size.should == 1

      @communication_channel.bounce_count = 100
      @communication_channel.save!
      messages = NotificationMessageCreator.new(@notification, @assignment, :to_list => @user).create_message
      messages.select{|m| m.to == 'value for path'}.size.should == 0
    end

    it "should not use notification policies for unconfirmed communication channels" do
      notification_set
      cc = communication_channel_model(:workflow_state => 'unconfirmed', :path => "nope")
      notification_policy_model(:communication_channel_id => cc.id, :notification_id => @notification.id)
      messages = NotificationMessageCreator.new(@notification, @assignment, :to_list => @user).create_message
      messages.size.should == 2
      messages.map(&:to).sort.should == ['dashboard', 'value for path']
    end

    it "should force certain categories to send immediately" do
      notification_set(:notification_opts => { :name => "Thing 1", :category => 'Not Migration' })
      @notification_policy.frequency = 'daily'
      @notification_policy.save!
      expect { NotificationMessageCreator.new(@notification, @assignment, :to_list => @user).create_message }.to change(DelayedMessage, :count).by 1

      notification_set(:notification_opts => { :name => "Thing 2", :category => 'Migration' })
      @notification_policy.frequency = 'daily'
      @notification_policy.save!
      expect { NotificationMessageCreator.new(@notification, @assignment, :to_list => @user).create_message }.to change(DelayedMessage, :count).by 0
    end

    it "should not use retired channels for summary messages" do
      notification_set
      @notification_policy.frequency = 'daily'
      @notification_policy.save!
      @communication_channel.retire!

      expect {
        NotificationMessageCreator.new(@notification, @assignment, :to_list => @user).create_message
      }.to change(DelayedMessage, :count).by 0
    end
 end
  
  context "localization" do
    before(:each) do
      notification_set
      Message.any_instance.stubs(:body).returns('template')
    end

    it "should translate ERB in the notification" do
      messages = NotificationMessageCreator.new(@notification, @assignment, :to_list => @user).create_message
      messages.each {|m| m.subject.should eql("This is 5!")}
    end

    it "should respect browser locales" do
      I18n.backend.stub(piglatin: {messages: {test_name: {email: {subject: "Isthay isay ivefay!"}}}}) do
        @user.browser_locale = 'piglatin'
        @user.save(validate: false) # the validation was declared before :piglatin was added, so we skip it
        messages = NotificationMessageCreator.new(@notification, @assignment, :to_list => @user).create_message
        messages.each {|m| m.subject.should eql("Isthay isay ivefay!")}
        I18n.locale.should eql(:en)
      end
    end

    it "should respect user locales" do
      I18n.backend.stub(shouty: {messages: {test_name: {email: {subject: "THIS IS *5*!!!!?!11eleventy1"}}}}) do
        @user.locale = 'shouty'
        @user.save(validate: false)
        messages = NotificationMessageCreator.new(@notification, @assignment, :to_list => @user).create_message
        messages.each {|m| m.subject.should eql("THIS IS *5*!!!!?!11eleventy1")}
        I18n.locale.should eql(:en)
      end
    end

    it "should respect course locales" do
      course
      I18n.backend.stub(es: {messages: {test_name: {email: {subject: 'El Tigre Chino'}}}}) do
        @course.enroll_teacher(@user).accept!
        @course.update_attribute(:locale, 'es')
        messages = NotificationMessageCreator.new(@notification, @course, :to_list => @user).create_message
        messages.each { |m| m.subject.should eql('El Tigre Chino') }
        I18n.locale.should eql(:en)
      end
    end

    it "should respect account locales" do
      course
      I18n.backend.stub(es: {messages: {test_name: {email: {subject: 'El Tigre Chino'}}}}) do
        @course.account.update_attribute(:default_locale, 'es')
        @course.enroll_teacher(@user).accept!
        messages = NotificationMessageCreator.new(@notification, @course, :to_list => @user).create_message
        messages.each { |m| m.subject.should eql('El Tigre Chino') }
        I18n.locale.should eql(:en)
      end
    end
  end

  context "sharding" do
    specs_require_sharding

    it "should create the message on the user's shard" do
      notification_set
      Message.any_instance.stubs(:get_template).returns('template')
      @shard1.activate do
        account = Account.create!
        user_with_pseudonym(:active_all => 1, :account => account)
        messages = NotificationMessageCreator.new(@notification, @assignment, :to_list => @user).create_message
        messages.length.should >= 1
        messages.each { |m| m.shard.should == @shard1 }
      end
    end

    it "should create policies and summary messages on the user's shard" do
      @shard1.activate do
        @user = User.create!
        @cc = @user.communication_channels.create!(path: "user@example.com")
        @cc.confirm!
      end
      notification_model(category: 'TestWeekly')
      Message.any_instance.stubs(:get_template).returns('template')
      @cc.notification_policies.should be_empty
      @cc.delayed_messages.should be_empty
      NotificationMessageCreator.new(@notification, @user, :to_list => @user).create_message
      @cc.notification_policies.reload.should_not be_empty
      @cc.delayed_messages.reload.should_not be_empty

    end

    it "should find an already existing notification policy" do
      notification_model(category: 'TestWeekly')
      @shard1.activate do
        @user = User.create!
        @cc = @user.communication_channels.create!(path: "user@example.com")
        @cc.confirm!
        @cc.notification_policies.create!(
          :notification => @notification,
          :frequency => @notification.default_frequency
        )
      end
      Message.any_instance.stubs(:get_template).returns('template')
      @cc.notification_policies.reload.count.should == 1
      NotificationMessageCreator.new(@notification, @user, :to_list => @user).create_message
      @cc.notification_policies.reload.count.should == 1
    end
  end
end
