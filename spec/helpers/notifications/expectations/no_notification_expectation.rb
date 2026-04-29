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
  # Expectation class for verifying no notifications are sent
  # Example usage:
  #   expect_no_notifications.when { @assignment.save_without_broadcasting }
  class NoNotificationExpectation
    def initialize(&block)
      @block = block
    end

    # Example: .when { @unpublished_assignment.save! }
    # Example: .during { @muted_assignment.grade_student(@student, grade: 95) }
    def when(&)
      initial_messages = Message.all.to_a if defined?(Message)

      result = yield

      if defined?(Message)
        new_messages = Message.all.to_a - initial_messages
        if new_messages.any?
          notification_names = new_messages.map(&:notification_name).uniq.join(", ")
          raise RSpec::Expectations::ExpectationNotMetError,
                "Expected no notifications to be sent, but got: #{notification_names}"
        end
      end

      result
    end
    alias_method :during, :when
  end
end
