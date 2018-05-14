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
#         "resource_name": {
#           "description": "The localized resource name",
#           "example": "Courses",
#           "type": "string"
#         },
#         "controller": {
#           "description": "The controller the scope is associated to",
#           "example": "courses",
#           "type": "string"
#         },
#         "action": {
#           "description": "The controller action the scope is associated to",
#           "example": "index",
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
  # @argument group_by [String, "resource_name"]
  #   The attribute to group the scopes by. By default no grouping is done.
  #
  # @returns [Scope]
  def index
    if authorized_action(@context, @current_user, :manage_role_overrides)
      named_scopes = TokenScopes::DETAILED_SCOPES.each_with_object([]) do |frozen_scope, arr|
        scope = frozen_scope.dup
        api_scope_mapper_class = ApiScopeMapperLoader.load
        scope[:resource] ||= api_scope_mapper_class.lookup_resource(scope[:controller], scope[:action])
        scope[:resource_name] = api_scope_mapper_class.name_for_resource(scope[:resource])
        arr << scope if scope[:resource_name]
        scope
      end
      named_scopes = Canvas::ICU.collate_by(named_scopes) {|s| s[:resource_name]}
      scopes = params[:group_by] == "resource_name" ? named_scopes.group_by {|route| route[:resource_name]} : named_scopes
      render json: scopes
    end
  end

  private

  def check_feature_flag
    return if @context.try(:site_admin?) && Setting.get(Setting::SITE_ADMIN_ACCESS_TO_NEW_DEV_KEY_FEATURES, nil).present?
    return if @context.root_account.feature_enabled?(:api_token_scoping)
    render json: [], status: :forbidden
  end
end
