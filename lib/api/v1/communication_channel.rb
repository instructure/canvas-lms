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

module Api::V1::CommunicationChannel
  include Api::V1::Json

  # Internal: The attributes returned by communication_channel_json.
  JSON_OPTS = {
    :only => %w{ id path path_type position user_id } }

  # Public: Given a communication channel, return it in an API-friendly format.
  #
  # channel - The communication channel to turn into a hash.
  # current_user - The requesting user.
  # session - The current session (or nil, if no session is available)
  #
  # Returns a Hash of communication channel attributes:
  #   :id
  #   :address (path)
  #   :type (path_type)
  #   :position
  #   :user_id
  def communication_channel_json(channel, current_user, session)
    api_json(channel, current_user, session, JSON_OPTS).tap do |json|
      # Rename attributes for mass-consumption
      json[:address] = json.delete(:path)
      json[:type]    = json.delete(:path_type)
    end
  end
end
