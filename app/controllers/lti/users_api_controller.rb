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
  class UsersApiController < ApplicationController
    include Lti::Ims::AccessTokenHelper
    include Api::V1::User

    skip_before_action :load_user
    before_action :authorized_lti2_tool
    before_action :user_in_context, only: :show
    before_action :tool_in_context, only: :group_index

    USER_SERVICE = 'vnd.Canvas.User'.freeze
    GROUP_INDEX_SERVICE = 'vnd.Canvas.GroupIndex'.freeze
    SERVICE_DEFINITIONS = [
      {
        id: USER_SERVICE,
        endpoint: 'api/lti/users/{user_id}',
        format: ['application/json'].freeze,
        action: ['GET'].freeze
      }.freeze,
      {
        id: GROUP_INDEX_SERVICE,
        endpoint: 'api/lti/group/{group_id}/users',
        format: ['application/json'].freeze,
        action: ['GET'].freeze
      }.freeze
    ].freeze

    USER_INCLUDES = %w(email lti_id).freeze

    def lti2_service_name
      USER_SERVICE
    end

    # @API Get a single user (lti)
    #
    # Get a single Canvas user by Canvas id or LTI id. Tool providers may only access
    # users that have been assigned an assignment associated with their tool.
    #
    # @returns User
    def show
      render json: user_json(user, user, nil, USER_INCLUDES, tool_proxy.context)
    end

    # @API Get all users in a group (lti)
    #
    # Get all Canvas users in a group. Tool providers may only access
    # groups that belong to the context the tool is installed in.
    #
    # @returns [User]
    def group_index
      users = Api.paginate(group.participating_users, self, lti_user_group_index_url)
      user_json_preloads(users)
      render json: users.map { |user| user_json(user, user, nil, USER_INCLUDES, group.context) }
    end

    private

    def user
      @_user ||= User.find_by(lti_context_id: params[:id]) || User.find(params[:id])
    end

    def group
      @_group ||= Group.find(params[:group_id])
    end

    def tool_in_context
      render_unauthorized_action unless PermissionChecker.authorized_lti2_action?(
        tool: tool_proxy,
        context: group.course
      ) && group.active?
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
