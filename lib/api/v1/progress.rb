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

module Api::V1::Progress
  include Api::V1::Json

  def progress_json(progress, current_user, session, opts={})
    api_json(progress, current_user, session, :only => %w(id context_id context_type user_id tag completion workflow_state created_at updated_at message)).tap do |hash|
      hash['url'] = polymorphic_url([:api_v1, progress])
    end
  end
end

