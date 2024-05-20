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

## Helpers
def notification_set(opts = {})
  user_opts = opts.delete(:user_opts) || {}
  notification_opts = opts.delete(:notification_opts) || {}

  assignment_model
  notification_model({ subject: "<%= t :subject, 'This is 5!' %>", name: "Test Name" }.merge(notification_opts))
  user_model({ workflow_state: "registered" }.merge(user_opts))
  cc = communication_channel_model
  cc.confirm!

  @notification_policy = cc.notification_policies.first

  @notification.reload
end

describe NotificationMessageCreator do
  context "create_message" do
    before do
      allow_any_instance_of(Message).to receive(:get_template).and_return("template")
    end

    it "only sends dashboard messages for users with non-validated channels" do
      assignment_model
      notification_model
      u1 = user_model(workflow_state: "registered")
      communication_channel_model(path: "user@example.com", workflow_state: "active")
      u2 = user_model(workflow_state: "registered")
      communication_channel_model

      messages = NotificationMessageCreator.new(@notification, @assignment, to_list: [u1, u2]).create_message
      expect(messages.length).to be(3)
      expect(messages.map(&:to).sort).to eq ["dashboard", "dashboard", "user@example.com"]
    end

    it "only sends messages to active communication channels" do
      assignment_model
      user_model(workflow_state: "registered")
      notification_model
      a = communication_channel_model(workflow_state: "active")
      b = communication_channel_model(workflow_state: "active", path: "path2@example.com")
      c = communication_channel_model(workflow_state: "active", path: "path3@example.com")
      d = communication_channel_model(path: "path4@example.com")

      @user.reload
      messages = NotificationMessageCreator.new(@notification, @assignment, to_list: @user).create_message
      paths = messages.collect(&:to)
      expect(paths).to include(a.path)
      expect(paths).to include(b.path)
      expect(paths).to include(c.path)
      expect(paths).not_to include(d.path)
    end

    it "defaults to the account time zone if the user has no time zone" do
      original_time_zone = Time.zone
      Time.zone = "UTC"
      course_with_teacher
      account = @course.account
      account.default_time_zone = "Pretoria"
      account.save!

      @user = user_model(workflow_state: "registered")
      communication_channel(@user, { username: "a@example.com", active_cc: true })

      due_at = Time.zone.parse("2014-06-06 11:59:59")
      assignment_model(course: @course, due_at:)

      notification = Notification.create!(name: "Assignment Created", category: "Due Date")

      messages = NotificationMessageCreator.new(
        notification,
        @assignment,
        to_list: @user,
        data: {
          course_id: @assignment.context_id,
          root_account_id: @assignment.root_account_id
        }
      ).create_message

      presenter = Utils::DatetimeRangePresenter.new(due_at, nil, :event, ActiveSupport::TimeZone.new("Pretoria"))
      due_at_string = presenter.as_string(shorten_midnight: false)

      expect(messages.count).to eq 1
      expect(messages[0].html_body.include?(due_at_string)).to be true
      Time.zone = original_time_zone
    end

    it "uses the default channel if no policies apply" do
      assignment_model
      user_model(workflow_state: "registered")
      a = communication_channel_model(workflow_state: "active")
      communication_channel_model(path: "path2@example.com")
      communication_channel_model(path: "path3@example.com")
      expect(a).to be_active

      @n = Notification.create(name: "New Notification")
      a.notification_policies.create!(notification: @n, frequency: Notification::FREQ_IMMEDIATELY)
      messages = NotificationMessageCreator.new(@n, @assignment, to_list: @user).create_message
      expect(messages.count).to be(1)
      expect(messages.first.communication_channel).to eql(@user.communication_channel)
    end

    it "uses the default channel and the push channel if only the push channel has a policy" do
      assignment_model
      @user = user_model(workflow_state: "registered")
      a = communication_channel(@user, { username: "a@example.com", active_cc: true })
      b = communication_channel(@user, { username: "b@example.com", active_cc: true })
      @n = Notification.create!(name: "New notification", category: "TestImmediately")
      messages = NotificationMessageCreator.new(@n, @assignment, to_list: @user).create_message
      channels = messages.collect(&:communication_channel)
      expect(channels).to include(a)
      expect(channels).not_to include(b)

      b.notification_policies.create!(notification: @n, frequency: "immediately")
      messages = NotificationMessageCreator.new(@n, @assignment, to_list: @user).create_message
      channels = messages.collect(&:communication_channel)
      expect(channels).to include(b)
      expect(channels).to include(a)
    end

    it "only sends notifications to active channels" do
      assignment_model
      @user = user_model(workflow_state: "registered")
      a = communication_channel(@user, { username: "a@example.com", active_cc: true })
      b = communication_channel(@user, { username: "b@example.com" })
      @n = Notification.create!(name: "New notification", category: "TestImmediately")

      messages = NotificationMessageCreator.new(@n, @assignment, to_list: @user).create_message
      channels = messages.collect(&:communication_channel)
      expect(channels).to include(a)
      expect(channels).not_to include(b)
    end

    it "does not send a notification when policy override is disabled for a course" do
      notification_set(notification_opts: { category: "Announcement" })
      NotificationPolicyOverride.enable_for_context(@user, @course, enable: false)
      data = { course_id: @course.id, root_account_id: @course.root_account_id }
      messages = NotificationMessageCreator.new(@notification, @assignment, to_list: @user, data:).create_message
      expect(messages).to be_empty
    end

    it "does send a notification when course_id is not passed in" do
      notification_set(notification_opts: { category: "Announcement" })
      NotificationPolicyOverride.enable_for_context(@user, @course, enable: false)
      data = { root_account_id: @course.root_account_id }
      messages = NotificationMessageCreator.new(@notification, @assignment, to_list: @user, data:).create_message
      expect(messages.length).to be(1)
    end

    it "sends registration emails to unconfirmed communication_channels" do
      notification_model({ subject: "test", name: "Test Name", category: "Registration" })
      communication_channel(user_model, cc_state: "unconfirmed")
      account_user = account_model.account_users.create!(user: @user)
      messages = NotificationMessageCreator.new(@notification, account_user, to_list: @user).create_message
      expect(messages.length).to be(1)
    end

    it "does send other notifications when policy override is in effect" do
      notification_set(notification_opts: { category: "Registration" })
      NotificationPolicyOverride.enable_for_context(@user, @course, enable: false)
      data = { course_id: @course.id, root_account_id: @course.root_account_id }
      messages = NotificationMessageCreator.new(@notification, @assignment, to_list: @user, data:).create_message
      expect(messages.length).to be(1)
    end

    it "does not send dispatch messages for pre-registered users" do
      course_factory
      notification_model
      u1 = user_model(name: "user 2")
      communication_channel(u1, { username: "user2@example.com", active_cc: true })
      @a = @course.assignments.create
      messages = NotificationMessageCreator.new(@notification, @a, to_list: u1).create_message
      expect(messages).to be_empty
    end

    it "sends registration messages for pre-registered users" do
      notification_set(user_opts: { workflow_state: "pre_registered" }, notification_opts: { category: "Registration" })
      messages = NotificationMessageCreator.new(@notification, @assignment, to_list: @user).create_message
      expect(messages).not_to be_empty
      expect(messages.length).to be(1)
      expect(messages.first.to).to eql(@communication_channel.path)
    end

    it "sends registration messages to the communication channels in the to list" do
      notification_set(notification_opts: { category: "Registration" })
      cc = communication_channel(@user, { username: "user1@example.com" })
      communication_channel(@user, { username: "user2@example.com", active_cc: true })
      messages = NotificationMessageCreator.new(@notification, @assignment, to_list: [cc]).create_message
      expect(messages.length).to be(1)
      expect(messages[0].to).to eql(cc.path)
    end

    it "sends dashboard and dispatch messages for registered users based on default policies" do
      course_factory
      notification_model(category: "TestImmediately")
      u1 = user_model(name: "user 1", workflow_state: "registered")
      communication_channel(u1, { username: "user1@example.com", active_cc: true })
      @a = @course.assignments.create
      messages = NotificationMessageCreator.new(@notification, @a, to_list: u1).create_message
      expect(messages).not_to be_empty
      expect(messages.length).to be(2)
      expect(messages[0].to).to eql("user1@example.com")
      expect(messages[1].to).to eql("dashboard")
    end

    it "does not dispatch non-immediate message based on default policies" do
      notification_model(category: "TestDaily", name: "Show In Feed")
      expect(@notification.default_frequency).to eql("daily")
      u1 = user_model(name: "user 1", workflow_state: "registered")

      # make the first channel retired, to verify that it'll get an active one
      communication_channel(u1, { username: "retired@example.com", cc_state: "retired" })
      cc = communication_channel(u1, { username: "active@example.com", active_cc: true })

      @a = assignment_model
      messages = NotificationMessageCreator.new(@notification, @a, to_list: u1).create_message
      expect(messages).not_to be_empty
      expect(messages.length).to be(1)
      expect(messages[0].to).to eql("dashboard")
      expect(DelayedMessage.all).not_to be_empty
      expect(DelayedMessage.last).not_to be_nil
      expect(DelayedMessage.last.notification_id).to eql(@notification.id)
      expect(DelayedMessage.last.communication_channel_id).to eql(cc.id)
      expect(DelayedMessage.last.root_account_id).to eql Account.default.id
      expect(DelayedMessage.last.send_at).to be > Time.now.utc
    end

    it "is able to set default policies to never for a specific user" do
      notification_model(category: "TestImmediately", name: "New notification")
      expect(@notification.default_frequency).to eql("immediately")

      u1 = user_model(name: "user 1", workflow_state: "registered")
      u1.default_notifications_disabled = true
      u1.save!
      communication_channel(u1, { username: "active@example.com", active_cc: true })
      u2 = user_model(name: "user 2", workflow_state: "registered")
      cc2 = communication_channel(u2, { username: "active2@example.com", active_cc: true })

      @a = assignment_model
      messages = NotificationMessageCreator.new(@notification, @a, to_list: [u1, u2]).create_message
      expect(messages.filter_map(&:communication_channel)).to eq [cc2] # doesn't include u1's cc
    end

    it "makes a delayed message for each user policy with a delayed frequency" do
      notification_set
      NotificationPolicy.delete_all
      nps = (1..3).map do |i|
        cc = communication_channel_model(path: "user#{i}@example.com")
        cc.confirm!
        cc.notification_policies.first
      end

      expect { NotificationMessageCreator.new(@notification, @assignment, to_list: @user).create_message }.not_to change(DelayedMessage, :count)

      nps.each do |np|
        np.frequency = "never"
        np.save!
      end
      @user.reload
      expect { NotificationMessageCreator.new(@notification, @assignment, to_list: @user).create_message }.not_to change(DelayedMessage, :count)

      nps.each do |np|
        np.frequency = "daily"
        np.save!
      end
      @user.reload
      expect { NotificationMessageCreator.new(@notification, @assignment, to_list: @user).create_message }.to change(DelayedMessage, :count).by 3

      nps.each do |np|
        np.frequency = "weekly"
        np.save!
      end
      @user.reload
      expect { NotificationMessageCreator.new(@notification, @assignment, to_list: @user).create_message }.to change(DelayedMessage, :count).by 3
    end

    it "makes a delayed message for a notification with a set delayed frequency (even if another policy is set to immediate)" do
      notification_set
      @notification_policy.update_attribute(:frequency, "daily")

      other_notification = Notification.create!(subject: "yo", name: "Test Not 2")
      NotificationPolicy.create!(notification: other_notification, communication_channel: @communication_channel)

      NotificationMessageCreator.new(@notification, @assignment, to_list: @user).create_message
      expect(Message.where(communication_channel_id: @communication_channel).exists?).to be false # no immediate message
      expect(DelayedMessage.where(communication_channel_id: @communication_channel).exists?).to be true
    end

    describe "notification's default frequency" do
      before(:once) do
        # two channels, two notifications with default freq of never and daily, and a notification policy.
        notification_set({ notification_opts: { category: "Discussion" } })
        @a = @cc
        @never_notification = @notification
        communication_channel_model(path: "yes@example.com").confirm!
        @b = @cc
      end

      let(:notification) { notification_model({ subject: "<%= t :subject, 'hoy es today' %>", name: "Test daily", category: "DiscussionEntry" }) }
      let(:immediate_notification) { notification_model({ name: "Newish notification", category: "TestImmediately" }) }

      it "does not create delayed messages when default is never" do
        expect { NotificationMessageCreator.new(@never_notification, @assignment, to_list: @user).create_message }.not_to change(DelayedMessage, :count)
      end

      it "uses the default policy on default channel" do
        expect { NotificationMessageCreator.new(notification, @assignment, to_list: @user).create_message }.to change(DelayedMessage, :count).by 1
      end

      it "does not use default policy on default channel when other policy exists" do
        notification_policy_model(notification:, communication_channel: @communication_channel, frequency: "immediately")
        expect { NotificationMessageCreator.new(notification, @assignment, to_list: @user).create_message }.not_to change(DelayedMessage, :count)
      end

      it "uses default policy on immediate notifications" do
        messages = NotificationMessageCreator.new(immediate_notification, @assignment, to_list: @user).create_message
        channels = messages.collect(&:communication_channel)
        expect(channels).to include(@a)
        expect(channels).not_to include(@b)
      end

      it "does not use default policy on immediate notifications when other policy exists" do
        notification_policy_model(notification: immediate_notification, communication_channel: @b, frequency: "immediately")
        messages = NotificationMessageCreator.new(immediate_notification, @assignment, to_list: @user).create_message
        channels = messages.collect(&:communication_channel)
        expect(channels).to include(@b)
        expect(channels).not_to include(@a)
      end
    end

    it "sends dashboard (but not dispatch messages) for registered users based on default policies" do
      course_factory
      notification_model(category: "TestNever", name: "Show In Feed")
      expect(@notification.default_frequency).to eql("never")
      u1 = user_model(name: "user 1", workflow_state: "registered")
      communication_channel(u1, { username: "user1@example.com", active_cc: true })
      @a = @course.assignments.create
      messages = NotificationMessageCreator.new(@notification, @a, to_list: u1).create_message
      expect(messages).not_to be_empty
      expect(messages.length).to be(1)
      expect(messages[0].to).to eql("dashboard")
    end

    it "does not send dashboard messages for non-feed or non-dashboard messages" do
      course_factory
      notification_model(category: "TestNever", name: "Don't Show In Feed")
      expect(@notification.default_frequency).to eql("never")
      u1 = user_model(name: "user 1", workflow_state: "registered")
      communication_channel(u1, { username: "user1@example.com", active_cc: true })
      @a = @course.assignments.create
      messages = NotificationMessageCreator.new(@notification, @a, to_list: u1).create_message
      expect(messages).to be_empty
      @notification.name = "Show In Feed"
      @notification.category = "Summaries"
      messages = NotificationMessageCreator.new(@notification, @a, to_list: u1).create_message
      expect(messages).to be_empty
    end

    it "replaces messages when a similar notification occurs" do
      notification_set

      all_messages = []
      messages = NotificationMessageCreator.new(@notification, @assignment, to_list: @user).create_message
      all_messages += messages
      expect(messages.length).to be(2)
      m1 = messages.first
      m2 = messages.last

      messages = NotificationMessageCreator.new(@notification, @assignment, to_list: @user).create_message
      all_messages += messages
      expect(messages).not_to be_empty
      expect(messages.length).to be(2)

      expect(all_messages.count do |m|
        m.to == m1.to and m.notification == m1.notification and m.communication_channel == m1.communication_channel
      end).to be(2)

      expect(all_messages.count do |m|
        m.to == m2.to and m.notification == m2.notification and m.communication_channel == m2.communication_channel
      end).to be(2)
    end

    it "creates stream items" do
      notification_set(notification_opts: { name: "Show In Feed" })
      expect(@user.stream_item_instances.count).to eq 0
      NotificationMessageCreator.new(@notification, @assignment, to_list: @user).create_message
      expect(@user.stream_item_instances.count).to eq 1
      si = @user.stream_item_instances.first.stream_item
      expect(si.asset_type).to eq "Message"
      expect(si.asset_id).to be_nil
    end

    it "does not get confused with nil values in the to list" do
      notification_set
      messages = NotificationMessageCreator.new(@notification, @assignment, to_list: nil).create_message
      expect(messages).to be_empty
    end

    it "does not send messages after the user's limit" do
      notification_set
      expect(NotificationPolicy.count).to eq 1
      Rails.cache.delete(["recent_messages_for", @user.id].cache_key)
      allow(User).to receive(:max_messages_per_day).and_return(1)
      User.max_messages_per_day.times do
        messages = NotificationMessageCreator.new(@notification, @assignment, to_list: @user).create_message
        expect(messages.reject { |m| m.to == "dashboard" }).not_to be_empty
      end
      expect(DelayedMessage.count).to be(0)
      messages = NotificationMessageCreator.new(@notification, @assignment, to_list: @user).create_message
      expect(messages.reject { |m| m.to == "dashboard" }).to be_empty
      expect(DelayedMessage.count).to be(1)
      expect(NotificationPolicy.count).to eq 2
      # should not create more dummy policies
      messages = NotificationMessageCreator.new(@notification, @assignment, to_list: @user).create_message
      expect(messages.reject { |m| m.to == "dashboard" }).to be_empty
      expect(NotificationPolicy.count).to eq 2
    end

    it "doesn't crash when multiple jobs are trying to find an effective policy" do
      notification_set(no_policy: true)
      nmc = NotificationMessageCreator.new(@notification, @assignment, to_list: @user)
      channels = nmc.to_user_channels[@user]
      expect(channels.size).to eq(1)
      policy = nmc.send(:effective_policy_for, @user, channels.first)
      policy2 = nmc.send(:effective_policy_for, @user, channels.first)
      expect(policy2.id).to_not be_nil
      expect(policy2.id).to eq(policy.id)
    end

    it "does not send to bouncing channels" do
      notification_set
      @communication_channel.bounce_count = CommunicationChannel::RETIRE_THRESHOLD - 1
      @communication_channel.save!
      messages = NotificationMessageCreator.new(@notification, @assignment, to_list: @user).create_message
      expect(messages.count { |m| m.to == "valid@example.com" }).to eq 1

      @communication_channel.bounce_count = CommunicationChannel::RETIRE_THRESHOLD
      @communication_channel.save!
      @user.reload
      messages = NotificationMessageCreator.new(@notification, @assignment, to_list: @user).create_message
      expect(messages.count { |m| m.to == "valid@example.com" }).to eq 0
    end

    it "persists a message and delayed message for bounced emails" do
      notification_set
      @communication_channel.bounce_count = CommunicationChannel::RETIRE_THRESHOLD
      @communication_channel.save!
      @user.reload
      delayed = @communication_channel.delayed_messages.count
      immediate = @communication_channel.messages.count
      messages = NotificationMessageCreator.new(@notification, @assignment, to_list: @user).create_message
      expect(messages.count { |m| m.to == "valid@example.com" }).to eq 0
      expect(@communication_channel.messages.count).to eq immediate + 1
      expect(@communication_channel.messages.last.workflow_state).to eq "bounced"
      expect(@communication_channel.delayed_messages.count).to eq delayed + 1
    end

    it "does not use notification policies for unconfirmed communication channels" do
      notification_set
      communication_channel_model(workflow_state: "unconfirmed", path: "nope@example.com")
      messages = NotificationMessageCreator.new(@notification, @assignment, to_list: @user).create_message
      expect(messages.size).to eq 2
      expect(messages.map(&:to).sort).to eq ["dashboard", "valid@example.com"]
    end

    it "does not use notification policies for unconfirmed communication channels even if that's all the user has" do
      notification_set
      @communication_channel.update_attribute(:workflow_state, "unconfirmed")
      messages = NotificationMessageCreator.new(@notification, @assignment, to_list: @user).create_message
      expect(messages.size).to eq 1
      expect(messages.map(&:to).sort).to eq ["dashboard"]
    end

    it "does not force non immediate categories to be immediate" do
      notification_set(notification_opts: { name: "Thing 1", category: "Not Migration" })
      @notification_policy.frequency = "daily"
      @notification_policy.save!
      expect { NotificationMessageCreator.new(@notification, @assignment, to_list: @user).create_message }.to change(DelayedMessage, :count).by 1
    end

    it "forces certain categories to send immediately" do
      notification_set(notification_opts: { name: "Thing 2", category: "Migration" })
      @notification_policy.frequency = "daily"
      @notification_policy.save!
      expect { NotificationMessageCreator.new(@notification, @assignment, to_list: @user).create_message }.not_to change(DelayedMessage, :count)
    end

    it "does not use retired channels for summary messages" do
      notification_set
      @notification_policy.frequency = "daily"
      @notification_policy.save!
      @communication_channel.retire!

      expect do
        NotificationMessageCreator.new(@notification, @assignment, to_list: @user).create_message
      end.not_to change(DelayedMessage, :count)
    end

    it "does not use non-email channels for summary messages" do
      notification_set
      @notification_policy.frequency = "daily"
      @notification_policy.save!
      @communication_channel.update_attribute(:path_type, "sms")

      expect do
        NotificationMessageCreator.new(@notification, @assignment, to_list: @user).create_message
      end.not_to change(DelayedMessage, :count)
    end

    context "notification policy overrides" do
      before { notification_set({ notification_opts: { category: "PandaExpressTime" } }) }

      it "uses the policy override if available for immediate messages" do
        @notification_policy.frequency = "daily"
        @notification_policy.save!
        NotificationPolicyOverride.create_or_update_for(@user.email_channel, @notification.category, "immediately", @course)

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

      it "uses the policy override if available for delayed messages" do
        @notification_policy.frequency = "immediately"
        @notification_policy.save!
        NotificationPolicyOverride.create_or_update_for(@user.email_channel, @notification.category, "daily", @course)

        expect do
          NotificationMessageCreator.new(
            @notification,
            @assignment,
            to_list: @user,
            data: {
              course_id: @course.id,
              root_account_id: @user.account.id
            }
          ).create_message
        end.to change(DelayedMessage, :count).by 1
      end

      it "uses course overrides over account overrides" do
        @notification_policy.frequency = "weekly"
        @notification_policy.save!
        NotificationPolicyOverride.create_or_update_for(@user.email_channel, @notification.category, "immediately", @course)
        NotificationPolicyOverride.create_or_update_for(@user.email_channel, @notification.category, "daily", @user.account)

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

      it "uses account overrides over normal policies" do
        @notification_policy.frequency = "weekly"
        @notification_policy.save!
        NotificationPolicyOverride.create_or_update_for(@user.email_channel, @notification.category, "immediately", @user.account)

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
    before do
      notification_set
      allow_any_instance_of(Message).to receive(:body).and_return("template")
    end

    it "translates ERB in the notification" do
      messages = NotificationMessageCreator.new(@notification, @assignment, to_list: @user).create_message
      messages.each { |m| expect(m.subject).to eql("This is 5!") }
    end

    it "disrespects browser locales" do
      I18n.backend.stub(piglatin: { messages: { test_name: { email: { subject: "Isthay isay ivefay!" } } } }) do
        @user.browser_locale = "piglatin"
        @user.save(validate: false) # the validation was declared before :piglatin was added, so we skip it
        messages = NotificationMessageCreator.new(@notification, @assignment, to_list: @user).create_message
        messages.each { |m| expect(m.subject).to eql("This is 5!") }
        expect(I18n.locale).to be(:en)
      end
    end

    it "respects user locales" do
      I18n.backend.stub("en-SHOUTY": { messages: { test_name: { email: { subject: "THIS IS *5*!!!!?!11eleventy1" } } } }) do
        @user.locale = "en-SHOUTY"
        @user.save(validate: false)
        messages = NotificationMessageCreator.new(@notification, @assignment, to_list: @user).create_message
        messages.each { |m| expect(m.subject).to eql("THIS IS *5*!!!!?!11eleventy1") }
        expect(I18n.locale).to be(:en)
      end
    end

    it "respects course locales" do
      course_factory
      I18n.backend.stub(es: { messages: { test_name: { email: { subject: "El Tigre Chino" } } } }) do
        @course.enroll_teacher(@user).accept!
        @course.update_attribute(:locale, "es")
        messages = NotificationMessageCreator.new(@notification, @course, to_list: @user).create_message
        messages.each { |m| expect(m.subject).to eql("El Tigre Chino") }
        expect(I18n.locale).to be(:en)
      end
    end

    it "respects account locales" do
      course_factory
      I18n.backend.stub(es: { messages: { test_name: { email: { subject: "El Tigre Chino" } } } }) do
        @course.account.update_attribute(:default_locale, "es")
        @course.enroll_teacher(@user).accept!
        messages = NotificationMessageCreator.new(@notification, @course, to_list: @user).create_message
        messages.each { |m| expect(m.subject).to eql("El Tigre Chino") }
        expect(I18n.locale).to be(:en)
      end
    end
  end

  context "sharding" do
    specs_require_sharding

    it "creates the message on the user's shard" do
      notification_set
      allow_any_instance_of(Message).to receive(:get_template).and_return("template")
      @shard1.activate do
        account = Account.create!
        user_with_pseudonym(active_all: 1, account:)
        messages = NotificationMessageCreator.new(@notification, @assignment, to_list: @user).create_message
        expect(messages.length).to be >= 1
        messages.each { |m| expect(m.shard).to eq @shard1 }
      end
    end

    it "creates policies and summary messages on the user's shard" do
      @shard1.activate do
        @user = User.create!
        communication_channel(@user, { username: "user@example.com", active_cc: true })
      end
      notification_model(category: "TestWeekly")
      allow_any_instance_of(Message).to receive(:get_template).and_return("template")
      expect(@cc.notification_policies).to be_empty
      expect(@cc.delayed_messages).to be_empty
      NotificationMessageCreator.new(@notification, @user, to_list: @user).create_message
      expect(@cc.notification_policies.reload).not_to be_empty
      expect(@cc.delayed_messages.reload).not_to be_empty
    end

    it "properly finds the root account for cross-shard summary messages" do
      Canvas::MessageHelper.create_notification(name: "Summaries", category: "Summaries")

      @user = User.create!
      communication_channel(@user, { username: "user@example.com", active_cc: true })

      notification_model(name: "Assignment Created")
      notification_policy_model(notification: @notification, communication_channel: @cc)
      @notification_policy.frequency = "daily"
      @notification_policy.save!

      @shard1.activate do
        @cs_account = Account.new
        @cs_account.settings[:outgoing_email_default_name] = "OutgoingName"
        @cs_account.save!
        course_factory(active_all: true, account: @cs_account)
        @course.enroll_student(@user).accept!
        assignment_model(course: @course)
      end

      dm = @cc.delayed_messages.reload.first
      expect(dm).to_not be_nil

      DelayedMessage.summarize([dm])
      message = @user.messages.reload.last
      expect(message.root_account).to eq @cs_account
      expect(message.from_name).to eq "OutgoingName"
    end

    it "finds an already existing notification policy" do
      notification_model(category: "TestWeekly")
      @shard1.activate do
        @user = User.create!
        communication_channel(@user, { username: "user@example.com", active_cc: true })
      end
      allow_any_instance_of(Message).to receive(:get_template).and_return("template")
      expect(@cc.notification_policies.reload.count).to eq 1
      NotificationMessageCreator.new(@notification, @user, to_list: @user).create_message
      expect(@cc.notification_policies.reload.count).to eq 1
    end

    it "cancels duplicate messages" do
      # we only cancel messages in Production because in test the table may not exist. we should skip this test if it becomes flaky see patchset: /246496
      skip("cancel_pending_duplicate_messages required to test") unless ENV["RAILS_LOAD_CANCEL_PENDING_DUPLICATE_MESSAGES"]

      allow_any_instance_of(Message).to receive(:get_template).and_return("template")
      # we make the messages immediate, because cancellation occurs when delay has finished.
      allow_any_instance_of(NotificationMessageCreator).to receive(:immediate_policy?).and_return(true)

      @shard1.activate do
        @user = User.create!
        communication_channel(@user, { username: "user@example.com", active_cc: true })
      end

      @shard2.activate do
        @user2 = User.create!
        communication_channel(@user2, { username: "user2@example.com", active_cc: true })
      end

      notification_model({ subject: "test", name: "Test Name", category: "Submission Graded" })
      # two messages for user shard1 and two messages for user2 shard2
      NotificationMessageCreator.new(@notification, @user, to_list: [@user, @user2]).create_message
      NotificationMessageCreator.new(@notification, @user, to_list: [@user, @user2]).create_message
      NotificationMessageCreator.new(@notification, @user, to_list: [@user, @user2]).create_message

      expect(@user.messages.length).to be(3)
      expect(@user.messages.where("messages.workflow_state='cancelled'").length).to be(2)
      expect(@user2.messages.length).to be(3)
      expect(@user2.messages.where("messages.workflow_state='cancelled'").length).to be(2)
    end
  end

  describe "#cancel_pending_duplicate_messages" do
    context "partitions" do
      let(:subject) { NotificationMessageCreator.new(double("notification", name: nil), nil) }

      def set_up_stubs(start_time, *conditions)
        scope = double("Message Scope")
        expect(Message).to receive(:in_partition).ordered.with("created_at" => start_time).and_return(scope)
        expect(scope).to receive(:where).ordered.and_return(scope)
        expect(scope).to receive(:for).ordered.and_return(scope)
        expect(scope).to receive(:by_name).ordered.and_return(scope)
        expect(scope).to receive(:for_user).ordered.and_return(scope)
        expect(scope).to receive(:cancellable).ordered.and_return(scope)
        unless conditions.empty?
          expect(scope).to receive(:where).with(*conditions).ordered.and_return(scope)
        end
        allow(Message.connection).to receive(:table_exists?).and_return(true)
        expect(scope).to receive(:update_all).ordered

        user = User.create!
        to_user_channels = Hash.new([])
        to_user_channels[user] = user.communication_channels
        subject.instance_variable_set(:@to_user_channels, to_user_channels)
      end

      it "targets a single partition by default" do
        now = Time.parse("2020-08-26 12:00:00UTC")
        Timecop.freeze(now) do
          set_up_stubs(now - 6.hours, created_at: (now - 6.hours)..now)
          subject.send(:cancel_pending_duplicate_messages)
        end
        # now verify the in_partition calls will result in what we expect
        expect(Message.infer_partition_table_name("created_at" => now - 6.hours)).to eq "messages_2020_35"
      end

      it "targets both partitions if we cross the partition boundary" do
        now = Time.parse("2020-08-24 03:00:00UTC")
        Timecop.freeze(now) do
          set_up_stubs(now - 6.hours, "created_at>=?", now - 6.hours)
          set_up_stubs(now, "created_at<=?", now)
          subject.send(:cancel_pending_duplicate_messages)
        end
        # now verify the in_partition calls will result in what we expect
        expect(Message.infer_partition_table_name("created_at" => now - 6.hours)).to eq "messages_2020_34"
        expect(Message.infer_partition_table_name("created_at" => now)).to eq "messages_2020_35"
      end

      it "targets 3 partitions if it's really long" do
        now = Time.parse("2020-08-24 03:00:00UTC")
        duration = 1.week + 6.hours
        stub_const("NotificationMessageCreator::PENDING_DUPLICATE_MESSAGE_WINDOW", duration)
        Timecop.freeze(now) do
          set_up_stubs(now - duration, "created_at>=?", now - duration)
          set_up_stubs(now - 6.hours)
          set_up_stubs(now, "created_at<=?", now)
          subject.send(:cancel_pending_duplicate_messages)
        end
        # now verify the in_partition calls will result in what we expect
        expect(Message.infer_partition_table_name("created_at" => now - duration)).to eq "messages_2020_33"
        expect(Message.infer_partition_table_name("created_at" => now - 6.hours)).to eq "messages_2020_34"
        expect(Message.infer_partition_table_name("created_at" => now)).to eq "messages_2020_35"
      end
    end
  end

  it "User just receives email notification" do
    allow_any_instance_of(Message).to receive(:get_template).and_return("template")
    assignment_model
    notification_model

    user = user_model(workflow_state: "registered")
    communication_channel_model(path: "7871234567@txt.att.net", path_type: "sms", workflow_state: "active")

    messages = NotificationMessageCreator.new(@notification, @assignment, to_list: [user]).create_message

    # User just receives email because SMS is deprecated.
    expect(messages.length).to be(1)
  end
end
