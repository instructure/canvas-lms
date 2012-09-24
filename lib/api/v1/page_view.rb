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

  def page_view_json(page_view, current_user, session)
    api_json(page_view, current_user, session, API_PAGE_VIEW_JSON_OPTS)
  end
end
