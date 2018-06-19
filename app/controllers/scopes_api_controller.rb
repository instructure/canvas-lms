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
#         "resource": {
#           "description": "The resource the scope is associated with",
#           "example": "courses",
#           "type": "string"
#         },
#         "verb": {
#           "description": "The HTTP verb for the scope",
#           "example": "GET",
#           "type": "string"
#         },
#         "scope": {
#           "description": "The identifier for the scope",
#           "example": "url:GET|/api/v1/courses",
#           "type": "string"
#         }
#       }
#     }
#
class ScopesApiController < ApplicationController
  before_action :require_context
  before_action :require_user
  before_action :check_feature_flag

  # @API List scopes
  # A list of scopes that can be applied to developer keys and access tokens.
  #
  # @argument group_by [String, "resource"]
  #   The attribute to group the scopes by. By default no grouping is done.
  #
  # @returns [Scope]
  def index
    if authorized_action(@context, @current_user, :manage_role_overrides)
      scopes = params[:group_by] == "resource" ? TokenScopes::GROUPED_DETAILED_SCOPES : TokenScopes::DETAILED_SCOPES
      render json: scopes
    end
  end

  private
  def check_feature_flag
    return if @context.root_account.feature_enabled?(:api_token_scoping)
    render json: [], status: :forbidden
  end
end
