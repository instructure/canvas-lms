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

describe DelayedMessage do
  it "should create a new instance given valid attributes" do
    delayed_message_model
  end
  
  context "named scopes" do
    before :once do
      DelayedMessage.delete_all
    end

    it "should have scope for :daily" do
      delayed_message_model(:frequency => 'daily')
      DelayedMessage.for(:daily).should == [@delayed_message]
    end
    
    it "should scope for :weekly" do
      delayed_message_model(:frequency => 'weekly')
      DelayedMessage.for(:weekly).should == [@delayed_message]
    end
    
    it "should scope for notification" do
      notification_model
      delayed_message_model
      DelayedMessage.for(@notification).should == [@delayed_message]
    end
    
    it "should scope for notification_policy" do
      notification_policy_model
      delayed_message_model(:notification_policy_id => @notification_policy.id)
      @notification_policy.should be_is_a(NotificationPolicy)
      DelayedMessage.for(@notification_policy).should == [@delayed_message]
    end
    
    it "should scope for communication_channel" do
      communication_channel_model
      delayed_message_model(:communication_channel_id => @communication_channel.id)
      @communication_channel.should be_is_a(CommunicationChannel)
      DelayedMessage.for(@communication_channel).should == [@delayed_message]
    end
    
    it "should scope for context" do
      delayed_message_model
      @delayed_message.context = assignment_model
      @delayed_message.save!
      DelayedMessage.for(@assignment).should == [@delayed_message]
    end

    it "should have a scope to order the messages by a field" do
      notification = notification_model
      cc = user.communication_channels.create!(:path => 'path@example.com')
      nps = (1..3).inject([]) do |list, e|
        list << cc.notification_policies.create!(:notification => notification, :frequency => Notification::FREQ_IMMEDIATELY)
      end
      dms = nps.map do |np|
        DelayedMessage.create!(:notification => notification,
                               :notification_policy => np,
                               :context => cc,
                               :communication_channel => cc)
      end
      DelayedMessage.by(:notification_policy_id).map(&:id).should eql(dms.map(&:id).sort)
    end
    
    it "should have a scope to filter by the state" do
      notification = notification_model :name => 'New Stuff'
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
    before :once do
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
    Canvas::MessageHelper.create_notification(:name => 'Summaries', :category => 'Summaries')
    account = Account.create!(:name => 'new acct')
    user = user_with_pseudonym(:account => account)
    user.pseudonym.account.should == account
    HostUrl.expects(:context_host).with(user.pseudonym.account).at_least(1).returns("dm.dummy.test.host")
    HostUrl.stubs(:default_host).returns("test.host")
    dm = DelayedMessage.create!(:summary => "This is a notification", :context => Account.default, :communication_channel => user.communication_channel, :notification => notification_model)
    DelayedMessage.summarize([dm])
    message = Message.last
    message.body.to_s.should_not match(%r{http://test.host/})
    message.body.to_s.should match(%r{http://dm.dummy.test.host/})
  end

  context "sharding" do
    specs_require_sharding

    it "should create messages on the user's shard" do
      Canvas::MessageHelper.create_notification(:name => 'Summaries', :category => 'Summaries')

      @shard1.activate do
        account = Account.create!(:name => 'new acct')
        user = user_with_pseudonym(:account => account)
        user.pseudonym.account.should == account
        HostUrl.expects(:context_host).with(user.pseudonym.account).at_least(1).returns("dm.dummy.test.host")
        HostUrl.stubs(:default_host).returns("test.host")
        @cc = user.communication_channel
        @dm = DelayedMessage.create!(:summary => "This is a notification", :context => account, :communication_channel => @cc, :notification => notification_model)
      end
      @shard2.activate do
        DelayedMessage.summarize([@dm])
        @cc.messages.last.should_not be_nil
        @cc.messages.last.shard.should == @shard1
      end
    end
  end

  describe "set_send_at" do
    before :once do
      # shouldn't be used, but to make sure it's not equal to any of the other
      # time zones in play
      Time.zone = 'UTC'
      @true_now = Time.zone.now

      # time zones of interest
      @mountain = ActiveSupport::TimeZone.us_zones.find{ |zone| zone.name == 'Mountain Time (US & Canada)' }
      @central = ActiveSupport::TimeZone.us_zones.find{ |zone| zone.name == 'Central Time (US & Canada)' }
      @eastern = ActiveSupport::TimeZone.us_zones.find{ |zone| zone.name == 'Eastern Time (US & Canada)' }

      # set up user in central time (different than the specific time zones
      # referenced in set_send_at)
      @account = Account.create!(:name => 'new acct')
      @user = user_with_pseudonym(:account => @account)
      @user.time_zone = @central.name
      @user.pseudonym.update_attribute(:account, @account)
      @user.save
    end

    before :each do
      # build the delayed message
      @dm = DelayedMessage.new(:context => @account, :communication_channel => @user.communication_channel)
    end

    it "should do nothing if the CC isn't set yet" do
      @dm.communication_channel = nil
      @dm.send(:set_send_at)
      @dm.send_at.should be_nil
    end

    it "should do nothing if send_at is already set" do
      send_at = @true_now - 5.days
      @dm.send_at = send_at
      @dm.send(:set_send_at)
      @dm.send_at.should == send_at
    end

    it "should set to 6pm in the user's time zone for non-weekly messages" do
      Timecop.freeze(@central.now.change(:hour => 12)) do
        @dm.frequency = 'daily'
        @dm.send(:set_send_at)
        @dm.send_at.should == @central.now.change(:hour => 18)
      end
    end

    it "should set to 6pm in the Mountain time zone for non-weekly messages when the user hasn't set a time zone" do
      @user.time_zone = nil
      @user.save

      Timecop.freeze(@mountain.now.change(:hour => 12)) do
        @dm.frequency = 'daily'
        @dm.send(:set_send_at)
        @dm.send_at.should == @mountain.now.change(:hour => 18)
      end
    end

    it "should set to 6pm the next day for non-weekly messages created after 6pm" do
      Timecop.freeze(@central.now.change(:hour => 20)) do
        @dm.frequency = 'daily'
        @dm.send(:set_send_at)
        @dm.send_at.should == @central.now.tomorrow.change(:hour => 18)
      end
    end

    it "should set to next saturday (Eastern-time) for weekly messages" do
      monday = @eastern.now.monday
      saturday = monday + 5.days
      sunday = saturday + 1.day

      Timecop.freeze(monday) do
        @dm.frequency = 'weekly'
        @dm.send(:set_send_at)
        @dm.send_at.in_time_zone(@eastern).midnight.should == saturday
      end

      Timecop.freeze(sunday) do
        @dm.send_at = nil
        @dm.send(:set_send_at)
        @dm.send_at.in_time_zone(@eastern).midnight.should == saturday + 1.week
      end
    end

    it "should set to next saturday (Eastern-time) for weekly messages scheduled later saturday" do
      monday = @eastern.now.monday
      saturday = monday + 5.days

      Timecop.freeze(monday) do
        @dm.frequency = 'weekly'
        @dm.send(:set_send_at)
      end

      Timecop.freeze(@dm.send_at + 30.minutes) do
        @dm.send_at = nil
        @dm.send(:set_send_at)
        @dm.send_at.in_time_zone(@eastern).midnight.should == saturday + 1.week
      end
    end

    it "should use the same time of day across weeks for weekly messages for the same user" do
      # anchor to January 1st to avoid DST; we're consigned to slightly weird
      # behavior around DST, but don't want it failing tests
      monday = @eastern.now.change(:month => 1, :day => 1).monday
      first = nil

      Timecop.freeze(monday) do
        @dm.frequency = 'weekly'
        @dm.send(:set_send_at)
        first = @dm.send_at
      end

      Timecop.freeze(monday + 1.week) do
        @dm.send_at = nil
        @dm.send(:set_send_at)
        @dm.send_at.in_time_zone(@eastern).should == first + 1.week
      end
    end

    it "should spread weekly messages for users in different accounts over the windows" do
      monday = @eastern.now.monday
      saturday = monday + 5.days

      Timecop.freeze(monday) do
        @dm.frequency = 'weekly'

        expected_windows = []
        actual_windows = []

        DelayedMessage::WEEKLY_ACCOUNT_BUCKETS.times.map do |i|
          @dm.communication_channel.user.pseudonym.account_id = i
          @dm.send_at = nil
          @dm.send(:set_send_at)
          actual_windows << (@dm.send_at - saturday).to_i / (60 * DelayedMessage::MINUTES_PER_WEEKLY_ACCOUNT_BUCKET)
          expected_windows << i
        end

        actual_windows.sort.should == expected_windows
      end
    end

    it "should spread weekly messages for different users in the same account over the same window" do
      monday = @eastern.now.monday
      saturday = monday + 5.days

      Timecop.freeze(monday) do
        @dm.frequency = 'weekly'

        expected_diffs = []
        actual_diffs = []
        windows = []

        DelayedMessage::MINUTES_PER_WEEKLY_ACCOUNT_BUCKET.times.map do |i|
          @dm.communication_channel.user.id = i
          @dm.send_at = nil
          @dm.send(:set_send_at)
          window = (@dm.send_at - saturday).to_i / (60 * DelayedMessage::MINUTES_PER_WEEKLY_ACCOUNT_BUCKET)
          windows << window
          actual_diffs << @dm.send_at - saturday - (DelayedMessage::MINUTES_PER_WEEKLY_ACCOUNT_BUCKET * window).minutes
          expected_diffs << i.minutes
        end

        actual_diffs.sort.should == expected_diffs
        windows.uniq.size.should == 1
      end
    end
  end

  describe '.context_type' do
    it 'returns the correct representation of a quiz submission' do
      message = delayed_message_model
      submission = quiz_model.quiz_submissions.create!
      message.context = submission
      message.save
      message.context_type.should == 'Quizzes::QuizSubmission'

      DelayedMessage.where(id: message).update_all(context_type: 'QuizSubmission')

      DelayedMessage.find(message.id).context_type.should == 'Quizzes::QuizSubmission'
    end
  end
end
