#
# Copyright (C) 2012 - present Instructure, Inc.
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
  #   :workflow_state
  #   :created_at
  def communication_channel_json(channel, current_user, session)
    only = %w{ id path_type position workflow_state user_id created_at }
    # Uses the method "path_description" instead of the field "path" because
    # when path_type is twitter or yo, it goes and fetches tha user's account
    # name with a fallback display value.
    methods = %w{ path_description }

    # If the user is super special, show them this channel's bounce details
    if channel.grants_right?(current_user, :read_bounce_details)
      only += [
        'last_bounce_at',
        'last_transient_bounce_at',
        'last_suppression_bounce_at'
      ]
      methods += [
        'last_bounce_summary',
        'last_transient_bounce_summary'
      ]
    end

    api_json(channel, current_user, session, only: only, methods: methods).tap do |json|
      # Rename attributes for mass-consumption
      json[:address] = json.delete(:path_description)
      json[:type] = json.delete(:path_type)
    end
  end

end
