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
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

# Helpers
def delayed_message(send_at)
  message = DelayedMessage.new(notification: @notification, context: @context,
          communication_channel: @recipient.communication_channel)
  message.send_at = send_at
  message.save!
  message
end

def old_messages(count = 2)
  (1..count).map do
    delayed_message(100.days.ago)
  end
end

def new_messages(count = 2)
  (1..count).map do
    delayed_message(Time.now)
  end
end

describe MessageScrubber do

  describe '#scrub' do

    before(:each) do
      @context      = course
      @notification = Notification.create!(name: 'Test Notification', category: 'Test')
      @recipient    = user

      @recipient.communication_channels.create!(path_type: 'email', path: 'user@example.com')
    end

    it 'should delete delayed messages older than 90 days' do
      messages = old_messages(2)
      scrubber = MessageScrubber.new
      scrubber.scrub
      DelayedMessage.where(id: messages.map(&:id)).count.should == 0
    end

    it 'should not delete messages younger than 90 days' do
      messages = old_messages(1) + new_messages(1)

      scrubber = MessageScrubber.new
      scrubber.scrub
      DelayedMessage.where(id: messages.map(&:id)).count.should == 1
    end

    it 'should log predicted results if passed dry_run=true' do
      logger   = mock
      messages = old_messages(2)
      scrubber = MessageScrubber.new(logger: logger)

      logger.expects(:info).with("MessageScrubber: 2 records would be deleted (older than #{scrubber.limit})")
      scrubber.scrub(dry_run: true)
    end
  end

  describe '#scrub_all' do
    specs_require_sharding

    before(:each) do
      @messages = []
      @notification = Notification.create!(name: 'Test Notification', category: 'Test')

      @shard1.activate do
        @context      = course
        @recipient    = user(name: 'User One')
        @recipient.communication_channels.create!(path_type: 'email', path: 'user1@example.com')
        @messages.concat(old_messages(1))
      end

      @shard2.activate do
        @context      = course
        @recipient    = user(name: 'User Two')
        @recipient.communication_channels.create!(path_type: 'email', path: 'user2@example.com')
        @messages.concat(old_messages(1))
      end
    end

    it 'should scrub all shards' do
      scrubber = MessageScrubber.new

      scrubber.scrub_all
      [@shard1, @shard2].each do |shard|
        shard.activate do
          DelayedMessage.where(id: @messages.map(&:id)).count.should == 0
        end
      end
    end

    it 'should log each shard separately' do
      logger   = mock
      scrubber = MessageScrubber.new(logger: logger)

      logger.expects(:info).times(Shard.all.count)
      scrubber.scrub_all(dry_run: true)
    end
  end
end
