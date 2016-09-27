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

class UserListsController < ApplicationController
  skip_before_filter :verify_authenticity_token
  before_filter :require_context

  # POST /courses/:course_id/user_lists.json
  # POST /accounts/:account_id/user_lists.json
  def create
    return unless authorized_action(@context, @current_user, @context.is_a?(Course) ? [:manage_students, :manage_admin_users] : :manage_account_memberships)
    respond_to do |format|
      format.json do
        if value_to_boolean(params[:v2])
          search_type = params[:search_type]
          can_read_sis = @context.grants_right?(@current_user, :read_sis) || @context.root_account.grants_right?(@current_user, :manage_sis)
          return render_unauthorized_action if search_type == "sis_user_id" && !can_read_sis
          # in theory i could make this a whole new api thingy and document it
          # but honestly I'd rather keep it hidden so nobody knows my shame
          render :json => UserListV2.new(params[:user_list],
            root_account: @context.root_account,
            search_type: search_type,
            current_user: @current_user,
            can_read_sis: can_read_sis
          )
        else
          render :json => UserList.new(params[:user_list],
            root_account: @context.root_account,
            search_method: @context.user_list_search_mode_for(@current_user),
            current_user: @current_user)
        end
      end
    end
  end
end
