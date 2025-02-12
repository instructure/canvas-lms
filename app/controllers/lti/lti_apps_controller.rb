# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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
module Lti
  # @API LTI Launch Definitions
  #
  # @model Lti::LaunchDefinition
  #   {
  #     "id": "Lti::LaunchDefinition",
  #     "description": "A bare-bones representation of an LTI tool used by Canvas to launch the tool",
  #     "properties": {
  #       "definition_type": {
  #         "description": "The type of the launch definition. Always 'ContextExternalTool'",
  #         "example": "ContextExternalTool",
  #         "type": "string"
  #       },
  #       "definition_id": {
  #         "description": "The Canvas ID of the tool",
  #         "example": "123",
  #         "type": "string"
  #       },
  #       "name": {
  #         "description": "The display name of the tool for the given placement",
  #         "example": "My Tool",
  #         "type": "string"
  #       },
  #      "description": {
  #         "description": "The description of the tool for the given placement.",
  #         "example": "This is a tool that does things.",
  #         "type": "string"
  #       },
  #      "url": {
  #         "description": "The launch URL for the tool",
  #         "example": "https://www.example.com/launch",
  #         "type": "string"
  #       },
  #      "domain": {
  #         "description": "The domain of the tool",
  #         "example": "example.com",
  #         "type": "string"
  #       },
  #      "placements": {
  #         "description": "Placement-specific config for given placements",
  #         "example": { "assignment_selection": { "type": "Lti::PlacementLaunchDefinition" } },
  #         "type": "object"
  #       }
  #     }
  #   }
  #
  # @model Lti::PlacementLaunchDefinition
  #   {
  #     "id": "Lti::PlacementLaunchDefinition",
  #     "description": "A bare-bones LTI configuration for a specific placement",
  #     "properties": {
  #       "message_type": {
  #         "description": "The LTI launch message type",
  #         "example": "LtiResourceLinkRequest",
  #         "type": "string"
  #       },
  #       "url": {
  #         "description": "The launch URL for this placement",
  #         "example": "https://www.example.com/launch?placement=assignment_selection",
  #         "type": "string"
  #       },
  #       "title": {
  #         "description": "The title of the tool for this placement",
  #         "example": "My Tool (Assignment Selection)",
  #         "type": "string"
  #       }
  #     }
  #   }
  class LtiAppsController < ApplicationController
    before_action :require_context
    before_action :require_user, except: [:launch_definitions]

    def index
      if authorized_action(@context, @current_user, :read_as_admin)
        collection = app_collator.bookmarked_collection

        respond_to do |format|
          app_defs = Api.paginate(collection, self, named_context_url(@context, :api_v1_context_app_definitions_url, include_host: true))

          mc_status = setup_master_course_restrictions(app_defs.select { |o| o.is_a?(ContextExternalTool) }, @context)
          format.json { render json: app_collator.app_definitions(app_defs, master_course_status: mc_status) }
        end
      end
    end

    # @API List LTI Launch Definitions
    #
    # List all tools available in this context for the given placements, in the form of Launch Definitions.
    # Used primarily by the Canvas frontend. API users should consider using the External Tools API instead.
    # This endpoint is cached for 10 minutes!
    #
    # @argument placements[Array] The placements to return launch definitions for. If not provided, an empty list will be returned.
    # @argument only_visible[Boolean] If true, only return launch definitions that are visible to the current user. Defaults to true.
    def launch_definitions
      placements = params["placements"] || []
      if authorized_for_launch_definitions(@context, @current_user, placements)
        # only_visible requires that specific placements are requested.  If a user is not read_admin, and they request only_visible
        # without placements, an empty array will be returned.
        collection = if placements == ["global_navigation"] && !value_to_boolean(params[:only_visible])
                       # We allow global_navigation to pull all the launch_definitions, even if they are not explicitly visible to user.
                       AppLaunchCollator.bookmarked_collection(@context, placements, { current_user: @current_user, session:, only_visible: false })
                     else
                       AppLaunchCollator.bookmarked_collection(@context, placements, { current_user: @current_user, session:, only_visible: true })
                     end
        pagination_args = { max_per_page: 100 }
        respond_to do |format|
          launch_defs = GuardRail.activate(:secondary) do
            Api.paginate(
              collection,
              self,
              named_context_url(@context, :api_v1_context_launch_definitions_url, include_host: true),
              pagination_args
            )
          end
          format.json do
            cancel_cache_buster
            expires_in 10.minutes
            render json: AppLaunchCollator.launch_definitions(launch_defs, placements)
          end
        end
      end
    end

    private

    def app_collator
      @app_collator ||= AppCollator.new(@context, method(:reregistration_url_builder))
    end

    def reregistration_url_builder(context, tool_proxy_id)
      polymorphic_url([context, :tool_proxy_reregistration], tool_proxy_id:)
    end

    def authorized_for_launch_definitions(context, user, placements)
      # This is a special case to allow any user (students especially) to access the
      # launch definitions for global navigation specifically. This is requested in
      # the context of an account, not a course, so a student would normally not
      # have any account-level permissions. So instead, just ensure that the user
      # is associated with the current account (not sure how it could be otherwise?)
      return true if context.is_a?(Account) &&
                     placements == ["global_navigation"] &&
                     user_in_account?(user, context)

      authorized_action(context, user, :read)
    end

    def user_in_account?(user, account)
      return false unless user.present?

      user.associated_accounts.include? account
    end
  end
end
