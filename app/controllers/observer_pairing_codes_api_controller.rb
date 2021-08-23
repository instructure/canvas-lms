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
#

require 'atom'

# @API User Observees
#
# @model PairingCode
#     {
#       "id": "PairingCode",
#       "description": "A code used for linking a user to a student to observe them.",
#       "properties": {
#         "user_id": {
#           "description": "The ID of the user.",
#           "example": 2,
#           "type": "integer",
#           "format": "int64"
#         },
#         "code": {
#           "description": "The actual code to be sent to other APIs",
#           "example": "abc123",
#           "type": "string"
#         },
#         "expires_at": {
#           "description": "When the code expires",
#           "example": "2012-05-30T17:45:25Z",
#           "type": "string",
#           "format": "date-time"
#         },
#         "workflow_state": {
#           "description": "The current status of the code",
#           "example": "active",
#           "type": "string"
#         }
#       }
#     }
class ObserverPairingCodesApiController < ApplicationController

  before_action :require_user

  # @API Create observer pairing code
  #
  # If the user is a student, will generate a code to be used with self registration
  # or observees APIs to link another user to this student.
  #
  # @returns PairingCode
  def create
    user = api_find(User, params[:user_id])
    return render_unauthorized_action unless user.has_student_enrollment?

    if authorized_action(user, @current_user, :generate_observer_pairing_code)
      code = user.generate_observer_pairing_code
      render json: presenter(code)
    end
  end

  def presenter(code)
    {
      user_id: code.user_id,
      code: code.code,
      expires_at: code.expires_at,
      workflow_state: code.workflow_state
    }
  end
end
