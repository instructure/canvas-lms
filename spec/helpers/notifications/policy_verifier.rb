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
  # Helper class to verify notification policies are configured correctly on models
  # Example usage:
  #   verify_notification_policy(@assignment) do
  #     should_send(:assignment_created).to(@course.students)
  #     should_not_send(:assignment_graded)
  #   end
  class PolicyVerifier
    def initialize(model)
      @model = model
      @expectations = []
    end

    # Example: should_send(:assignment_created).to(@course.students)
    def should_send(notification_name)
      @expectations << { type: :should_send, name: notification_name.to_s.titleize }
    end

    # Example: should_not_send(:assignment_graded)  # When not yet graded
    def should_not_send(notification_name)
      @expectations << { type: :should_not_send, name: notification_name.to_s.titleize }
    end

    # Example: should_send(:assignment_created).to(@student1, @student2)
    def to(*recipients)
      @expectations.last[:recipients] = recipients.flatten
    end

    # Called internally to verify all expectations
    def verify!
      @expectations.each do |expectation|
        policies = @model.class.broadcast_policy_list.select { |p| p.dispatch == expectation[:name] }

        policies.each do |policy|
          should_send = @model.instance_eval(&policy.whenever)

          case expectation[:type]
          when :should_send
            raise "Expected to send #{expectation[:name]} but condition returned false" unless should_send

            if expectation[:recipients]
              actual = @model.instance_eval(&policy.to)
              missing = expectation[:recipients] - actual
              raise "Expected recipients missing: #{missing.inspect}" if missing.any?
            end
          when :should_not_send
            raise "Expected not to send #{expectation[:name]} but condition returned true" if should_send
          end
        end
      end
    end
  end
end
