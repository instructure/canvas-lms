#
# Copyright (C) 2017 - present Instructure, Inc.
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


module Lti
# @API Plagiarism Detection Platform Users
# **Plagiarism Detection Platform API for Users (Must use <a href="jwt_access_tokens.html">JWT access tokens</a> with this API).**
#
# @model User
#     {
#       "id": "User",
#       "description": "A Canvas user",
#       "properties": {
#         "id": {
#           "example": 4,
#           "type": "integer"
#         },
#         "name": {
#           "example": "John Smith",
#           "type": "string"
#         },
#         "sortable_name": {
#           "example": "Smith, John",
#           "type": "string"
#         },
#         "email": {
#           "example": "john@test.com",
#           "type": "string"
#         },
#         "lti_id": {
#           "example": "86157096483e6b3a50bfedc6bac902c0b20a824f",
#           "type": "string"
#         }
#       }
#     }
  class UsersApiController < ApplicationController
    include Lti::Ims::AccessTokenHelper
    include Api::V1::User

    skip_before_action :load_user
    before_action :authorized_lti2_tool, :user_in_context

    USER_SERVICE = 'vnd.Canvas.User'.freeze
    SERVICE_DEFINITIONS = [
      {
        id: USER_SERVICE,
        endpoint: 'api/lti/users/{user_id}',
        format: ['application/json'].freeze,
        action: ['GET'].freeze
      }.freeze
    ].freeze

    def lti2_service_name
      USER_SERVICE
    end

    # @API Get a single user
    #
    # Get a single Canvas user by Canvas id or LTI id. Tool providers may only access
    # users that have been assigned an assignment associated with their tool.
    def show
      render json: user_json(user, user, nil, %w(email lti_id), tool_proxy.context)
    end

    private

    def user
      @_user ||= User.find_by(lti_context_id: params[:id]) || User.find(params[:id])
    end

    def user_in_context
      user_assignments = user.enrollments.active.preload(:course).map(&:course).map do |c|
        Assignments::ScopedToUser.new(c, user).scope
      end.flatten
      tool_assignments = AssignmentConfigurationToolLookup.by_tool_proxy(tool_proxy)
      render_unauthorized_action if (tool_assignments & user_assignments).blank?
    end
  end
end