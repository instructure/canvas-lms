# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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
  class LogService < ApplicationService
    LAUNCH_TYPES = %i[
      direct_link
      indirect_link
      content_item
      resource_selection
    ].freeze

    def initialize(tool:, context:, user:, launch_type:, placement: nil)
      raise ArgumentError, "context must be a Course, Account, or Group" unless [Course, Account, Group].include? context.class
      raise ArgumentError, "launch_type must be one of #{LAUNCH_TYPES.join(", ")}" unless LAUNCH_TYPES.include?(launch_type.to_sym)

      super()
      @tool = tool
      @context = context
      @user = user
      @launch_type = launch_type
      @placement = placement
    end

    def call
      return unless @context.root_account.feature_enabled?(:lti_log_launches)
      return unless Account.site_admin.feature_enabled?(:lti_log_launches_site_admin)

      PandataEvents.send_event(:lti_launch, log_data, for_user_id: @user&.global_id)
    end

    def log_data
      {
        tool_id: @tool.tool_id,
        tool_domain: @tool.domain,
        tool_url: @tool.url, # this could get really long
        tool_name: @tool.name,
        tool_version: @tool.lti_version,
        tool_client_id: @tool.global_developer_key_id.to_s,
        launch_type: @launch_type,
        message_type:,
        placement: @placement,
        context_id: @context.global_id.to_s,
        context_type: @context.class.name,
        user_id: @user&.global_id&.to_s,
        user_relationship:
      }
    end

    def message_type
      return @tool.extension_setting(@placement, :message_type) if @placement

      # no placement means this is a launch from a content item
      if @tool.lti_version == "1.3"
        "LtiResourceLinkRequest"
      else
        "basic-lti-launch-request"
      end
    end

    # An array showing how the user interfaces with the context.
    # Always includes any account roles the user may have.
    # When context is a Course, includes enrollments for that user.
    # When context is a Group, includes memberships for that user.
    #
    # Example: "GroupMembership,StudentEnrollment,ObserverEnrollment,AccountAdmin"
    def user_relationship
      return "" unless @user

      relationships =
        case @context
        when Group
          user_group_relationship(@context) + user_course_relationship(@context.context) + user_account_relationship(@context.context.account)
        when Course
          user_course_relationship(@context) + user_account_relationship(@context.account)
        when Account
          user_account_relationship(@context)
        end

      relationships.uniq.join(",")
    end

    private

    def user_group_relationship(group)
      group.participating_users(@user.id).map { |_| "GroupMembership" }
    end

    def user_course_relationship(course)
      course.enrollments.active.where(user: @user).pluck(:type)
    end

    def user_account_relationship(account)
      account.account_users_for(@user).map(&:role).pluck(:name)
    end
  end
end
