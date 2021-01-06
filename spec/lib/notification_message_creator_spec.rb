# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

describe NotificationMessageCreator do
  context 'create_message' do
    before(:each) do
      allow_any_instance_of(Message).to receive(:get_template).and_return('template')
    end

    it "should only send dashboard messages for users with non-validated channels" do
      assignment_model
      notification_model
      u1 = user_model(:workflow_state => "registered")
      c1 = communication_channel_model(:path => "user@example.com", :workflow_state => 'active')
      u2 = user_model(:workflow_state => "registered")
      c2 = communication_channel_model
      [c1, c2].each do |cc|
        notification_policy_model(:communication_channel => cc,
                                  :notification => @notification,
                                  :frequency => "immediately")
      end
      messages = NotificationMessageCreator.new(@notification, @assignment, :to_list => [u1, u2]).create_message
      expect(messages.length).to eql(3)
      expect(messages.map(&:to).sort).to eq ['dashboard', 'dashboard', 'user@example.com']
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
      expect(paths).to include(a.path)
      expect(paths).to include(b.path)
      expect(paths).to include(c.path)
      expect(paths).not_to include(d.path)
    end

    it "should use the default channel if no policies apply" do
      assignment_model
      user_model(:workflow_state => 'registered')
      a = communication_channel_model(:workflow_state => 'active')
      b = communication_channel_model(:path => "path2@example.com")
      c = communication_channel_model(:path => "path3@example.com")
      expect(a).to be_active

      @n = Notification.create(:name => "New Notification")
      a.notification_policies.create!(:notification => @n, :frequency => Notification::FREQ_IMMEDIATELY)
      messages = NotificationMessageCreator.new(@n, @assignment, :to_list => @user).create_message
      expect(messages.count).to eql(1)
      expect(messages.first.communication_channel).to eql(@user.communication_channel)
    end

    it 'uses the default channel and the push channel if only the push channel has a policy' do
      assignment_model
      @user = user_model(:workflow_state => 'registered')
      a = communication_channel(@user, {username: 'a@example.com', active_cc: true})
      b = communication_channel(@user, {username: 'b@example.com', active_cc: true})
      @n = Notification.create!(:name => "New notification", :category => 'TestImmediately')
      messages = NotificationMessageCreator.new(@n, @assignment, :to_list => @user).create_message
      channels = messages.collect(&:communication_channel)
      expect(channels).to include(a)
      expect(channels).not_to include(b)

      b.notification_policies.create!(:notification => @n, :frequency => 'immediately')
      messages = NotificationMessageCreator.new(@n, @assignment, :to_list => @user).create_message
      channels = messages.collect(&:communication_channel)
      expect(channels).to include(b)
      expect(channels).to include(a)
    end

    it 'only sends notifications to active channels' do
      assignment_model
      @user = user_model(:workflow_state => 'registered')
      a = communication_channel(@user, {username: 'a@example.com', active_cc: true})
      b = communication_channel(@user, {username: 'b@example.com'})
      @n = Notification.create!(:name => "New notification", :category => 'TestImmediately')

      messages = NotificationMessageCreator.new(@n, @assignment, :to_list => @user).create_message
      channels = messages.collect(&:communication_channel)
      expect(channels).to include(a)
      expect(channels).not_to include(b)
    end

    it 'does not send a notification when policy override is disabled for a course' do
      notification_set(notification_opts: { :category => "Announcement" })
      NotificationPolicyOverride.enable_for_context(@user, @course, enable: false)
      data = { course_id: @course.id, root_account_id: @course.root_account_id }
      messages = NotificationMessageCreator.new(@notification, @assignment, to_list: @user, data: data).create_message
      expect(messages).to be_empty
    end

    it 'does send a notification when course_id is not passed in' do
      notification_set(notification_opts: { :category => "Announcement" })
      NotificationPolicyOverride.enable_for_context(@user, @course, enable: false)
      data = { root_account_id: @course.root_account_id }
      messages = NotificationMessageCreator.new(@notification, @assignment, to_list: @user, data: data).create_message
      expect(messages.length).to eql(1)
    end

    it 'should send registration emails to unconfirmed communication_channels' do
      notification_model({ subject: "test", name: "Test Name", category: "Registration" })
      communication_channel(user_model, cc_state: 'unconfirmed')
      account_user = account_model.account_users.create!(user: @user)
      messages = NotificationMessageCreator.new(@notification, account_user, to_list: @user).create_message
      expect(messages.length).to eql(1)
    end

    it 'does send other notifications when policy override is in effect' do
      notification_set(notification_opts: { :category => "Registration" })
      NotificationPolicyOverride.enable_for_context(@user, @course, enable: false)
      data = { course_id: @course.id, root_account_id: @course.root_account_id }
      messages = NotificationMessageCreator.new(@notification, @assignment, to_list: @user, data: data).create_message
      expect(messages.length).to eql(1)
    end

    it "should not send dispatch messages for pre-registered users" do
      course_factory
      notification_model
      u1 = user_model(:name => "user 2")
      communication_channel(u1, {username: 'user2@example.com', active_cc: true})
      @a = @course.assignments.create
      messages = NotificationMessageCreator.new(@notification, @a, :to_list => u1).create_message
      expect(messages).to be_empty
    end

    it "should send registration messages for pre-registered users" do
      notification_set(:user_opts => {:workflow_state => "pre_registered"}, :notification_opts => {:category => "Registration"})
      messages = NotificationMessageCreator.new(@notification, @assignment, :to_list => @user).create_message
      expect(messages).not_to be_empty
      expect(messages.length).to eql(1)
      expect(messages.first.to).to eql(@communication_channel.path)
    end

    it "should send registration messages to the communication channels in the to list" do
      notification_set(:notification_opts => {:category => "Registration"})
      cc = communication_channel(@user, {username: 'user1@example.com'})
      communication_channel(@user, {username: 'user2@example.com', active_cc: true})
      messages = NotificationMessageCreator.new(@notification, @assignment, :to_list => [cc]).create_message
      expect(messages.length).to be(1)
      expect(messages[0].to).to eql(cc.path)
    end

    it "should send dashboard and dispatch messages for registered users based on default policies" do
      course_factory
      notification_model(:category => 'TestImmediately')
      u1 = user_model(:name => "user 1", :workflow_state => "registered")
      communication_channel(u1, {username: 'user1@example.com', active_cc: true})
      @a = @course.assignments.create
      messages = NotificationMessageCreator.new(@notification, @a, :to_list => u1).create_message
      expect(messages).not_to be_empty
      expect(messages.length).to be(2)
      expect(messages[0].to).to eql("user1@example.com")
      expect(messages[1].to).to eql("dashboard")
    end

    it "should not dispatch non-immediate message based on default policies" do
      notification_model(:category => 'TestDaily', :name => "Show In Feed")
      expect(@notification.default_frequency).to eql("daily")
      u1 = user_model(:name => "user 1", :workflow_state => "registered")

      # make the first channel retired, to verify that it'll get an active one
      communication_channel(u1, {username: 'retired@example.com', cc_state: 'retired'})
      cc = communication_channel(u1, {username: 'active@example.com', active_cc: true})

      @a = assignment_model
      messages = NotificationMessageCreator.new(@notification, @a, :to_list => u1).create_message
      expect(messages).not_to be_empty
      expect(messages.length).to eql(1)
      expect(messages[0].to).to eql("dashboard")
      expect(DelayedMessage.all).not_to be_empty
      expect(DelayedMessage.last).not_to be_nil
      expect(DelayedMessage.last.notification_id).to eql(@notification.id)
      expect(DelayedMessage.last.communication_channel_id).to eql(cc.id)
      expect(DelayedMessage.last.root_account_id).to eql Account.default.id
      expect(DelayedMessage.last.send_at).to be > Time.now.utc
    end

    it "should be able to set default policies to never for a specific user" do
      notification_model(:category => 'TestImmediately', :name => "New notification")
      expect(@notification.default_frequency).to eql("immediately")

      u1 = user_model(:name => "user 1", :workflow_state => "registered")
      u1.default_notifications_disabled = true
      u1.save!
      communication_channel(u1, {username: 'active@example.com', active_cc: true})
      u2 = user_model(:name => "user 2", :workflow_state => "registered")
      cc2 = communication_channel(u2, {username: 'active2@example.com', active_cc: true})

      @a = assignment_model
      messages = NotificationMessageCreator.new(@notification, @a, :to_list => [u1, u2]).create_message
      expect(messages.map(&:communication_channel).compact).to eq [cc2] # doesn't include u1's cc
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
      @user.reload
      expect { NotificationMessageCreator.new(@notification, @assignment, :to_list => @user).create_message }.to change(DelayedMessage, :count).by 0

      nps.each { |np| np.frequency = 'daily'; np.save! }
      @user.reload
      expect { NotificationMessageCreator.new(@notification, @assignment, :to_list => @user).create_message }.to change(DelayedMessage, :count).by 3

      nps.each { |np| np.frequency = 'weekly'; np.save! }
      @user.reload
      expect { NotificationMessageCreator.new(@notification, @assignment, :to_list => @user).create_message }.to change(DelayedMessage, :count).by 3
    end

    it "should make a delayed message for a notification with a set delayed frequency (even if another policy is set to immediate)" do
      notification_set
      @notification_policy.update_attribute(:frequency, 'daily')

      other_notification =  Notification.create!(:subject => "yo", :name => "Test Not 2")
      other_np = NotificationPolicy.create!(:notification => other_notification, :communication_channel => @communication_channel)

      NotificationMessageCreator.new(@notification, @assignment, :to_list => @user).create_message
      expect(Message.where(:communication_channel_id => @communication_channel).exists?).to eq false # no immediate message
      expect(DelayedMessage.where(:communication_channel_id => @communication_channel).exists?).to eq true
    end

    describe "notification's default frequency" do
      before(:once) do
        # two channels, two notifications with default freq of never and daily, and a notification policy.
        notification_set({ notification_opts: { category: 'Discussion' } })
        @a = @cc
        @never_notification = @notification
        communication_channel_model(path: 'yes@example.com').confirm!
        @b = @cc
      end

      let(:notification) { notification_model({ subject: "<%= t :subject, 'hoy es today' %>", name: "Test daily", category: 'DiscussionEntry' }) }
      let(:immediate_notification) { notification_model({ name: "Newish notification", category: 'TestImmediately' }) }

      it 'should not create delayed messages when default is never' do
        expect { NotificationMessageCreator.new(@never_notification, @assignment, to_list: @user).create_message }.to change(DelayedMessage, :count).by 0
      end

      it 'should use the default policy on default channel' do
        expect { NotificationMessageCreator.new(notification, @assignment, :to_list => @user).create_message }.to change(DelayedMessage, :count).by 1
      end

      it 'should not use default policy on default channel when other policy exists' do
        notification_policy_model(notification: notification, communication_channel: @communication_channel, frequency: 'immediately')
        expect { NotificationMessageCreator.new(notification, @assignment, :to_list => @user).create_message }.to change(DelayedMessage, :count).by 0
      end

      it "should use default policy on immediate notifications" do
        messages = NotificationMessageCreator.new(immediate_notification, @assignment, :to_list => @user).create_message
        channels = messages.collect(&:communication_channel)
        expect(channels).to include(@a)
        expect(channels).not_to include(@b)
      end

      it 'should not use default policy on immediate notifications when other policy exists' do
        notification_policy_model(notification: immediate_notification, communication_channel: @b, frequency: 'immediately')
        messages = NotificationMessageCreator.new(immediate_notification, @assignment, :to_list => @user).create_message
        channels = messages.collect(&:communication_channel)
        expect(channels).to include(@b)
        expect(channels).not_to include(@a)
      end
    end

    it "should send dashboard (but not dispatch messages) for registered users based on default policies" do
      course_factory
      notification_model(:category => 'TestNever', :name => "Show In Feed")
      expect(@notification.default_frequency).to eql("never")
      u1 = user_model(:name => "user 1", :workflow_state => "registered")
      communication_channel(u1, {username: 'user1@example.com', active_cc: true})
      @a = @course.assignments.create()
      messages = NotificationMessageCreator.new(@notification, @a, :to_list => u1).create_message
      expect(messages).not_to be_empty
      expect(messages.length).to be(1)
      expect(messages[0].to).to eql("dashboard")
    end

    it "should not send dashboard messages for non-feed or non-dashboard messages" do
      course_factory
      notification_model(:category => 'TestNever', :name => "Don't Show In Feed")
      expect(@notification.default_frequency).to eql("never")
      u1 = user_model(:name => "user 1", :workflow_state => "registered")
      communication_channel(u1, {username: 'user1@example.com', active_cc: true})
      @a = @course.assignments.create
      messages = NotificationMessageCreator.new(@notification, @a, :to_list => u1).create_message
      expect(messages).to be_empty
      @notification.name = "Show In Feed"
      @notification.category = "Summaries"
      messages = NotificationMessageCreator.new(@notification, @a, :to_list => u1).create_message
      expect(messages).to be_empty
    end

    it "should replace messages when a similar notification occurs" do
      notification_set

      all_messages = []
      messages = NotificationMessageCreator.new(@notification, @assignment, :to_list => @user).create_message
      all_messages += messages
      expect(messages.length).to eql(2)
      m1 = messages.first
      m2 = messages.last

      messages = NotificationMessageCreator.new(@notification, @assignment, :to_list => @user).create_message
      all_messages += messages
      expect(messages).not_to be_empty
      expect(messages.length).to eql(2)

      expect(all_messages.select {|m|
        m.to == m1.to and m.notification == m1.notification and m.communication_channel == m1.communication_channel
      }.length).to eql(2)

      expect(all_messages.select {|m|
        m.to == m2.to and m.notification == m2.notification and m.communication_channel == m2.communication_channel
      }.length).to eql(2)
    end

    it "should create stream items" do
      notification_set(:notification_opts => {:name => "Show In Feed"})
      expect(@user.stream_item_instances.count).to eq 0
      messages = NotificationMessageCreator.new(@notification, @assignment, :to_list => @user).create_message
      expect(@user.stream_item_instances.count).to eq 1
      si = @user.stream_item_instances.first.stream_item
      expect(si.asset_type).to eq 'Message'
      expect(si.asset_id).to be_nil
    end

    it "should not get confused with nil values in the to list" do
      notification_set
      messages = NotificationMessageCreator.new(@notification, @assignment, :to_list => nil).create_message
      expect(messages).to be_empty
    end

    it "should not send messages after the user's limit" do
      notification_set
      expect(NotificationPolicy.count).to eq 1
      Rails.cache.delete(['recent_messages_for', @user.id].cache_key)
      allow(User).to receive(:max_messages_per_day).and_return(1)
      User.max_messages_per_day.times do
        messages = NotificationMessageCreator.new(@notification, @assignment, :to_list => @user).create_message
        expect(messages.select{|m| m.to != 'dashboard'}).not_to be_empty
      end
      expect(DelayedMessage.count).to eql(0)
      messages = NotificationMessageCreator.new(@notification, @assignment, :to_list => @user).create_message
      expect(messages.select{|m| m.to != 'dashboard'}).to be_empty
      expect(DelayedMessage.count).to eql(1)
      expect(NotificationPolicy.count).to eq 2
      # should not create more dummy policies
      messages = NotificationMessageCreator.new(@notification, @assignment, :to_list => @user).create_message
      expect(messages.select{|m| m.to != 'dashboard'}).to be_empty
      expect(NotificationPolicy.count).to eq 2
    end

    it "should not send to bouncing channels" do
      notification_set
      @communication_channel.bounce_count = CommunicationChannel::RETIRE_THRESHOLD - 1
      @communication_channel.save!
      messages = NotificationMessageCreator.new(@notification, @assignment, :to_list => @user).create_message
      expect(messages.select{|m| m.to == 'valid@example.com'}.size).to eq 1

      @communication_channel.bounce_count = CommunicationChannel::RETIRE_THRESHOLD
      @communication_channel.save!
      @user.reload
      messages = NotificationMessageCreator.new(@notification, @assignment, :to_list => @user).create_message
      expect(messages.select{|m| m.to == 'valid@example.com'}.size).to eq 0
    end

    it "should persist a message and delayed message for bounced emails" do
      notification_set
      @communication_channel.bounce_count = CommunicationChannel::RETIRE_THRESHOLD
      @communication_channel.save!
      @user.reload
      delayed = @communication_channel.delayed_messages.count
      immediate = @communication_channel.messages.count
      messages = NotificationMessageCreator.new(@notification, @assignment, :to_list => @user).create_message
      expect(messages.select{|m| m.to == 'valid@example.com'}.size).to eq 0
      expect(@communication_channel.messages.count).to eq immediate + 1
      expect(@communication_channel.messages.last.workflow_state).to eq 'bounced'
      expect(@communication_channel.delayed_messages.count).to eq delayed + 1
    end

    it "should not use notification policies for unconfirmed communication channels" do
      notification_set
      cc = communication_channel_model(workflow_state: 'unconfirmed', path: 'nope@example.com')
      notification_policy_model(communication_channel_id: cc.id, notification_id: @notification.id)
      messages = NotificationMessageCreator.new(@notification, @assignment, to_list: @user).create_message
      expect(messages.size).to eq 2
      expect(messages.map(&:to).sort).to eq ['dashboard', 'valid@example.com']
    end

    it "should not use notification policies for unconfirmed communication channels even if that's all the user has" do
      notification_set
      @communication_channel.update_attribute(:workflow_state, 'unconfirmed')
      messages = NotificationMessageCreator.new(@notification, @assignment, :to_list => @user).create_message
      expect(messages.size).to eq 1
      expect(messages.map(&:to).sort).to eq ['dashboard']
    end

    it "should not force non immediate categories to be immediate" do
      notification_set(:notification_opts => { :name => "Thing 1", :category => 'Not Migration' })
      @notification_policy.frequency = 'daily'
      @notification_policy.save!
      expect { NotificationMessageCreator.new(@notification, @assignment, :to_list => @user).create_message }.to change(DelayedMessage, :count).by 1
    end

    it 'should force certain categories to send immediately' do
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

    it "should not use non-email channels for summary messages" do
      notification_set
      @notification_policy.frequency = 'daily'
      @notification_policy.save!
      @communication_channel.update_attribute(:path_type, 'sms')

      expect {
        NotificationMessageCreator.new(@notification, @assignment, :to_list => @user).create_message
      }.to change(DelayedMessage, :count).by 0
    end

    context "notification policy overrides" do
      before(:each) { notification_set({ notification_opts: { category: 'PandaExpressTime' } }) }

      it 'uses the policy override if available for immediate messages' do
        @notification_policy.frequency = 'daily'
        @notification_policy.save!
        NotificationPolicyOverride.create_or_update_for(@user.email_channel, @notification.category, 'immediately', @course)

        messages = NotificationMessageCreator.new(
          @notification,
          @assignment,
          to_list: @user,
          data: {
            course_id: @course.id,
            root_account_id: @user.account.id
          }
        ).create_message
        expect(messages).not_to be_empty
      end

      it 'uses the policy override if available for delayed messages' do
        @notification_policy.frequency = 'immediately'
        @notification_policy.save!
        NotificationPolicyOverride.create_or_update_for(@user.email_channel, @notification.category, 'daily', @course)

        expect {
          NotificationMessageCreator.new(
            @notification,
            @assignment,
            to_list: @user,
            data: {
              course_id: @course.id,
              root_account_id: @user.account.id
            }
          ).create_message
        }.to change(DelayedMessage, :count).by 1
      end

      it 'uses course overrides over account overrides' do
        @notification_policy.frequency = 'weekly'
        @notification_policy.save!
        NotificationPolicyOverride.create_or_update_for(@user.email_channel, @notification.category, 'immediately', @course)
        NotificationPolicyOverride.create_or_update_for(@user.email_channel, @notification.category, 'daily', @user.account)

        messages = NotificationMessageCreator.new(
          @notification,
          @assignment,
          to_list: @user,
          data: {
            course_id: @course.id,
            root_account_id: @user.account.id
          }
        ).create_message
        expect(messages).not_to be_empty
        expect(DelayedMessage.count).to be 0
      end

      it 'uses account overrides over normal policies' do
        @notification_policy.frequency = 'weekly'
        @notification_policy.save!
        NotificationPolicyOverride.create_or_update_for(@user.email_channel, @notification.category, 'immediately', @user.account)

        messages = NotificationMessageCreator.new(
          @notification,
          @assignment,
          to_list: @user,
          data: {
            course_id: @course.id,
            root_account_id: @user.account.id
          }
        ).create_message
        expect(messages).not_to be_empty
        expect(DelayedMessage.count).to be 0
      end
    end
  end

  context "localization" do
    before(:each) do
      notification_set
      allow_any_instance_of(Message).to receive(:body).and_return('template')
    end

    it "should translate ERB in the notification" do
      messages = NotificationMessageCreator.new(@notification, @assignment, :to_list => @user).create_message
      messages.each {|m| expect(m.subject).to eql("This is 5!")}
    end

    it "should disrespect browser locales" do
      I18n.backend.stub(piglatin: {messages: {test_name: {email: {subject: "Isthay isay ivefay!"}}}}) do
        I18n.config.available_locales_set.merge([:piglatin, 'piglatin'])
        @user.browser_locale = 'piglatin'
        @user.save(validate: false) # the validation was declared before :piglatin was added, so we skip it
        messages = NotificationMessageCreator.new(@notification, @assignment, :to_list => @user).create_message
        messages.each {|m| expect(m.subject).to eql("This is 5!")}
        expect(I18n.locale).to eql(:en)
      end
    end

    it "should respect user locales" do
      I18n.backend.stub(shouty: {messages: {test_name: {email: {subject: "THIS IS *5*!!!!?!11eleventy1"}}}}) do
        I18n.config.available_locales_set.merge([:shouty, 'shouty'])
        @user.locale = 'shouty'
        @user.save(validate: false)
        messages = NotificationMessageCreator.new(@notification, @assignment, :to_list => @user).create_message
        messages.each {|m| expect(m.subject).to eql("THIS IS *5*!!!!?!11eleventy1")}
        expect(I18n.locale).to eql(:en)
      end
    end

    it "should respect course locales" do
      course_factory
      I18n.backend.stub(es: {messages: {test_name: {email: {subject: 'El Tigre Chino'}}}}) do
        I18n.config.available_locales_set.merge([:es, 'es'])
        @course.enroll_teacher(@user).accept!
        @course.update_attribute(:locale, 'es')
        messages = NotificationMessageCreator.new(@notification, @course, :to_list => @user).create_message
        messages.each { |m| expect(m.subject).to eql('El Tigre Chino') }
        expect(I18n.locale).to eql(:en)
      end
    end

    it "should respect account locales" do
      course_factory
      I18n.backend.stub(es: {messages: {test_name: {email: {subject: 'El Tigre Chino'}}}}) do
        I18n.config.available_locales_set.merge([:es, 'es'])
        @course.account.update_attribute(:default_locale, 'es')
        @course.enroll_teacher(@user).accept!
        messages = NotificationMessageCreator.new(@notification, @course, :to_list => @user).create_message
        messages.each { |m| expect(m.subject).to eql('El Tigre Chino') }
        expect(I18n.locale).to eql(:en)
      end
    end
  end

  context "sharding" do
    specs_require_sharding

    it "should create the message on the user's shard" do
      notification_set
      allow_any_instance_of(Message).to receive(:get_template).and_return('template')
      @shard1.activate do
        account = Account.create!
        user_with_pseudonym(:active_all => 1, :account => account)
        messages = NotificationMessageCreator.new(@notification, @assignment, :to_list => @user).create_message
        expect(messages.length).to be >= 1
        messages.each { |m| expect(m.shard).to eq @shard1 }
      end
    end

    it "should create policies and summary messages on the user's shard" do
      @shard1.activate do
        @user = User.create!
        communication_channel(@user, {username: 'user@example.com', active_cc: true})
      end
      notification_model(category: 'TestWeekly')
      allow_any_instance_of(Message).to receive(:get_template).and_return('template')
      expect(@cc.notification_policies).to be_empty
      expect(@cc.delayed_messages).to be_empty
      NotificationMessageCreator.new(@notification, @user, :to_list => @user).create_message
      expect(@cc.notification_policies.reload).not_to be_empty
      expect(@cc.delayed_messages.reload).not_to be_empty
    end

    it "should properly find the root account for cross-shard summary messages" do
      Canvas::MessageHelper.create_notification(:name => 'Summaries', :category => 'Summaries')
      notification_model(:name => 'Assignment Created')

      @user = User.create!
      communication_channel(@user, {username: 'user@example.com', active_cc: true})

      notification_policy_model(:notification => @notification, :communication_channel => @cc)
      @notification_policy.frequency = 'daily'
      @notification_policy.save!

      @shard1.activate do
        @cs_account = Account.new
        @cs_account.settings[:outgoing_email_default_name] = "OutgoingName"
        @cs_account.save!
        course_factory(active_all: true, :account => @cs_account)
        @course.enroll_student(@user).accept!
        assignment_model(:course => @course)
      end

      dm = @cc.delayed_messages.reload.first
      expect(dm).to_not be_nil

      DelayedMessage.summarize([dm])
      message = @user.messages.reload.last
      expect(message.root_account).to eq @cs_account
      expect(message.from_name).to eq "OutgoingName"
    end

    it "should find an already existing notification policy" do
      notification_model(category: 'TestWeekly')
      @shard1.activate do
        @user = User.create!
        communication_channel(@user, {username: 'user@example.com', active_cc: true})
        @cc.notification_policies.create!(
          :notification => @notification,
          :frequency => @notification.default_frequency
        )
      end
      allow_any_instance_of(Message).to receive(:get_template).and_return('template')
      expect(@cc.notification_policies.reload.count).to eq 1
      NotificationMessageCreator.new(@notification, @user, :to_list => @user).create_message
      expect(@cc.notification_policies.reload.count).to eq 1
    end
  end

  describe "#cancel_pending_duplicate_messages" do
    context "partitions" do
      let(:subject) { NotificationMessageCreator.new(double("notification", name: nil), nil) }

      def set_up_stubs(start_time, *conditions)
        scope = double("Message Scope")
        expect(Message).to receive(:in_partition).ordered.with('created_at' => start_time).and_return(scope)
        expect(scope).to receive(:where).ordered.and_return(scope)
        expect(scope).to receive(:for).ordered.and_return(scope)
        expect(scope).to receive(:by_name).ordered.and_return(scope)
        expect(scope).to receive(:for_user).ordered.and_return(scope)
        expect(scope).to receive(:cancellable).ordered.and_return(scope)
        unless conditions.empty?
          expect(scope).to receive(:where).with(*conditions).ordered.and_return(scope)
        end
        expect(scope).to receive(:update_all).ordered
      end

      it "targets a single partition by default" do
        now = Time.parse("2020-08-26 12:00:00UTC")
        Timecop.freeze(now) do
          set_up_stubs(now - 6.hours, created_at: (now - 6.hours)..now)
          subject.send(:cancel_pending_duplicate_messages)
        end
        # now verify the in_partition calls will result in what we expect
        expect(Message.infer_partition_table_name('created_at' => now - 6.hours)).to eq "messages_2020_35"
      end

      it "targets both partitions if we cross the partition boundary" do
        now = Time.parse("2020-08-24 03:00:00UTC")
        Timecop.freeze(now) do
          set_up_stubs(now - 6.hours, "created_at>=?", now - 6.hours)
          set_up_stubs(now, "created_at<=?", now)
          subject.send(:cancel_pending_duplicate_messages)
        end
        # now verify the in_partition calls will result in what we expect
        expect(Message.infer_partition_table_name('created_at' => now - 6.hours)).to eq "messages_2020_34"
        expect(Message.infer_partition_table_name('created_at' => now)).to eq "messages_2020_35"
      end

      it "targets 3 partitions if it's really long" do
        now = Time.parse("2020-08-24 03:00:00UTC")
        Setting.set("pending_duplicate_message_window_hours", 7 * 24 + 6)
        Timecop.freeze(now) do
          set_up_stubs(now - (7 * 24 + 6).hours, "created_at>=?", now - (7 * 24 + 6).hours)
          set_up_stubs(now - 6.hours)
          set_up_stubs(now, "created_at<=?", now)
          subject.send(:cancel_pending_duplicate_messages)
        end
        # now verify the in_partition calls will result in what we expect
        expect(Message.infer_partition_table_name('created_at' => now - (24 * 7 + 6).hours)).to eq "messages_2020_33"
        expect(Message.infer_partition_table_name('created_at' => now - 6.hours)).to eq "messages_2020_34"
        expect(Message.infer_partition_table_name('created_at' => now)).to eq "messages_2020_35"
      end
    end
  end
end
