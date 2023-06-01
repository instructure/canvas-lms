# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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
  include Api::V1::Group

  API_GROUP_CATEGORY_JSON_OPTS = {
    only: %w[id name role self_signup group_limit auto_leader created_at]
  }.freeze

  def group_category_json(group_category, user, session, options = {})
    api_json(group_category, user, session, API_GROUP_CATEGORY_JSON_OPTS)
      .merge!(context_data(group_category))
      .merge!(included_data(group_category, user, session, options[:include]))
      .merge!(group_category_sis(group_category, user))
      .merge!(group_category_data(group_category, user))
  end

  private

  def group_category_data(group_category, user)
    {
      "protected" => group_category.protected?,
      "allows_multiple_memberships" => group_category.allows_multiple_memberships?,
      "is_member" => group_category.is_member?(user)
    }
  end

  def group_category_sis(group_category, user)
    hash = {}
    if group_category.root_account.grants_any_right?(user, :read_sis, :manage_sis)
      hash["sis_group_category_id"] = group_category.sis_source_id
    end
    if group_category.root_account.grants_right?(user, :manage_sis)
      hash["sis_import_id"] = group_category.sis_batch_id
    end
    hash
  end

  def included_data(group_category, user, session, includes)
    hash = {}
    if includes
      if includes.include?("progress_url") && group_category.current_progress && group_category.current_progress.pending?
        hash["progress"] = progress_json(group_category.current_progress, user, session)
      end
      if includes.include?("groups_count")
        hash["groups_count"] = group_category.groups.active.size
      end
      if includes.include?("unassigned_users_count")
        hash["unassigned_users_count"] = group_category.unassigned_users.count(:all)
      end
      if includes.include?("groups")
        hash["groups"] = group_category.groups.by_name.active.map { |group| group_json(group, user, session) }
      end
    end
    hash
  end

  def group_categories_json(group_categories, user, session, options = {})
    group_categories.map { |group_category| group_category_json(group_category, user, session, options) }
  end
end
