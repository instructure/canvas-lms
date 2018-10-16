#
# Copyright (C) 2018 - present Instructure, Inc.
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

class FixEnrollmentAcceptedNotificationCategory < ActiveRecord::Migration[5.1]
  tag :postdeploy
  disable_ddl_transaction!

  def change
    # Fix the category that this notification belongs to. Note that changing
    # the category doesn't actually change the notification policy for users
    # to use their settings for this category group. We manually fix those up
    # next.
    n = Notification.find_by(name: "Enrollment Accepted")
    if n.nil?
      n = Notification.create(
        name: "Enrollment Accepted",
        subject: "No Subject",
        category: "Other",
        delay_for: 0,
        workflow_state: "active"
      )
    elsif Shard.current.default?
      n.category = "Other"
      n.save!
    end

    # These are what we need to update. They should now have the same frequency
    # settings as everything else in the "Other" notification category group
    communication_channel_ids_to_update = []
    NotificationPolicy.find_ids_in_ranges(:batch_size => 100_000) do |min_id, max_id|
      communication_channel_ids_to_update += NotificationPolicy.
        where(id: min_id..max_id).
        where(notification_id: n.id).
        pluck(:communication_channel_id)
    end

    # Get existing notifications in the "Other" group that we can use to find
    # the correct frequency to set the "Enrollment Accepted" to
    other_category_target_ids = Notification.
      where(category: "Other").
      where(workflow_state: "active").
      where.not(id: n.id).
      pluck(:id)

    # Batch update the required notification policies
    communication_channel_ids_to_update.each_slice(1000) do |batched_cc_ids|
      # Find what the new frequency should be for the "Enrollment Accepted"
      # notification, based on other values in the same notification category are,
      # or using the default 'daily' value if no other notifications in these
      # categories have an override set.
      channel_freq_map = {}
      other_category_targets = NotificationPolicy.
        where(notification_id: other_category_target_ids).
        where(communication_channel_id: batched_cc_ids)
      batched_cc_ids.each do |communication_channel_id|
        channel_freq_map[communication_channel_id] = 'daily'
      end
      other_category_targets.each do |np|
        channel_freq_map[np.communication_channel_id] = np.frequency
      end

      # Group all the same frequencies together, so we can update them in the
      # database in one go instead of doing a seperate update on each individual
      # item
      frequency_grouping = Hash.new { |h, k| h[k] = [] }
      channel_freq_map.each do |communication_channel_id, frequency|
        frequency_grouping[frequency].push(communication_channel_id)
      end

      # Actually update items in the database
      frequency_grouping.each do |frequency, communication_channel_ids|
        NotificationPolicy.
          where(notification_id: n.id).
          where(communication_channel_id: communication_channel_ids).
          update_all(frequency: frequency)
      end
    end
  end
end
