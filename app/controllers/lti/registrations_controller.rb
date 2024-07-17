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
# @internal
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
#           "description": "The user that created this registration. Not always present.",
#           "example": { "type": "User" },
#           "$ref": "User"
#         },
#         "updated_by": {
#           "description": "The user that last updated this registration. Not always present.",
#           "example": { "type": "User" },
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
# @model Lti::ToolConfiguration
#     {
#       "id": "Lti::ToolConfiguration",
#       "description": "A Registration's Canvas-specific tool configuration. Tool-provided and standardized.",
#       "properties": {
#         "name": {
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
#         "launch_height": {
#           "description": "Default iframe height. Not valid for all placements. Overridable by placements.",
#           "example": 800,
#           "type": "number"
#         },
#         "launch_width": {
#           "description": "Default iframe width. Not valid for all placements. Overridable by placements.",
#           "example": 1000,
#           "type": "number"
#         },
#         "icon_url": {
#           "description": "Default icon URL. Not valid for all placements. Overridable by placements.",
#           "example": "https://mytool.com/icon.png",
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
#         "redirect_uris": {
#           "description": "1.3 specific. List of possible launch URLs for after the Canvas authorize redirect step",
#           "example": ["https://mytool.com/launch", "https://mytool.com/1_3/launch"],
#           "type": "array",
#           "items": { "type": "string" }
#         },
#         "public_jwk": {
#           "description": "1.3 specific. The tool's public JWK in JSON format. Discouraged in favor of a url hosting a JWK set.",
#           "example": { "e": "AQAB", "etc": "etc" },
#           "type": "object"
#         },
#         "public_jwk_url": {
#           "description": "1.3 specific. The tool-hosted URL containing its public JWK keyset.",
#           "example": "https://mytool.com/1_3/jwks",
#           "type": "string"
#         },
#         "scopes": {
#           "description": "1.3 specific. List of LTI scopes requested by the tool",
#           "example": ["https://purl.imsglobal.org/spec/lti-ags/scope/lineitem"],
#           "type": "array",
#           "items": { "type": "string" }
#         },
#         "oauth_compliant": {
#           "description": "1.1 specific. If true, query parameters from the launch URL will not be copied to the POST body.",
#           "example": false,
#           "type": "boolean"
#         },
#         "allow_membership_service_access": {
#           "description": "1.1 specific. If true, tool can access the 1.1 Membership Service.",
#           "example": true,
#           "type": "boolean"
#         },
#         "consumer_key": {
#           "description": "1.1 specific. Tool-provided key for authentication, serves similar purpose to 1.3 deployment id.",
#           "example": "a_fake_consumer_key",
#           "type": "string"
#         },
#         "shared_secret": {
#           "description": "1.1 specific. Tool-provided secret for authentication.",
#           "example": "a_fake_shared_secret_do_not_share",
#           "type": "string"
#         },
#         "prefer_sis_email": {
#           "description": "1.1 specific. If true, the tool will send the SIS email in the lis_person_contact_email_primary launch property",
#           "example": false,
#           "type": "boolean"
#         },
#         "placements": {
#           "description": "List of placements configured by the tool",
#           "example": [{ "type": "Lti::Placement" }],
#           "type": "array",
#           "items": { "$ref": "Lti::Placement" }
#         }
#       }
#     }
# @model Lti::Placement
#     {
#       "id": "Lti::Placement",
#       "description": "The tool's configuration for a specific placement",
#       "properties": {
#         "placement": {
#           "description": "The name of the placement.",
#           "example": "course_navigation",
#           "type": "string"
#         },
#         "canvas_icon_class": {
#           "description": "The HTML class name of an InstUI Icon. Used instead of an icon_url in select placements.",
#           "example": "icon-lti",
#           "type": "string"
#         },
#         "custom_fields": {
#           "description": "Placement-specific custom fields to send in the launch. Merged with tool-level custom fields.",
#           "example": { "special_placement_thing": "foo1234" },
#           "type": "object"
#         },
#         "default": {
#           "description": "Default display state for course_navigation. If 'enabled', will show in course sidebar. If 'disabled', will be hidden.",
#           "example": "disabled",
#           "type": "string"
#         },
#         "display_type": {
#           "description": "The Canvas layout to use when launching the tool. See the Navigation Placement docs.",
#           "example": "full_width_in_context",
#           "type": "string"
#         },
#         "enabled": {
#           "description": "If true, the tool will show in this placement. If false, it will not.",
#           "example": true,
#           "type": "boolean"
#         },
#         "icon_svg_path_64": {
#           "description": "An SVG to use instead of an icon_url. Only valid for global_navigation.",
#           "example": "M100,37L70.1,10.5v176H37...",
#           "type": "string"
#         },
#         "icon_url": {
#           "description": "Default icon URL. Not valid for all placements. Overrides tool-level icon_url.",
#           "example": "https://mytool.com/icon.png",
#           "type": "string"
#         },
#         "labels": {
#           "description": "Canvas-specific i18n for placement text. See the Navigation Placement docs.",
#           "example": { "en": "Hello World", "es": "Hola Mundo" },
#           "type": "object"
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
#         "message_type": {
#           "description": "An LTI-spec message type to use for this placement.",
#           "example": "LtiDeepLinkingRequest",
#           "type": "string"
#         },
#         "prefer_sis_email": {
#           "description": "1.1 specific. If true, the tool will send the SIS email in the lis_person_contact_email_primary launch property",
#           "example": true,
#           "type": "boolean"
#         },
#         "required_permissions": {
#           "description": "Comma-separated list of Canvas permission short names required for a user to launch from this placement.",
#           "example": "manage_course_content_edit,manage_course_content_read",
#           "type": "string"
#         },
#         "root_account_only": {
#           "description": "If set to true, the tool will not be shown in the account navigation for subaccounts. Only valid for account_navigation.",
#           "example": true,
#           "type": "boolean"
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
#         "target_link_uri": {
#           "description": "The 1.3 launch URL for this placement. Overrides tool-level target_link_uri.",
#           "example": "https://mytool.com/launch?placement=course_navigation",
#           "type": "string"
#         },
#         "text": {
#           "description": "Text to show in the placement. Overrides tool-level title.",
#           "example": "My Tool (Course Nav)",
#           "type": "string"
#         },
#         "windowTarget": {
#           "description": "When set to '_blank', opens placement in a new tab.",
#           "example": "_blank",
#           "type": "string"
#         },
#         "url": {
#           "description": "The 1.1 launch URL for this placement. Overrides tool-level url.",
#           "example": "https://mytool.com/launch?placement=course_navigation",
#           "type": "string"
#         },
#         "visibility": {
#           "description": "Specifies types of users that can see this placement. Only valid for some placements like course_navigation.",
#           "example": "admins",
#           "type": "string"
#         }
#       }
#     }
#
# @model Lti::RegistrationAccountBinding
#     {
#       "id": "Lti::RegistrationAccountBinding",
#       "description": "A binding between an Lti::Registration and an Account",
#       "properties": {
#         "id": {
#           "description": "The Canvas id of the binding",
#           "example": 1,
#           "type": "integer"
#         },
#         "account_id": {
#           "description": "The Canvas id of the binding's account",
#           "example": 1,
#           "type": "string"
#         },
#         "registration_id": {
#           "description": "The Canvas id of the binding's registration. Can be global",
#           "example": "10000000000001",
#           "type": "string"
#         },
#         "workflow_state": {
#           "description": "Represents the registration state for this account. On signifies fully enabled, Allow lets subcontexts enable if desired.",
#           "example": "active",
#           "type": "string",
#           "enum":
#           [
#             "on",
#             "off",
#             "allow"
#           ]
#         },
#         "created_at": {
#           "description": "Timestamp of the binding's creation",
#           "example": "2024-01-01T00:00:00Z",
#           "type": "string"
#         },
#         "updated_at": {
#           "description": "Timestamp of the binding's last update",
#           "example": "2024-01-01T00:00:00Z",
#           "type": "string"
#         },
#         "created_by": {
#           "description": "The user that created this binding. Not always present.",
#           "example": { "type": "User" },
#           "$ref": "User"
#         },
#         "updated_by": {
#           "description": "The user that last updated this binding. Not always present.",
#           "example": { "type": "User" },
#           "$ref": "User"
#         },
#         "root_account_id": {
#           "description": "The Canvas id of the root account",
#           "example": 1,
#           "type": "integer"
#         }
#       }
#     }
class Lti::RegistrationsController < ApplicationController
  before_action :require_account_context_instrumented
  before_action :require_feature_flag
  before_action :require_manage_lti_registrations
  before_action :require_dynamic_registration, only: [:destroy, :update]
  before_action :validate_workflow_state, only: :bind
  before_action :validate_list_params, only: :list

  include Api::V1::Lti::Registration

  def index
    set_active_tab "apps"
    add_crumb t("#crumbs.apps", "Apps")

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
  #   installed_by, updated_by, and on. Defaults to installed.
  #
  # @argument dir [String, "asc"|"desc"]
  #   The order to sort the given column by. Defaults to desc.
  #
  # @returns {"total": "integer", data: [Lti::Registration] }
  #
  # @example_request
  #
  #   This would return the specified LTI registration
  #   curl -X GET 'https://<canvas>/api/v1/accounts/<account_id>/registrations' \
  #        -H "Authorization: Bearer <token>"
  def list
    GuardRail.activate(:secondary) do
      eager_load_models = [
        { lti_registration_account_bindings: [:created_by, :updated_by] },
        :created_by, # registration's created_by
        :updated_by  # registration's updated_by
      ]

      # Get all registrations on this account, regardless of their bindings
      account_registrations = Lti::Registration.active
                                               .where(account_id: params[:account_id])
                                               .eager_load(eager_load_models)

      # Get all registration account bindings that are bound to the site admin account and that are "on,"
      # since they will apply to this account (and all accounts)
      forced_on_in_site_admin = Shard.default.activate do
        Lti::Registration.active
                         .where(account: Account.site_admin)
                         .where(lti_registration_account_bindings: { workflow_state: "on", account_id: Account.site_admin.id })
                         .eager_load(eager_load_models)
      end

      # Get all registration account bindings in this account, then fetch the registrations from their own shards
      # Omit registrations that were found in the "account_registrations" list; we're only looking for ones that
      # are uniquely being inherited from a different account.
      inherited_on_registration_bindings = Lti::RegistrationAccountBinding.where(workflow_state: "on")
                                                                          .where(account_id: params[:account_id])
                                                                          .where.not(registration_id: account_registrations.map(&:id))

      registration_ids = inherited_on_registration_bindings.map(&:registration_id)
      inherited_on_registrations = Shard.partition_by_shard(registration_ids) do |registration_ids_for_shard|
        Lti::Registration.where(id: registration_ids_for_shard).eager_load(eager_load_models)
      end.flatten

      all_registrations = account_registrations + forced_on_in_site_admin + inherited_on_registrations

      search_terms = params[:query]&.downcase&.split
      all_registrations = filter_registrations_by_search_query(all_registrations, search_terms) if search_terms

      # sort by the 'sort' parameter, or installed (a.k.a. created_at) if no parameter was given
      sort_field = params[:sort]&.to_sym || :installed

      sorted_registrations = all_registrations.sort_by do |reg|
        case sort_field
        when :name
          reg.name.downcase
        when :nickname
          reg.admin_nickname&.downcase || ""
        when :lti_version
          reg.lti_version
        when :installed
          reg.created_at
        when :installed_by
          reg.created_by&.name&.downcase || ""
        when :updated_by
          reg.updated_by&.name&.downcase || ""
        when :on
          reg.account_binding_for(@account)&.workflow_state || ""
        end
      end

      sorted_registrations.reverse! unless params[:dir] == "asc"

      per_page = Api.per_page_for(self, default: 15)
      paginated_registrations, _metadata = Api.jsonapi_paginate(sorted_registrations, self, url_for, { per_page: })
      render json: {
        total: all_registrations.size,
        data: lti_registrations_json(paginated_registrations, @current_user, session, @context, includes: [:account_binding])
      }
    end
  rescue => e
    report_error(e)
    raise e
  end

  # @API Show an LTI Registration
  # Return details about the specified LTI registration, including the
  # configuration and account binding.
  #
  # @returns Lti::Registration
  #
  # @example_request
  #
  #   This would return the specified LTI registration
  #   curl -X GET 'https://<canvas>/api/v1/accounts/<account_id>/registrations/<registration_id>' \
  #        -H "Authorization: Bearer <token>"
  def show
    GuardRail.activate(:secondary) do
      registration = Lti::Registration.active.find(params[:id])
      render json: lti_registration_json(registration, @current_user, session, @context, includes: [:account_binding, :configuration])
    end
  rescue => e
    report_error(e)
    raise e
  end

  # @API Update an LTI Registration
  # Update the specified LTI registration with the provided parameters
  #
  # @argument admin_nickname [String] The admin-configured friendly display name for the registration
  #
  # @example_request
  #
  #   This would update the specified LTI registration
  #   curl -X PUT 'https://<canvas>/api/v1/accounts/<account_id>/registrations/<registration_id>' \
  #       -H "Authorization: Bearer <token>" \
  #       -d 'admin_nickname=A New Nickname'
  #
  # @returns Lti::Registration
  def update
    registration.update!(update_params)
    render json: lti_registration_json(registration, @current_user, session, @context)
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
  #   curl -X DELETE 'https://<canvas>/api/v1/accounts/<account_id>/registrations/<registration_id>' \
  #        -H "Authorization: Bearer <token>"
  def destroy
    registration.destroy
    render json: lti_registration_json(registration, @current_user, session, @context, includes: [:account_binding, :configuration])
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
  #   curl -X POST 'https://<canvas>/api/v1/accounts/<account_id>/registrations/<registration_id>/bind' \
  #        -H "Authorization: Bearer <token>" \
  #        -H "Content-Type: application/json" \
  #        -d '{"workflow_state": "on"}'
  def bind
    account_binding = Lti::RegistrationAccountBinding.find_or_initialize_by(account: @context, registration:)

    if account_binding.new_record?
      account_binding.created_by = @current_user
    end

    account_binding.updated_by = @current_user
    account_binding.workflow_state = params[:workflow_state]

    if account_binding.save
      render json: lti_registration_account_binding_json(account_binding, @current_user, session, @context)
    else
      render json: account_binding.errors, status: :unprocessable_entity
    end
  end

  private

  def update_params
    params.permit(:admin_nickname).merge({ updated_by: @current_user })
  end

  # At the model level, setting an invalid workflow_state will silently change it to the
  # initial state ("off") without complaining, so enforce this here as part of the API contract.
  def validate_workflow_state
    return if %w[on off allow].include?(params.require(:workflow_state))

    render_error(:invalid_workflow_state, "workflow_state must be one of 'on', 'off', or 'allow'")
  end

  def validate_list_params
    # Calling to_i on a non-number returns 0. This does mean we'll accept something like 10.5, though
    render_error("invalid_page", "page param should be an integer") unless params[:page].nil? || params[:page].to_i > 0
    render_error("invalid_dir", "dir param should be asc, desc, or empty") unless ["asc", "desc", nil].include?(params[:dir])

    valid_sort_fields = %w[name nickname lti_version installed installed_by updated_by on]
    render_error("invalid_sort", "#{params[:sort]} is not a valid field for sorting") unless [*valid_sort_fields, nil].include?(params[:sort])
  end

  def require_dynamic_registration
    return if registration.dynamic_registration?

    render_error(:dynamic_registration_required, "Temporarily, only Registrations created using LTI Dynamic Registration can be modified")
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

  def require_feature_flag
    unless @context.root_account.feature_enabled?(:lti_registrations_page)
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
    InstStatsd::Statsd.increment("canvas.lti_registrations_controller.request_error", tags: { action: action_name, code: })
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
end
