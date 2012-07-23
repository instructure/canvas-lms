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
#

# @API Admins
class AdminsController < ApplicationController
  before_filter :require_user
  before_filter :get_context

  include Api::V1::Admin

  # @API Make an account admin
  #
  # Flag an existing user as an admin within the account.
  #
  # @argument user_id The id of the user to promote.
  #
  # @argument role [Optional] The user's admin relationship with the
  #   account will be created with the given role. Defaults to
  #   'AccountAdmin'.
  #
  # @argument send_confirmation [Optional] [0|1] Send a notification email to the new admin if set to '1'; send no email if set to '0'. Default is '1'.
  def create
    if authorized_action(@context, @current_user, :manage_account_memberships)
      user = api_find(User, params[:user_id])
      admin = user.flag_as_admin(@context, params[:role], !(params[:send_confirmation] == '0'))
      render :json => admin_json(admin, @current_user, session)
    end
  end
end
