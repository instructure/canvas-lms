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

describe NotificationPolicy do
  it "creates a new instance given valid attributes" do
    notification_policy_model
  end

  context "channels" do
    before(:once) do
      @course = factory_with_protected_attributes(Course, name: "test course", workflow_state: "available")
      @student = factory_with_protected_attributes(User, name: "student", workflow_state: "registered")
      e = @course.enroll_student(@student)
      e.accept!
      Notification.all.each(&:destroy)
      Notification.reset_cache!
      @notif = Notification.create!(name: "Assignment Created", subject: "Test", category: "TestNever")
    end

    it "causes message dispatch to specified channel on triggered policies" do
      communication_channel(@student, { username: "default@example.com", active_cc: true })
      communication_channel(@student, { username: "secondary@example.com", active_cc: true })
      @cc.notification_policies.first.update_attribute(:frequency, "immediately")
      @assignment = @course.assignments.create!(title: "test assignment")
      expect(@assignment.messages_sent).to include("Assignment Created")
      m = @assignment.messages_sent["Assignment Created"].find { |message| message.to == "default@example.com" }
      expect(m).to be_nil
      m = @assignment.messages_sent["Assignment Created"].find { |message| message.to == "secondary@example.com" }
      expect(m).not_to be_nil
    end

    it "prevents message dispatches if set to 'never' on triggered policies" do
      communication_channel(@student, { username: "secondary@example.com", active_cc: true })
      @cc.notification_policies.first.update_attribute(:frequency, "never")
      @assignment = @course.assignments.create!(title: "test assignment")
      m = @assignment.messages_sent["Assignment Created"].find { |message| message.to == "default@example.com" }
      expect(m).to be_nil
      m = @assignment.messages_sent["Assignment Created"].find { |message| message.to == "secondary@example.com" }
      expect(m).to be_nil
    end

    it "prevents message dispatches if no policy setting exists" do
      communication_channel(@student, { username: "secondary@example.com", active_cc: true })
      NotificationPolicy.where(notification_id: @notif, communication_channel_id: @cc).delete_all
      @assignment = @course.assignments.create!(title: "test assignment")
      m = @assignment.messages_sent["Assignment Created"].find { |message| message.to == "default@example.com" }
      expect(m).to be_nil
      m = @assignment.messages_sent["Assignment Created"].find { |message| message.to == "secondary@example.com" }
      expect(m).to be_nil
    end
  end

  it "passes 'data' to the message" do
    Notification.create! name: "Hello",
                         subject: "Hello",
                         category: "TestImmediately"
    allow_any_instance_of(Message).to receive(:get_template).and_return("here's a free id <%= data.course_id %>")
    klass = Class.new(ActiveRecord::Base) do
      self.table_name = :courses

      has_a_broadcast_policy
      set_broadcast_policy do
        dispatch :hello
        to do
          u = User.create
          u.communication_channels.build(
            path: "blarg@example.com",
            path_type: "email"
          ) { |cc| cc.workflow_state = "active" }
          u.save!
          u.register
          u
        end
        whenever { true }
        data { { course_id: "this is a real course_id", root_account_id: Account.default.id } }
      end
      def root_account
        Account.default
      end
    end
    dt = klass.new(account_id: Account.default.id,
                   root_account_id: Account.default.id,
                   enrollment_term_id: Account.default.default_enrollment_term.id,
                   workflow_state: "created")
    dt.save!
    msg = dt.messages_sent["Hello"].find { |m| m.to == "blarg@example.com" }
    expect(msg).not_to be_nil
    expect(msg.body).to include "this is a real course_id"
  end

  context "named scopes" do
    it "has a named scope for users" do
      user_with_pseudonym(active_all: 1)
      notification_policy_model(communication_channel: @cc)
      expect(NotificationPolicy.for(@user)).to eq [@notification_policy]
    end

    it "has a named scope for notifications" do
      notification_model
      notification_policy_model(notification: @notification)
      expect(NotificationPolicy.for(@notification)).to eq [@notification_policy]
    end

    it "does not slow down from other kinds of input on the *for* named scope" do
      notification_policy_model
      expect(NotificationPolicy.for(:anything_else)).to eq NotificationPolicy.all
    end

    context "by" do
      before :once do
        user_with_pseudonym(active_all: 1)
        @n1 = notification_policy_model(frequency: "immediately", communication_channel: @cc, notification: notification_model(name: "N1"))
        @n2 = notification_policy_model(frequency: "daily", communication_channel: @cc, notification: notification_model(name: "N2"))
        @n3 = notification_policy_model(frequency: "weekly", communication_channel: @cc, notification: notification_model(name: "N3"))
        @n4 = notification_policy_model(frequency: "never", communication_channel: @cc, notification: notification_model(name: "N4"))
      end

      it "has a scope to differentiate by frequency" do
        expect(NotificationPolicy.by_frequency(:immediately)).to eq [@n1]
        expect(NotificationPolicy.by_frequency(:daily)).to eq [@n2]
        expect(NotificationPolicy.by_frequency(:weekly)).to eq [@n3]
        expect(NotificationPolicy.by_frequency(:never)).to eq [@n4]
      end

      it "is able to differentiate by several frequencies at once" do
        expect(NotificationPolicy.by_frequency([:immediately, :daily])).to include(@n1)
        expect(NotificationPolicy.by_frequency([:immediately, :daily])).to include(@n2)
      end

      it "is able to combine an array of frequencies with a for scope" do
        expect(NotificationPolicy.for(@user).by_frequency([:daily, :weekly])).to include(@n2)
        expect(NotificationPolicy.for(@user).by_frequency([:daily, :weekly])).to include(@n3)
        expect(NotificationPolicy.for(@user).by_frequency([:daily, :weekly])).not_to include(@n1)
      end
    end

    it "finds all daily and weekly policies for the user, communication_channel, and notification" do
      user_model
      communication_channel_model
      notification_model

      NotificationPolicy.delete_all

      n1 = notification_policy_model

      policies = NotificationPolicy.for(@notification).for(@user).for(@communication_channel).by_frequency([:daily, :weekly])
      expect(policies).to eq []

      n1.update_attribute(:frequency, "never")
      policies = NotificationPolicy.for(@notification).for(@user).for(@communication_channel).by_frequency([:daily, :weekly])
      expect(policies).to eq []

      n1.update_attribute(:frequency, "daily")
      policies = NotificationPolicy.for(@notification).for(@user).for(@communication_channel).by_frequency([:daily, :weekly])
      expect(policies).to eq [n1]

      n1.update_attribute(:frequency, "weekly")
      policies = NotificationPolicy.for(@notification).for(@user).for(@communication_channel).by_frequency([:daily, :weekly])
      expect(policies).to eq [n1]
    end
  end

  describe "setup_for" do
    it "does not fail when params does not include a user, and the account doesn't allow scores in e-mails" do
      user_model
      communication_channel_model
      notification_model(name: "Setting 1", category: "MultiCategory")
      params = { channel_id: @communication_channel.id }
      params[:root_account] = Account.default
      params[:root_account].settings[:allow_sending_scores_in_emails] = false
      NotificationPolicy.setup_for(@user, params)
    end

    it "updates send_observed_names_in_notifications when included" do
      user_model
      communication_channel_model
      params = { channel_id: @communication_channel.id }
      params[:root_account] = Account.default
      params[:user] = { send_observed_names_in_notifications: "true" }
      NotificationPolicy.setup_for(@user, params)
      expect(@user.send_observed_names_in_notifications?).to be true
      params[:user] = { send_observed_names_in_notifications: "false" }
      NotificationPolicy.setup_for(@user, params)
      expect(@user.send_observed_names_in_notifications?).to be false

      # Verify KNO-298
      params[:root_account].settings[:allow_sending_scores_in_emails] = false
      params[:user] = { send_observed_names_in_notifications: "true" }
      NotificationPolicy.setup_for(@user, params)
      expect(@user.send_observed_names_in_notifications?).to be true
    end

    it "sets all notification entries within the same category" do
      user_model
      communication_channel_model
      notify1 = notification_model(name: "Setting 1", category: "MultiCategory")
      notify2 = notification_model(name: "Setting 2", category: "MultiCategory")

      NotificationPolicy.delete_all

      trifecta_opts = {
        communication_channel: @communication_channel,
        frequency: Notification::FREQ_NEVER
      }
      n1 = notification_policy_model(trifecta_opts.merge(notification: notify1))
      n2 = notification_policy_model(trifecta_opts.merge(notification: notify2))
      params = { category: "multi_category", channel_id: @communication_channel.id, frequency: Notification::FREQ_IMMEDIATELY }
      NotificationPolicy.setup_for(@user, params)
      n1.reload
      n2.reload
      expect(n1.frequency).to eq Notification::FREQ_IMMEDIATELY
      expect(n2.frequency).to eq Notification::FREQ_IMMEDIATELY
    end

    it "does not modify another user's preferences" do
      notification_model
      hax0r = user_with_communication_channel
      user_with_communication_channel
      expect do
        NotificationPolicy.setup_for(hax0r, channel_id: @cc.id, frequency: Notification::FREQ_IMMEDIATELY, category: "test_immediately")
      end.to raise_error(ActiveRecord::RecordNotFound)
      expect(@user.notification_policies.any?).to be false
    end

    context "sharding" do
      specs_require_sharding

      it "creates records on the correct shard" do
        user_with_pseudonym(active_all: true)
        NotificationPolicy.delete_all
        notification_model
        @shard1.activate do
          expect(@user.notification_policies.scope.exists?).to be_falsey
          NotificationPolicy.setup_for(@user, channel_id: @cc.id, frequency: Notification::FREQ_IMMEDIATELY, category: "test_immediately")
          expect(@user.notification_policies.scope.exists?).to be_truthy
        end
      end
    end
  end

  describe "setup_with_default_policies" do
    before :once do
      @user = User.create!
      @communication_channel = communication_channel(@user, { username: "email@example.com" })
      @announcement = notification_model(name: "Setting 1", category: "Announcement")
    end

    before do
      allow(Notification).to receive(:all).and_return([@notification])
    end

    it "creates default NotificationPolicy entries if missing" do
      # Ensure no existing policies
      NotificationPolicy.delete_all

      policies = NotificationPolicy.setup_with_default_policies(@user)
      expect(policies.length).to eq 1
      expect(policies.first.frequency).to eq @announcement.default_frequency
    end

    it "does not overwrite an existing setting with a default" do
      # Create an existing policy entry
      NotificationPolicy.delete_all
      notification_policy_model({ communication_channel: @communication_channel,
                                  notification: @announcement,
                                  frequency: Notification::FREQ_NEVER })

      expect(@announcement.default_frequency).not_to eq Notification::FREQ_NEVER # verify that it differs from the default
      policies = NotificationPolicy.setup_with_default_policies(@user)
      expect(policies.length).to eq 1
      expect(policies.first.frequency).to eq Notification::FREQ_NEVER
    end

    it "does not set defaults on secondary communication channel" do
      NotificationPolicy.delete_all
      # Setup the second channel (higher position)
      primary_channel   = @user.communication_channel
      secondary_channel = communication_channel_model(path: "secondary@example.com")
      # start out with 0 on primary and secondary
      expect(primary_channel.notification_policies.count).to eq 0
      expect(secondary_channel.notification_policies.count).to eq 0
      # Load data
      NotificationPolicy.setup_with_default_policies(@user)
      # Primary should have 1 created and secondary should be left alone.
      expect(primary_channel.notification_policies.count).to eq 1
      expect(secondary_channel.notification_policies.count).to eq 0
    end

    it "does not pull defaults from non-default channels" do
      NotificationPolicy.delete_all
      # Setup the second channel (higher position)
      primary_channel   = @user.communication_channel
      secondary_channel = communication_channel_model(path: "secondary@example.com")
      secondary_channel.notification_policies.create!(notification: @notification, frequency: Notification::FREQ_NEVER)
      NotificationPolicy.setup_with_default_policies(@user)
      # Primary should have 1 created and secondary should be left alone.
      expect(primary_channel.reload.notification_policies.count).to eq 1
      expect(secondary_channel.reload.notification_policies.count).to eq 1
    end

    it "does not error if no channel exists" do
      NotificationPolicy.delete_all
      CommunicationChannel.delete_all
      expect { NotificationPolicy.setup_with_default_policies(@user) }.not_to raise_error
    end

    context "across shards" do
      specs_require_sharding

      it "finds user categories accross shards" do
        @shard1.activate do
          @shard_user = user_model
          @channel = communication_channel_model(user: @shard_user)
          NotificationPolicy.delete_all
          @policy = @channel.notification_policies.create!(notification: @notification, frequency: Notification::FREQ_NEVER)
          NotificationPolicy.setup_with_default_policies(@shard_user)
          expect(@policy.reload.frequency).to eq Notification::FREQ_NEVER
        end
      end
    end
  end

  context "find_all_for" do
    it "only returns course type notification policies if provided a course context type" do
      student = factory_with_protected_attributes(User, name: "student", workflow_state: "registered")
      channel = communication_channel(student, { username: "default@example.com", active_cc: true })

      course_type_notification = Notification.create!(name: "Course Type", subject: "Test", category: "Due Date")
      notification = Notification.create!(name: "Panda Express", subject: "Test", category: "Whatever")

      NotificationPolicy.create(notification: course_type_notification, communication_channel: channel, frequency: "immediately")
      NotificationPolicy.create(notification:, communication_channel: channel, frequency: "daily")
      NotificationPolicy.create(communication_channel: channel, frequency: "daily")

      policies = NotificationPolicy.find_all_for(channel, context_type: "Course")
      expect(policies.count).to eq 1
      expect(policies.first.notification.name).to eq course_type_notification.name
    end

    it "creates NotificationPolicies with default frequencies when they don't exist" do
      student = factory_with_protected_attributes(User, name: "student", workflow_state: "registered")
      channel = communication_channel(student, { username: "default@example.com", active_cc: true })
      notification = Notification.create!(name: "Panda Express", subject: "Test", category: "Whatever")

      # No existing policie with active communication channel
      expect(channel.notification_policies.count).to eq 0
      NotificationPolicy.find_all_for(channel)

      expect(channel.notification_policies.count).to eq 1
      expect(channel.notification_policies.first.frequency).to eq notification.default_frequency(channel.user)
    end
  end
end
