# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

module DataFixup
  module SetPostingNotificationFrequency
    def self.run
      grading_notifs = Notification.where(category: "Grading")
      submission_posted_notif = Notification.find_by(category: "Grading", name: "Submission Posted")
      submissions_posted_notif = Notification.find_by(category: "Grading", name: "Submissions Posted")
      posted_notifs = [submission_posted_notif, submissions_posted_notif]
      other_grading_notifs = grading_notifs - posted_notifs
      other_grading_notif_ids = other_grading_notifs.pluck(:id)
      fixup_time = Time.zone.now

      # We're only fixing notification policies that were created by default,
      # as we don't want to accidentally stomp on any user set policies.
      policy_scope = NotificationPolicy.
        where(notification: posted_notifs).
        where(frequency: "immediately").
        where("updated_at = created_at")

      CommunicationChannel.find_ids_in_batches do |cc_ids|
        communication_channels = CommunicationChannel.where(id: cc_ids).preload(:notification_policies)

        new_policies = []
        should_be_daily = []
        should_be_weekly = []
        should_be_never = []

        communication_channels.each do |cc|
          other_grading_notif_policies = cc.notification_policies.select do |policy|
            other_grading_notif_ids.include?(policy.notification_id)
          end

          # If Grading policies are already set to "immediately", there is no
          # harm in not creating Submission(s) Posted policies as the default
          # is already "immediately".
          next if other_grading_notif_policies.all? { |policy| policy.frequency == "immediately" }

          submission_posted_policy = cc.notification_policies.find do |policy|
            policy.notification_id == submission_posted_notif.id
          end

          submissions_posted_policy = cc.notification_policies.find do |policy|
            policy.notification_id == submissions_posted_notif.id
          end

          if submission_posted_policy.nil?
            new_policies << {
              communication_channel_id: cc.id,
              created_at: fixup_time,
              frequency: "immediately",
              notification_id: submission_posted_notif.id,
              updated_at: fixup_time
            }
          end

          if submissions_posted_policy.nil?
            new_policies << {
              communication_channel_id: cc.id,
              created_at: fixup_time,
              frequency: "immediately",
              notification_id: submissions_posted_notif.id,
              updated_at: fixup_time
            }
          end

          # There should not be a mixture of frequencies aside from the
          # Submission(s) Posted policies we're fixing, as the UI and API both
          # present a toggle that affects all notification policies within a
          # category.
          if other_grading_notif_policies.all? { |policy| policy.frequency == "daily" }
            should_be_daily << cc
          elsif other_grading_notif_policies.all? { |policy| policy.frequency == "weekly" }
            should_be_weekly << cc
          elsif other_grading_notif_policies.all? { |policy| policy.frequency == "never" }
            should_be_never << cc
          end
        end

        # Insert first so that they will be corrected in the update_all's below.
        NotificationPolicy.bulk_insert(new_policies)

        policy_scope.where(communication_channel: should_be_daily).update_all(frequency: "daily", updated_at: fixup_time)
        policy_scope.where(communication_channel: should_be_weekly).update_all(frequency: "weekly", updated_at: fixup_time)
        policy_scope.where(communication_channel: should_be_never).update_all(frequency: "never", updated_at: fixup_time)
      end
    end
  end
end
