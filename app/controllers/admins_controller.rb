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

# @API Admins
# Manage account role assignments
#
# @model Admin
#    {
#       "id": "Admin",
#       "required": ["id"],
#       "properties": {
#         "id": {
#           "description": "The unique identifier for the account role/user assignment.",
#           "example": 1023,
#           "type": "integer"
#         },
#         "role": {
#           "description": "The account role assigned. This can be 'AccountAdmin' or a user-defined role created by the Roles API.",
#           "example": "AccountAdmin",
#           "type": "string"
#         },
#         "user": {
#           "description": "The user the role is assigned to. See the Users API for details.",
#           "$ref": "User"
#         },
#         "workflow_state": {
#           "description": "The status of the account role/user assignment.",
#           "type": "string",
#           "example": "deleted"
#         }
#       }
#    }
class AdminsController < ApplicationController
  before_action :require_user
  before_action :get_context

  include Api::V1::Admin

  # @API Make an account admin
  #
  # Flag an existing user as an admin within the account.
  #
  # @argument user_id [Required, Integer]
  #   The id of the user to promote.
  #
  # @argument role [String]
  #   [DEPRECATED] The user's admin relationship with the account will be
  #   created with the given role. Defaults to 'AccountAdmin'.
  #
  # @argument role_id [Integer]
  #   The user's admin relationship with the account will be created with the given role. Defaults to the built-in role for 'AccountAdmin'.
  #
  # @argument send_confirmation [Boolean]
  #   Send a notification email to
  #   the new admin if true. Default is true.
  #
  # @returns Admin
  def create
    user = api_find(User, params[:user_id])
    raise(ActiveRecord::RecordNotFound, "Couldn't find User with API id '#{params[:user_id]}'") unless SisPseudonym.for(user, @context, type: :implicit, require_sis: false)

    require_role
    admin = @context.account_users.where(user_id: user.id, role_id: @role.id).first_or_initialize
    admin.workflow_state = "active"

    return unless authorized_action(admin, @current_user, :create)

    if admin.new_record? || admin.workflow_state_changed?
      if admin.save
        # if they don't provide it, or they explicitly want it
        if params[:send_confirmation].nil? ||
           Canvas::Plugin.value_to_boolean(params[:send_confirmation])
          if user.registered?
            admin.account_user_notification!
          else
            admin.account_user_registration!
          end
        end
      else
        return render json: admin.errors, status: :bad_request
      end
    end
    render json: admin_json(admin, @current_user, session)
  end

  # @API Remove account admin
  #
  # Remove the rights associated with an account admin role from a user.
  #
  # @argument role [String]
  #   [DEPRECATED] Account role to remove from the user.
  #
  # @argument role_id [Required, Integer]
  #   The id of the role representing the user's admin relationship with the account.
  #
  # @returns Admin
  def destroy
    user = api_find(User, params[:user_id])
    require_role
    admin = @context.account_users.where(user_id: user, role_id: @role.id).first!
    if authorized_action(admin, @current_user, :destroy)
      admin.destroy
      render json: admin_json(admin, @current_user, session)
    end
  end

  # @API List account admins
  #
  # A paginated list of the admins in the account
  #
  # @argument user_id[] [[Integer]]
  #   Scope the results to those with user IDs equal to any of the IDs specified here.
  #
  # @returns [Admin]
  def index
    if authorized_action(@context, @current_user, :manage_account_memberships)
      user_ids = api_find_all(User, Array(params[:user_id])).pluck(:id) if params[:user_id]
      scope = @context.account_users.active.preload(:user, :role)
      scope = scope.where(user_id: user_ids) if user_ids
      route = polymorphic_url([:api_v1, @context, :admins])
      admins = Api.paginate(scope.order(:id), self, route).reject { |admin| admin.user.nil? }
      render json: admins.collect { |admin| admin_json(admin, @current_user, session) }
    end
  end

  # @API List my admin roles
  #
  # A paginated list of the current user's roles in the account. The results are the same
  # as those returned by the {api:AdminsController#index List account admins} endpoint with
  # +user_id+ set to +self+, except the "Admins - Add / Remove" permission is not required.
  #
  # @returns [Admin]
  def self_roles
    if authorized_action(@context, @current_user, :read)
      scope = @context.account_users.active.where(user_id: @current_user)
      route = polymorphic_url([:api_v1, @context, :self_roles])
      admins = Api.paginate(scope.order(:id), self, route)
      render json: admins.map { |admin| admin_json(admin, @current_user, session) }
    end
  end

  protected

  def require_role
    @role = Role.get_role_by_id(params[:role_id]) if params[:role_id]
    @context.shard.activate do
      @role ||= @context.get_account_role_by_name(params[:role]) if params[:role]
      @role ||= Role.get_built_in_role("AccountAdmin", root_account_id: @context.resolved_root_account_id)
    end
  end
end
