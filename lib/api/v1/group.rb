# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

  GROUP_MEMBER_LIMIT = 1000

  API_GROUP_JSON_OPTS = {
    only: %w[id name description is_public join_level group_category_id max_membership created_at],
    methods: %w[members_count storage_quota_mb],
  }.freeze

  API_GROUP_MEMBERSHIP_JSON_OPTS = {
    only: %w[id group_id user_id workflow_state moderator created_at].freeze
  }.freeze

  # permission keys need to be symbols
  API_PERMISSIONS_TO_INCLUDE = %i[create_discussion_topic join create_announcement].freeze

  def group_json(group, user, session, options = {})
    options.reverse_merge!(include_inactive_users: false)
    includes = options[:include] || []
    permissions_to_include = API_PERMISSIONS_TO_INCLUDE if includes.include?("permissions")

    hash = api_json(group, user, session, API_GROUP_JSON_OPTS, permissions_to_include)
    hash.merge!(context_data(group))
    image = group.avatar_attachment
    hash["avatar_url"] = image && thumbnail_image_url(image)
    hash["role"] = group.group_category.role if group.group_category
    # hash['leader_id'] = group.leader_id
    hash["leader"] = group.leader ? user_display_json(group.leader, group) : nil

    if includes.include?("users")
      users = if group.grants_right?(@current_user, :read_as_admin)
                group.users.order_by_sortable_name.limit(GROUP_MEMBER_LIMIT).distinct
              else
                group.participating_users_in_context(sort: true, include_inactive_users: options[:include_inactive_users]).limit(GROUP_MEMBER_LIMIT).distinct
              end
      active_user_ids = nil
      if options[:include_inactive_users]
        active_user_ids = group.participating_users_in_context.pluck("id").to_set
      end

      # TODO: this should be switched to user_display_json
      hash["users"] = users.map do |u|
        json = user_json(u, user, session)
        if options[:include_inactive_users] && active_user_ids
          json["active"] = active_user_ids.include?(u.id)
        end
        json
      end
    end
    if includes.include?("group_category")
      hash["group_category"] = group.group_category && group_category_json(group.group_category, user, session)
    end
    if includes.include?("favorites")
      hash["is_favorite"] = group.favorite_for_user?(user)
    end
    hash["html_url"] = group_url(group) if includes.include? "html_url"
    hash["sis_group_id"] = group.sis_source_id if group.root_account.grants_any_right?(user, session, :read_sis, :manage_sis)
    hash["sis_import_id"] = group.sis_batch_id if group.root_account.grants_right?(user, session, :manage_sis)
    hash["has_submission"] = group.submission?
    hash["concluded"] = group.context.concluded? || group.context.deleted?
    hash["tabs"] = tabs_available_json(group, user, session, ["external"]) if includes.include?("tabs")

    if includes.include?("can_access")
      hash["can_access"] = group.grants_right?(@current_user, :read)
    end

    if includes.include?("can_message")
      hash["can_message"] = group.grants_right?(@current_user, :send_messages)
    end
    hash
  end

  def group_membership_json(membership, user, session, options = {})
    includes = options[:include] || []
    hash = api_json(membership, user, session, API_GROUP_MEMBERSHIP_JSON_OPTS)
    if includes.include?("just_created")
      hash["just_created"] = membership.just_created || false
    end
    if membership.group.root_account.grants_any_right?(user, session, :read_sis, :manage_sis)
      hash["sis_group_id"] = membership.group.sis_source_id
    end
    if membership.group.root_account.grants_right?(user, session, :manage_sis)
      hash["sis_import_id"] = membership.sis_batch_id
    end
    hash
  end
end
