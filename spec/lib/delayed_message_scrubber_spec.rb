# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

describe DelayedMessageScrubber do
  # Helpers
  def delayed_message(send_at)
    message = DelayedMessage.new(notification: @notification,
                                 context: @context,
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

  describe "#scrub" do
    before do
      @context      = course_factory
      @notification = Notification.create!(name: "Test Notification", category: "Test")
      @recipient    = user_factory

      communication_channel(@recipient, { username: "user@example.com" })
    end

    it "deletes delayed messages older than 90 days" do
      messages = old_messages(2)
      scrubber = DelayedMessageScrubber.new
      scrubber.scrub
      expect(DelayedMessage.where(id: messages.map(&:id)).count).to eq 0
    end

    it "does not delete messages younger than 90 days" do
      messages = old_messages(1) + new_messages(1)

      scrubber = DelayedMessageScrubber.new
      scrubber.scrub
      expect(DelayedMessage.where(id: messages.map(&:id)).count).to eq 1
    end

    it "logs predicted results if passed dry_run=true" do
      logger = double
      old_messages(2)
      scrubber = DelayedMessageScrubber.new(logger:)

      expect(logger).to receive(:info).with("DelayedMessageScrubber: 2 records would be deleted (older than #{scrubber.limit})")
      scrubber.scrub(dry_run: true)
    end
  end
end
