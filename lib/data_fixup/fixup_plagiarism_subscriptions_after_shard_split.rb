#
# Copyright (C) 2020 - present Instructure, Inc.
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

# this datafixup is not intended to have a corresponding migration. it will be
# manually applied

module DataFixup
  # This fixup is meant to be run after a shard split.
  #
  # Plagiarism platform live event subscriptions use
  # the shard ID of events to deliver the event to
  # the correct customer.
  #
  # This data fixup destroys all subscriptions that
  # are orphaned in the shard split and then recreates
  # them.
  class FixupPlagiarismSubscriptionsAfterShardSplit
    def self.run
      # We just did a shard split, so we need to update
      # all plagiarism platform subscriptions
      AssignmentConfigurationToolLookup.find_each do |actl|
        # Clean up so we don't have orphaned subscriptions
        perform_subscription_operation(:destroy_subscription, actl)

        # Recreate the subscription using the new shard ID
        perform_subscription_operation(:create_subscription, actl)
      end
    end

    def self.perform_subscription_operation(operation, actl)
      actl.send(operation)
    rescue => e
      ::Canvas::Errors.capture(
        e,
        {
          tags: {
            type: "#{operation}_after_shard_split"
          },
          extra: {
            subscription_id: actl.subscription_id,
            assignment_id: actl.assignment.global_id
          }
        }
      )
    end
    private_class_method :perform_subscription_operation
  end
end