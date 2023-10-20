# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

module BroadcastPolicy
  class NotificationPolicy
    attr_accessor :dispatch, :to, :whenever, :data, :recipient_filter

    def initialize(dispatch)
      self.dispatch = dispatch
      self.recipient_filter = ->(record, _user) { record }
    end

    # This should be called for an instance.  It can only be sent out if the
    # condition is met, if there is a notification that we can find, and if
    # there is someone to send this to.  At this point, a Message record is
    # created, which will be delayed, consolidated, dispatched to the right
    # server, and then finally sent through that server.
    #
    # This now sets a series of temporary flags while working for audit
    # reasons.
    def broadcast(record)
      return if record.respond_to?(:skip_broadcasts) && record.skip_broadcasts
      return unless record.instance_eval(&whenever)

      notification = BroadcastPolicy.notification_finder.by_name(dispatch)
      return if notification.nil?

      record.class.connection.after_transaction_commit do
        to_list = record.instance_eval(&to)
        to_list = to_list.eager_load(:active_pseudonyms) if to_list.try(:reflections)&.key?("active_pseudonyms")
        to_list = Array(to_list).flatten
        next if to_list.empty?

        data = record.instance_eval(&self.data) if self.data
        to_list.each_slice(NotificationPolicy.slice_size) do |to_slice|
          recipients = to_slice.reject { |to| to.class.method_defined?(:suspended?) ? to.suspended? : false }
          next if recipients.empty?

          BroadcastPolicy.notifier.send_notification(
            record,
            dispatch,
            notification,
            recipients,
            data
          )
        end
      end
    end

    # if the to_list is users, each user will have a couple of communication channels,
    # then we need to load the policies for them. Limiting the number to 500 keeps
    # the process from memory bloat on the job server and large queries in the database.
    # For 99% of broadcasts this will not change anything.
    def self.slice_size
      if defined?(Setting)
        Setting.get("broadcast_policy_slice_size", 500).to_i
      else
        500
      end
    end
  end

  require "active_support/core_ext/object/try"
end
