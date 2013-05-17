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

module Api::V1::Collaborator
  include Api::V1::Json

  def collaborator_json(collaborator, current_user, session)
    api_json(collaborator, current_user, session, :only => %w{id}).tap do |hash|
      hash['type'] = collaborator.group_id.present? ? 'group' : 'user'
      hash['name'] = collaborator.user.try(:sortable_name) ||
        collaborator.group.try(:name)
      hash['collaborator_id'] = collaborator.user.try(:id) ||
        collaborator.group.id
    end
  end
end

