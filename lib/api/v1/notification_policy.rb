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

# includes Enrollment json helpers
module Api::V1::NotificationPolicy
  include Api::V1::Json

  # Internal: The attributes returned by notification_category_json.
  JSON_OPTS = {
    :only => %w{ id notification_id communication_channel_id frequency } }

  # Public: Given a NotificationPolicy model, return it in an API-friendly format.
  #
  # policy - The notification policy object to turn into a hash.
  # user - The requesting user.
  # session - The current session (or nil, if no session is available)
  #
  # Returns a Hash of notification attributes and additional method results:
  #   :id
  #   :notification_id
  #   :communication_channel_id
  #   :frequency
  def notification_policy_json(policy, user, session)
    api_json(policy, user, session, JSON_OPTS).tap do |json|
      # Add the category from the linked notification
      json[:category] = policy.notification.try(:category)
      # Rename some attributes for more friendly usage
      json[:channel_id] = json.delete(:communication_channel_id)
    end
  end

end
