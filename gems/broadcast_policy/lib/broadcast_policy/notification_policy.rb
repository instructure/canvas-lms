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
      if (record.skip_broadcasts rescue false)
        record.messages_failed[self.dispatch] = "Broadcasting explicitly skipped"
        return false
      end
      begin
        meets_condition = record.instance_eval &self.whenever
      rescue
        meets_condition = false
        record.messages_failed[self.dispatch] = "Error thrown attempting to meet condition."
        return false
      end

      unless meets_condition
        record.messages_failed[self.dispatch] = "Did not meet condition."
        return false
      end
      notification = BroadcastPolicy.notification_finder.by_name(self.dispatch)
      # logger.warn "Could not find notification for #{record.inspect}" unless notification
      unless notification
        record.messages_failed[self.dispatch] = "Could not find notification: #{self.dispatch}."
        return false
      end
      # self.consolidated_notifications[notification_name.to_s.titleize] rescue nil
      begin
        to_list = record.instance_eval &self.to
      rescue
        to_list = nil
        record.messages_failed[self.dispatch] = "Error thrown attempting to generate a recipient list."
        return false
      end
      unless to_list
        record.messages_failed[self.dispatch] = "Could not generate a recipient list."
        return false
      end
      to_list = Array[to_list].flatten

      begin
        asset_context = record.instance_eval &self.context if self.context
      rescue
        record.messages_failed[self.dispatch] = "Error thrown attempting to get asset_context."
        return false
      end

      begin
        data = record.instance_eval &self.data if self.data
      rescue
        record.messages_failed[self.dispatch] = "Error thrown attempting to get data."
        return false
      end

      BroadcastPolicy.notifier.send_notification(record, self.dispatch, notification, to_list, asset_context, data)
    end

  end
  
end
