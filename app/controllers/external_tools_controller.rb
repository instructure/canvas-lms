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

# @API External Tools
# API for accessing and configuring external tools on accounts and courses.
# "External tools" are IMS LTI links: http://www.imsglobal.org/developers/LTI/index.cfm.
#
# For a definitive list of all supported placements for external tools and more information
# on configuring them,
# see the <a href="file.placements_overview.html">Placements Documentation</a>.
#
# @model ContextExternalTool
#     {
#       "id": "ContextExternalTool",
#       "description": "An external tool configured for a specific context",
#       "properties": {
#         "id": {
#           "description": "The unique identifier for the external tool",
#           "example": 37,
#           "type": "integer"
#         },
#         "name": {
#           "description": "The name of the external tool",
#           "example": "Basic 1.1 tool",
#           "type": "string"
#         },
#         "description": {
#           "description": "A description of the external tool",
#           "example": "Basic LTI 1.1 Tool",
#           "type": "string"
#         },
#         "url": {
#           "description": "The launch URL for the external tool",
#           "example": "http://example.com/launch",
#           "type": "string"
#         },
#         "domain": {
#           "description": "The domain to match links against. Note that this doesn't contain the protocol.",
#           "example": "example.com",
#           "type": "string"
#         },
#         "consumer_key": {
#           "description": "The consumer key used by the tool (The associated shared secret is not returned)",
#           "example": "key",
#           "type": "string"
#         },
#         "created_at": {
#           "description": "Timestamp of the tool's creation",
#           "example": "2037-07-21T13:29:31Z",
#           "type": "string"
#         },
#         "updated_at": {
#           "description": "Timestamp of the tool's last update",
#           "example": "2037-07-28T19:38:31Z",
#           "type": "string"
#         },
#         "privacy_level": {
#           "description": "How much user information to send to the external tool",
#           "example": "anonymous",
#           "type": "string",
#           "enum": ["anonymous", "name_only", "email_only", "public"]
#         },
#         "custom_fields": {
#           "description": "Custom fields that will be sent to the tool consumer",
#           "example": {"key": "value"},
#           "type": "object"
#         },
#         "workflow_state": {
#           "description": "The current state of the external tool",
#           "example": "public",
#           "type": "string",
#           "enum": ["public", "anonymous", "deleted"]
#         },
#         "is_rce_favorite": {
#           "description": "Boolean determining whether this tool should be in a preferred location in the RCE. Only present if the tool can be an RCE favorite.",
#           "example": false,
#           "type": "boolean"
#         },
#         "is_top_nav_favorite": {
#           "description": "Boolean determining whether this tool should have a dedicated button in Top Navigation. Only present if the tool can be a top nav favorite.",
#           "example": false,
#           "type": "boolean"
#         },
#         "selection_width": {
#           "description": "The pixel width of the iFrame that the tool will be rendered in",
#           "example": 500,
#           "type": "integer"
#         },
#         "selection_height": {
#           "description": "The pixel height of the iFrame that the tool will be rendered in",
#           "example": 500,
#           "type": "integer"
#         },
#         "icon_url": {
#           "description": "The URL for the tool icon",
#           "example": "https://example.com/icon.png",
#           "type": "string"
#         },
#         "not_selectable": {
#           "description": "Whether the tool is not selectable from assignment and modules",
#           "example": false,
#           "type": "boolean"
#         },
#         "version": {
#           "description": "The LTI version of the tool",
#           "example": "1.1",
#           "type": "string",
#           "enum": ["1.1", "1.3"]
#         },
#         "unified_tool_id": {
#           "description": "The unique identifier for the tool in LearnPlatform",
#           "example": null,
#           "type": "string"
#         },
#         "developer_key_id": {
#           "description": "The developer key id associated with this tool. Only present for LTI 1.3 tools.",
#           "example": 123,
#           "type": "integer"
#         },
#         "lti_registration_id": {
#           "description": "The LTI registration id associated with this tool. Only present for LTI 1.3 tools.",
#           "example": 456,
#           "type": "integer"
#         },
#         "deployment_id": {
#           "description": "The unique identifier for the deployment of the tool",
#           "example": "37:b82229c6e10bcb87beb1f1b287faee560ddc3109",
#           "type": "string"
#         },
#         "allow_membership_service_access": {
#           "description": "Whether the tool can access the membership service. Only present if the feature is enabled.",
#           "example": false,
#           "type": "boolean"
#         },
#         "prefer_sis_email": {
#           "description": "Whether to send the SIS email address in launches",
#           "example": false,
#           "type": "boolean"
#         },
#         "estimated_duration": {
#           "description": "The estimated duration for completing this tool. Only present for horizon courses when the tool has an estimated duration.",
#           "$ref": "EstimatedDuration"
#         },
#         "account_navigation": {
#           "description": "Configuration for account navigation placement. Null if not configured for this placement.",
#           "example": {"type": "ContextExternalToolPlacement"},
#           "$ref": "ContextExternalToolPlacement"
#         },
#         "analytics_hub": {
#           "description": "Configuration for analytics hub placement. Null if not configured for this placement.",
#           "example": {"type": "ContextExternalToolPlacement"},
#           "$ref": "ContextExternalToolPlacement"
#         },
#         "assignment_edit": {
#           "description": "Configuration for assignment edit placement. Null if not configured for this placement.",
#           "example": {"type": "ContextExternalToolPlacement"},
#           "$ref": "ContextExternalToolPlacement"
#         },
#         "assignment_group_menu": {
#           "description": "Configuration for assignment group menu placement. Null if not configured for this placement.",
#           "example": {"type": "ContextExternalToolPlacement"},
#           "$ref": "ContextExternalToolPlacement"
#         },
#         "assignment_index_menu": {
#           "description": "Configuration for assignment index menu placement. Null if not configured for this placement.",
#           "example": {"type": "ContextExternalToolPlacement"},
#           "$ref": "ContextExternalToolPlacement"
#         },
#         "assignment_menu": {
#           "description": "Configuration for assignment menu placement. Null if not configured for this placement.",
#           "example": {"type": "ContextExternalToolPlacement"},
#           "$ref": "ContextExternalToolPlacement"
#         },
#         "assignment_selection": {
#           "description": "Configuration for assignment selection placement. Null if not configured for this placement.",
#           "example": {"type": "ContextExternalToolPlacement"},
#           "$ref": "ContextExternalToolPlacement"
#         },
#         "assignment_view": {
#           "description": "Configuration for assignment view placement. Null if not configured for this placement.",
#           "example": {"type": "ContextExternalToolPlacement"},
#           "$ref": "ContextExternalToolPlacement"
#         },
#         "collaboration": {
#           "description": "Configuration for collaboration placement. Null if not configured for this placement.",
#           "example": {"type": "ContextExternalToolPlacement"},
#           "$ref": "ContextExternalToolPlacement"
#         },
#         "conference_selection": {
#           "description": "Configuration for conference selection placement. Null if not configured for this placement.",
#           "example": {"type": "ContextExternalToolPlacement"},
#           "$ref": "ContextExternalToolPlacement"
#         },
#         "course_assignments_menu": {
#           "description": "Configuration for course assignments menu placement. Null if not configured for this placement.",
#           "example": {"type": "ContextExternalToolPlacement"},
#           "$ref": "ContextExternalToolPlacement"
#         },
#         "course_home_sub_navigation": {
#           "description": "Configuration for course home sub navigation placement. Null if not configured for this placement.",
#           "example": {"type": "ContextExternalToolPlacement"},
#           "$ref": "ContextExternalToolPlacement"
#         },
#         "course_navigation": {
#           "description": "Configuration for course navigation placement. Null if not configured for this placement.",
#           "example": {"type": "ContextExternalToolPlacement"},
#           "$ref": "ContextExternalToolPlacement"
#         },
#         "course_settings_sub_navigation": {
#           "description": "Configuration for course settings sub navigation placement. Null if not configured for this placement.",
#           "example": {"type": "ContextExternalToolPlacement"},
#           "$ref": "ContextExternalToolPlacement"
#         },
#         "discussion_topic_index_menu": {
#           "description": "Configuration for discussion topic index menu placement. Null if not configured for this placement.",
#           "example": {"type": "ContextExternalToolPlacement"},
#           "$ref": "ContextExternalToolPlacement"
#         },
#         "discussion_topic_menu": {
#           "description": "Configuration for discussion topic menu placement. Null if not configured for this placement.",
#           "example": {"type": "ContextExternalToolPlacement"},
#           "$ref": "ContextExternalToolPlacement"
#         },
#         "editor_button": {
#           "description": "Configuration for editor button placement. Null if not configured for this placement.",
#           "example": {"type": "ContextExternalToolPlacement"},
#           "$ref": "ContextExternalToolPlacement"
#         },
#         "file_index_menu": {
#           "description": "Configuration for file index menu placement. Null if not configured for this placement.",
#           "example": {"type": "ContextExternalToolPlacement"},
#           "$ref": "ContextExternalToolPlacement"
#         },
#         "file_menu": {
#           "description": "Configuration for file menu placement. Null if not configured for this placement.",
#           "example": {"type": "ContextExternalToolPlacement"},
#           "$ref": "ContextExternalToolPlacement"
#         },
#         "global_navigation": {
#           "description": "Configuration for global navigation placement. Null if not configured for this placement.",
#           "example": {"type": "ContextExternalToolPlacement"},
#           "$ref": "ContextExternalToolPlacement"
#         },
#         "homework_submission": {
#           "description": "Configuration for homework submission placement. Null if not configured for this placement.",
#           "example": {"type": "ContextExternalToolPlacement"},
#           "$ref": "ContextExternalToolPlacement"
#         },
#         "link_selection": {
#           "description": "Configuration for link selection placement. Null if not configured for this placement.",
#           "example": {"type": "ContextExternalToolPlacement"},
#           "$ref": "ContextExternalToolPlacement"
#         },
#         "migration_selection": {
#           "description": "Configuration for migration selection placement. Null if not configured for this placement.",
#           "example": {"type": "ContextExternalToolPlacement"},
#           "$ref": "ContextExternalToolPlacement"
#         },
#         "module_group_menu": {
#           "description": "Configuration for module group menu placement. Null if not configured for this placement.",
#           "example": {"type": "ContextExternalToolPlacement"},
#           "$ref": "ContextExternalToolPlacement"
#         },
#         "module_index_menu": {
#           "description": "Configuration for module index menu placement. Null if not configured for this placement.",
#           "example": {"type": "ContextExternalToolPlacement"},
#           "$ref": "ContextExternalToolPlacement"
#         },
#         "module_index_menu_modal": {
#           "description": "Configuration for module index menu modal placement. Null if not configured for this placement.",
#           "example": {"type": "ContextExternalToolPlacement"},
#           "$ref": "ContextExternalToolPlacement"
#         },
#         "module_menu_modal": {
#           "description": "Configuration for module menu modal placement. Null if not configured for this placement.",
#           "example": {"type": "ContextExternalToolPlacement"},
#           "$ref": "ContextExternalToolPlacement"
#         },
#         "module_menu": {
#           "description": "Configuration for module menu placement. Null if not configured for this placement.",
#           "example": {"type": "ContextExternalToolPlacement"},
#           "$ref": "ContextExternalToolPlacement"
#         },
#         "page_index_menu": {
#           "description": "Configuration for page index menu placement. Null if not configured for this placement.",
#           "example": {"type": "ContextExternalToolPlacement"},
#           "$ref": "ContextExternalToolPlacement"
#         },
#         "page_menu": {
#           "description": "Configuration for page menu placement. Null if not configured for this placement.",
#           "example": {"type": "ContextExternalToolPlacement"},
#           "$ref": "ContextExternalToolPlacement"
#         },
#         "post_grades": {
#           "description": "Configuration for post grades (sync grades) placement. Null if not configured for this placement.",
#           "example": {"type": "ContextExternalToolPlacement"},
#           "$ref": "ContextExternalToolPlacement"
#         },
#         "quiz_index_menu": {
#           "description": "Configuration for quiz index menu placement. Null if not configured for this placement.",
#           "example": {"type": "ContextExternalToolPlacement"},
#           "$ref": "ContextExternalToolPlacement"
#         },
#         "quiz_menu": {
#           "description": "Configuration for quiz menu placement. Null if not configured for this placement.",
#           "example": {"type": "ContextExternalToolPlacement"},
#           "$ref": "ContextExternalToolPlacement"
#         },
#         "resource_selection": {
#           "description": "Configuration for resource selection placement. Null if not configured for this placement. This placement is deprecated.",
#           "example": {"type": "ContextExternalToolPlacement"},
#           "$ref": "ContextExternalToolPlacement"
#         },
#         "similarity_detection": {
#           "description": "Configuration for similarity detection placement. Null if not configured for this placement.",
#           "example": {"type": "ContextExternalToolPlacement"},
#           "$ref": "ContextExternalToolPlacement"
#         },
#         "student_context_card": {
#           "description": "Configuration for student context card placement. Null if not configured for this placement.",
#           "example": {"type": "ContextExternalToolPlacement"},
#           "$ref": "ContextExternalToolPlacement"
#         },
#         "submission_type_selection": {
#           "description": "Configuration for submission type selection placement. Null if not configured for this placement.",
#           "example": {"type": "ContextExternalToolPlacement"},
#           "$ref": "ContextExternalToolPlacement"
#         },
#         "tool_configuration": {
#           "description": "Configuration for tool configuration placement. Null if not configured for this placement.",
#           "example": {"type": "ContextExternalToolPlacement"},
#           "$ref": "ContextExternalToolPlacement"
#         },
#         "top_navigation": {
#           "description": "Configuration for top navigation placement. Null if not configured for this placement.",
#           "example": {"type": "ContextExternalToolPlacement"},
#           "$ref": "ContextExternalToolPlacement"
#         },
#         "user_navigation": {
#           "description": "Configuration for user navigation placement. Null if not configured for this placement.",
#           "example": {"type": "ContextExternalToolPlacement"},
#           "$ref": "ContextExternalToolPlacement"
#         },
#         "wiki_index_menu": {
#           "description": "Configuration for wiki index menu placement. Null if not configured for this placement.",
#           "example": {"type": "ContextExternalToolPlacement"},
#           "$ref": "ContextExternalToolPlacement"
#         },
#         "wiki_page_menu": {
#           "description": "Configuration for wiki page menu placement. Null if not configured for this placement.",
#           "example": {"type": "ContextExternalToolPlacement"},
#           "$ref": "ContextExternalToolPlacement"
#         },
#         "ActivityAssetProcessor": {
#           "description": "Configuration for activity asset processor placement. Null if not configured for this placement.",
#           "example": {"type": "ContextExternalToolPlacement"},
#           "$ref": "ContextExternalToolPlacement"
#         },
#         "ActivityAssetProcessorContribution": {
#           "description": "Configuration for activity asset processor contribution placement. Null if not configured for this placement.",
#           "example": {"type": "ContextExternalToolPlacement"},
#           "$ref": "ContextExternalToolPlacement"
#         },
#         "message_settings": {
#           "description": "Configuration for placementless message types (currently only LtiEulaRequest).",
#           "type": "array",
#           "items": {
#             "$ref": "ContextExternalToolMessageSettings"
#           },
#           "example": [
#             {
#               "type": "LtiEulaRequest",
#               "enabled": true,
#               "target_link_uri": "https://example.com/eula",
#               "custom_fields": {"agreement_version": "2.1"}
#             }
#           ]
#         }
#       }
#     }
#
# @model ContextExternalToolPlacement
#     {
#       "id": "ContextExternalToolPlacement",
#       "description": "Configuration for a specific placement of an external tool. If null, no configuration is present.",
#       "properties": {
#         "enabled": {
#           "description": "Whether this placement is enabled",
#           "example": true,
#           "type": "boolean"
#         },
#         "url": {
#           "description": "The launch URL for this specific placement. Overrides the tool's default URL. For LTI 1.1 tools only.",
#           "example": "http://example.com/launch?placement=course_navigation",
#           "type": "string"
#         },
#         "target_link_uri": {
#           "description": "The launch URL for this specific placement. Overrides the tool's default target_link_uri. For LTI 1.3 tools only.",
#           "example": "http://example.com/launch?placement=course_navigation",
#           "type": "string"
#         },
#         "text": {
#           "description": "The text/label to display for this placement. Overridable by 'labels' in placement configuration.",
#           "example": "Course Navigation Tool",
#           "type": "string"
#         },
#         "label": {
#           "description": "The localized label for this placement. This is the resolved text after applying internationalization.",
#           "example": "Course Navigation Tool",
#           "type": "string"
#         },
#         "labels": {
#           "description": "Internationalization labels for this placement. Keys are locale codes, values are localized text.",
#           "example": {"en": "Course Navigation", "es": "Navegación del Curso"},
#           "type": "object"
#         },
#         "message_type": {
#           "description": "The LTI message type for this placement. Not all placements support all message types.",
#           "example": "LtiResourceLinkRequest",
#           "type": "string",
#           "enum": ["basic_lti_request", "ContentItemSelectionRequest", "LtiResourceLinkRequest", "LtiDeepLinkingRequest"]
#         },
#         "selection_width": {
#           "description": "The width of the iframe or popup for this placement",
#           "example": 500,
#           "type": "integer"
#         },
#         "selection_height": {
#           "description": "The height of the iframe or popup for this placement",
#           "example": 500,
#           "type": "integer"
#         },
#         "launch_width": {
#           "description": "The width of the launch window. Not standard everywhere yet.",
#           "example": 800,
#           "type": "integer"
#         },
#         "launch_height": {
#           "description": "The height of the launch window. Not standard everywhere yet.",
#           "example": 600,
#           "type": "integer"
#         },
#         "icon_url": {
#           "description": "The URL of the icon for this placement",
#           "example": "https://example.com/icon.png",
#           "type": "string"
#         },
#         "canvas_icon_class": {
#           "description": "The Canvas icon class to use for this placement instead of an icon URL",
#           "example": "icon-lti",
#           "type": "string"
#         },
#         "allow_fullscreen": {
#           "description": "Whether to allow fullscreen mode for this placement (top_navigation placement only)",
#           "example": true,
#           "type": "boolean"
#         },
#         "custom_fields": {
#           "description": "Custom fields to be sent with this placement's launch. Merged with tool-level custom fields.",
#           "example": {"placement_id": "course_nav", "special_param": "value"},
#           "type": "object"
#         },
#         "visibility": {
#           "description": "Controls who can see this placement",
#           "example": "members",
#           "type": "string",
#           "enum": ["public", "members", "admins"]
#         },
#         "required_permissions": {
#           "description": "Comma-separated list of Canvas permissions required to launch from this placement. The user must have all permissions in order to launch the tool.",
#           "example": "manage_course_content_edit,manage_course_content_read",
#           "type": "string"
#         },
#         "default": {
#           "description": "Default display state for navigation placements. Only applies to account_navigation and course_navigation placements.",
#           "example": "disabled",
#           "type": "string",
#           "enum": ["enabled", "disabled"]
#         },
#         "display_type": {
#           "description": "The layout type to use when launching the tool. For global_navigation and analytics_hub, defaults to 'full_width'.",
#           "example": "full_width_in_context",
#           "type": "string",
#           "enum": ["default", "full_width", "full_width_in_context", "full_width_with_nav", "in_nav_context", "borderless"]
#         },
#         "windowTarget": {
#           "description": "When set to '_blank', opens placement in a new tab. Only '_blank' is supported.",
#           "example": "_blank",
#           "type": "string",
#           "enum": ["_blank"]
#         },
#         "accept_media_types": {
#           "description": "Comma-separated list of media types that the tool can accept. Only valid for file_menu placement.",
#           "example": "image/*,video/*",
#           "type": "string"
#         },
#         "use_tray": {
#           "description": "If true, the tool will be launched in the tray. Only used by the editor_button placement.",
#           "example": true,
#           "type": "boolean"
#         },
#         "icon_svg_path_64": {
#           "description": "An SVG path to use instead of an icon_url. Only valid for global_navigation placement.",
#           "example": "M100,37L70.1,10.5v176H37...",
#           "type": "string"
#         },
#         "root_account_only": {
#           "description": "Whether this placement should only be available at the root account level. Only applies to account_navigation placement.",
#           "example": false,
#           "type": "boolean"
#         },
#         "description": {
#           "description": "A description of this placement. Only valid for submission_type_selection placement. Maximum length of 255 characters.",
#           "example": "Submit your work using our external tool",
#           "type": "string"
#         },
#         "require_resource_selection": {
#           "description": "Whether resource selection is required for this placement. Only valid for submission_type_selection placement.",
#           "example": true,
#           "type": "boolean"
#         },
#         "prefer_sis_email": {
#           "description": "If true, the tool will send the SIS email in the lis_person_contact_email_primary launch property. LTI 1.1 only.",
#           "example": false,
#           "type": "boolean"
#         },
#         "oauth_compliant": {
#           "description": "If true, query parameters from the launch URL will not be copied to the POST body. LTI 1.1 only.",
#           "example": true,
#           "type": "boolean"
#         }
#       }
#     }
#
# @model ContextExternalToolMessageSettings
#     {
#       "id": "ContextExternalToolMessageSettings",
#       "description": "Configuration for a placementless message type (message type that doesn't belong to a specific placement)",
#       "properties": {
#         "type": {
#           "description": "The message type identifier (e.g., 'LtiEulaRequest')",
#           "example": "LtiEulaRequest",
#           "type": "string"
#         },
#         "enabled": {
#           "description": "Whether this message type is enabled",
#           "example": true,
#           "type": "boolean"
#         },
#         "target_link_uri": {
#           "description": "The target URI for launching this message type",
#           "example": "https://example.com/eula",
#           "type": "string"
#         },
#         "custom_fields": {
#           "description": "Custom fields specific to this message type.",
#           "example": {"key": "value"},
#           "type": "object"
#         }
#       }
#     }
#
# @model EstimatedDuration
#     {
#       "id": "EstimatedDuration",
#       "description": "An estimated duration for completing a learning activity",
#       "properties": {
#         "id": {
#           "description": "The unique identifier for the estimated duration",
#           "example": 123,
#           "type": "integer"
#         },
#         "duration": {
#           "description": "The estimated duration in ISO 8601 format",
#           "example": "PT30M",
#           "type": "string"
#         },
#         "created_at": {
#           "description": "Timestamp of when the estimated duration was created",
#           "example": "2024-01-01T00:00:00Z",
#           "type": "string"
#         },
#         "updated_at": {
#           "description": "Timestamp of when the estimated duration was last updated",
#           "example": "2024-01-01T00:00:00Z",
#           "type": "string"
#         }
#       }
#     }
class ExternalToolsController < ApplicationController
  include NewQuizzesHelper

  class InvalidSettingsError < StandardError; end

  before_action :require_context, except: [:all_visible_nav_tools]
  before_action :require_tool_create_rights, only: [:create, :create_tool_from_tool_config]
  before_action :require_tool_configuration, only: [:create_tool_from_tool_config]
  before_action :require_access_to_context, except: %i[index sessionless_launch all_visible_nav_tools]
  before_action :require_user, only: [:generate_sessionless_launch]
  before_action :get_context, only: %i[retrieve show resource_selection]
  before_action :parse_context_codes, only: [:all_visible_nav_tools]
  before_action :set_extra_csp_frame_ancestor!, only: %i[retrieve resource_selection]
  skip_before_action :verify_authenticity_token, only: :resource_selection

  include Api::V1::ExternalTools
  include Lti::RedisMessageClient
  include Lti::Concerns::SessionlessLaunches
  include Lti::Concerns::ParentFrame
  include K5Mode

  WHITELISTED_QUERY_PARAMS = [
    :platform
  ].freeze

  # @API List external tools
  # Returns the paginated list of external tools for the current context.
  # See the get request docs for a single tool for a list of properties on an external tool.
  #
  # @argument search_term [String]
  #   The partial name of the tools to match and return.
  #
  # @argument selectable [Boolean]
  #   If true, then only tools that are meant to be selectable are returned.
  #
  # @argument include_parents [Boolean]
  #   If true, then include tools installed in all accounts above the current context
  #
  # @argument placement [String]
  #   The placement type to filter by.
  #
  #   Return all tools at the current context as well as all tools from the parent, and filter the tools list to only those with a placement of 'editor_button'
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/courses/<course_id>/external_tools?include_parents=true&placement=editor_button' \
  #        -H "Authorization: Bearer <token>"
  #
  # @returns [ContextExternalTool]
  #
  def index
    if authorized_action(@context, @current_user, :read)
      @tools = if Canvas::Plugin.value_to_boolean(params[:include_parents])
                 Lti::ContextToolFinder.all_tools_for(@context, current_user: (params[:include_personal] ? @current_user : nil))
               else
                 base_scope = Lti::ContextToolFinder.only_for(@context).active

                 if @context.root_account.feature_enabled?(:lti_registrations_next)
                   available_deployment_ids = Lti::ContextControl.deployment_ids_for_context(@context)
                   base_scope.where(id: available_deployment_ids).or(base_scope.lti_1_1)
                 else
                   base_scope
                 end
               end
      @tools = ContextExternalTool.search_by_attribute(@tools, :name, params[:search_term])

      @context.shard.activate do
        @tools = @tools.placements(params[:placement]) if params[:placement]
      end
      if Canvas::Plugin.value_to_boolean(params[:selectable])
        @tools = @tools.select(&:selectable)
      end
      respond_to do |format|
        @tools = Api.paginate(@tools, self, tool_pagination_url)
        format.json { render json: external_tools_json(@tools, @context, @current_user, session) }
      end
    end
  end

  def finished
    @headers = false
  end

  TimingMeta = Struct.new(:tags)

  def retrieve
    Utils::InstStatsdUtils::Timing.track "lti.retrieve.request_time" do |timing_meta|
      tool, url = find_tool_and_url(
        resource_link_lookup_uuid,
        params[:url],
        @context,
        params[:client_id],
        params[:resource_link_id],
        prefer_1_1: !!params[:prefer_1_1]
      )
      @tool = tool
      placement = placement_from_params
      add_crumb(@tool.name)
      @lti_launch = lti_launch(
        tool: @tool,
        selection_type: placement,
        launch_url: url,
        content_item_id: params[:content_item_id],
        secure_params: params[:secure_params]
      )
      unless @lti_launch
        timing_meta.tags = { error: true, lti_version: tool&.lti_version }.compact
        return
      end

      launch_type = placement.present? ? :indirect_link : :content_item
      Lti::LogService.new(tool:, context: @context, user: @current_user, session_id: session[:session_id], placement:, launch_type:, launch_url: url).call

      display_override = params["borderless"] ? "borderless" : params[:display]
      render Lti::AppUtil.display_template(@tool.display_type(placement), display_override:)
      timing_meta.tags = { lti_version: tool&.lti_version }.compact
    rescue InvalidSettingsError => e
      flash[:error] = e.message
      redirect_to named_context_url(@context, :context_url)
      timing_meta.tags = { error: true, lti_version: tool&.lti_version }.compact
    end
  end

  # Finds a tool for a given resource_link_id or url in a context
  # Prefers the resource_link_id, but defaults to the provided_url,
  #   if the resource_link does not provide a url
  def find_tool_and_url(lookup_id, provided_url, context, client_id, resource_link_id = nil, prefer_1_1: false)
    resource_link = if resource_link_id
                      Lti::ResourceLink.where(
                        resource_link_uuid: resource_link_id,
                        context:
                      ).active.take
                    else
                      Lti::ResourceLink.where(
                        lookup_uuid: lookup_id,
                        context:
                      ).active.take
                    end
    if resource_link.nil? || resource_link.url.nil?
      # If the resource_link doesn't have a url, then use the provided url to look up the tool
      tool = Lti::ToolFinder.from_url(provided_url, context, preferred_client_id: client_id, prefer_1_1:)
      unless tool
        invalid_settings_error
      end
      [tool, provided_url]
    elsif resource_link.url
      tool = resource_link.current_external_tool context
      unless tool
        invalid_settings_error
      end
      [tool, resource_link.url]
    else
      invalid_settings_error
    end
  end

  def invalid_settings_error
    raise InvalidSettingsError, t("#application.errors.invalid_external_tool", "Couldn't find valid settings for this link")
  end

  # @API Get a sessionless launch url for an external tool.
  # Returns a sessionless launch url for an external tool.
  # Prefers the resource_link_lookup_uuid, but defaults to the other passed
  #   parameters id, url, and launch_type
  #
  # NOTE: Either the resource_link_lookup_uuid, id, or url must be provided unless launch_type is assessment or module_item.
  #
  # @argument id [String]
  #   The external id of the tool to launch.
  #
  # @argument url [String]
  #   The LTI launch url for the external tool.
  #
  # @argument assignment_id [String]
  #   The assignment id for an assignment launch. Required if launch_type is set to "assessment".
  #
  # @argument module_item_id [String]
  #   The assignment id for a module item launch. Required if launch_type is set to "module_item".
  #
  # @argument launch_type [String, "assessment"|"module_item"]
  #   The type of launch to perform on the external tool. Placement names (eg. "course_navigation")
  #   can also be specified to use the custom launch url for that placement; if done, the tool id
  #   must be provided.
  #
  # @argument resource_link_lookup_uuid [String]
  #   The identifier to lookup a resource link.
  #
  # @response_field id The id for the external tool to be launched.
  # @response_field name The name of the external tool to be launched.
  # @response_field url The url to load to launch the external tool for the user.
  #
  # @example_request
  #
  #   Finds the tool by id and returns a sessionless launch url
  #   curl 'https://<canvas>/api/v1/courses/<course_id>/external_tools/sessionless_launch' \
  #        -H "Authorization: Bearer <token>" \
  #        -F 'id=<external_tool_id>'
  #
  # @example_request
  #
  #   Finds the tool by launch url and returns a sessionless launch url
  #   curl 'https://<canvas>/api/v1/courses/<course_id>/external_tools/sessionless_launch' \
  #        -H "Authorization: Bearer <token>" \
  #        -F 'url=<lti launch url>'
  #
  # @example_request
  #
  #   Finds the tool associated with a specific assignment and returns a sessionless launch url
  #   curl 'https://<canvas>/api/v1/courses/<course_id>/external_tools/sessionless_launch' \
  #        -H "Authorization: Bearer <token>" \
  #        -F 'launch_type=assessment' \
  #        -F 'assignment_id=<assignment_id>'
  #
  # @example_request
  #
  #   Finds the tool associated with a specific module item and returns a sessionless launch url
  #   curl 'https://<canvas>/api/v1/courses/<course_id>/external_tools/sessionless_launch' \
  #        -H "Authorization: Bearer <token>" \
  #        -F 'launch_type=module_item' \
  #        -F 'module_item_id=<module_item_id>'
  #
  # @example_request
  #
  #   Finds the tool by id and returns a sessionless launch url for a specific placement
  #   curl 'https://<canvas>/api/v1/courses/<course_id>/external_tools/sessionless_launch' \
  #        -H "Authorization: Bearer <token>" \
  #        -F 'id=<external_tool_id>' \
  #        -F 'launch_type=<placement_name>'

  def generate_sessionless_launch
    # prerequisite checks
    unless Canvas.redis_enabled?
      @context.errors.add(:redis, "Redis is not enabled, but is required for sessionless LTI launch")
      return render json: @context.errors, status: :service_unavailable
    end

    if params[:resource_link_lookup_uuid]
      generate_common_sessionless_launch(options: {
                                           resource_link_lookup_uuid: params[:resource_link_lookup_uuid]
                                         })
    else
      launch_type = params[:launch_type]
      case launch_type
      when "module_item"
        generate_module_item_sessionless_launch
      when "assessment"
        generate_assignment_sessionless_launch
      else
        generate_common_sessionless_launch(options: { launch_url: params[:url] })
      end
    end
  end

  def sessionless_launch
    Utils::InstStatsdUtils::Timing.track "lti.sessionless_launch.request_time" do |timing_meta|
      if Canvas.redis_enabled?
        launch_settings = fetch_and_delete_launch(
          @context,
          params[:verifier],
          prefix: Lti::RedisMessageClient::SESSIONLESS_LAUNCH_PREFIX
        )
      end
      unless launch_settings
        render plain: t(:cannot_locate_launch_request, "Cannot locate launch request, please try again."), status: :not_found
        timing_meta.tags = { error: true }
        return
      end

      launch_settings = JSON.parse(launch_settings)
      @lti_launch = Lti::Launch.new
      @lti_launch.params = launch_settings["tool_settings"]
      @lti_launch.link_text =  launch_settings["tool_name"]
      @lti_launch.analytics_id = launch_settings["analytics_id"]

      tool = Lti::ToolFinder.find_by(id: launch_settings.dig("metadata", "tool_id")) ||
             Lti::ToolFinder.from_url(launch_settings["launch_url"], @context)
      if tool
        # Use domain-specific URL for environment overrides
        launch_url_with_overrides = tool.url_with_environment_overrides(launch_settings["launch_url"])
        @lti_launch.resource_url = launch_url_with_overrides

        placement = launch_settings.dig("metadata", "placement")
        launch_type = launch_settings.dig("metadata", "launch_type")&.to_sym
        Lti::LogService.new(tool:, context: @context, user: @current_user, session_id: session[:session_id], placement:, launch_type:, launch_url: launch_url_with_overrides).call
        log_asset_access(tool, "external_tools", "external_tools", overwrite: false)
      else
        @lti_launch.resource_url = launch_settings["launch_url"]
      end

      render Lti::AppUtil.display_template("borderless")
      timing_meta.tags = { lti_version: tool&.lti_version }.compact
    end
  end

  # @API Get a single external tool
  # Returns the specified external tool.
  #
  # @returns ContextExternalTool
  def show
    Utils::InstStatsdUtils::Timing.track "lti.show.request_time" do |timing_meta|
      if api_request?
        tool = Lti::ContextToolFinder.only_for(@context).active.find(params[:external_tool_id])
        render json: external_tool_json(tool, @context, @current_user, session)
        timing_meta.tags = { lti_version: tool.lti_version }
      else
        placement = placement_from_params || "#{@context.class.url_context_class.to_s.downcase}_navigation"
        unless find_tool(params[:id], placement)
          timing_meta.tags = { error: true }
          return
        end

        add_crumb(@tool.label_for(placement, I18n.locale))

        # Check if this is an Item Banks launch with native experience enabled
        if item_banks_launch?(@tool, placement) && new_quizzes_native_experience_enabled?
          return render_native_item_banks(placement)
        end

        @return_url = named_context_url(@context, :context_external_content_success_url, "external_tool_redirect", { include_host: true })
        @redirect_return = true

        success_url = tool_return_success_url(placement)
        cancel_url = tool_return_cancel_url(placement) || success_url
        js_env(redirect_return_success_url: success_url,
               redirect_return_cancel_url: cancel_url)
        js_env(course_id: @context.id) if @context.is_a?(Course)

        set_active_tab @tool.asset_string
        @show_embedded_chat = false if @tool.tool_id == "chat"

        launch_url = params[:launch_url] if params[:launch_url] && @tool.matches_host?(params[:launch_url])
        @lti_launch = lti_launch(tool: @tool, selection_type: placement, launch_url:)
        unless @lti_launch
          timing_meta.tags = { error: true }
          return
        end

        # Some LTI apps have tutorial trays. Provide some details to the client to know what tray, if any, to show
        js_env(LTI_LAUNCH_RESOURCE_URL: @lti_launch.resource_url)
        set_tutorial_js_env

        Lti::LogService.new(tool: @tool, context: @context, user: @current_user, session_id: session[:session_id], placement:, launch_type: :direct_link, launch_url: @tool.url_with_environment_overrides(launch_url || @tool.url)).call

        render Lti::AppUtil.display_template(@tool.display_type(placement), display_override: params[:display])
        timing_meta.tags = { lti_version: @tool&.lti_version }.compact
      end
    end
  end

  def migration_info
    # Define tool to be the external tool associated with the external tool id from the route
    tool = ContextExternalTool.find(params[:external_tool_id])

    # Instance variable for the migration status -- this will be used for conditional rendering
    migration_running = tool.migrating?

    unless migration_running
      return render json: { migration_running: }
    end

    migration_progress = tool.progresses.where.not(workflow_state: "completed").first

    total_items = migration_progress.results[:total_batches]

    tool_id = migration_progress.results[:tool_id]
    completed_items = total_items - Delayed::Job.where(strand: "ContextExternalTool#migrate_content_to_1_3/#{tool_id}").count

    render json: { migration_running:, total_items:, completed_items: }
  end

  def tool_return_success_url(selection_type = nil)
    case @context
    when Course
      case selection_type
      when "course_settings_sub_navigation"
        course_settings_url(@context)
      else
        course_url(@context)
      end
    when Account
      case selection_type
      when "global_navigation"
        dashboard_url
      else
        account_url(@context)
      end
    else
      dashboard_url
    end
  end

  def tool_return_cancel_url(selection_type)
    case @context
    when Course
      if selection_type == "course_home_sub_navigation"
        course_url(@context)
      end
    else
      nil
    end
  end

  def resource_selection
    Utils::InstStatsdUtils::Timing.track "lti.resource_selection.request_time" do |timing_meta|
      placement = params[:placement] || params[:launch_type]
      selection_type = placement || "resource_selection"
      selection_type = "editor_button" if params[:editor]
      selection_type = "homework_submission" if params[:homework]

      @headers = false

      unless find_tool(params[:external_tool_id], selection_type)
        timing_meta.tags = { error: true }
        return
      end

      @return_url =
        if @tool&.use_1_3?
          deep_linking_cancel_url(include_host: true, placement:)
        else
          named_context_url(@context, :context_external_content_success_url, "external_tool_dialog", include_host: true)
        end

      @lti_launch = lti_launch(tool: @tool, selection_type:, launch_token: params[:launch_token], secure_params: params[:secure_params])
      unless @lti_launch
        timing_meta.tags = { error: true, lti_version: @tool&.lti_version }.compact
        return
      end

      Lti::LogService.new(tool: @tool, context: @context, user: @current_user, session_id: session[:session_id], placement: selection_type, launch_type: :resource_selection).call

      render Lti::AppUtil.display_template("borderless")
      timing_meta.tags = { lti_version: @tool&.lti_version }.compact
    end
  end

  def find_tool(id, selection_type)
    return unless selection_type == "editor_button" || verified_user_check

    if selection_type.nil? || Lti::ResourcePlacement::PLACEMENTS.include?(selection_type.to_sym)
      @tool = Lti::ToolFinder.from_id(id, @context, placement: selection_type)
    end

    unless @tool
      flash[:error] = t "#application.errors.invalid_external_tool_id", "Couldn't find valid settings for this tool"
      redirect_to named_context_url(@context, :context_url)
    end

    @tool
  end
  protected :find_tool

  def lti_launch(tool:, selection_type: nil, launch_url: nil, content_item_id: nil, secure_params: nil, launch_token: nil, post_live_event: true)
    link_params = { custom: {}, ext: {} }
    if secure_params.present?
      jwt_body = Canvas::Security.decode_jwt(secure_params)
      link_params[:ext][:lti_assignment_id] = jwt_body[:lti_assignment_id] if jwt_body[:lti_assignment_id]
    end
    opts = { launch_url:, link_params:, launch_token:, context_module_id: params[:context_module_id], parent_frame_context: params[:parent_frame_context] }
    @return_url ||= url_for(@context)
    message_type = tool.extension_setting(selection_type, "message_type") if selection_type
    log_asset_access(@tool, "external_tools", "external_tools") if post_live_event

    @tool_form_id = random_lti_tool_form_id
    js_env(LTI_TOOL_FORM_ID: @tool_form_id)

    case message_type
    when "ContentItemSelectionResponse", "ContentItemSelection"
      # ContentItemSelectionResponse is deprecated, use ContentItemSelection instead
      content_item_selection(tool, selection_type, message_type, opts)
    when "ContentItemSelectionRequest"
      opts[:content_item_id] = content_item_id if content_item_id
      content_item_selection_request(tool, selection_type, opts)
    else
      opts[:content_item_id] = content_item_id if content_item_id
      basic_lti_launch_request(tool, selection_type, opts)
    end
  rescue Lti::Errors::UnauthorizedError => e
    Canvas::Errors.capture_exception(:lti_launch, e, :info)
    render_unauthorized_action
    nil
  rescue Lti::Errors::UnsupportedExportTypeError,
         Lti::Errors::InvalidLaunchUrlError,
         Lti::Errors::InvalidMediaTypeError,
         Lti::Errors::UnsupportedPlacement => e
    Canvas::Errors.capture_exception(:lti_launch, e, :info)
    respond_to do |format|
      err = t("There was an error generating the tool launch")
      format.html do
        flash[:error] = err
        redirect_to named_context_url(@context, :context_url)
      end
      format.json { render json: { error: err } }
    end
    nil
  end
  protected :lti_launch

  # As `resource_link_lookup_id` was renamed to `resource_link_lookup_uuid` we
  # have to support both names because, there are cases like RCE editor, that a
  # resource link was previously-created and the generated links couldn't stop
  # working.
  def resource_link_lookup_uuid
    params[:resource_link_lookup_id] || params[:resource_link_lookup_uuid]
  end
  protected :resource_link_lookup_uuid

  def resource_link_id
    params[:resource_link_id]
  end

  # Get resource link from `resource_link_lookup_id` or `resource_link_lookup_uuid`
  # query param, and ensure the tool matches the resource link.
  # Used for link-level custom params, and to
  # determine resource_link_id to send to tool.
  def lookup_resource_link(tool)
    return nil if resource_link_lookup_uuid.nil? && resource_link_id.nil?

    resource_link = if resource_link_id
                      Lti::ResourceLink.where(
                        resource_link_uuid: resource_link_id,
                        context: @context,
                        root_account_id: tool.root_account_id
                      ).active.take
                    else
                      Lti::ResourceLink.where(
                        lookup_uuid: resource_link_lookup_uuid,
                        context: @context,
                        root_account_id: tool.root_account_id
                      ).active.take
                    end
    if resource_link.nil?
      raise InvalidSettingsError, t(
        "Couldn't find valid settings for this link: Resource link not found"
      )
    end

    # Verify the resource link was intended for the domain it's being
    # launched from
    if params[:url] && !resource_link&.current_external_tool(@context)
                                     &.matches_host?(params[:url])
      nil
    else
      resource_link
    end
  end

  def assignment_from_assignment_id(lti_assignment_id: nil)
    if params[:assignment_id].present?
      assignment = api_find(@context.assignments.active, params[:assignment_id])
    elsif lti_assignment_id.present?
      assignment = @context.assignments.active.find_by(lti_context_id: lti_assignment_id)
    end
    return nil unless assignment

    raise Lti::Errors::UnauthorizedError unless assignment.grants_right?(@current_user, :read)

    assignment
  end

  # This handles non-content item 1.1 launches, and 1.3 launches including deep linking requests.
  # LtiAdvantageAdapter#generate_lti_params (called via
  # adapter.generate_post_payload) determines whether or not an LTI 1.3 launch
  # is a deep linking request
  def basic_lti_launch_request(tool, selection_type = nil, opts = {})
    lti_launch = tool.settings["post_only"] ? Lti::Launch.new(post_only: true) : Lti::Launch.new
    default_opts = {
      resource_type: selection_type,
      selected_html: params[:selection],
      domain: HostUrl.context_host(@domain_root_account, request.host)
    }

    opts = default_opts.merge(opts)
    opts[:launch_url] = tool.url_with_environment_overrides(opts[:launch_url])

    assignment = assignment_from_assignment_id(lti_assignment_id: opts.dig(:link_params, :ext, :lti_assignment_id))

    if assignment.present? && @current_user.present?
      assignment = AssignmentOverrideApplicator.assignment_overridden_for(assignment, @current_user)
    end

    if assignment.present? && ((@current_user && assignment.quiz_lti?) || assignment.root_account.feature_enabled?(:lti_resource_link_id_speedgrader_launches_reference_assignment))
      # Set assignment LTI launch parameters for this code path (e.g. launches
      # from SpeedGrader)
      opts[:link_code] = @tool.opaque_identifier_for(assignment.external_tool_tag)
      opts[:overrides] ||= {}
      opts[:overrides]["resource_link_title"] = assignment.title
    end

    # This is only for 1.3: editing collaborations for 1.1 goes thru content_item_selection_request()
    if selection_type == "collaboration"
      collaboration = opts[:content_item_id].presence&.then { ExternalToolCollaboration.find it }
      collaboration = nil unless collaboration&.update_url == params[:url]
    end

    expander = variable_expander(
      assignment:,
      tool:,
      launch: lti_launch,
      post_message_token: opts[:launch_token],
      secure_params: params[:secure_params],
      placement: opts[:resource_type],
      launch_url: opts[:launch_url],
      collaboration:,
      resource_link: lookup_resource_link(tool)
    )

    adapter = if tool.use_1_3?
                a = Lti::LtiAdvantageAdapter.new(
                  tool:,
                  user: @current_user,
                  context: @context,
                  return_url: @return_url,
                  expander:,
                  include_storage_target: !in_lti_mobile_webview?,
                  opts: opts.merge(
                    resource_link: lookup_resource_link(tool)
                  )
                )

                # Prevent attempting OIDC login flow with the target link uri
                opts.delete(:launch_url)
                a
              else
                Lti::LtiOutboundAdapter.new(tool, @current_user, @context).prepare_tool_launch(
                  @return_url,
                  expander,
                  opts
                )
              end

    lti_launch.params = generate_lti_launch_params(
      selection_type:,
      adapter:,
      assignment:,
      tool:,
      student_id: params[:student_id]
    )

    lti_launch.resource_url = opts[:launch_url] || adapter.launch_url
    lti_launch.link_text = selection_type ? tool.label_for(selection_type.to_sym, I18n.locale) : tool.default_label
    lti_launch.analytics_id = tool.tool_id

    lti_launch
  end
  protected :basic_lti_launch_request

  def generate_lti_launch_params(
    selection_type:,
    adapter:,
    tool:,
    assignment:,
    student_id:
  )
    if selection_type == "homework_submission" && assignment && !tool.use_1_3?
      adapter.generate_post_payload_for_homework_submission(assignment)
    elsif selection_type == "student_context_card" && student_id
      student = api_find(User, student_id)
      can_launch = tool.visible_with_permission_check?(selection_type, @current_user, @context, session) &&
                   @context.user_has_been_student?(student)
      raise Lti::Errors::UnauthorizedError unless can_launch

      adapter.generate_post_payload_for_student_context_card(student:)
    elsif tool.extension_setting(selection_type, "required_permissions")
      can_launch = tool.visible_with_permission_check?(selection_type, @current_user, @context, session)
      raise Lti::Errors::UnauthorizedError unless can_launch

      adapter.generate_post_payload
    elsif selection_type == "assignment_selection" && assignment&.external_tool_tag&.content_id == tool.id &&
          !tool.use_1_3? && params[:assignment_id].present?
      # Special case mostly for New Quizzes' benefit to make certain
      # assignment_selection launches have more assignment context. Should not
      # be used for LTI 1.3 as generate_post_payload_for_assignment is for
      # resource link requests only and DeepLinkingRequest doesn't support
      # resource_link claim. See efa31c0bfb1d
      adapter.generate_post_payload_for_assignment(
        assignment,
        lti_grade_passback_api_url(tool),
        blti_legacy_grade_passback_api_url(tool),
        lti_turnitin_outcomes_placement_url(tool.id)
      )
    else
      adapter.generate_post_payload
    end
  end
  protected :generate_lti_launch_params

  def content_item_selection(tool, placement, message_type, opts = {})
    media_types = params.select do |param|
      Lti::ContentItemResponse::MEDIA_TYPES.include?(param.to_sym)
    end
    content_item_response = Lti::ContentItemResponse.new(
      @context,
      self,
      @current_user,
      media_types.to_unsafe_h,
      params["export_type"]
    )
    launch_url = tool.launch_url(extension_type: placement, preferred_launch_url: opts[:launch_url])
    params = Lti::ContentItemSelectionRequest.default_lti_params(@context, @domain_root_account, @current_user)
                                             .merge({
                                                      # required params
                                                      lti_message_type: message_type,
                                                      lti_version: "LTI-1p0",
                                                      resource_link_id: Lti::V1p1::Asset.opaque_identifier_for(@context),
                                                      content_items: content_item_response.to_json(lti_message_type: message_type),
                                                      launch_presentation_return_url: @return_url,
                                                      context_title: @context.name,
                                                      tool_consumer_instance_name: @domain_root_account.name,
                                                      tool_consumer_instance_contact_email: HostUrl.outgoing_email_address,
                                                    })
                                             .merge(variable_expander(tool:, attachment: content_item_response.file, launch_url:)
      .expand_variables!(tool.set_custom_fields(placement)))

    lti_launch = @tool.settings["post_only"] ? Lti::Launch.new(post_only: true) : Lti::Launch.new
    lti_launch.resource_url = launch_url
    lti_launch.params = Lti::Security.signed_post_params(
      params,
      lti_launch.resource_url,
      tool.consumer_key,
      tool.shared_secret,
      @context.root_account.feature_enabled?(:disable_lti_post_only) || tool.extension_setting(:oauth_compliant)
    )
    lti_launch.link_text = tool.label_for(placement.to_sym)
    lti_launch.analytics_id = tool.tool_id

    lti_launch
  end
  protected :content_item_selection

  # Do an official content-item request as specified: http://www.imsglobal.org/LTI/services/ltiCIv1p0pd/ltiCIv1p0pd.html
  def content_item_selection_request(tool, placement, opts = {})
    selection_request = Lti::ContentItemSelectionRequest.new(context: @context,
                                                             domain_root_account: @domain_root_account,
                                                             user: @current_user,
                                                             base_url: request.base_url,
                                                             tool:,
                                                             secure_params: params[:secure_params])

    assignment = assignment_from_assignment_id

    opts = {
      post_only: @tool.settings["post_only"].present?,
      launch_url: tool.launch_url(extension_type: placement, preferred_launch_url: opts[:launch_url]),
      content_item_id: opts[:content_item_id],
      assignment:,
      parent_frame_context: opts[:parent_frame_context]
    }

    collaboration = opts[:content_item_id].present? ? ExternalToolCollaboration.find(opts[:content_item_id]) : nil

    base_expander = variable_expander(
      tool:,
      collaboration:,
      launch_url: opts[:launch_url]
    )

    expander = Lti::PrivacyLevelExpander.new(placement, base_expander)

    selection_request.generate_lti_launch(
      placement:,
      expanded_variables: expander.expanded_variables!(tool.set_custom_fields(placement)),
      opts:
    )
  end
  protected :content_item_selection_request

  # @API Create an external tool
  # Create an external tool in the specified course/account.
  # The created tool will be returned, see the "show" endpoint for an example.
  # If a client ID is supplied canvas will attempt to create a context external
  # tool using the LTI 1.3 standard.
  #
  # @argument client_id [Required, String]
  #   The client id is attached to the developer key.
  #   If supplied all other parameters are unnecessary and will be ignored
  #
  # @argument name [Required, String]
  #   The name of the tool
  #
  # @argument privacy_level [Required, String, "anonymous"|"name_only"|"email_only"|"public"]
  #   How much user information to send to the external tool.
  #
  # @argument consumer_key [Required, String]
  #   The consumer key for the external tool
  #
  # @argument shared_secret [Required, String]
  #   The shared secret with the external tool
  #
  # @argument description [String]
  #   A description of the tool
  #
  # @argument url [String]
  #   The url to match links against. Either "url" or "domain" should be set,
  #   not both.
  #
  # @argument domain [String]
  #   The domain to match links against. Either "url" or "domain" should be
  #   set, not both.
  #
  # @argument icon_url [String]
  #   The url of the icon to show for this tool
  #
  # @argument text [String]
  #   The default text to show for this tool
  #
  # @argument custom_fields[field_name] [String]
  #   Custom fields that will be sent to the tool consumer; can be used
  #   multiple times
  #
  # @argument is_rce_favorite [Boolean]
  #   (Deprecated in favor of {api:ExternalToolsController#mark_rce_favorite Mark tool to RCE Favorites} and
  #   {api:ExternalToolsController#unmark_rce_favorite Unmark tool from RCE Favorites})
  #   Whether this tool should appear in a preferred location in the RCE.
  #   This only applies to tools in root account contexts that have an editor
  #   button placement.
  #
  # @argument <placement_name>[<placement_configuration_key>] [variable]
  #   Set the <placement_configuration_key> value for a specific placement.
  # See the <a href="file.lti_dev_key_config.html#placements-params">Placements Documentation</a> for more information on what
  # placements are available, the possible fields, and their accepted values.
  #
  # @argument config_type [String, "by_url" | "by_xml"]
  #   Configuration can be passed in as Common Cartridge XML instead of using query
  #   parameters. If this value is "by_url" or "by_xml" then an XML
  #   configuration will be expected in either the "config_xml" or "config_url"
  #   parameter. Note that the name parameter overrides the tool name provided
  #   in the XML.
  #
  # @argument config_xml [String]
  #   XML tool configuration, as specified in the Common Cartridge XML specification. This is
  #   required if "config_type" is set to "by_xml"
  #
  # @argument config_url [String]
  #   URL where the server can retrieve an XML tool configuration, as specified
  #   in the Common Cartridge XML specification. This is required if "config_type" is set to
  #   "by_url"
  #
  # @argument not_selectable [Boolean]
  #   Default: false. If set to true, and if resource_selection is set to false,
  #   the tool won't show up in the external tool
  #   selection UI in modules and assignments
  #
  # @argument oauth_compliant [Boolean]
  #   Default: false, if set to true LTI query params will not be copied to the
  #   post body.
  #
  # @argument unified_tool_id [String]
  #   The unique identifier for the tool in LearnPlatform
  #
  # @example_request
  #
  #   This would create a tool on this course with two custom fields and a course navigation tab
  #   curl -X POST 'https://<canvas>/api/v1/courses/<course_id>/external_tools' \
  #        -H "Authorization: Bearer <token>" \
  #        -F 'name=LTI Example' \
  #        -F 'consumer_key=asdfg' \
  #        -F 'shared_secret=lkjh' \
  #        -F 'url=https://example.com/ims/lti' \
  #        -F 'privacy_level=name_only' \
  #        -F 'custom_fields[key1]=value1' \
  #        -F 'custom_fields[key2]=value2' \
  #        -F 'course_navigation[text]=Course Materials' \
  #        -F 'course_navigation[enabled]=true'
  #
  # @example_request
  #
  #   This would create a tool on the account with navigation for the user profile page
  #   curl -X POST 'https://<canvas>/api/v1/accounts/<account_id>/external_tools' \
  #        -H "Authorization: Bearer <token>" \
  #        -F 'name=LTI Example' \
  #        -F 'consumer_key=asdfg' \
  #        -F 'shared_secret=lkjh' \
  #        -F 'url=https://example.com/ims/lti' \
  #        -F 'privacy_level=name_only' \
  #        -F 'user_navigation[url]=https://example.com/ims/lti/user_endpoint' \
  #        -F 'user_navigation[text]=Something Cool'
  #        -F 'user_navigation[enabled]=true'
  #
  # @example_request
  #
  #   This would create a tool on the account with configuration pulled from an external URL
  #   curl -X POST 'https://<canvas>/api/v1/accounts/<account_id>/external_tools' \
  #        -H "Authorization: Bearer <token>" \
  #        -F 'name=LTI Example' \
  #        -F 'consumer_key=asdfg' \
  #        -F 'shared_secret=lkjh' \
  #        -F 'config_type=by_url' \
  #        -F 'config_url=https://example.com/ims/lti/tool_config.xml'
  #
  # @returns ContextExternalTool
  def create
    verify_uniqueness = params.dig(:external_tool, :verify_uniqueness).present?
    if params.key?(:client_id)
      raise ActiveRecord::RecordInvalid unless developer_key.usable_in_context?(@context)

      @tool = developer_key.lti_registration.new_external_tool(@context, verify_uniqueness:, current_user: @current_user)
    else
      external_tool_params = (params[:external_tool] || params).to_unsafe_h
      @tool = @context.context_external_tools.new
      if request.media_type == "application/x-www-form-urlencoded"
        custom_fields = Lti::AppUtil.custom_params(request.raw_post)
        external_tool_params[:custom_fields] = custom_fields if custom_fields.present?
      end
      set_tool_attributes(@tool, external_tool_params)
      @tool.check_for_duplication if verify_uniqueness
      unless @tool.errors.blank? && @tool.save
        raise Lti::ContextExternalToolErrors, @tool.errors
      end
    end
    @tool.migrate_content_to_1_3_if_needed!
    ContextExternalTool.invalidate_nav_tabs_cache(@tool, @domain_root_account)
    if api_request?
      render json: external_tool_json(@tool, @context, @current_user, session)
    else
      render json: @tool.as_json(methods: %i[readable_state custom_fields_string], include_root: false)
    end
  rescue Lti::ContextExternalToolErrors => e
    render json: e.errors, status: :bad_request
  end

  # Add an external tool and verify the provided
  # configuration url matches the associated
  # configuration url listed on the app
  # center. Besides the argument listed, all arguments
  # are identical to the "Create an external tool"
  # endpoint.
  #
  # @argument app_center_id [Required, String]
  #   ID of the external tool in the app center
  #
  # @argument config_settings [String]
  #   Stringified object of key/value pairs to be used
  #   as query string parameters on the XML configuration
  #   URL.
  #
  # @returns ContextExternalTool
  def create_tool_with_verification
    if authorized_action(@context, @current_user, :update)
      app_api = AppCenter::AppApi.new(@context)

      required_params = %i[
        consumer_key
        shared_secret
        name
        app_center_id
        context_id
        context_type
        config_settings
      ]

      # we're ok with an "unsafe" hash because we're filtering via required_params
      external_tool_params = params.to_unsafe_h.select { |k, _| required_params.include?(k.to_sym) }
      external_tool_params[:config_url] = app_api.get_app_config_url(external_tool_params[:app_center_id], external_tool_params[:config_settings])
      external_tool_params[:config_type] = "by_url"

      @tool = @context.context_external_tools.new
      set_tool_attributes(@tool, external_tool_params)
      respond_to do |format|
        if @tool.save
          ContextExternalTool.invalidate_nav_tabs_cache(@tool, @domain_root_account)
          format.json { render json: external_tool_json(@tool, @context, @current_user, session) }
        else
          format.json { render json: @tool.errors, status: :bad_request }
        end
      end
    end
  end

  # @API Edit an external tool
  # Update the specified external tool. Uses same parameters as create. Returns the updated tool.
  #
  # NOTE: Any updates made to LTI 1.3 tools with this API will be overridden if any changes are
  # made to the tool's associated LTI Registration/Developer Key configuration. In almost all cases,
  # changes should be made to the tool's associated LTI Registration configuration, not individual tools.
  #
  # @example_request
  #
  #   This would update the specified keys on this external tool
  #   curl -X PUT 'https://<canvas>/api/v1/courses/<course_id>/external_tools/<external_tool_id>' \
  #        -H "Authorization: Bearer <token>" \
  #        -F 'name=Public Example' \
  #        -F 'privacy_level=public'
  #
  # @returns ContextExternalTool
  def update
    @tool = Lti::ContextToolFinder.only_for(@context).active.find(params[:id] || params[:external_tool_id])
    if authorized_action(@tool, @current_user, :update_manually)
      external_tool_params = (params[:external_tool] || params).to_unsafe_h
      if request.media_type == "application/x-www-form-urlencoded"
        custom_fields = Lti::AppUtil.custom_params(request.raw_post)
        external_tool_params[:custom_fields] = custom_fields if custom_fields.present?
      end
      respond_to do |format|
        set_tool_attributes(@tool, external_tool_params)
        if @tool.save
          ContextExternalTool.invalidate_nav_tabs_cache(@tool, @domain_root_account)
          if api_request?
            format.json { render json: external_tool_json(@tool, @context, @current_user, session) }
          else
            format.json { render json: @tool.as_json(methods: [:readable_state, :custom_fields_string], include_root: false) }
          end
        else
          format.json { render json: @tool.errors, status: :bad_request }
        end
      end
    end
  end

  # @API Delete an external tool
  # Remove the specified external tool
  #
  # @example_request
  #
  #   This would delete the specified external tool
  #   curl -X DELETE 'https://<canvas>/api/v1/courses/<course_id>/external_tools/<external_tool_id>' \
  #        -H "Authorization: Bearer <token>"
  #
  # @returns ContextExternalTool
  #
  def destroy
    @tool = Lti::ContextToolFinder.only_for(@context).active.find(params[:id] || params[:external_tool_id])
    delete_tool(@tool)
  end

  def jwt_token
    tool = Lti::ToolFinder.from_url(params[:tool_launch_url], @context, preferred_tool_id: params[:tool_id])

    raise ActiveRecord::RecordNotFound if tool.nil?

    launch = lti_launch(tool:, post_live_event: false)
    return unless launch

    params = launch.params.reject { |p| p.starts_with?("oauth_") }
    params[:consumer_key] = tool.consumer_key
    params[:iat] = Time.zone.now.to_i

    render json: { jwt_token: Canvas::Security.create_jwt(params, nil, tool.shared_secret) }
  end

  # @API Mark tool as RCE Favorite
  # Mark the specified editor_button external tool as a favorite in the RCE editor
  # for courses in the given account and its subaccounts (if the subaccounts
  # haven't set their own RCE Favorites). This places the tool in a preferred location
  # in the RCE. Cannot mark more than 2 tools as RCE Favorites.
  #
  # @example_request
  #
  #   curl -X POST 'https://<canvas>/api/v1/accounts/<account_id>/external_tools/rce_favorites/<id>' \
  #        -H "Authorization: Bearer <token>"
  def mark_rce_favorite
    if authorized_action(@context, @current_user, :manage_lti_edit)
      @tool = Lti::ToolFinder.from_id(params[:id], @context)
      raise ActiveRecord::RecordNotFound unless @tool
      unless @tool.can_be_rce_favorite?
        return render json: { message: "Tool does not have an editor_button placement" }, status: :bad_request
      end

      favorite_ids = @context.get_rce_favorite_tool_ids
      favorite_ids << @tool.global_id
      favorite_ids.uniq!
      if favorite_ids.length > 2
        valid_ids = Lti::ContextToolFinder.new(@context, placements: [:editor_button]).all_tools_scope_union.pluck(:id)
        valid_ids.map! { |id| Shard.global_id_for(id) }
        favorite_ids &= valid_ids # try to clear out any possibly deleted tool references first before causing a fuss
      end
      # On_by_default tools don't count towards the limit
      client_ids = ContextExternalTool.where(id: favorite_ids).select(:developer_key_id).map(&:global_developer_key_id)
      on_by_default_ids = ContextExternalTool.on_by_default_ids
      if (client_ids - on_by_default_ids).length > 2
        render json: { message: "Cannot have more than 2 favorited tools" }, status: :bad_request
      else
        @context.settings[:rce_favorite_tool_ids] = { value: favorite_ids }
        @context.save!
        render json: { rce_favorite_tool_ids: favorite_ids.map { |id| Shard.relative_id_for(id, Shard.current, Shard.current) } }
      end
    end
  end

  # @API Unmark tool as RCE Favorite
  # Unmark the specified external tool as a favorite in the RCE editor
  # for the given account. The tool will remain available but will no longer
  # appear in the preferred favorites location.
  #
  # @example_request
  #
  #   curl -X DELETE 'https://<canvas>/api/v1/accounts/<account_id>/external_tools/rce_favorites/<id>' \
  #        -H "Authorization: Bearer <token>"
  def unmark_rce_favorite
    if authorized_action(@context, @current_user, :manage_lti_edit)
      favorite_ids = @context.get_rce_favorite_tool_ids
      if favorite_ids.delete(Shard.global_id_for(params[:id]))
        @context.settings[:rce_favorite_tool_ids] = { value: favorite_ids }
        @context.save!
      end
      render json: { rce_favorite_tool_ids: favorite_ids.map { |id| Shard.relative_id_for(id, Shard.current, Shard.current) } }
    end
  end

  # @API Add tool to Top Navigation Favorites
  # Adds a dedicated button in Top Navigation for the specified tool for the given account.
  # Cannot set more than 2 top_navigation Favorites.
  #
  # @example_request
  #
  #   curl -X POST 'https://<canvas>/api/v1/accounts/<account_id>/external_tools/top_nav_favorites/<id>' \
  #        -H "Authorization: Bearer <token>"
  def add_top_nav_favorite
    if authorized_action(@context, @current_user, :manage_lti_add)
      @tool = Lti::ToolFinder.from_id(params[:id], @context)
      raise ActiveRecord::RecordNotFound unless @tool
      unless @tool.can_be_top_nav_favorite?
        return render json: { message: "Tool does not have top_navigation placement" }, status: :bad_request
      end

      favorite_ids = @context.get_top_nav_favorite_tool_ids
      favorite_ids << @tool.global_id
      favorite_ids.uniq!
      if favorite_ids.length > 2
        valid_ids = Lti::ContextToolFinder.new(@context, placements: [:top_navigation]).all_tools_scope_union.pluck(:id)
        valid_ids.map! { |id| Shard.global_id_for(id) }
        favorite_ids &= valid_ids # try to clear out any possibly deleted tool references first before causing a fuss
      end
      if favorite_ids.length > 2
        render json: { message: "Cannot have more than 2 favorited tools" }, status: :bad_request
      else
        @context.settings[:top_nav_favorite_tool_ids] = { value: favorite_ids }
        @context.save!
        render json: { top_nav_favorite_tool_ids: favorite_ids.map { |id| Shard.relative_id_for(id, Shard.current, Shard.current) } }
      end
    end
  end

  # @API Remove tool from Top Navigation Favorites
  # Removes the dedicated button in Top Navigation for the specified tool for the given account.
  #
  # @example_request
  #
  #   curl -X DELETE 'https://<canvas>/api/v1/accounts/<account_id>/external_tools/top_nav_favorites/<id>' \
  #        -H "Authorization: Bearer <token>"
  def remove_top_nav_favorite
    if authorized_action(@context, @current_user, :manage_lti_delete)
      favorite_ids = @context.get_top_nav_favorite_tool_ids
      if favorite_ids.delete(Shard.global_id_for(params[:id]))
        @context.settings[:top_nav_favorite_tool_ids] = { value: favorite_ids }
        @context.save!
      end
      render json: { top_nav_favorite_tool_ids: favorite_ids.map { |id| Shard.relative_id_for(id, Shard.current, Shard.current) } }
    end
  end

  # @API Get visible course navigation tools
  # Get a list of external tools with the course_navigation placement that have not been hidden in
  # course settings and whose visibility settings apply to the requesting user. These tools are the
  # same that appear in the course navigation.
  #
  # The response format is the same as for List external tools, but with additional context_id and
  # context_name fields on each element in the array.
  #
  # @argument context_codes[] [Required]
  #   List of context_codes to retrieve visible course nav tools for (for example, +course_123+). Only
  #   courses are presently supported.
  #
  # @example_request
  #   curl 'https://<canvas>/api/v1/external_tools/visible_course_nav_tools?context_codes[]=course_5' \
  #        -H "Authorization: Bearer <token>"
  #
  # @response_field context_id The unique identifier of the associated context
  # @response_field context_name The name of the associated context
  #
  # @example_response
  #      [{
  #        "id": 1,
  #        "domain": "domain.example.com",
  #        "url": "http://www.example.com/ims/lti",
  #        "context_id": 5,
  #        "context_name": "Example Course",
  #        ...
  #      },
  #      { ...  }]
  #
  def all_visible_nav_tools
    GuardRail.activate(:secondary) do
      courses = api_find_all(Course, @course_ids)
      return unless courses.all? { |course| authorized_action(course, @current_user, :read) }

      render json: external_tools_json_for_courses(courses)
    end
  end

  # @API Get visible course navigation tools for a single course
  # Get a list of external tools with the course_navigation placement that have not been hidden in
  # course settings and whose visibility settings apply to the requesting user. These tools are the
  # same that appear in the course navigation.
  #
  # The response format is the same as Get visible course navigation tools.
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/courses/<course_id>/external_tools/visible_course_nav_tools' \
  #        -H "Authorization: Bearer <token>"
  def visible_course_nav_tools
    GuardRail.activate(:secondary) do
      return unless authorized_action(@context, @current_user, :read)
      return render json: { message: "Only course context is supported" }, status: :bad_request unless context.is_a?(Course)

      render json: external_tools_json_for_courses([@context])
    end
  end

  private

  def external_tools_json_for_courses(courses)
    courses.reduce([]) do |all_results, course|
      tabs = course.tabs_available(@current_user, course_subject_tabs: true)
      tool_ids = []
      tabs.select { |t| t[:external] }.each do |t|
        tool_ids << t[:args][1] if t[:args] && t[:args][1]
      end
      @tools = ContextExternalTool.where(id: tool_ids)
      @tools = tool_ids.filter_map { |id| @tools.find { |t| t[:id] == id } }
      results = external_tools_json(@tools, course, @current_user, session).map do |result|
        # add some identifying information here to simplify grouping by context for the consumer
        result["context_id"] = course.id
        result["context_name"] = course.name
        result
      end
      all_results.push(*results)
    end
  end

  def parse_context_codes
    context_codes = Array(params[:context_codes])
    if context_codes.empty?
      return render json: { message: "Missing context_codes" }, status: :bad_request
    end

    @course_ids = context_codes.inject([]) do |ids, context_code|
      klass, id = ActiveRecord::Base.parse_asset_string(context_code)
      unless klass == "Course"
        return render json: { message: "Invalid context_codes; only `course` codes are supported" },
                      status: :bad_request
      end
      ids << id
    end
  end

  def generate_module_item_sessionless_launch
    module_item_id = params[:module_item_id]

    unless module_item_id
      @context.errors.add(:module_item_id, "A module item id must be provided for module item LTI launch")
      return render json: @context.errors, status: :bad_request
    end

    module_item = ContentTag.find(module_item_id)

    if module_item.context_module_id.blank?
      @context.errors.add(:module_item_id, "The content tag with the specified id is not a content item")
      return render json: @context.errors, status: :bad_request
    end

    generate_common_sessionless_launch(
      launch_url: module_item.url,
      options: { module_item: }
    )
  end

  def generate_assignment_sessionless_launch
    unless params[:assignment_id]
      @context.errors.add(:assignment_id, "An assignment id must be provided for assessment LTI launch")
      return render json: @context.errors, status: :bad_request
    end

    assignment = api_find(@context.assignments, params[:assignment_id])

    return unless authorized_action(assignment, @current_user, :read)

    # Apply assignment overrides for the current user (critical for date-based locks)
    assignment = AssignmentOverrideApplicator.assignment_overridden_for(assignment, @current_user) if @current_user

    # For students, verify submit permission (includes: visible_to_user, locked_for, excused_for, enrollment_active)
    if @context.grants_right?(@current_user, :participate_as_student) &&
       !@context.grants_right?(@current_user, :manage_assignments) &&
       !assignment.grants_right?(@current_user, :submit)
      return render_unauthorized_action
    end

    unless assignment.external_tool_tag
      @context.errors.add(:assignment_id, "The assignment must have an external tool tag")
      return render json: @context.errors, status: :bad_request
    end

    generate_common_sessionless_launch(
      launch_url: assignment.external_tool_tag.url,
      options: { assignment: }
    )
  end

  def generate_common_sessionless_launch(launch_url: nil, options: {})
    tool_id = params[:id]
    launch_url = params[:url] || launch_url
    launch_type = params[:launch_type]
    module_item = options[:module_item]
    assignment = options[:assignment]
    resource_link_lookup_uuid = options[:resource_link_lookup_uuid]

    if assignment.present? && @current_user.present?
      assignment = AssignmentOverrideApplicator.assignment_overridden_for(assignment, @current_user)
    end

    unless tool_id || launch_url || module_item || resource_link_lookup_uuid
      message = "A tool id, tool url, module item id, or resource link lookup uuid must be provided"
      @context.errors.add(:id, message)
      @context.errors.add(:url, message)
      @context.errors.add(:module_item_id, message)
      @context.errors.add(:resource_link_lookup_uuid, message)
      return render json: @context.errors, status: :bad_request
    end

    # Prefer resource_link_lookup_uuid when given over other parameters
    if resource_link_lookup_uuid
      @tool = find_tool_and_url(resource_link_lookup_uuid, launch_url, context, nil).first
    elsif launch_url && module_item.blank?
      @tool = Lti::ToolFinder.from_url(launch_url, @context, preferred_tool_id: tool_id)
    elsif module_item
      @tool = Lti::ToolFinder.from_content_tag(module_item, @context)
    else
      return unless find_tool(tool_id, launch_type)
    end

    if @tool.blank? || (@tool.url.blank? && @tool&.extension_setting(launch_type, :url).blank? && launch_url.blank?)
      respond_to do |format|
        format.html do
          flash[:error] = t "#application.errors.invalid_external_tool", "Couldn't find valid settings for this link"
          redirect_to named_context_url(@context, :context_url)
          return
        end
        format.json { render json: { errors: { external_tool: "Unable to find a matching external tool" } } and return }
      end
    end

    # In the case of cross-shard launches, direct the request to the
    # tool's shard.
    tool_account_res = direct_to_tool_account(@tool, @context) if @tool.shard != Shard.current
    return render json: tool_account_res.body, status: tool_account_res.code if tool_account_res&.success?

    if @tool.use_1_3?
      # Create a launch URL that uses a session token to
      # initialize a Canvas session and launch the tool.
      begin
        launch_link = sessionless_launch_link(
          options.merge(id: tool_id, launch_type:, lookup_id: resource_link_lookup_uuid),
          @context,
          @tool,
          generate_session_token
        )
        render json: { id: @tool.id, name: @tool.name, url: launch_link }
      rescue UnauthorizedClient
        render_unauthorized_action
      end
    else
      metadata = {
        placement: launch_type,
        launch_type: tool_id.present? ? :direct_link : :indirect_link,
        tool_id:
      }
      # generate the launch
      opts = {
        launch_url: @tool.url_with_environment_overrides(launch_url),
        resource_type: launch_type
      }
      if module_item || assignment
        opts[:link_code] = @tool.opaque_identifier_for(module_item || assignment.external_tool_tag)
        metadata[:launch_type] = :content_item
      end

      opts[:overrides] = {
        **whitelisted_query_params,
        "resource_link_title" => (module_item || assignment)&.title
      }.compact

      adapter = Lti::LtiOutboundAdapter.new(
        @tool,
        @current_user,
        @context
      ).prepare_tool_launch(
        url_for(@context),
        variable_expander(assignment:, content_tag: module_item, launch_url: opts[:launch_url]),
        opts
      )

      tool_settings = if assignment
                        adapter.generate_post_payload_for_assignment(
                          assignment,
                          lti_grade_passback_api_url(@tool),
                          blti_legacy_grade_passback_api_url(@tool),
                          lti_turnitin_outcomes_placement_url(@tool.id)
                        )
                      else
                        adapter.generate_post_payload
                      end
      launch_settings = {
        launch_url: adapter.launch_url(post_only: @tool.settings["post_only"]),
        tool_name: @tool.name,
        analytics_id: @tool.tool_id,
        tool_settings:,
        metadata:
      }

      # store the launch settings and return to the user
      verifier = cache_launch(launch_settings, @context, prefix: Lti::RedisMessageClient::SESSIONLESS_LAUNCH_PREFIX)

      uri = if @context.is_a?(Account)
              URI(account_external_tools_sessionless_launch_url(@context))
            else
              URI(course_external_tools_sessionless_launch_url(@context))
            end

      # NOTE: now that we are using session_token here for LTI 1.1 tools, we
      # _might_ be able to simplify the above code and just do a regular launch
      # with token like we do for LTI 1.3 -- see this comment's commit
      uri.query = { verifier:, session_token: session_token_if_authorized }.compact.to_query

      render json: { id: @tool.id, name: @tool.name, url: uri.to_s }
    end
  end

  def session_token_if_authorized
    generate_session_token
  rescue Lti::Concerns::SessionlessLaunches::UnauthorizedClient
    nil
  end

  def set_tool_attributes(tool, params)
    attrs = Lti::ResourcePlacement.valid_placements(@domain_root_account)
    attrs += %i[name
                description
                url
                icon_url
                canvas_icon_class
                domain
                privacy_level
                consumer_key
                shared_secret
                custom_fields
                custom_fields_string
                text
                config_type
                config_url
                config_xml
                not_selectable
                app_center_id
                oauth_compliant
                is_rce_favorite
                is_top_nav_favorite
                unified_tool_id
                message_settings]
    attrs += [:allow_membership_service_access] if @context.root_account.feature_enabled?(:membership_service_for_lti_tools)
    attrs += [:estimated_duration_attributes] if @context.try(:horizon_course?)

    attrs.each do |prop|
      tool.send(:"#{prop}=", params[prop]) if params.key?(prop)
    end
  end

  def require_access_to_context
    if @context.is_a?(Account)
      require_user
    elsif !@context.grants_right?(@current_user, session, :read)
      render_unauthorized_action
    end
  end

  def variable_expander(opts = {})
    default_opts = {
      current_user: @current_user,
      current_pseudonym: @current_pseudonym,
      tool: @tool,
      editor_contents: params[:editor_contents],
      editor_selection: params[:selection]
    }
    Lti::VariableExpander.new(@domain_root_account, @context, self, default_opts.merge(opts))
  end

  def require_tool_create_rights
    authorized_action(@context, @current_user, :manage_lti_add)
  end

  def require_tool_configuration
    return if developer_key.tool_configuration.present?

    head :not_found
  end

  def developer_key
    @_developer_key = DeveloperKey.nondeleted.find(params[:client_id])
  end

  def delete_tool(tool)
    if authorized_action(tool, @current_user, :delete)
      respond_to do |format|
        if tool.destroy
          if api_request?
            ContextExternalTool.invalidate_nav_tabs_cache(tool, @domain_root_account)
            format.json { render json: external_tool_json(tool, @context, @current_user, session) }
          else
            format.json { render json: tool.as_json(methods: [:readable_state, :custom_fields_string], include_root: false) }
          end
        else
          format.json { render json: tool.errors, status: :bad_request }
        end
      end
    end
  end

  def placement_from_params
    params[:placement] || params[:launch_type]
  end

  def whitelisted_query_params
    @_whitelisted_query_params ||= WHITELISTED_QUERY_PARAMS.each_with_object({}) do |query_param, h|
      h[query_param] = params[query_param] if params.key?(query_param)
    end
  end

  def item_banks_launch?(tool, placement)
    # Check if this is a quiz_lti tool with course_navigation or account_navigation placement
    # and the custom_fields indicate it's for item_banks
    return false unless tool.quiz_lti?
    return false unless %w[course_navigation account_navigation].include?(placement)

    # Check if the tool's placement has item_banks custom field
    nav_settings = tool.extension_setting(placement.to_sym)
    return false unless nav_settings

    custom_fields = nav_settings[:custom_fields] || {}
    custom_fields[:item_banks].present?
  end

  def render_native_item_banks(placement)
    add_new_quizzes_bundle

    # Build launch data with item banks context
    signed_launch_data = build_item_banks_launch_data(placement)

    js_env(NEW_QUIZZES: signed_launch_data)

    add_body_class("native-new-quizzes full-width")

    render "assignments/native_new_quizzes", layout: "application"
  end

  def build_item_banks_launch_data(placement)
    # Create a variable expander for LTI variable substitution
    variable_expander = Lti::VariableExpander.new(
      @domain_root_account,
      @context,
      self,
      {
        current_user: @current_user,
        current_pseudonym: @current_pseudonym,
        tool: @tool
      }
    )

    # Build launch data using the NewQuizzes::LaunchDataBuilder
    # but without an assignment (since this is item banks, not a specific quiz)
    ::NewQuizzes::LaunchDataBuilder.new(
      context: @context,
      assignment: nil, # No assignment for item banks
      tool: @tool,
      current_user: @current_user,
      controller: self,
      request:,
      variable_expander:,
      placement: # Pass the placement for placement-specific custom fields
    ).build_with_signature
  end
end
