#
# Copyright (C) 2011 Instructure, Inc.
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
#         "status": {
#           "description": "The status of the account role/user assignment.",
#           "type": "string",
#           "example": "deleted"
#         }
#       }
#    }
class AdminsController < ApplicationController
  before_filter :require_user
  before_filter :get_context

  include Api::V1::Admin

  # @API Make an account admin
  #
  # Flag an existing user as an admin within the account.
  #
  # @argument user_id [Integer]
  #   The id of the user to promote.
  #
  # @argument role [Optional, String]
  #   The user's admin relationship with the account will be created with the
  #   given role. Defaults to 'AccountAdmin'.
  #
  # @argument send_confirmation [Optional, Boolean] Send a notification email to
  #   the new admin if true. Default is true.
  #
  # @returns Admin
  def create
    user = api_find(User, params[:user_id])
    raise(ActiveRecord::RecordNotFound, "Couldn't find User with API id '#{params[:user_id]}'") unless user.find_pseudonym_for_account(@context.root_account, true)
    role = params[:role] || 'AccountAdmin'
    admin = @context.account_users.where(user_id: user.id, membership_type: role).first_or_initialize

    if authorized_action(admin, @current_user, :create)
      if admin.new_record?
        admin.save!
        if !(params[:send_confirmation] == '0')
          if user.registered?
            admin.account_user_notification!
          else
            admin.account_user_registration!
          end
        end
      end
      render :json => admin_json(admin, @current_user, session)
    end
  end
  
  # @API Remove account admin
  #
  # Remove the rights associated with an account admin role from a user.
  #
  # @argument role [Optional, String]
  #   Account role to remove from the user. Defaults to 'AccountAdmin'. Any
  #   other account role must be specified explicitly.
  #
  # @returns Admin
  def destroy
    user = api_find(User, params[:user_id])
    role = params[:role] || 'AccountAdmin'
    admin = @context.account_users.where(user_id: user, membership_type: role).first!
    if authorized_action(admin, @current_user, :destroy)
      admin.destroy
      render :json => admin_json(admin, @current_user, session)
    end
  end

  # @API List account admins
  #
  # List the admins in the account
  #
  # @argument user_id[] [Optional, [Integer]]
  #   Scope the results to those with user IDs equal to any of the IDs specified here.
  #
  # @returns [Admin]
  def index
    if authorized_action(@context, @current_user, :manage_account_memberships)
      scope = @context.account_users
      scope = scope.where(user_id: params[:user_id]) if params[:user_id]
      route = polymorphic_url([:api_v1, @context, :admins])
      admins = Api.paginate(scope.order(:id), self, route)
      render :json => admins.collect{ |admin| admin_json(admin, @current_user, session) }
    end
  end
end
