# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

module Lti::Concerns
  module SessionlessLaunches
    class UnauthorizedClient < StandardError
    end

    # Directs the sessionless launch generate request
    # to the canvas domain the tool belongs to.
    #
    # This helps in scenarios when the tool is being
    # launched from shard A but is installed in shard B
    # (cross-shard enrollments, for example).
    def direct_to_tool_account(tool, context)
      return if tool.blank?
      return if params[:redirect].present? # Prevent potential endless loops
      return unless context.is_a? Course # The only known valid cross-shard scenario

      # This will only work if an access token is being used
      return if @access_token.blank?

      url = api_v1_course_external_tool_sessionless_launch_url(
        context,
        params: sessionless_launch_params.merge(redirect: true),
        host: host_for_tool(tool)
      )

      Canvas.timeout_protection("cross-shard LTI launch", raise_on_timeout: true) do
        HTTParty.get url, headers: { "Authorization" => request.headers["Authorization"] }
      end
    end

    def host_for_tool(tool)
      # We can keep the same host if the tool is from
      # the same shard as the current request
      #
      # Otherwise, we need the host to match the host of the
      # tool's account's primary domain.
      host = request.host if tool.shard == Shard.current
      host ||= tool.root_account.try(:primary_domain)&.host_with_test(request.host_with_port)
      host || request.host
    end

    def sessionless_launch_params
      params.permit(
        :assignment_id,
        :course_id,
        :id,
        :launch_type,
        :module_item_id,
        :url
      )
    end

    # Generates a token that will initialize a new session when
    # sent in a Canvas request
    def generate_session_token
      # only allow from API, and not from files domain, as /login/session_token does
      raise UnauthorizedClient unless @access_token
      raise UnauthorizedClient if HostUrl.is_file_host?(request.host_with_port)

      # Only allow unscoped keys access to a session token
      raise UnauthorizedClient if @access_token.developer_key.require_scopes?

      login_pseudonym = @real_current_pseudonym || @current_pseudonym

      SessionToken.new(
        login_pseudonym.global_id,
        current_user_id: @real_current_user ? @current_user.global_id : nil,
        used_remember_me_token: true
      ).to_s
    end

    # Generates a URL a client may use to launch a tool without
    # an initial session in Canvas.
    #
    # Currently we support three launch types: Assignment, Module Item,
    # and a General Course/Account launch.
    #
    # For an explanation of each type please review the documentation
    # for the generate_sessionless_launch endpoint.
    def sessionless_launch_link(options, context, tool, session_token)
      if options[:assignment].present?
        assignment = options[:assignment]
        assignment.migrate_to_1_3_if_needed!(tool)
        assignment_launch_link(assignment, session_token)
      elsif options[:module_item].present?
        module_item_link(options[:module_item], session_token)
      elsif (options[:launch_url] || options[:lookup_id]) && options[:id].blank? && options[:launch_type].blank?
        retrieve_launch_link(context, session_token, options[:launch_url], options[:lookup_id])
      else
        course_or_account_launch_link(context, tool, session_token, options[:launch_url], options[:launch_type])
      end
    end

    def module_item_link(module_item, session_token)
      course_context_modules_item_redirect_url(
        course_id: module_item.context.id,
        id: module_item.id,
        display: :borderless,
        session_token:
      )
    end

    def assignment_launch_link(assignment, session_token)
      course_assignment_url(
        course_id: assignment.course.id,
        id: assignment.id,
        display: :borderless,
        session_token:
      )
    end

    def retrieve_launch_link(context, session_token, launch_url, lookup_id)
      context_type = context.class.to_s.downcase

      send(
        :"retrieve_#{context_type}_external_tools_url",
        context.id,
        url: launch_url,
        display: :borderless,
        session_token:,
        resource_link_lookup_uuid: lookup_id
      )
    end

    def course_or_account_launch_link(context, tool, session_token, launch_url, launch_type)
      context_type = context.class.to_s.downcase
      send(
        :"#{context_type}_external_tool_url",
        context.id,
        id: tool.id,
        display: :borderless,
        session_token:,
        launch_url:,
        launch_type:
      )
    end
  end
end
