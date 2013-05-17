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

  API_GROUP_CATEGORY_JSON_OPTS = {
      :only => %w(id name role self_signup)
  }

  def group_category_json(group_category, user, session, options = {})
    hash = api_json(group_category, user, session, API_GROUP_CATEGORY_JSON_OPTS)
    hash.merge!(context_data(group_category))
    hash
  end

end