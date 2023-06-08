# frozen_string_literal: true

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
    include Lti::IMS::AccessTokenHelper
    include Api::V1::User

    skip_before_action :load_user
    before_action :authorized_lti2_tool
    before_action :user_in_context, only: :show
    before_action :tool_in_context, only: :group_index

    USER_SERVICE = "vnd.Canvas.User"
    GROUP_INDEX_SERVICE = "vnd.Canvas.GroupIndex"
    SERVICE_DEFINITIONS = [
      {
        id: USER_SERVICE,
        endpoint: "api/lti/users/{user_id}",
        format: ["application/json"].freeze,
        action: ["GET"].freeze
      }.freeze,
      {
        id: GROUP_INDEX_SERVICE,
        endpoint: "api/lti/groups/{group_id}/users",
        format: ["application/json"].freeze,
        action: ["GET"].freeze
      }.freeze
    ].freeze

    USER_INCLUDES = %w[email lti_id].freeze

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
      render json: user_json(user, user, nil, [], tool_proxy.context, tool_includes: USER_INCLUDES)
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
      UserPastLtiId.manual_preload_past_lti_ids(users, group.context)
      render json: users.map { |user| user_json(user, user, nil, [], group.context, tool_includes: USER_INCLUDES) }
    end

    private

    def user
      @_user ||= User.joins(:past_lti_ids).where(user_past_lti_ids: { user_lti_context_id: params[:id] }).take ||
                 User.active.find_by(lti_context_id: params[:id]) ||
                 User.active.find(params[:id])
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
      tool_proxy_assignments = AssignmentConfigurationToolLookup.by_tool_proxy_scope(tool_proxy).select(:assignment_id)
      user_visible_to_proxy = Enrollment.joins(course: :assignments)
                                        .where(user:, assignments: { id: tool_proxy_assignments })
                                        .merge(Course.active).merge(Assignment.active)
                                        .exists?
      render_unauthorized_action unless user_visible_to_proxy
    end
  end
end
