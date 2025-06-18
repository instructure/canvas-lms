# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

# @API LTI Registrations
# @beta
#
# API for accessing and configuring LTI registrations in a root account.
# LTI Registrations can be any of:
# - 1.3 Dynamic Registration
# - 1.3 manual installation (via JSON, URL, or UI)
# - 1.1 manual installation (via XML, URL, or UI)
#
# The Dynamic Registration process uses a different API endpoint to finalize
# the process and create the registration.  The
# <a href="/doc/api/registration.html">Registration guide</a> has more details on that process.
#
# @model Lti::Registration
#     {
#       "id": "Lti::Registration",
#       "description": "A registration of an LTI tool in Canvas",
#       "properties": {
#         "id": {
#           "description": "the Canvas ID of the Lti::Registration object",
#           "example": 2,
#           "type": "integer"
#         },
#         "name": {
#           "description": "Tool-provided registration name",
#           "example": "My LTI Tool",
#           "type": "string"
#         },
#         "admin_nickname": {
#           "description": "Admin-configured friendly display name",
#           "example": "My LTI Tool (Campus A)",
#           "type": "string"
#         },
#         "icon_url": {
#           "description": "Tool-provided URL to the tool's icon",
#           "example": "https://mytool.com/icon.png",
#           "type": "string"
#         },
#         "vendor": {
#           "description": "Tool-provided name of the tool vendor",
#           "example": "My Tool LLC",
#           "type": "string"
#         },
#         "account_id": {
#           "description": "The Canvas id of the account that owns this registration",
#           "example": 1,
#           "type": "integer"
#         },
#         "internal_service": {
#           "description": "Flag indicating if registration is internally-owned",
#           "example": false,
#           "type": "boolean"
#         },
#         "inherited": {
#           "description": "Flag indicating if registration is owned by this account, or inherited from Site Admin",
#           "example": false,
#           "type": "boolean"
#         },
#         "lti_version": {
#           "description": "LTI version of the registration, either 1.1 or 1.3",
#           "example": "1.3",
#           "type": "string"
#         },
#         "dynamic_registration": {
#           "description": "Flag indicating if registration was created using LTI Dynamic Registration. Only present if lti_version is 1.3",
#           "example": false,
#           "type": "boolean"
#         },
#         "workflow_state": {
#           "description": "The state of the registration",
#           "example": "active",
#           "type": "string",
#           "enum":
#           [
#             "active",
#             "deleted"
#           ]
#         },
#         "created_at": {
#           "description": "Timestamp of the registration's creation",
#           "example": "2024-01-01T00:00:00Z",
#           "type": "string"
#         },
#         "updated_at": {
#           "description": "Timestamp of the registration's last update",
#           "example": "2024-01-01T00:00:00Z",
#           "type": "string"
#         },
#         "created_by": {
#           "description": "The user that created this registration. Not always present. If a string, this registration was created by Instructure.",
#           "example": { "type": "User" },
#           "type": "string|User",
#           "$ref": "User"
#         },
#         "updated_by": {
#           "description": "The user that last updated this registration. Not always present. If a string, this registration was last updated by Instructure.",
#           "example": { "type": "User" },
#           "type": "string|User",
#           "$ref": "User"
#         },
#         "root_account_id": {
#           "description": "The Canvas id of the root account",
#           "example": 1,
#           "type": "integer"
#         },
#         "account_binding": {
#           "description": "The binding for this registration and this account",
#           "example": { "type": "Lti::RegistrationAccountBinding" },
#           "$ref": "Lti::RegistrationAccountBinding"
#         },
#         "configuration": {
#           "description": "The Canvas-style tool configuration for this registration",
#           "example": { "type": "Lti::ToolConfiguration" },
#           "$ref": "Lti::ToolConfiguration"
#         }
#       }
#     }
#
# @model Lti::LegacyConfiguration
#     {
#       "id": "Lti::LegacyConfiguration",
#       "description": "A legacy configuration format for LTI 1.3 tools.",
#       "properties": {
#         "title": {
#           "description": "The display name of the tool",
#           "example": "My Tool",
#           "type": "string"
#         },
#         "description": {
#           "description": "The description of the tool",
#           "example": "My Tool is built by me, for me.",
#           "type": "string"
#         },
#         "custom_fields": {
#           "description": "A key-value listing of all custom fields the tool has requested",
#           "example": { "context_title": "$Context.title", "special_tool_thing": "foo1234" },
#           "type": "object"
#         },
#         "target_link_uri": {
#           "description": "The default launch URL for the tool. Overridable by placements.",
#           "example": "https://mytool.com/launch",
#           "type": "string"
#         },
#         "oidc_initiation_url": {
#           "description": "1.3 specific. URL used for initial login request",
#           "example": "https://mytool.com/1_3/login",
#           "type": "string"
#         },
#         "oidc_initiation_urls": {
#           "description": "1.3 specific. Region-specific login URLs for data protection compliance",
#           "example": { "eu-west-1": "https://dub.mytool.com/1_3/login" },
#           "type": "object"
#         },
#         "public_jwk": {
#           "description": "1.3 specific. The tool's public JWK in JSON format. Discouraged in favor of a url hosting a JWK set.",
#           "example": { "e": "AQAB", "etc": "etc" },
#           "type": "object"
#         },
#         "public_jwk_url": {
#           "description": "1.3 specific. The tool-hosted URL containing its public JWK keyset. Canvas may cache JWKs up to 5 minutes.",
#           "example": "https://mytool.com/1_3/jwks",
#           "type": "string"
#         },
#         "scopes": {
#           "description": "1.3 specific. List of LTI scopes requested by the tool",
#           "example": ["https://purl.imsglobal.org/spec/lti-ags/scope/lineitem"],
#           "type": "array",
#           "items": { "type": "string" }
#         },
#         "extensions": {
#           "description": "Array of extensions for the tool",
#           "type": "array",
#           "items": {
#             "type": "object",
#             "required": ["platform", "settings"],
#             "properties": {
#               "platform": {
#                 "description": "Must be canvas.instructure.com",
#                 "example": "canvas.instructure.com",
#                 "type": "string"
#               },
#               "domain": {
#                 "description": "The domain of the tool",
#                 "example": "legacytool.com",
#                 "type": "string"
#               },
#               "tool_id": {
#                 "description": "Tool-provided identifier, can be anything",
#                 "example": "LegacyTool",
#                 "type": "string"
#               },
#               "privacy_level": {
#                 "description": "Canvas-defined privacy level for the tool",
#                 "example": "public",
#                 "type": "string",
#                 "enum": ["public", "anonymous", "name_only", "email_only"]
#               },
#               "settings": {
#                 "description": "Settings for the tool",
#                 "type": "object",
#                 "required": ["placements"],
#                 "properties": {
#                   "text": {
#                     "description": "The text of the link to the tool (if applicable).",
#                     "example": "Hello World",
#                     "type": "object"
#                   },
#                   "labels": {
#                     "description": "Canvas-specific i18n for placement text. See the Navigation Placement docs.",
#                     "example": { "en": "Hello World", "es": "Hola Mundo" },
#                     "type": "object"
#                   },
#                   "custom_fields": {
#                     "description": "Placement-specific custom fields to send in the launch. Merged with tool-level custom fields.",
#                     "example": { "special_placement_thing": "foo1234" },
#                     "type": "object"
#                   },
#                   "selection_height": {
#                     "description": "Default iframe height. Not valid for all placements. Overrides tool-level launch_height.",
#                     "example": 800,
#                     "type": "number"
#                   },
#                   "selection_width": {
#                     "description": "Default iframe width. Not valid for all placements. Overrides tool-level launch_width.",
#                     "example": 1000,
#                     "type": "number"
#                   },
#                   "launch_height": {
#                     "description": "Default iframe height. Not valid for all placements. Overrides tool-level launch_height.",
#                     "example": 800,
#                     "type": "number"
#                   },
#                   "launch_width": {
#                     "description": "Default iframe width. Not valid for all placements. Overrides tool-level launch_width.",
#                     "example": 1000,
#                     "type": "number"
#                   },
#                   "icon_url": {
#                     "description": "Default icon URL. Not valid for all placements. Overrides tool-level icon_url.",
#                     "example": "https://mytool.com/icon.png",
#                     "type": "string"
#                   },
#                   "canvas_icon_class": {
#                     "description": "The HTML class name of an InstUI Icon. Used instead of an icon_url in select placements.",
#                     "example": "icon-lti",
#                     "type": "string"
#                   },
#                   "required_permissions": {
#                     "description": "Comma-separated list of Canvas permission short names required for a user to launch from this placement.",
#                     "example": "manage_course_content_edit,manage_course_content_read",
#                     "type": "string"
#                   },
#                   "windowTarget": {
#                     "description": "When set to '_blank', opens placement in a new tab.",
#                     "example": "_blank",
#                     "type": "string"
#                   },
#                   "display_type": {
#                     "description": "The Canvas layout to use when launching the tool. See the Navigation Placement docs.",
#                     "example": "full_width_in_context",
#                     "type": "string",
#                     "enum": [
#                       "default",
#                       "full_width",
#                       "full_width_in_context",
#                       "full_width_with_nav",
#                       "in_nav_context",
#                       "borderless"
#                     ]
#                   },
#                   "url": {
#                     "description": "The 1.1 launch URL for this placement. Overrides tool-level url.",
#                     "example": "https://mytool.com/launch?placement=course_navigation",
#                     "type": "string"
#                   },
#                   "target_link_uri": {
#                     "description": "The 1.3 launch URL for this placement. Overrides tool-level target_link_uri.",
#                     "example": "https://mytool.com/launch?placement=course_navigation",
#                     "type": "string"
#                   },
#                   "visibility": {
#                     "description": "Specifies types of users that can see this placement. Only valid for some placements like course_navigation.",
#                     "example": "admins",
#                     "type": "string"
#                   },
#                   "prefer_sis_email": {
#                     "description": "1.1 specific. If true, the tool will send the SIS email in the lis_person_contact_email_primary launch property",
#                     "example": false,
#                     "type": "boolean"
#                   },
#                   "oauth_compliant": {
#                     "description": "1.1 specific. If true, query parameters from the launch URL will not be copied to the POST body.",
#                     "example": true,
#                     "type": "boolean"
#                   },
#                   "icon_svg_path_64": {
#                     "description": "An SVG to use instead of an icon_url. Only valid for global_navigation.",
#                     "example": "M100,37L70.1,10.5v176H37...",
#                     "type": "string"
#                   },
#                   "default": {
#                     "description": "Default display state for course_navigation. If 'enabled', will show in course sidebar. If 'disabled', will be hidden.",
#                     "example": "disabled",
#                     "type": "string"
#                   },
#                   "accept_media_types": {
#                     "description": "Comma-separated list of media types that the tool can accept. Only valid for file_item.",
#                     "example": "image/*,video/*",
#                     "type": "string"
#                   },
#                   "use_tray": {
#                     "description": "If true, the tool will be launched in the tray. Only used by the editor_button placement.",
#                     "example": true,
#                     "type": "boolean"
#                   },
#                   "placements": {
#                     "description": "List of placements configured by the tool",
#                     "type": "array",
#                     "items": {
#                       "$ref": "Lti::Placement"
#                     }
#                   }
#                 }
#               }
#             }
#           }
#         }
#       }
#     }
#
# @model Lti::ToolConfiguration
#     {
#       "id": "Lti::ToolConfiguration",
#       "description": "A Registration's Canvas-specific tool configuration.",
#       "properties": {
#         "title": {
#           "description": "The display name of the tool",
#           "example": "My Tool",
#           "type": "string"
#         },
#         "description": {
#           "description": "The description of the tool",
#           "example": "My Tool is built by me, for me.",
#           "type": "string"
#         },
#         "custom_fields": {
#           "description": "A key-value listing of all custom fields the tool has requested",
#           "example": { "context_title": "$Context.title", "special_tool_thing": "foo1234" },
#           "type": "object"
#         },
#         "target_link_uri": {
#           "description": "The default launch URL for the tool. Overridable by placements.",
#           "example": "https://mytool.com/launch",
#           "type": "string"
#         },
#         "domain": {
#           "description": "The tool's main domain. Highly recommended for deep linking, used to match links to the tool.",
#           "example": "mytool.com",
#           "type": "string"
#         },
#         "tool_id": {
#           "description": "Tool-provided identifier, can be anything",
#           "example": "MyTool",
#           "type": "string"
#         },
#         "privacy_level": {
#           "description": "Canvas-defined privacy level for the tool",
#           "example": "public",
#           "type": "string",
#           "enum":
#           [
#             "public",
#             "anonymous",
#             "name_only",
#             "email_only"
#           ]
#         },
#         "oidc_initiation_url": {
#           "description": "1.3 specific. URL used for initial login request",
#           "example": "https://mytool.com/1_3/login",
#           "type": "string"
#         },
#         "oidc_initiation_urls": {
#           "description": "1.3 specific. Region-specific login URLs for data protection compliance",
#           "example": { "eu-west-1": "https://dub.mytool.com/1_3/login" },
#           "type": "object"
#         },
#         "public_jwk": {
#           "description": "1.3 specific. The tool's public JWK in JSON format. Discouraged in favor of a url hosting a JWK set.",
#           "example": { "e": "AQAB", "etc": "etc" },
#           "type": "object"
#         },
#         "public_jwk_url": {
#           "description": "1.3 specific. The tool-hosted URL containing its public JWK keyset. Canvas may cache JWKs up to 5 minutes.",
#           "example": "https://mytool.com/1_3/jwks",
#           "type": "string"
#         },
#         "scopes": {
#           "description": "1.3 specific. List of LTI scopes requested by the tool",
#           "example": ["https://purl.imsglobal.org/spec/lti-ags/scope/lineitem"],
#           "type": "array",
#           "items": { "type": "string" }
#         },
#         "redirect_uris": {
#           "description": "1.3 specific. List of possible launch URLs for after the Canvas authorize redirect step",
#           "example": ["https://mytool.com/launch", "https://mytool.com/1_3/launch"],
#           "type": "array",
#           "items": { "type": "string" }
#         },
#         "launch_settings": {
#           "description": "Default launch settings for all placements",
#           "example": { "message_type": "LtiResourceLinkRequest" },
#           "$ref": "Lti::LaunchSettings"
#         },
#         "placements": {
#           "description": "List of placements configured by the tool",
#           "example": [{ "type": "Lti::Placement" }],
#           "type": "array",
#           "items": { "$ref": "Lti::Placement" }
#         }
#       }
#     }
#
# @model Lti::LaunchSettings
#     {
#       "id": "Lti::LaunchSettings",
#       "description": "Default launch settings for all placements",
#       "properties": {
#         "message_type": {
#           "description": "Default message type for all placements",
#           "example": "LtiResourceLinkRequest",
#           "type": "string",
#           "enum":
#           [
#             "LtiResourceLinkRequest",
#             "LtiDeepLinkingRequest"
#           ]
#         },
#         "text": {
#           "description": "The text of the link to the tool (if applicable).",
#           "example": "Hello World",
#           "type": "string"
#         },
#         "labels": {
#           "description": "Canvas-specific i18n for placement text. See the Navigation Placement docs.",
#           "example": { "en": "Hello World", "es": "Hola Mundo" },
#           "type": "object"
#         },
#         "custom_fields": {
#           "description": "Placement-specific custom fields to send in the launch. Merged with tool-level custom fields.",
#           "example": { "special_placement_thing": "foo1234" },
#           "type": "object"
#         },
#         "selection_height": {
#           "description": "Default iframe height. Not valid for all placements. Overrides tool-level launch_height.",
#           "example": 800,
#           "type": "number"
#         },
#         "selection_width": {
#           "description": "Default iframe width. Not valid for all placements. Overrides tool-level launch_width.",
#           "example": 1000,
#           "type": "number"
#         },
#         "launch_height": {
#           "description": "Default iframe height. Not valid for all placements. Overrides tool-level launch_height.",
#           "example": 800,
#           "type": "number"
#         },
#         "launch_width": {
#           "description": "Default iframe width. Not valid for all placements. Overrides tool-level launch_width.",
#           "example": 1000,
#           "type": "number"
#         },
#         "icon_url": {
#           "description": "Default icon URL. Not valid for all placements. Overrides tool-level icon_url.",
#           "example": "https://mytool.com/icon.png",
#           "type": "string"
#         },
#         "canvas_icon_class": {
#           "description": "The HTML class name of an InstUI Icon. Used instead of an icon_url in select placements.",
#           "example": "icon-lti",
#           "type": "string"
#         },
#         "required_permissions": {
#           "description": "Comma-separated list of Canvas permission short names required for a user to launch from this placement.",
#           "example": "manage_course_content_edit,manage_course_content_read",
#           "type": "string"
#         },
#         "windowTarget": {
#           "description": "When set to '_blank', opens placement in a new tab.",
#           "example": "_blank",
#           "type": "string"
#         },
#         "display_type": {
#           "description": "The Canvas layout to use when launching the tool. See the Navigation Placement docs.",
#           "example": "full_width_in_context",
#           "type": "string",
#           "enum": [
#             "default",
#             "full_width",
#             "full_width_in_context",
#             "full_width_with_nav",
#             "in_nav_context",
#             "borderless"
#           ]
#         },
#         "url": {
#           "description": "The 1.1 launch URL for this placement. Overrides tool-level url.",
#           "example": "https://mytool.com/launch?placement=course_navigation",
#           "type": "string"
#         },
#         "target_link_uri": {
#           "description": "The 1.3 launch URL for this placement. Overrides tool-level target_link_uri.",
#           "example": "https://mytool.com/launch?placement=course_navigation",
#           "type": "string"
#         },
#         "visibility": {
#           "description": "Specifies types of users that can see this placement. Only valid for some placements like course_navigation.",
#           "example": "admins",
#           "type": "string"
#         },
#         "prefer_sis_email": {
#           "description": "1.1 specific. If true, the tool will send the SIS email in the lis_person_contact_email_primary launch property",
#           "example": false,
#           "type": "boolean"
#         },
#         "oauth_compliant": {
#           "description": "1.1 specific. If true, query parameters from the launch URL will not be copied to the POST body.",
#           "example": true,
#           "type": "boolean"
#         },
#         "icon_svg_path_64": {
#           "description": "An SVG to use instead of an icon_url. Only valid for global_navigation.",
#           "example": "M100,37L70.1,10.5v176H37...",
#           "type": "string"
#         },
#         "default": {
#           "description": "Default display state for course_navigation. If 'enabled', will show in course sidebar. If 'disabled', will be hidden.",
#           "example": "disabled",
#           "type": "string"
#         },
#         "accept_media_types": {
#           "description": "Comma-separated list of media types that the tool can accept. Only valid for file_item.",
#           "example": "image/*,video/*",
#           "type": "string"
#         },
#         "use_tray": {
#           "description": "If true, the tool will be launched in the tray. Only used by the editor_button placement.",
#           "example": true,
#           "type": "boolean"
#         }
#       }
#     }
#
# @model Lti::Placement
#     {
#       "id": "Lti::Placement",
#       "description": "The tool's configuration for a specific placement",
#       "properties": {
#         "placement": {
#           "description": "The name of the placement.",
#           "example": "course_navigation",
#           "type": "string",
#           "enum":
#           [
#             "account_navigation",
#             "analytics_hub",
#             "assignment_edit",
#             "assignment_group_menu",
#             "assignment_index_menu",
#             "assignment_menu",
#             "assignment_selection",
#             "assignment_view",
#             "collaboration",
#             "conference_selection",
#             "course_assignments_menu",
#             "course_home_sub_navigation",
#             "course_navigation",
#             "course_settings_sub_navigation",
#             "discussion_topic_index_menu",
#             "discussion_topic_menu",
#             "file_index_menu",
#             "file_menu",
#             "global_navigation",
#             "homework_submission",
#             "link_selection",
#             "migration_selection",
#             "module_group_menu",
#             "module_index_menu",
#             "module_index_menu_modal",
#             "module_menu_modal",
#             "module_menu",
#             "post_grades",
#             "quiz_index_menu",
#             "quiz_menu",
#             "resource_selection",
#             "similarity_detection",
#             "student_context_card",
#             "submission_type_selection",
#             "tool_configuration",
#             "top_navigation",
#             "user_navigation",
#             "wiki_index_menu",
#             "wiki_page_menu",
#             "editor_button"
#           ]
#         },
#         "enabled": {
#           "description": "If true, the tool will show in this placement. If false, it will not.",
#           "example": true,
#           "type": "boolean"
#         },
#         "message_type": {
#           "description": "Default message type for all placements",
#           "example": "LtiResourceLinkRequest",
#           "type": "string",
#           "enum":
#           [
#             "LtiResourceLinkRequest",
#             "LtiDeepLinkingRequest"
#           ]
#         },
#         "text": {
#           "description": "The text of the link to the tool (if applicable).",
#           "example": "Hello World",
#           "type": "string"
#         },
#         "labels": {
#           "description": "Canvas-specific i18n for placement text. See the Navigation Placement docs.",
#           "example": { "en": "Hello World", "es": "Hola Mundo" },
#           "type": "object"
#         },
#         "custom_fields": {
#           "description": "Placement-specific custom fields to send in the launch. Merged with tool-level custom fields.",
#           "example": { "special_placement_thing": "foo1234" },
#           "type": "object"
#         },
#         "selection_height": {
#           "description": "Default iframe height. Not valid for all placements. Overrides tool-level launch_height.",
#           "example": 800,
#           "type": "number"
#         },
#         "selection_width": {
#           "description": "Default iframe width. Not valid for all placements. Overrides tool-level launch_width.",
#           "example": 1000,
#           "type": "number"
#         },
#         "launch_height": {
#           "description": "Default iframe height. Not valid for all placements. Overrides tool-level launch_height.",
#           "example": 800,
#           "type": "number"
#         },
#         "launch_width": {
#           "description": "Default iframe width. Not valid for all placements. Overrides tool-level launch_width.",
#           "example": 1000,
#           "type": "number"
#         },
#         "icon_url": {
#           "description": "Default icon URL. Not valid for all placements. Overrides tool-level icon_url.",
#           "example": "https://mytool.com/icon.png",
#           "type": "string"
#         },
#         "canvas_icon_class": {
#           "description": "The HTML class name of an InstUI Icon. Used instead of an icon_url in select placements.",
#           "example": "icon-lti",
#           "type": "string"
#         },
#         "required_permissions": {
#           "description": "Comma-separated list of Canvas permission short names required for a user to launch from this placement.",
#           "example": "manage_course_content_edit,manage_course_content_read",
#           "type": "string"
#         },
#         "windowTarget": {
#           "description": "When set to '_blank', opens placement in a new tab.",
#           "example": "_blank",
#           "type": "string"
#         },
#         "display_type": {
#           "description": "The Canvas layout to use when launching the tool. See the Navigation Placement docs.",
#           "example": "full_width_in_context",
#           "type": "string",
#           "enum": [
#             "default",
#             "full_width",
#             "full_width_in_context",
#             "full_width_with_nav",
#             "in_nav_context",
#             "borderless"
#           ]
#         },
#         "url": {
#           "description": "The 1.1 launch URL for this placement. Overrides tool-level url.",
#           "example": "https://mytool.com/launch?placement=course_navigation",
#           "type": "string"
#         },
#         "target_link_uri": {
#           "description": "The 1.3 launch URL for this placement. Overrides tool-level target_link_uri.",
#           "example": "https://mytool.com/launch?placement=course_navigation",
#           "type": "string"
#         },
#         "visibility": {
#           "description": "Specifies types of users that can see this placement. Only valid for some placements like course_navigation.",
#           "example": "admins",
#           "type": "string",
#           "enum": [
#             "admins",
#             "members",
#             "public"
#           ]
#         },
#         "prefer_sis_email": {
#           "description": "1.1 specific. If true, the tool will send the SIS email in the lis_person_contact_email_primary launch property",
#           "example": false,
#           "type": "boolean"
#         },
#         "oauth_compliant": {
#           "description": "(Only applies to 1.1) If true, Canvas will not copy launch URL query parameters to the POST body.",
#           "example": true,
#           "type": "boolean"
#         },
#         "icon_svg_path_64": {
#           "description": "An SVG to use instead of an icon_url. Only valid for global_navigation.",
#           "example": "M100,37L70.1,10.5v176H37...",
#           "type": "string"
#         },
#         "default": {
#           "description": "Default display state for course_navigation. If 'enabled', will show in course sidebar. If 'disabled', will be hidden.",
#           "example": "disabled",
#           "type": "string"
#         },
#         "accept_media_types": {
#           "description": "Comma-separated list of media types that the tool can accept. Only valid for file_item.",
#           "example": "image/*,video/*",
#           "type": "string"
#         },
#         "use_tray": {
#           "description": "If true, the tool will be launched in the tray. Only used by the editor_button placement.",
#           "example": true,
#           "type": "boolean"
#         }
#       }
#     }
#
# @model Lti::Overlay
#     {
#       "id": "Lti::Overlay",
#       "description": "Changes made by a Canvas admin to a tool's configuration.",
#       "properties": {
#         "title": {
#           "description": "The display name of the tool",
#           "example": "My Tool",
#           "type": "string"
#         },
#         "description": {
#           "description": "The description of the tool",
#           "example": "My Tool is built by me, for me.",
#           "type": "string"
#         },
#         "custom_fields": {
#           "description": "A key-value listing of all custom fields the tool has requested",
#           "example": { "context_title": "$Context.title", "special_tool_thing": "foo1234" },
#           "type": "object"
#         },
#         "target_link_uri": {
#           "description": "The default launch URL for the tool. Overridable by placements.",
#           "example": "https://mytool.com/launch",
#           "type": "string"
#         },
#         "domain": {
#           "description": "The tool's main domain. Highly recommended for deep linking, used to match links to the tool.",
#           "example": "mytool.com",
#           "type": "string"
#         },
#         "privacy_level": {
#           "description": "Canvas-defined privacy level for the tool",
#           "example": "public",
#           "type": "string",
#           "enum":
#           [
#             "public",
#             "anonymous",
#             "name_only",
#             "email_only"
#           ]
#         },
#         "oidc_initiation_url": {
#           "description": "1.3 specific. URL used for initial login request",
#           "example": "https://mytool.com/1_3/login",
#           "type": "string"
#         },
#         "disabled_scopes": {
#           "description": "1.3 specific. List of LTI scopes that the tool has requested but an admin has disabled",
#           "example": ["https://purl.imsglobal.org/spec/lti-ags/scope/lineitem"],
#           "type": "array",
#           "items": { "type": "string" }
#         },
#         "disabled_placements": {
#           "description": "List of placements that the tool has requested but an admin has disabled",
#           "example": ["course_navigation"],
#           "type": "array",
#           "items": { "type": "string" }
#         },
#         "placements": {
#           "description": "Placement-specific settings changed by an admin",
#           "example": { "course_navigation": { "$ref": "Lti::Placement" } },
#           "type": "object",
#           "items": { "$ref": "Lti::PlacementOverlay" }
#         }
#       }
#     }
#
# @model Lti::PlacementOverlay
#     {
#       "id": "Lti::PlacementOverlay",
#       "description": "Changes made by a Canvas admin to a tool's configuration for a specific placement.",
#       "properties": {
#         "text": {
#           "description": "The text of the link to the tool (if applicable).",
#           "example": "Hello World",
#           "type": "string"
#         },
#         "target_link_uri": {
#           "description": "The default launch URL for the tool. Overridable by placements.",
#           "example": "https://mytool.com/launch",
#           "type": "string"
#         },
#         "message_type": {
#           "description": "Default message type for all placements",
#           "example": "LtiResourceLinkRequest",
#           "type": "string",
#           "enum":
#           [
#             "LtiResourceLinkRequest",
#             "LtiDeepLinkingRequest"
#           ]
#         },
#         "launch_height": {
#           "description": "Default iframe height. Not valid for all placements. Overrides tool-level launch_height.",
#           "example": 800,
#           "type": "number"
#         },
#         "launch_width": {
#           "description": "Default iframe width. Not valid for all placements. Overrides tool-level launch_width.",
#           "example": 1000,
#           "type": "number"
#         },
#         "icon_url": {
#           "description": "Default icon URL. Not valid for all placements. Overrides tool-level icon_url.",
#           "example": "https://mytool.com/icon.png",
#           "type": "string"
#         },
#         "default": {
#           "description": "Default display state for course_navigation. If 'enabled', will show in course sidebar. If 'disabled', will be hidden.",
#           "example": "disabled",
#           "type": "string"
#         }
#       }
#     }
#
# @model ListLtiRegistrationsResponse
#     {
#       "id": "ListLtiRegistrationsResponse",
#       "description": "The response for the List LTI Registrations API endpoint",
#       "properties": {
#         "total": {
#           "description": "The total number of LTI registrations across all pages",
#           "example": 1,
#           "type": "integer"
#         },
#         "data": {
#           "description": "The paginated list of LTI::Registrations",
#           "example": [{ "$ref": "Lti::Registration" }],
#           "type": "array",
#           "items": { "$ref": "Lti::Registration" }
#         }
#       }
#     }
#
# @model ContextSearchResponse
#     {
#       "id": "ContextSearchResponse",
#       "description": "The response for the Search Accounts and Courses API endpoint",
#       "properties": {
#         "accounts": {
#           "description": "Accounts that match the search query. Limited to 100.",
#           "example": [{ "$ref": "Account" }],
#           "type": "array",
#           "items": {
#             "$ref": "SearchableAccount"
#           }
#         },
#         "courses": {
#           "description": "Courses that match the search query. Limited to 100.",
#           "example": [{ "$ref": "Course" }],
#           "type": "array",
#           "items": {
#             "$ref": "SearchableCourse"
#           }
#         }
#       }
#     }
#
# @model SearchableAccount
#     {
#       "id": "SearchableAccount",
#       "description": "A minimal representation of an Account for Canvas Apps search purposes",
#       "properties": {
#         "id": {
#           "description": "The Canvas DB ID",
#           "example": "1",
#           "type": "string"
#         },
#         "name": {
#           "description": "The account name",
#           "example": "An Account",
#           "type": "string"
#         },
#         "sis_id": {
#           "description": "The SIS ID of the account, if any. Only present if user can read or manage SIS.",
#           "example": "sis-account-1",
#           "type": "string"
#         },
#         "display_path": {
#           "description": "Names of the accounts in this account's hierarchy, excluding the root and this account.",
#           "example": ["Sub Account"],
#           "type": "array",
#           "items": {
#             "type": "string"
#           }
#         }
#       }
#     }
#
# @model SearchableCourse
#     {
#       "id": "SearchableCourse",
#       "description": "A minimal representation of a Course for Canvas Apps search purposes",
#       "properties": {
#         "id": {
#           "description": "The Canvas DB ID",
#           "example": "1",
#           "type": "string"
#         },
#         "name": {
#           "description": "The course name",
#           "example": "A Course",
#           "type": "string"
#         },
#         "sis_id": {
#           "description": "The SIS ID of the course, if any. Only present if user can read or manage SIS.",
#           "example": "sis-course-1",
#           "type": "string"
#         },
#         "display_path": {
#           "description": "Names of the accounts in this course's account hierarchy, excluding the root.",
#           "example": ["Sub Account"],
#           "type": "array",
#           "items": {
#             "type": "string"
#           }
#         },
#         "course_code": {
#           "description": "The course code",
#           "example": "COURSE-101",
#           "type": "string"
#         }
#       }
#     }
#
class Lti::RegistrationsController < ApplicationController
  before_action :require_root_account_instrumented
  before_action :require_feature_flag
  before_action :require_lti_registrations_next_feature_flag, only: %i[reset context_search]
  before_action :require_manage_lti_registrations
  before_action :validate_workflow_state, only: %i[bind create update]
  before_action :validate_list_params, only: :list
  before_action :validate_registration_params, only: %i[create update]
  before_action :restrict_dynamic_registration_updates, only: %i[update]
  before_action :require_registration_params, only: :create

  include Api::V1::Lti::Registration

  def index
    set_active_tab "apps"

    inject_lti_usage_env

    # allows override of DR url hard-coded into Discover page
    # todo: remove once Discover page retrieves and uses correct DR url
    temp_dr_url = Setting.get("lti_discover_page_dyn_reg_url", "")
    if temp_dr_url.present?
      js_env({
               dynamicRegistrationUrl: temp_dr_url
             })
    end

    render :index
  end

  # @API List LTI Registrations in an account
  # Returns all LTI registrations in the specified account.
  # Includes registrations created in this account, those set to 'allow' from a
  # parent root account (like Site Admin) and 'on' for this account,
  # and those enabled 'on' at the parent root account level.
  #
  # @argument per_page [integer] The number of registrations to return per page. Defaults to 15.
  #
  # @argument page [integer] The page number to return. Defaults to 1.
  #
  # @argument sort [String]
  #   The field to sort by. Choices are: name, nickname, lti_version, installed,
  #   installed_by, updated_by, updated, and on. Defaults to installed.
  #
  # @argument dir [String, "asc"|"desc"]
  #   The order to sort the given column by. Defaults to desc.
  #
  # @argument include[] [String]
  #   Array of additional data to include. Always includes [account_binding].
  #
  #   "account_binding":: the registration's binding to the given account
  #   "configuration":: the registration's Canvas-style tool configuration, without any overlays applied.
  #   "overlaid_configuration":: the registration's Canvas-style tool configuration, with all overlays applied.
  #   "overlay":: the registration's admin-defined configuration overlay
  #
  # @returns ListLtiRegistrationsResponse
  #
  # @example_request
  #
  #   This would return the specified LTI registration
  #   curl -X GET 'https://<canvas>/api/v1/accounts/<account_id>/registrations' \
  #        -H "Authorization: Bearer <token>"
  def list
    includes = [:account_binding] + (Array(params[:include]).map(&:to_sym) - [:overlay_versions])
    list_service_params = {
      account: @account,
      search_terms: params[:query]&.downcase&.split,
      sort_field: params[:sort]&.to_sym || :installed,
      sort_direction: params[:dir]&.to_sym || :desc,
      preload_overlays: includes.include?(:overlay)
    }

    registrations, preloads = Lti::ListRegistrationService
                              .call(**list_service_params)
                              .values_at(:registrations, :preloaded_associations)

    per_page = Api.per_page_for(self, default: 15)
    paginated_registrations, _metadata = Api.jsonapi_paginate(registrations, self, url_for, { per_page: })
    render json: {
      total: registrations.size,
      data: lti_registrations_json(paginated_registrations, @current_user, session, @context, includes:, preloads:)
    }
  rescue => e
    report_error(e)
    raise e
  end

  # @internal
  # @API Validate LtiConfiguration
  # Validates the provided LTI 1.3 JSON config against the LtiConfiguration schema,
  # and returns any errors found. Also transforms the JSON from LtiConfiguration
  # to InternalLtiConfiguration format before returning.
  # JSON config can be provided via url that points to an endpoint hosted by a tool,
  # or directly in the request body.
  # This is a utility endpoint for the LTI registration UI. Fetching tool config server-side
  # prevents CORS issues for the tool.
  #
  # @argument lti_configuration [Optional, JSON] The LTI 1.3 JSON config to validate.
  # @argument url [Optional, String] The URL to fetch the LTI 1.3 JSON config from.
  #
  # @returns { configuration: Lti::ToolConfiguration } | { errors: [String] }
  #
  # @example_request
  #
  #   This would return the JSON in InternalLtiConfiguration format
  #   curl -X POST 'https://<canvas>/api/v1/accounts/<account_id>/lti_registrations/configuration/validate' \
  #        -d '{"lti_configuration": <LTI JSON config>}' \
  #        -H "Content-Type: application/json" \
  #        -H "Authorization: Bearer <token>"
  def validate_lti_configuration
    unless params[:lti_configuration].present? || params[:url].present?
      return render_configuration_errors(["one of lti_configuration or url is required"])
    end
    if params[:lti_configuration].present? && params[:url].present?
      return render_configuration_errors(["only one of lti_configuration or url is allowed"])
    end

    if params[:lti_configuration].present?
      config = params.require(:lti_configuration).to_unsafe_h
    else
      begin
        result = CanvasHttp.get(params.require(:url))

        unless result.is_a?(Net::HTTPSuccess)
          return render_configuration_errors(["invalid configuration url"])
        end

        config = JSON.parse(result.body)
      rescue CanvasHttp::Error,
             CanvasHttp::RelativeUriError,
             CanvasHttp::InsecureUriError,
             Timeout::Error,
             SocketError,
             SystemCallError,
             OpenSSL::SSL::SSLError
        return render_configuration_errors(["invalid configuration url"])
      rescue JSON::ParserError
        return render_configuration_errors(["url does not return JSON"])
      end
    end

    errors = Schemas::LtiConfiguration.validation_errors(config, allow_nil: true)
    if errors.present?
      return render_configuration_errors(errors)
    end

    configuration = Schemas::InternalLtiConfiguration.from_lti_configuration(config)

    # The internal configuration conversion method doesn't include redirect_uris,
    # as doing so might cause the actual redirect_uris on existing tool configurations
    # to be overwritten. We need to include them here so that the UI can display
    # them properly.
    configuration[:redirect_uris] ||= [configuration[:target_link_uri]]
    configuration[:redirect_uris] = Array(configuration[:redirect_uris])

    render json: { configuration: }
  end

  # @API Show an LTI Registration
  # Return details about the specified LTI registration, including the
  # configuration and account binding.
  #
  # @argument include[] [String]
  #   Array of additional data to include. Always includes [account_binding configuration].
  #
  #   "account_binding":: the registration's binding to the given account
  #   "configuration":: the registration's Canvas-style tool configuration, without any overlays applied.
  #   "overlaid_configuration":: the registration's Canvas-style tool configuration, with all overlays applied.
  #   "overlaid_legacy_configuration":: the registration's legacy-style configuration, with all overlays applied.
  #   "overlay":: the registration's admin-defined configuration overlay
  #   "overlay_versions":: the registration's overlay's edit history
  #
  # @returns Lti::Registration
  #
  # @example_request
  #
  #   This would return the specified LTI registration
  #   curl -X GET 'https://<canvas>/api/v1/accounts/<account_id>/lti_registrations/<registration_id>' \
  #        -H "Authorization: Bearer <token>"
  def show
    GuardRail.activate(:secondary) do
      registration = Lti::Registration.active.find(params[:id])
      includes = [:account_binding, :configuration] + Array(params[:include]).map(&:to_sym)
      account_binding = registration.account_binding_for(@context)
      overlay = registration.overlay_for(@context) if includes.include?(:overlay)
      render json: lti_registration_json(registration,
                                         @current_user,
                                         session,
                                         @context,
                                         includes:,
                                         account_binding:,
                                         overlay:)
    end
  rescue => e
    report_error(e)
    raise e
  end

  # @API Create an LTI Registration
  # Create a new LTI Registration, as well as an associated Tool Configuration, Developer Key, and Registration Account
  # binding.
  # To install/create using Dynamic Registration, please use the
  # <a href="/doc/api/registration.html">Dynamic Registration API.</a>
  #
  # @argument name [String] The name of the tool. If one isn't provided, it will be inferred from the configuration's title.
  # @argument admin_nickname [String] A friendly nickname set by admins to override the tool name
  # @argument vendor [String] The vendor of the tool
  # @argument description [String] A description of the tool. Cannot exceed 2048 bytes.
  # @argument configuration [Required, Lti::ToolConfiguration | Lti::LegacyConfiguration] The LTI 1.3 configuration for the tool
  # @argument overlay [Lti::Overlay] The overlay configuration for the tool. Overrides values in the base configuration.
  # @argument unified_tool_id [String] The unique identifier for the tool, used for analytics. If not provided, one will be generated.
  # @argument workflow_state [String, "on" | "off" | "allow"]
  #   The desired state for this registration/account binding. "allow" is only valid for Site Admin registrations.
  #   Defaults to "off".
  #
  # @example_request
  #
  #   This would create a new LTI Registration, as well as an associated Developer Key
  #   and LTI Tool Configuration.
  #
  #   curl -X POST 'https://<canvas>/api/v1/accounts/<account_id>/lti_registrations' \
  #       -H "Authorization: Bearer <token>" \
  #       -H "Content-Type: application/json" \
  #       -d '{
  #             "vendor": "Example",
  #             "name": "An Example Tool",
  #             "admin_nickname": "A Great LTI Tool",
  #             "configuration": {
  #               "title": "Sample Tool",
  #               "description": "A sample LTI tool",
  #               "target_link_uri": "https://example.com/launch",
  #               "oidc_initiation_url": "https://example.com/oidc",
  #               "redirect_uris": ["https://example.com/redirect"],
  #               "scopes": ["https://purl.imsglobal.org/spec/lti-ags/scope/lineitem"],
  #               "placements": [
  #                 {
  #                   "placement": "course_navigation",
  #                   "enabled": true
  #                 }
  #               ],
  #               "launch_settings": {}
  #             }
  #           }'
  #
  # @returns Lti::Registration
  def create
    registration_params = {
      name: configuration_params[:title],
    }.with_indifferent_access.merge(params.permit(:vendor, :name, :admin_nickname, :description))
    create_params = {
      account: @context,
      created_by: @current_user,
      unified_tool_id: params[:unified_tool_id],
      registration_params:,
      configuration_params:,
      overlay_params:,
      binding_params: {
        workflow_state:,
      }
    }

    registration = Lti::CreateRegistrationService.call(**create_params)

    render status: :created, json: lti_registration_json(registration,
                                                         @current_user,
                                                         session,
                                                         @context,
                                                         includes: %i[account_binding configuration overlay],
                                                         account_binding: registration.account_binding_for(@context),
                                                         overlay: registration.overlay_for(@context))
  end

  # @API Show an LTI Registration (via the client_id)
  # Returns details about the specified LTI registration, including the
  # configuration and account binding.
  #
  # @returns Lti::Registration
  #
  # @example_request
  #
  #   This would return the specified LTI registration
  #   curl -X GET 'https://<canvas>/api/v1/accounts/<account_id>/lti_registration_by_client_id/<client_id>' \
  #        -H "Authorization: Bearer <token>"
  def show_by_client_id
    GuardRail.activate(:secondary) do
      developer_key = DeveloperKey.find(params[:client_id])
      unless developer_key&.lti_registration.present?
        return render json: { errors: "LTI registration not found" }, status: :not_found
      end

      registration = developer_key.lti_registration

      render json: lti_registration_json(registration,
                                         @current_user,
                                         session,
                                         @context,
                                         includes: [:account_binding, :configuration],
                                         account_binding: registration.account_binding_for(@context))
    end
  rescue => e
    report_error(e)
    raise e
  end

  # @API Update an LTI Registration
  # Update the specified LTI registration with the provided parameters. Note that updating the base tool configuration
  # of a registration that is associated with a Dynamic Registration will return a 422. All other fields can be updated
  # freely.
  #
  # @argument name [String] The name of the tool
  # @argument admin_nickname [String] The admin-configured friendly display name for the registration
  # @argument description [String] A description of the tool. Cannot exceed 2048 bytes.
  # @argument configuration [Lti::ToolConfiguration | Lti::LegacyConfiguration] The LTI 1.3 configuration for the tool. Note that updating the base tool configuration of a registration associated with a Dynamic Registration is not allowed.
  # @argument overlay [Lti::Overlay] The overlay configuration for the tool. Overrides values in the base configuration. Note that updating the overlay of a registration associated with a Dynamic Registration IS allowed.
  # @argument workflow_state [String, "on" | "off" | "allow"]
  #  The desired state for this registration/account binding. "allow" is only valid for Site Admin registrations.
  #
  # @example_request
  #
  #   This would update the specified LTI Registration, as well as its associated Developer Key
  #   and LTI Tool Configuration.
  #
  #   curl -X PUT 'https://<canvas>/api/v1/accounts/<account_id>/lti_registrations/<registration_id>' \
  #       -H "Authorization: Bearer <token>" \
  #       -H "Content-Type: application/json" \
  #       -d '{
  #             "vendor": "Example",
  #             "name": "An Example Tool",
  #             "admin_nickname": "A Great LTI Tool",
  #             "configuration": {
  #               "title": "Sample Tool",
  #               "description": "A sample LTI tool",
  #               "target_link_uri": "https://example.com/launch",
  #               "oidc_initiation_url": "https://example.com/oidc",
  #               "redirect_uris": ["https://example.com/redirect"],
  #               "scopes": ["https://purl.imsglobal.org/spec/lti-ags/scope/lineitem"],
  #               "placements": [
  #                 {
  #                   "placement": "course_navigation",
  #                   "enabled": true
  #                 }
  #               ],
  #               "launch_settings": {}
  #             }
  #           }'
  #
  # @returns Lti::Registration
  def update
    registration_params = params.permit(:admin_nickname, :vendor, :name, :description).to_h

    binding_params = {
      workflow_state: params[:workflow_state],
    }.compact

    update_params = {
      id: params[:id],
      account: @context,
      registration_params:,
      configuration_params:,
      overlay_params:,
      binding_params:,
      updated_by: @current_user
    }

    registration = Lti::UpdateRegistrationService.call(**update_params)

    render json: lti_registration_json(registration,
                                       @current_user,
                                       session,
                                       @context,
                                       includes: %i[account_binding
                                                    configuration
                                                    overlay
                                                    overlay_versions],
                                       account_binding: registration.account_binding_for(@context),
                                       overlay: registration.overlay_for(@context))
  rescue => e
    report_error(e)
    raise e
  end

  # @API Reset an LTI Registration to Defaults
  # Reset the specified LTI registration to its default settings in this context. This removes all customizations
  # that were present in the overlay associated with this context.
  #
  # @returns Lti::Registration
  #
  # @example_request
  #
  #   This would reset the specified LTI registration to its default settings
  #   curl -X PUT 'https://<canvas>/api/v1/accounts/<account_id>/lti_registrations/<registration_id>/reset' \
  #        -H "Authorization: Bearer <token>"
  def reset
    registration.overlay_for(@context)&.update!(data: {}, updated_by: @current_user)

    render json: lti_registration_json(registration,
                                       @current_user,
                                       session,
                                       @context,
                                       includes: %i[overlaid_configuration overlay overlay_versions],
                                       overlay: registration.overlay_for(@context))
  rescue => e
    report_error(e)
    raise e
  end

  # @API Delete an LTI Registration
  # Remove the specified LTI registration
  #
  # @returns Lti::Registration
  #
  # @example_request
  #
  #   This would delete the specified LTI registration
  #   curl -X DELETE 'https://<canvas>/api/v1/accounts/<account_id>/lti_registrations/<registration_id>' \
  #        -H "Authorization: Bearer <token>"
  def destroy
    unless @context == registration.account
      return render json: { errors: "registration does not belong to account" }, status: :bad_request
    end

    registration.destroy
    render json: lti_registration_json(registration,
                                       @current_user,
                                       session,
                                       @context,
                                       includes: %i[account_binding configuration overlay],
                                       account_binding: registration.account_binding_for(@context),
                                       overlay: registration.overlay_for(@context))
  rescue => e
    report_error(e)
    raise e
  end

  # @API Bind an LTI Registration to an Account
  # Enable or disable the specified LTI registration for the specified account.
  # To enable an inherited registration (eg from Site Admin), pass the registration's global ID.
  #
  # Only allowed for root accounts.
  #
  # <b>Specifics for Site Admin:</b>
  # "on" enables and locks the registration on for all root accounts.
  # "off" disables and hides the registration for all root accounts.
  # "allow" makes the registration visible to all root accounts, but accounts must bind it to use it.
  #
  # <b>Specifics for centrally-managed/federated consortia:</b>
  # Child root accounts may only bind registrations created in the same account.
  # For parent root account, binding also applies to all child root accounts.
  #
  # @argument workflow_state [Required, String, "on"|"off"|"allow"]
  #   The desired state for this registration/account binding. "allow" is only valid for Site Admin registrations.
  #
  # @returns Lti::RegistrationAccountBinding
  #
  # @example_request
  #
  #   This would enable the specified LTI registration for the specified account
  #   curl -X POST 'https://<canvas>/api/v1/accounts/<account_id>/lti_registrations/<registration_id>/bind' \
  #        -H "Authorization: Bearer <token>" \
  #        -H "Content-Type: application/json" \
  #        -d '{"workflow_state": "on"}'
  def bind
    Lti::AccountBindingService.call(
      account: @context,
      registration:,
      workflow_state: params.require(:workflow_state),
      user: @current_user
    ) => {lti_registration_account_binding:}

    render json: lti_registration_account_binding_json(lti_registration_account_binding, @current_user, session, @context)
  end

  # @API Search for Accounts and Courses
  # This is a utility endpoint used by the Canvas Apps UI and may not serve general use cases.
  #
  # Search for accounts and courses that match the search term on name, SIS id, or course code.
  # Returns bare-bones data about each account and course. Used to populate the search dropdowns
  # when managing LTI registration availability.
  #
  # @argument by_account_id [Optional, String] If provided, only searches within this account.
  # @argument search_term [Optional, String] String to search for in account names, SIS ids, or course codes.
  #
  # @returns ContextSearchResponse
  #
  # @example_request
  #
  #   This would search for accounts and courses matching the search term "example"
  #   curl -X GET 'https://<canvas>/api/v1/accounts/<account_id>/lti_registrations/context_search?search_term=example' \
  #        -H "Authorization: Bearer <token>"
  #
  def context_search
    account_id = params[:by_account_id]
    search_term = params[:search_term].to_s.strip
    can_read_sis = @context.grants_any_right?(@current_user, :read_sis, :manage_sis)

    account_scope = Account.active.where(root_account_id: @domain_root_account.id).or(Account.where(id: @domain_root_account.id))
    if account_id.present?
      subaccount_ids = Account.sub_account_ids_recursive(account_id)
      account_scope = account_scope.where(id: subaccount_ids + [account_id])
    end

    course_scope = Course.active.where(account: account_scope)

    if search_term.present?
      account_scope = account_scope.where("name ILIKE :s OR sis_source_id ILIKE :s", s: "%#{search_term}%")
      course_scope = course_scope.where("name ILIKE :s OR sis_source_id ILIKE :s OR course_code ILIKE :s", s: "%#{search_term}%")
    end

    accounts = account_scope.limit(20)
    courses = course_scope.limit(20)

    all_account_ids = (accounts.pluck(:id) + courses.pluck(:account_id)).uniq
    if all_account_ids.empty?
      return render json: { accounts: [], courses: [] }
    end

    account_chains = Account.account_chain_ids_for_multiple_accounts(all_account_ids)
                            # put highest-level account first and
                            # remove first (root) account from chain
                            .transform_values { |ids| ids.tap(&:pop).reverse }
    all_account_chain_ids = account_chains.values.flatten.uniq
    account_names = Account.where(id: all_account_chain_ids).pluck(:id, :name).to_h

    accounts_json = accounts.map do |account|
      display_path = account_chains[account.id].filter_map do |id|
        account_names[id] unless id == account.id # don't include the account itself in the display path
      end
      {
        id: account.id.to_s,
        name: account.name,
        sis_id: can_read_sis ? account.sis_source_id : nil,
        display_path:
      }
    end

    courses_json = courses.map do |course|
      display_path = account_chains[course.account_id].map { |id| account_names[id] }
      {
        id: course.id.to_s,
        name: course.name,
        sis_id: can_read_sis ? course.sis_source_id : nil,
        course_code: course.course_code,
        display_path:
      }
    end

    render json: {
      accounts: accounts_json,
      courses: courses_json
    }
  end

  private

  def render_configuration_errors(errors)
    render json: { errors: }, status: :unprocessable_entity
  end

  def configuration_params
    return @configuration_params if defined?(@configuration_params)

    @configuration_params = params[:configuration]&.to_unsafe_h

    if @configuration_params&.dig(:extensions).present?
      @configuration_params = Schemas::InternalLtiConfiguration.from_lti_configuration(@configuration_params)
    end

    @configuration_params = @configuration_params&.slice(*Schemas::InternalLtiConfiguration.allowed_base_properties)

    @configuration_params
  end

  def overlay_params
    @overlay_params ||= params[:overlay]&.to_unsafe_h
  end

  def validate_registration_params
    configuration = params[:configuration]
    overlay = params[:overlay]

    configuration = configuration.to_unsafe_h if configuration.is_a?(ActionController::Parameters)
    overlay = overlay.to_unsafe_h if overlay.is_a?(ActionController::Parameters)

    if configuration.present? && !configuration.is_a?(Hash)
      return render_configuration_errors(["configuration must be an object"])
    end

    if overlay.present? && !overlay.is_a?(Hash)
      return render_configuration_errors(["overlay must be an object"])
    end

    configuration_errors = if configuration&.dig(:extensions).present?
                             Schemas::LtiConfiguration.validation_errors(configuration, allow_nil: true)
                           elsif configuration.present?
                             Schemas::InternalLtiConfiguration.validation_errors(configuration, allow_nil: true)
                           end
    overlay_errors = Schemas::Lti::Overlay.validation_errors(overlay, allow_nil: true) if overlay.present?

    configuration_errors ||= []
    overlay_errors ||= []
    errors = configuration_errors + overlay_errors

    render_configuration_errors(errors) if errors.present?
  end

  # At the model level, setting an invalid workflow_state will silently change it to the
  # initial state ("off") without complaining, so enforce this here as part of the API contract.
  def validate_workflow_state
    return if workflow_state.nil? || %w[on off].include?(workflow_state)

    return if workflow_state == "allow" && context.site_admin?

    if workflow_state == "allow" && !context.site_admin?
      render_error(:invalid_workflow_state, "only site admin registrations can have a state of 'allow'")
    else
      render_error(:invalid_workflow_state, "workflow_state must be one of 'on', 'off', or 'allow'")
    end
  end

  def validate_list_params
    # Calling to_i on a non-number returns 0. This does mean we'll accept something like 10.5, though
    render_error("invalid_page", "page param should be an integer") unless params[:page].nil? || params[:page].to_i > 0
    render_error("invalid_dir", "dir param should be asc, desc, or empty") unless ["asc", "desc", nil].include?(params[:dir])

    valid_sort_fields = %w[name nickname lti_version installed installed_by updated_by updated on]
    render_error("invalid_sort", "#{params[:sort]} is not a valid field for sorting") unless [*valid_sort_fields, nil].include?(params[:sort])
  end

  def workflow_state
    params[:workflow_state]
  end

  def require_registration_params
    params.require(:configuration)
  end

  def restrict_dynamic_registration_updates
    return if configuration_params.blank?
    return if registration.ims_registration.blank?

    render_error(:tool_configuration_required, "Only manual configurations can be updated. Please create a new registration if you need to update the base tool configuration of a Dynamic Registration.")
  end

  def render_error(code, message, status: :unprocessable_entity)
    render json: { errors: [{ code:, message: }] }, status:
  end

  def registration
    @registration ||= Lti::Registration.active.find(params[:id])
  end

  def require_account_context_instrumented
    require_account_context
  rescue ActiveRecord::RecordNotFound => e
    report_error(e)
    raise e
  end

  def require_root_account_instrumented
    require_account_context
    unless @account.root_account?
      raise ActiveRecord::RecordNotFound
    end
  rescue ActiveRecord::RecordNotFound => e
    report_error(e)
    raise e
  end

  def require_feature_flag
    unless @account.feature_enabled?(:lti_registrations_page)
      respond_to do |format|
        format.html { render "shared/errors/404_message", status: :not_found }
        format.json { render_error(:not_found, "The specified resource does not exist.", status: :not_found) }
      end
    end
  end

  def require_lti_registrations_next_feature_flag
    unless @account.feature_enabled?(:lti_registrations_next)
      respond_to do |format|
        format.html { render "shared/errors/404_message", status: :not_found }
        format.json { render_error(:not_found, "The specified resource does not exist.", status: :not_found) }
      end
    end
  end

  def require_manage_lti_registrations
    require_context_with_permission(@context, :manage_lti_registrations)
  end

  def report_error(exception, code = nil)
    code ||= response_code_for_rescue(exception) if exception
    InstStatsd::Statsd.distributed_increment("canvas.lti_registrations_controller.request_error", tags: { action: action_name, code: })
  end

  def filter_registrations_by_search_query(registrations, search_terms)
    # all search terms must appear, but each can be in either the name,
    # admin_nickname, or vendor name. Remove the search terms from the list
    # as they are found -- keep the registration as a matching result if the
    # list is empty at the end.
    registrations.select do |registration|
      terms_to_find = search_terms.dup
      terms_to_find.delete_if do |term|
        attributes = %i[name admin_nickname vendor]
        attributes.any? do |attribute|
          registration[attribute]&.downcase&.include?(term)
        end
      end

      terms_to_find.empty?
    end
  end

  def inject_lti_usage_env
    js_env({
             LTI_USAGE: {
               env: Canvas.environment,
               region: Canvas.region,
               canvasBaseUrl: request.base_url,
               firstName: @current_user.short_name,
               locale: I18n.locale,
               rootAccountId: @account.id,
               rootAccountUuid: @account.uuid,
               isPremiumAccount: @account.feature_enabled?(:lti_usage_premium)
             },
           })

    remote_env({
                 ltiUsage: DynamicSettings.find("lti")["canvas_apps_lti_usage_url", failsafe: nil]
               })
  end
end
