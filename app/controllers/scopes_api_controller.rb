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

# @API Scopes
# API for retrieving API scopes
#
# @model Scope
#     {
#       "id": "Scope",
#       "description": "",
#       "properties": {
#         "name": {
#           "description": "The identifier for the scope",
#           "example": "https://api.instructure.com/auth/canvas.manage_groups",
#           "type": "string"
#         },
#         "label": {
#           "description": "A human readable description of what the scope allows",
#           "example": "Manage (create / edit / delete) groups",
#           "type": "string"
#         }
#       }
#     }
#
class ScopesApiController < ApplicationController
  before_action :require_context

  # @API List scopes
  # A list of scopes that can be applied to developer keys and access tokens.
  #
  # @returns [Scope]
  def index
    if authorized_action(@context, @current_user, :manage_role_overrides)
      render :json => RoleOverride.manageable_access_token_scopes(@context)
    end
  end
end
