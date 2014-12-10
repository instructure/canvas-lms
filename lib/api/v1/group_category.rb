#
# Copyright (C) 2013 Instructure, Inc.
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

module Api::V1::GroupCategory
  include Api::V1::Json
  include Api::V1::Context
  include Api::V1::Progress

  API_GROUP_CATEGORY_JSON_OPTS = {
    :only => %w(id name role self_signup group_limit auto_leader)
  }

  def group_category_json(group_category, user, session, options = {})
    hash = api_json(group_category, user, session, API_GROUP_CATEGORY_JSON_OPTS)
    hash.merge!(context_data(group_category))
    hash.merge!(included_data(group_category, options[:include]))
    hash['protected'] = group_category.protected?
    hash['allows_multiple_memberships'] = group_category.allows_multiple_memberships?
    hash['is_member'] = group_category.is_member?(user)
    hash
  end

  private
  def included_data(group_category, includes)
    hash = {}
    if includes
      if includes.include?('progress_url') && group_category.current_progress && group_category.current_progress.pending?
        hash['progress'] = progress_json(group_category.current_progress, user, session)
      end
      if includes.include?('groups_count')
        hash['groups_count'] = group_category.groups.active.size
      end
      if includes.include?('unassigned_users_count')
        hash['unassigned_users_count'] = group_category.unassigned_users.count
      end
    end
    hash
  end
end
