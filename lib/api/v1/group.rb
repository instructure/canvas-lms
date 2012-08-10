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

module Api::V1::Group
  include Api::V1::Json
  include Api::V1::Context

  API_GROUP_JSON_OPTS = {
    :only => %w(id name description is_public join_level group_category_id),
    :methods => %w(members_count),
  }

  API_GROUP_MEMBERSHIP_JSON_OPTS = {
    :only => %w(id group_id user_id workflow_state moderator)
  }

  def group_json(group, user, session, options = {})
    hash = api_json(group, user, session, API_GROUP_JSON_OPTS)
    hash.merge!(context_data(group))
    followed = ::UserFollow.followed_by_user([group], user)
    hash['followed_by_user'] = !!followed.include?(group)
    image = group.avatar_attachment
    hash['avatar_url'] = image && thumbnail_image_url(image, image.uuid)
    hash['role'] = group.group_category.role
    include = options[:include] || []
    if include.include?('users')
      # TODO: this should be switched to user_display_json
      hash['users'] = group.users.map{ |u| user_json(u, user, session) }
    end
    hash
  end

  def group_membership_json(membership, user, session)
    api_json(membership, user, session, API_GROUP_MEMBERSHIP_JSON_OPTS)
  end
end
