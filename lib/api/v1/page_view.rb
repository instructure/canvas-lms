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

module Api::V1::PageView
  include Api::V1::Json

  API_PAGE_VIEW_JSON_OPTS = {
    :methods => ::PageView::EXPORTED_COLUMNS,
  }

  def page_views_json(page_views, current_user, session)
    page_views.map { |pv| page_view_json(pv, @current_user, session) }
  end

  def page_view_json(page_view, current_user, session)
    json_hash = api_json(page_view, current_user, session, API_PAGE_VIEW_JSON_OPTS)
    json_hash[:id] = json_hash.delete(:request_id)
    json_hash[:contributed] = false # for backwards compatibility
    json_hash[:links] = {
      :user => json_hash.delete(:user_id),
      :context => json_hash.delete(:context_id),
      :asset => json_hash.delete(:asset_id),
      :real_user => json_hash.delete(:real_user_id),
      :account => json_hash.delete(:account_id),
    }
    json_hash
  end
end
