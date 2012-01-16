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

  def group_json(group, user, session, options = {})
    include = options[:include] || []
    hash = api_json(group, user, session, :only => %w{id name})
    if include.include?('users')
      hash['users'] = group.users.map{ |u| user_json(u, user, session) }
    end
    hash
  end
end

