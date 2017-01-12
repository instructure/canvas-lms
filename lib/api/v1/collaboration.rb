#
# Copyright (C) 2016 Instructure, Inc.
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

module Api::V1::Collaboration
  include Api::V1::Json

  def collaboration_json(collaboration, current_user, session)
    attribute_whitelist = %w{id collaboration_type document_id user_id context_id context_type url created_at updated_at description title type update_url}
    api_json(collaboration, current_user, session, :only => attribute_whitelist).tap do |hash|
      hash['user_name'] = collaboration.user[:name]
      hash['update_url'] = collaboration.update_url
    end
  end
end
