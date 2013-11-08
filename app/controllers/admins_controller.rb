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
# @object Admin
#     {
#       // The unique identifier for the account role/user assignment
#       "id": 1023,
#
#       // The account role assigned. This can be 'AccountAdmin' or a
#       // user-defined role created by the Roles API.
#       "role": "AccountAdmin",
#
#       // The user the role is assigned to. See the Users API for details.
#       "user": {
#         "id": 8191,
#         "name": "A. A. Dinwiddie",
#         "login_id": "bursar@uu.example.edu"
#       }
#     }
class AdminsController < ApplicationController
  before_filter :require_user
  before_filter :get_context

  include Api::V1::Admin

  # @API Make an account admin
  #
  # Flag an existing user as an admin within the account.
  #
  # @argument user_id [String]
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
    if authorized_action(@context, @current_user, :manage_account_memberships)
      user = api_find(User, params[:user_id])
      admin = user.flag_as_admin(@context, params[:role], !(params[:send_confirmation] == '0'))
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
    if authorized_action(@context, @current_user, :manage_account_memberships)
      user = api_find(User, params[:user_id])
      role = params[:role] || 'AccountAdmin'
      admin = @context.account_users.find_by_user_id_and_membership_type!(user.id, role)
      admin.destroy
      render :json => admin_json(admin, @current_user, session)
    end
  end
  
  # @API List account admins
  #
  # List the admins in the account
  # 
  # @returns [Admin]
  def index
    if authorized_action(@context, @current_user, :manage_account_memberships)
      scope = @context.account_users
      route = polymorphic_url([:api_v1, @context, :admins])
      admins = Api.paginate(scope, self, route, :order => :id) 
      render :json => admins.collect{ |admin| admin_json(admin, @current_user, session) }
    end
  end
end
