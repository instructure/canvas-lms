#
# Copyright (C) 2011 - 2014 Instructure, Inc.
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
    attr_accessor :dispatch, :to, :whenever, :context, :data, :recipient_filter

    def initialize(dispatch)
      self.dispatch = dispatch
      self.recipient_filter = lambda { |record, user| record }
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
      return unless record.instance_eval &self.whenever

      notification = BroadcastPolicy.notification_finder.by_name(self.dispatch)
      return if notification.nil?

      record.connection.after_transaction_commit do
        to_list = record.instance_eval(&self.to)
        to_list = Array(to_list).flatten
        next if to_list.empty?

        asset_context = record.instance_eval(&self.context) if self.context
        data = record.instance_eval(&self.data) if self.data

        BroadcastPolicy.notifier.send_notification(
          record,
          self.dispatch,
          notification,
          to_list,
          asset_context,
          data
        )
      end
    end

  end
  
end
