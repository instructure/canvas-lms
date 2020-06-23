#
# Copyright (C) 2019 - present Instructure, Inc.
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

module Api::V1::HistoryEntry
  include Api::V1::Json

  def history_entry_json(page_view, asset_user_access, user, session)
    entry = api_json(asset_user_access, user, session, only: %w(asset_code context_type context_id))
    entry['visited_at'] = page_view.created_at
    entry['visited_url'] = page_view.url
    entry['interaction_seconds'] = page_view.interaction_seconds
    entry['asset_icon'] = asset_user_access.icon
    entry['asset_name'] = asset_user_access.readable_name(include_group_name: false)
    entry['context_name'] = asset_user_access.context.nickname_for(user)
    entry
  end
end
