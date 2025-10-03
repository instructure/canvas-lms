# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

module NotificationSpecHelpers
  # Advanced spy class for detailed notification inspection
  # Example usage:
  #   spy = spy_on_notifications
  #   @assignment.save!
  #   expect(spy.count).to eq(2)
  #   expect(spy.for_notification(:assignment_created)).to have(1).item
  #   expect(spy.for_user(@student)).to have(1).item
  class NotificationSpy
    attr_reader :notifications

    def initialize
      @notifications = []
    end

    # Example: Called internally when a notification is sent
    def record(notification_args)
      @notifications << NotificationRecord.new(notification_args)
    end

    # Example: spy.clear  # Reset captured notifications
    delegate :clear, to: :@notifications

    # Example: spy.for_notification(:assignment_created)  # Get all assignment_created notifications
    def for_notification(name)
      name = name.to_s.titleize
      @notifications.select { |n| n.dispatch == name }
    end

    # Example: spy.for_user(@student)  # Get all notifications for a specific user
    def for_user(user)
      @notifications.select { |n| n.recipients.include?(user) }
    end

    # Example: expect(spy.count).to eq(5)  # Total number of notifications captured
    def count
      @notifications.size
    end

    NotificationRecord = Struct.new(:record, :dispatch, :recipients, :data) do
      def initialize(args)
        self.record = args[:record]
        self.dispatch = args[:dispatch].to_s.titleize
        self.recipients = Array(args[:to])
        self.data = args[:data] || {}
      end
    end
  end
end
