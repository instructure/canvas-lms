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

# @API Roles
# API for managing account- and course-level roles, and their associated permissions.
#
# @model RolePermissions
#     {
#       "id": "RolePermissions",
#       "description": "",
#       "properties": {
#         "enabled": {
#           "description": "Whether the role has the permission",
#           "example": true,
#           "type": "boolean"
#         },
#         "locked": {
#           "description": "Whether the permission is locked by this role",
#           "example": false,
#           "type": "boolean",
#           "default": false
#         },
#         "applies_to_self": {
#           "description": "Whether the permission applies to the account this role is in. Only present if enabled is true",
#           "example": true,
#           "type": "boolean",
#           "default": true
#         },
#         "applies_to_descendants": {
#           "description": "Whether the permission cascades down to sub accounts of the account this role is in. Only present if enabled is true",
#           "example": false,
#           "type": "boolean",
#           "default": true
#         },
#         "readonly": {
#           "description": "Whether the permission can be modified in this role (i.e. whether the permission is locked by an upstream role).",
#           "example": false,
#           "type": "boolean",
#           "default": false
#         },
#         "explicit": {
#           "description": "Whether the value of enabled is specified explicitly by this role, or inherited from an upstream role.",
#           "example": true,
#           "type": "boolean",
#           "default": false
#         },
#         "prior_default": {
#           "description": "The value that would have been inherited from upstream if the role had not explicitly set a value. Only present if explicit is true.",
#           "example": false,
#           "type": "boolean"
#         }
#       }
#     }
#
# @model Role
#     {
#       "id": "Role",
#       "description": "",
#       "properties": {
#         "id": {
#           "description": "The id of the role",
#           "example": 1,
#           "type": "integer"
#          },
#         "label": {
#           "description": "The label of the role.",
#           "example": "New Role",
#           "type": "string"
#         },
#         "role": {
#           "description": "The label of the role. (Deprecated alias for 'label')",
#           "example": "New Role",
#           "type": "string"
#         },
#         "base_role_type": {
#           "description": "The role type that is being used as a base for this role. For account-level roles, this is 'AccountMembership'. For course-level roles, it is an enrollment type.",
#           "example": "AccountMembership",
#           "type": "string"
#         },
#         "is_account_role": {
#           "description": "Whether this role applies to account memberships (i.e., not linked to an enrollment in a course).",
#           "example": true,
#           "type": "boolean"
#         },
#         "account": {
#           "description": "JSON representation of the account the role is defined in.",
#           "example": {"id": 1019, "name": "CGNU", "parent_account_id": 73, "root_account_id": 1, "sis_account_id": "cgnu"},
#           "type": "object",
#           "$ref": "Account"
#         },
#         "workflow_state": {
#           "description": "The state of the role: 'active', 'inactive', or 'built_in'",
#           "example": "active",
#           "type": "string"
#         },
#         "created_at": {
#           "description": "The date and time the role was created.",
#           "example": "2020-12-01T16:20:00-06:00",
#           "type": "datetime"
#         },
#         "last_updated_at": {
#           "description": "The date and time the role was last updated.",
#           "example": "2023-10-31T23:59:00-06:00",
#           "type": "datetime"
#         },
#         "permissions": {
#           "description": "A dictionary of permissions keyed by name (see 'List assignable permissions' API).",
#           "example": {"read_course_content": {"enabled": true, "locked": false, "readonly": false, "explicit": true, "prior_default": false}, "read_course_list": {"enabled": true, "locked": true, "readonly": true, "explicit": false}, "read_question_banks": {"enabled": false, "locked": true, "readonly": false, "explicit": true, "prior_default": false}, "read_reports": {"enabled": true, "locked": false, "readonly": false, "explicit": false}},
#           "type": "object",
#           "key": { "type": "string" },
#           "value": { "$ref": "RolePermissions" }
#         }
#       }
#     }
#
# @model Permission
#     {
#       "id": "Permission",
#       "description": "A permission that can be granted to a role",
#       "properties": {
#         "key": {
#           "description": "The API identifier for the permission",
#           "example": "manage_lti_add",
#           "type": "string"
#         },
#         "label": {
#           "description": "The human-readable label for the permission",
#           "example": "LTI - add",
#           "type": "string"
#         },
#         "group": {
#           "description": "The group this permission belongs to, if it is part of a granular permission group",
#           "example": "manage_lti",
#           "type": "string"
#         },
#         "group_label": {
#           "description": "The human-readable label for the group this permission belongs to",
#           "example": "Manage LTI",
#           "type": "string"
#         },
#         "available_to": {
#           "description": "The base role types this permission can be enabled for",
#           "example": ["AccountAdmin", "AccountMembership", "TeacherEnrollment", "TaEnrollment", "DesignerEnrollment"],
#           "type": "array",
#           "items": {"type": "string"}
#         },
#         "true_for": {
#           "description": "The base role types this permission is enabled for by default",
#           "example": ["AccountAdmin", "TeacherEnrollment", "TaEnrollment", "DesignerEnrollment"],
#           "type": "array",
#           "items": {"type": "string"}
#         }
#       }
#     }
#
class RoleOverridesController < ApplicationController
  before_action :require_context

  include HorizonMode

  OVERRIDE_VALUES = %w[checked unchecked].freeze

  before_action :load_canvas_career, only: [:index]

  before_action :require_role, only: %i[activate_role remove_role update show]

  # @API List roles
  # A paginated list of the roles available to an account.
  #
  # @argument account_id [Required, String]
  #   The id of the account to retrieve roles for.
  #
  # @argument state[] [String, "active"|"inactive"]
  #   Filter by role state. If this argument is omitted, only 'active' roles are
  #   returned.
  #
  # @argument show_inherited [Boolean]
  #   If this argument is true, all roles inherited from parent accounts will
  #   be included.
  #
  # @returns [Role]
  def api_index
    if authorized_action(@context, @current_user, :manage_role_overrides)
      route = polymorphic_url([:api, :v1, @context, :roles])
      states = params[:state].to_a.reject { |s| %w[active inactive].exclude?(s) }
      states = %w[active] if states.empty?

      roles = []
      roles += Role.visible_built_in_roles(root_account_id: @context.resolved_root_account_id) if states.include?("active")

      scope = value_to_boolean(params[:show_inherited]) ? @context.available_custom_roles(true) : @context.roles
      roles += scope.where(workflow_state: states).order(:id).to_a

      roles = Api.paginate(roles, self, route)
      ActiveRecord::Associations.preload(roles, :account)
      preloaded_overrides = RoleOverride.preload_overrides(@context, roles)
      render json: roles.map { |role| role_json(@context, role, @current_user, session, preloaded_overrides:) }
    end
  end

  def index
    if authorized_action(@context, @current_user, :manage_role_overrides)

      preloaded_overrides = RoleOverride.preload_overrides(@context, @context.available_account_roles)
      account_role_data = @context.available_account_roles.map do |role|
        role_json(@context, role, @current_user, session, preloaded_overrides:)
      end

      preloaded_overrides = RoleOverride.preload_overrides(@context, @context.available_course_roles)
      course_role_data = @context.available_course_roles.map do |role|
        role_json(@context, role, @current_user, session, preloaded_overrides:)
      end

      permission_groups = Permissions.permission_groups(@context).transform_values do |group_info|
        {
          label: group_info[:label].call,
          subtitle: group_info[:subtitle].call
        }.tap do |h|
          h[:course_subtitle] = group_info[:course_subtitle].call if group_info[:course_subtitle]
        end
      end

      js_env({
               ACCOUNT_ROLES: account_role_data,
               COURSE_ROLES: course_role_data,
               ACCOUNT_PERMISSIONS: account_permissions(@context),
               COURSE_PERMISSIONS: course_permissions(@context),
               ACCOUNT_ENABLE_ALERTS: @context.settings[:enable_alerts],
               PERMISSION_GROUPS: permission_groups
             })

      add_crumb t "Permissions"
      js_bundle :permissions
      css_bundle :permissions
      set_active_tab "permissions"
      page_has_instui_topnav
    end
  end

  # @API Get a single role
  # Retrieve information about a single role
  #
  # @argument account_id [Required, String]
  #   The id of the account containing the role
  #
  # @argument role_id [Required, Integer]
  #   The unique identifier for the role
  #
  # @argument role [String, Deprecated]
  #   The name for the role
  #
  # @returns Role
  def show
    if authorized_action(@context, @current_user, :manage_role_overrides)
      render json: role_json(@context, @role, @current_user, session)
    end
  end

  include Api::V1::Role

  # @API Create a new role
  # Create a new course-level or account-level role.
  #
  # @argument label [String, Required]
  #   Label for the role.
  #
  # @argument role [String, Deprecated]
  #   Deprecated alias for label.
  #
  # @argument base_role_type [String, "AccountMembership"|"StudentEnrollment"|"TeacherEnrollment"|"TaEnrollment"|"ObserverEnrollment"|"DesignerEnrollment"]
  #   Specifies the role type that will be used as a base
  #   for the permissions granted to this role.
  #
  #   Defaults to 'AccountMembership' if absent
  #
  # @argument permissions[<X>][explicit] [Boolean]
  #
  # @argument permissions[<X>][enabled] [Boolean]
  #   If explicit is 1 and enabled is 1, permission <X> will be explicitly
  #   granted to this role. If explicit is 1 and enabled has any other value
  #   (typically 0), permission <X> will be explicitly denied to this role. If
  #   explicit is any other value (typically 0) or absent, or if enabled is
  #   absent, the value for permission <X> will be inherited from upstream.
  #   Ignored if permission <X> is locked upstream (in an ancestor account).
  #
  #   May occur multiple times with unique values for <X>. Recognized
  #   permission names for <X> can be found on the
  #   {file:file.permissions.html Permissions list page}.
  #
  #   Some of these permissions are applicable only for roles on the site admin
  #   account, on a root account, or for course-level roles with a particular base role type;
  #   if a specified permission is inapplicable, it will be ignored.
  #
  #   Additional permissions may exist based on installed plugins.
  #
  #   A comprehensive list of all permissions are available:
  #
  #   Course Permissions PDF: http://bit.ly/cnvs-course-permissions
  #
  #   Account Permissions PDF: http://bit.ly/cnvs-acct-permissions
  #
  # @argument permissions[<X>][locked] [Boolean]
  #   If the value is 1, permission <X> will be locked downstream (new roles in
  #   subaccounts cannot override the setting). For any other value, permission
  #   <X> is left unlocked. Ignored if permission <X> is already locked
  #   upstream. May occur multiple times with unique values for <X>.
  #
  # @argument permissions[<X>][applies_to_self] [Boolean]
  #   If the value is 1, permission <X> applies to the account this role is in.
  #   The default value is 1. Must be true if applies_to_descendants is false.
  #   This value is only returned if enabled is true.
  #
  # @argument permissions[<X>][applies_to_descendants] [Boolean]
  #   If the value is 1, permission <X> cascades down to sub accounts of the
  #   account this role is in. The default value is 1.  Must be true if
  #   applies_to_self is false.This value is only returned if enabled is true.
  #
  # @example_request
  #   curl 'https://<canvas>/api/v1/accounts/<account_id>/roles.json' \
  #        -H "Authorization: Bearer <token>" \
  #        -F 'label=New Role' \
  #        -F 'permissions[read_course_content][explicit]=1' \
  #        -F 'permissions[read_course_content][enabled]=1' \
  #        -F 'permissions[read_course_list][locked]=1' \
  #        -F 'permissions[read_question_banks][explicit]=1' \
  #        -F 'permissions[read_question_banks][enabled]=0' \
  #        -F 'permissions[read_question_banks][locked]=1'
  #
  # @returns Role
  def add_role
    return unless authorized_action(@context, @current_user, :manage_role_overrides)

    name = api_request? ? (params[:label].presence || params[:role]) : params[:role_type]

    if api_request?
      return render json: { message: "missing required parameter 'role'" }, status: :bad_request if name.blank?

      used_names = @context.available_roles.map(&:name)
      return render json: { message: "role name #{name} already in use" }, status: :bad_request if used_names.include?(name)
    end

    base_role_type = params[:base_role_type] || Role::DEFAULT_ACCOUNT_TYPE
    role = @context.roles.build(name:)
    role.base_role_type = base_role_type
    role.workflow_state = "active"
    role.deleted_at = nil
    unless role.save
      if api_request?
        render json: role.errors, status: :bad_request
      else
        flash[:error] = t(:update_failed_notice, "Role creation failed")
        redirect_to named_context_url(@context, :context_permissions_url, account_roles: params[:account_roles])
      end
      return
    end

    unless api_request?
      redirect_to named_context_url(@context, :context_permissions_url, account_roles: params[:account_roles])
      return
    end

    # allow setting permissions immediately through API
    begin
      set_permissions_for(role, @context, params[:permissions])
    rescue BadPermissionSettingError => e
      return render json: { message: e }, status: :bad_request
    end

    # Add base_role_type_label for this role
    json = role_json(@context, role, @current_user, session)

    if (base_role = RoleOverride.enrollment_type_labels(@context).find { |br| br[:base_role_name] == base_role_type })
      json["base_role_type_label"] = base_role[:label].call
    end

    render json:
  end

  # @API Deactivate a role
  # Deactivates a custom role.  This hides it in the user interface and prevents it
  # from being assigned to new users.  Existing users assigned to the role will
  # continue to function with the same permissions they had previously.
  # Built-in roles cannot be deactivated.
  #
  # @argument role_id [Required, Integer]
  #   The unique identifier for the role
  #
  # @argument role [String, Deprecated]
  #   The name for the role
  #
  # @returns Role
  def remove_role
    if authorized_action(@context, @current_user, :manage_role_overrides)
      if @role.inactive?
        return render json: { message: t("cannot_deactivate_inactive_role", "Cannot deactivate an already inactive role") }, status: :bad_request
      elsif @role.built_in?
        return render json: { message: t("cannot_remove_built_in_role", "Cannot remove a built-in role") }, status: :bad_request
      end
      raise ActiveRecord::RecordNotFound unless @role.account == @context

      @role.deactivate!
      respond_to do |format|
        format.html { redirect_to named_context_url(@context, :context_permissions_url, account_roles: params[:account_roles]) }
        format.json { render json: role_json(@context, @role, @current_user, session) }
      end
    end
  end

  # @API Activate a role
  # Re-activates an inactive role (allowing it to be assigned to new users)
  #
  # @argument role_id [Required, Integer]
  #   The unique identifier for the role
  #
  # @argument role [Deprecated, String]
  #   The name for the role
  #
  # @returns Role
  def activate_role
    return unless authorized_action(@context, @current_user, :manage_role_overrides)

    if Role.where(account: @context, name: @role.name, workflow_state: "active").exists?
      return render json: { message: t("An active role already exists with that name") }, status: :bad_request
    end

    if @role.inactive?
      @role.activate!
      render json: role_json(@context, @role, @current_user, session)
    else
      render json: { message: t("no_role_found", "Role not found") }, status: :bad_request
    end
  end

  def create
    if authorized_action(@context, @current_user, :manage_role_overrides)
      roles = if params[:account_roles] || @context == Account.site_admin
                @context.available_account_roles(true)
              else
                @context.available_course_roles(true)
              end
      if params[:permissions]
        RoleOverride.permissions.each_key do |key|
          next unless params[:permissions][key]

          roles.each do |role|
            next unless (settings = params[:permissions][key][role.id.to_s] || params[:permissions][key][role.id])

            override = settings[:override] == "checked" if OVERRIDE_VALUES.include?(settings[:override])
            locked = settings[:locked] == "true" if settings[:locked]
            RoleOverride.manage_role_override(@context, role, key.to_s, override:, locked:)
          end
        end
      end
      flash[:notice] = t "notices.saved", "Changes Saved Successfully."
      redirect_to named_context_url(@context, :context_permissions_url, account_roles: params[:account_roles])
    end
  end

  # @API Update a role
  # Update permissions for an existing role.
  #
  # Recognized roles are:
  # * TeacherEnrollment
  # * StudentEnrollment
  # * TaEnrollment
  # * ObserverEnrollment
  # * DesignerEnrollment
  # * AccountAdmin
  # * Any previously created custom role
  #
  # @argument label [String]
  #   The label for the role. Can only change the label of a custom role that belongs directly to the account.
  #
  # @argument permissions[<X>][explicit] [Boolean]
  # @argument permissions[<X>][enabled] [Boolean]
  #   These arguments are described in the documentation for the
  #   {api:RoleOverridesController#add_role add_role method}.
  #   The list of available permissions can be found on the
  #   {file:file.permissions.html Permissions list page}.
  #
  # @argument permissions[<X>][applies_to_self] [Boolean]
  #   If the value is 1, permission <X> applies to the account this role is in.
  #   The default value is 1. Must be true if applies_to_descendants is false.
  #   This value is only returned if enabled is true.
  #
  # @argument permissions[<X>][applies_to_descendants] [Boolean]
  #   If the value is 1, permission <X> cascades down to sub accounts of the
  #   account this role is in. The default value is 1.  Must be true if
  #   applies_to_self is false.This value is only returned if enabled is true.
  #
  # @example_request
  #   curl https://<canvas>/api/v1/accounts/:account_id/roles/2 \
  #     -X PUT \
  #     -H 'Authorization: Bearer <access_token>' \
  #     -F 'label=New Role Name' \
  #     -F 'permissions[manage_groups][explicit]=1' \
  #     -F 'permissions[manage_groups][enabled]=1' \
  #     -F 'permissions[manage_groups][locked]=1' \
  #     -F 'permissions[send_messages][explicit]=1' \
  #     -F 'permissions[send_messages][enabled]=0'
  #
  # @returns Role
  def update
    return unless authorized_action(@context, @current_user, :manage_role_overrides)

    if (name = params[:label].presence) && @role.label != name
      if @role.built_in?
        return render json: { message: "cannot update the 'label' for a built-in role" }, status: :bad_request
      elsif @role.account != @context
        return render json: { message: "cannot update the 'label' for an inherited role" }, status: :bad_request
      else
        @role.name = name
        unless @role.save
          return render json: @role.errors, status: :bad_request
        end
      end
    end

    begin
      set_permissions_for(@role, @context, params[:permissions])
      render json: role_json(@context, @role, @current_user, session)
    rescue BadPermissionSettingError => e
      render json: { message: e }, status: :bad_request
    end
  end

  # @API List assignable permissions
  # List all permissions that can be granted to roles in the given account.
  #
  # This returns largely the same information documented on the {file:file.permissions.html Permissions list page},
  # with a few caveats:
  # * Permission labels and group labels returned by this API are localized (the same text visible in the web UI).
  # * This API includes permissions added by plugins.
  # * This API excludes permissions that are disabled in or otherwise do not apply to the given account.
  #
  # @argument search_term [String]
  #  If provided, return only permissions whose key, label, group, or group_label match the search string.
  #
  # @returns [Permission]
  def manageable_permissions
    if authorized_action(@context, @current_user, :manage_role_overrides)
      perms = RoleOverride.manageable_permissions(@context)

      perms.transform_values! do |info|
        {
          label: info[:label].call,
          available_to: info[:available_to],
          true_for: info[:true_for]
        }.tap do |h|
          h[:group] = info[:group].to_s if info[:group]
          h[:group_label] = Permissions.group_label(info[:group]) if info[:group]
        end
      end
      if params[:search_term].present?
        search = params[:search_term].downcase
        perms.select! do |key, info|
          key.to_s.include?(search) ||
            info[:label].downcase.include?(search) ||
            info[:group]&.downcase&.include?(search) ||
            info[:group_label]&.downcase&.include?(search)
        end
      end

      render json: perms.map { |key, info| { key: }.merge(info) }
    end
  end

  # Internal API endpoint
  # Used for checking Canvas permissions from Catalog
  # Could be generalized for other use cases by adding to the whitelist

  def check_account_permission
    whitelist = %w[manage_catalog]
    permission = params[:permission]

    if whitelist.include?(permission)
      render json: {
        permission:,
        granted: @context.grants_right?(@current_user, permission.to_sym)
      }
    else
      render json: { message: t("Permission not found") },
             status: :bad_request
    end
  end

  # Internal: Get role from params or return error. Used as before filter.
  #
  # Returns found role or false (to halt execution).
  def require_role
    @role = @context.get_role_by_id(params[:id])
    @role ||= @context.get_role_by_name(params[:id]) # for backwards-compatibility :/
    unless @role && !@role.deleted?
      if api_request?
        render json: {
                 message: "role not found"
               },
               status: :not_found
      else
        redirect_to named_context_url(@context,
                                      :context_permissions_url,
                                      account_roles: params[:account_roles])
      end

      return false
    end

    @role
  end
  protected :require_role

  class BadPermissionSettingError < StandardError; end

  # Internal: Loop through and set permission on role given in params.
  #
  # role - The role to set permissions for.
  # context - The current context.
  # permissions - The permissions from the request params.
  def set_permissions_for(role, context, permissions)
    return true if permissions.blank?

    manageable_permissions =
      if role.course_role?
        RoleOverride.manageable_permissions(context, role.base_role_type)
      else
        RoleOverride.manageable_permissions(context)
      end

    # Hash of permission names and groups for easier updating. Make everything
    # an array (even though only grouped permissions will have more then one
    # element) so we can use the same logic for updating grouped and ungrouped permissions
    grouped_permissions = Hash.new { |h, k| h[k] = [] }.with_indifferent_access
    manageable_permissions.each do |permission_name, permission|
      grouped_permissions[permission_name] << { name: permission_name, disable_locking: permission.key?(:group) }
      if permission.key?(:group)
        current_override = context.role_overrides.where(permission: permission_name, role_id: role.id).first
        grouped_permissions[permission[:group]] << { name: permission_name, disable_locking: false, currently: current_override&.enabled }
      end
    end

    RoleOverride.transaction do
      permissions.each do |permission_or_group_name, permission_updates|
        next if value_to_boolean(permission_updates[:readonly])

        target_permissions = grouped_permissions[permission_or_group_name]
        next if target_permissions.empty?

        if permission_updates.key?(:locked)
          if target_permissions.any? { |permission| permission[:disable_locking] }
            raise BadPermissionSettingError, t("Cannot change locked status on granular permission")
          else
            locked = value_to_boolean(permission_updates[:locked])
          end
        end

        if permission_updates.key?(:enabled) && value_to_boolean(permission_updates[:explicit])
          override = value_to_boolean(permission_updates[:enabled])
        end

        if permission_updates.key? :applies_to_self
          applies_to_self = value_to_boolean(permission_updates[:applies_to_self])
        end

        if permission_updates.key? :applies_to_descendants
          applies_to_descendants = value_to_boolean(permission_updates[:applies_to_descendants])
        end

        if applies_to_descendants == false && applies_to_self == false
          raise BadPermissionSettingError, t("Permission must be enabled for someone")
        end

        target_permissions.each do |permission|
          perm_override = (value_to_boolean(permission_updates[:explicit]) && override.nil?) ? permission[:currently] : override
          RoleOverride.manage_role_override(
            context,
            role,
            permission[:name].to_s,
            override: perm_override,
            locked:,
            applies_to_self:,
            applies_to_descendants:
          )
        end
      end
    end
  end
  protected :set_permissions_for

  private

  def course_permissions(context)
    site_admin = {
      group_name: t("site_admin_permissions", "Site Admin Permissions"),
      group_permissions: [],
      context_type: "Siteadmin"
    }
    account = {
      group_name: t("account_permissions", "Account Permissions"),
      group_permissions: [],
      context_type: "Account"
    }
    course = {
      group_name: t("course_permissions", "Course & Account Permissions"),
      group_permissions: [],
      context_type: "Course"
    }

    RoleOverride.manageable_permissions(context).each do |p|
      hash = { label: p[1][:label].call, permission_name: p[0] }
      if p[1].key?(:group)
        hash[:granular_permission_group] = p[1][:group]
      end

      # Check to see if the base role name is in the list of other base role names in p[1]
      is_course_permission = !!Role::ENROLLMENT_TYPES.intersect?(p[1][:available_to])

      if p[1][:account_only]
        if p[1][:account_only] == :site_admin
          site_admin[:group_permissions] << hash if is_course_permission
        elsif is_course_permission
          account[:group_permissions] << hash
        end
      elsif is_course_permission
        course[:group_permissions] << hash
      end
    end

    res = []
    res << site_admin if site_admin[:group_permissions].any?
    res << account if account[:group_permissions].any?
    res << course if course[:group_permissions].any?

    res.each do |pg|
      pg[:group_permissions].sort_by! { |p| p[:label] }
    end

    res
  end

  # Returns a hash with the available permissions grouped by groups of permissions. Permission hash looks like this
  #
  # ie:
  #   {
  #     :group_name => "Example Name",
  #     :group_permissions => [
  #       {
  #         :label => "Some Label"
  #         :permission_name => "Some Permission Name"
  #       },
  #       {
  #         :label => "Some Label"
  #         :permission_name => "Some Permission Name"
  #       }
  #     ]
  # context - the current context
  def account_permissions(context)
    site_admin = {
      group_name: t("site_admin_permissions", "Site Admin Permissions"),
      group_permissions: [],
      context_type: "Siteadmin"
    }
    account = {
      group_name: t("account_permissions", "Account Permissions"),
      group_permissions: [],
      context_type: "Account"
    }
    course = {
      group_name: t("course_permissions", "Course & Account Permissions"),
      group_permissions: [],
      context_type: "Course"
    }
    admin_tools = { group_name: t("admin_tools_permissions", "Admin Tools"), group_permissions: [] }

    # Add group_permissions
    RoleOverride.manageable_permissions(context).each do |p|
      next if !context.root_account? && p[0].to_s == "manage_developer_keys"

      hash = { label: p[1][:label].call, permission_name: p[0] }
      if p[1].key?(:group)
        hash[:granular_permission_group] = p[1][:group]
      end

      if p[1][:account_only]
        if p[1][:account_only] == :site_admin
          site_admin[:group_permissions] << hash
        elsif p[1][:admin_tool]
          admin_tools[:group_permissions] << hash
        else
          account[:group_permissions] << hash
        end
      else
        course[:group_permissions] << hash
      end
    end

    res = []
    res << site_admin if site_admin[:group_permissions].any?
    res << account if account[:group_permissions].any?
    res << admin_tools if admin_tools[:group_permissions].any?
    res << course if course[:group_permissions].any?

    res.each do |pg|
      pg[:group_permissions].sort_by! { |p| p[:label] }
    end

    res
  end
end
