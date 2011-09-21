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

module Api::V1::User
  JSON_FIELDS = {
    :include_root => false,
    :only => %w(id name),
    :methods => %w(sortable_name short_name)
  }

  def user_json(user)
    user.as_json(JSON_FIELDS).tap do |json|
      if user_json_is_admin? && pseudonym = user.pseudonym
        # the sis fields on pseudonym are poorly named -- sis_user_id is
        # the id in the SIS import data, where on every other table
        # that's called sis_source_id. But on pseudonym, sis_source_id is
        # the login id from the SIS import data.
        json.merge! :sis_user_id => pseudonym.sis_user_id,
                    :sis_login_id => pseudonym.sis_source_id,
                    :login_id => pseudonym.unique_id
      end
    end
  end

  # optimization hint, currently user only needs to pull pseudonym from the db
  # if a site admin is making the request or they can manage_students
  def user_json_is_admin?
    if @user_json_is_admin.nil?
      if @context.is_a?(UserProfile)
        permissions_context = permissions_account = @domain_root_account
      else
        permissions_context = @context
        permissions_account = @context.account
      end
      @user_json_is_admin = !!(
        permissions_context.grants_right?(@current_user, :manage_students) ||
        permissions_account.membership_for_user(@current_user) || 
        permissions_account.grants_right?(@current_user, :manage_sis)
      )
    end
    @user_json_is_admin
  end
end

