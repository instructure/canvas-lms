#
# Copyright (C) 2011 Instructure, Inc.
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

module Instructure #:nodoc:
  module Broadcast #:nodoc:
    module Policy #:nodoc:
      class PolicyStorage
        
        attr_accessor :dispatch, :to, :whenever
        
        def initialize(dispatch)
          self.dispatch = dispatch
        end

        # This should be called for an instance.  It can only be sent out if the
        # condition is met, if there is a notification that we can find, and if
        # there is someone to send this to.  At this point, a Message record is
        # created, which will be delayed, consolidated, dispatched to the right
        # server, and then finally sent through that server. 
        
        def dispatch(record)
          meets_condition = self.whenever.call(record)
          return false unless meets_condition

          notification = Notification.find_by_name(self.dispatch)
          return false unless notification
          # self.consolidated_notifications[notification_name.to_s.titleize] rescue nil
          
          to_list = self.to.call(record)
          return false unless to_list

          notification.create_message(record, to_list)
        end
        
      end
    end
  end
end
