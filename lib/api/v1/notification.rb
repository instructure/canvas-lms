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
module Api::V1::Notification
  include Api::V1::Json

  # Internal: The attributes returned by notification_category_json.
  JSON_OPTS = {
    :only => %w{ id name category workflow_state user_id } }

  # Public: Given a notification model, return it in an API-friendly format.
  #
  # category - The notification model to turn into a hash.
  # user - The requesting user.
  # session - The current session (or nil, if no session is available)
  #
  # Returns a Hash of notification attributes and additional method results:
  #   :id
  #   :name
  #   :category
  #   :display_name (read-only category_display_name method result)
  #   :category_description (read-only category_description method result)
  #   :option (related_user_setting method result with name and value of the associated user option)
  #   :user_id
  #   :workflow_state
  def notification_category_json(category, user, session)
    api_json(category, user, session, JSON_OPTS).tap do |json|
      # Add custom method result entries to the json
      json[:display_name]         = category.category_display_name
      json[:category_description] = category.category_description
      json[:option]               = category.related_user_setting(user)
    end
  end

end
