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

    def initialize(tool:, context:, user:, session_id:, launch_type:, launch_url: nil, placement: nil, message_type: nil, lti2: false)
      raise ArgumentError, "context must be a Course, Account, or Group" unless [Course, Account, Group].include? context.class
      raise ArgumentError, "launch_type must be one of #{LAUNCH_TYPES.join(", ")}" unless LAUNCH_TYPES.include?(launch_type.to_sym)

      super()
      @tool = tool
      @context = context
      @user = user
      @launch_type = launch_type
      @launch_url = launch_url
      @placement = placement
      @session_id = session_id
      @message_type = message_type
      @lti2 = lti2
    end

    def call
      return unless log_lti_launches?

      if @lti2
        log_lti2
      else
        PandataEvents.send_event(:lti_launch, log_data, for_user_id: @user&.global_id)
      end
    end

    private

    def log_lti2
      return unless @context.root_account.feature_enabled?(:lti_v2_turnitin_usage_log)
      return unless turnitin_url?

      PandataEvents.send_event(:lti_launch, log_lti2_data, for_user_id: @user&.global_id)
    end

    def log_lti_launches?
      Setting.get("log_lti_launches", "true") == "true"
    end

    def turnitin_url?
      uri = URI.parse(@launch_url)
      uri.host.end_with?("turnitin.com")
    end

    def log_data
      {
        unified_tool_id: @tool.unified_tool_id,
        tool_id: @tool.id.to_s,
        tool_provided_id: @tool.tool_id,
        tool_domain: @tool.domain,
        tool_url: @tool.url, # this could get really long
        tool_name: @tool.name,
        tool_version: @tool.lti_version,
        tool_client_id: @tool.global_developer_key_id.to_s,
        account_id: account_for_context.id.to_s,
        root_account_uuid: @context.root_account.uuid,
        launch_type: @launch_type,
        launch_url: @launch_url,
        message_type:,
        placement: @placement,
        context_id: @context.id.to_s,
        context_type: @context.class.name,
        user_id: Shard.relative_id_for(@user&.id, @user&.shard, Shard.current).to_s,
        session_id: @session_id,
        shard_id: Shard.current.id.to_s,
        user_relationship:
      }
    end

    def log_lti2_data
      {
        unified_tool_id: turnitin_utid,
        tool_id: nil,
        tool_provided_id: nil,
        tool_domain: nil,
        tool_url: nil,
        tool_name: "Turnitin",
        tool_version: "2.0",
        tool_client_id: nil,
        account_id: account_for_context.id.to_s,
        message_type: "basic-lti_launch-request",
        root_account_uuid: @context.root_account.uuid,
        launch_type: @launch_type,
        launch_url: @launch_url,
        placement: nil,
        context_id: @context.id.to_s,
        context_type: @context.class.name,
        user_id: Shard.relative_id_for(@user&.id, @user&.shard, Shard.current).to_s,
        session_id: @session_id,
        shard_id: Shard.current.id.to_s,
        user_relationship:
      }
    end

    def message_type
      return @message_type if @message_type
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
          if @context.context.is_a?(Course)
            user_group_relationship(@context) + user_course_relationship(@context.context) + user_account_relationship(@context.context.account)
          else
            user_group_relationship(@context) + user_account_relationship(@context.context)
          end
        when Course
          user_course_relationship(@context) + user_account_relationship(@context.account)
        when Account
          user_account_relationship(@context)
        end

      relationships.uniq.join(",")
    end

    def user_group_relationship(group)
      group.participating_users(@user.id).map { |_| "GroupMembership" }
    end

    def user_course_relationship(course)
      course.enrollments.active.where(user: @user).pluck(:type)
    end

    def user_account_relationship(account)
      account.account_users_for(@user).map(&:role).pluck(:name)
    end

    def account_for_context
      case @context
      when Account
        @context
      when Course
        @context.account
      when Group
        if @context.context.is_a?(Course)
          @context.context.account
        else
          @context.context
        end
      end
    end

    def turnitin_utid
      Setting.get("lti_v2_turnitin_utid", "")
    end
  end
end
