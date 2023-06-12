# frozen_string_literal: true

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

module LtiAdvantage::Messages
  class LoginRequest
    include ActiveModel::Model

    REQUIRED_PARAMETERS = %i[
      iss
      login_hint
      target_link_uri
    ].freeze

    OPTIONAL_PARAMETERS = %i[
      lti_message_hint
      canvas_region
      canvas_environment
      client_id
      lti_storage_target
      deployment_id
    ].freeze

    attr_accessor(*(REQUIRED_PARAMETERS + OPTIONAL_PARAMETERS))

    validates_presence_of(*REQUIRED_PARAMETERS)
  end
end
