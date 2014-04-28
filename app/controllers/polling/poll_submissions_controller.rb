#
# Copyright (C) 2014 Instructure, Inc.
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

# @API PollSubmissions
# @beta
# Manage submissions for polls
#
# @model PollSubmission
#    {
#       "id": "PollSubmission",
#       "required": ["id", "poll", "user"],
#       "properties": {
#         "id": {
#           "description": "The unique identifier for the account role/user assignment.",
#           "example": 1023,
#           "type": "integer"
#         },
#         "poll": {
#           "description": "The poll this submission is for.  See the Polls API for details.",
#           "$ref": "Poll"
#         },
#         "user": {
#           "description": "The user that submitted the poll submission. See the Users API for details.",
#           "$ref": "User"
#         },
#         "status": {
#           "description": "The status of the account role/user assignment.",
#           "type": "string",
#           "example": "deleted"
#         }
#       }
#    }

module Polling
  class PollSubmissionsController < ApplicationController
    before_filter :require_user

    def show
    end

    def create
    end
  end
end

