#
# Copyright (C) 2012 Instructure, Inc.
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

module Api::V1::UserFollow
  include Api::V1::Json

  API_USER_FOLLOW_JSON_OPTS = {
    :only => %w(following_user_id created_at),
  }

  def user_follow_json(user_follow, current_user, session)
    hash = api_json(user_follow, current_user, session, API_USER_FOLLOW_JSON_OPTS)
    hash["followed_#{user_follow.followed_item_type.underscore}_id"] = user_follow.followed_item_id
    hash
  end
end
