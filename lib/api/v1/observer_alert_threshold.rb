#
# Copyright (C) 2018 - present Instructure, Inc.
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

module Api::V1::ObserverAlertThreshold
  include Api::V1::Json
  include ApplicationHelper

  API_ALLOWED_OUTPUT_FIELDS = {
    :only => %w(
      id
      user_observation_link_id
      alert_type
      threshold
      workflow_state
    ).freeze
  }.freeze

  def observer_alert_threshold_json(threshold, user, session, _opts = {})
    api_json(threshold, user, session, API_ALLOWED_OUTPUT_FIELDS)
  end
end