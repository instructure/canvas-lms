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
#

module Api::V1::Group
  include Api::V1::Json
  include Api::V1::Context
  include Api::V1::Tab

  API_GROUP_JSON_OPTS = {
    :only => %w(id name description is_public join_level group_category_id max_membership),
    :methods => %w(members_count storage_quota_mb),
  }

  API_GROUP_MEMBERSHIP_JSON_OPTS = {
    :only => %w(id group_id user_id workflow_state moderator)
  }

  API_PERMISSIONS_TO_INCLUDE = [:create_discussion_topic, :join, :create_announcement] # permission keys need to be symbols

  def group_json(group, user, session, options = {})
    includes = options[:include] || []
    permissions_to_include = API_PERMISSIONS_TO_INCLUDE if includes.include?('permissions')

    hash = api_json(group, user, session, API_GROUP_JSON_OPTS, permissions_to_include)
    hash.merge!(context_data(group))
    image = group.avatar_attachment
    hash['avatar_url'] = image && thumbnail_image_url(image, image.uuid)
    hash['role'] = group.group_category.role if group.group_category
    #hash['leader_id'] = group.leader_id
    hash['leader'] = group.leader ? user_display_json(group.leader, group) : nil

    if includes.include?('users')
      users = group.grants_right?(@current_user, :read_as_admin) ?
        group.users.order_by_sortable_name.uniq : group.participating_users_in_context(sort: true).uniq

      # TODO: this should be switched to user_display_json
      hash['users'] = users.map{ |u| user_json(u, user, session) }
    end
    if includes.include?('group_category')
      hash['group_category'] = group.group_category && group_category_json(group.group_category, user, session)
    end
    if includes.include?('favorites')
      hash['is_favorite'] = group.favorite_for_user?(user)
    end
    hash['html_url'] = group_url(group) if includes.include? 'html_url'
    hash['sis_group_id'] = group.sis_source_id if group.context_type == 'Account' && group.account.grants_any_right?(user, session, :read_sis, :manage_sis)
    hash['sis_import_id'] = group.sis_batch_id if group.context_type == 'Account' && group.account.grants_right?(user, session, :manage_sis)
    hash['has_submission'] = group.submission?
    hash['concluded'] = group.context.concluded? || group.context.deleted?
    hash['tabs'] = tabs_available_json(group, user, session, ['external']) if includes.include?('tabs')
    hash
  end

  def group_membership_json(membership, user, session, options = {})
    includes = options[:include] || []
    hash = api_json(membership, user, session, API_GROUP_MEMBERSHIP_JSON_OPTS)
    if includes.include?('just_created')
      hash['just_created'] = membership.just_created || false
    end
    if membership.group.context_type == 'Account' && membership.group.account.grants_right?(user, session, :manage_sis)
      hash['sis_import_id'] = membership.sis_batch_id
    end
    hash
  end
end
