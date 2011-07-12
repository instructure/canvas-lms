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
    :only => %w(id name)
  }

  def user_json(user)
    user.as_json(JSON_FIELDS).tap do |json|
      if user_json_is_admin?
        # the sis fields on pseudonym are poorly named -- sis_user_id is
        # the id in the SIS import data, where on every other table
        # that's called sis_source_id. But on pseudonym, sis_source_id is
        # the login in from the SIS import data.
        json.merge! :sis_user_id => user.pseudonym.try(:sis_user_id), 
                    :sis_login_id => user.pseudonym.try(:sis_source_id), 
                    :login_id => user.pseudonym.unique_id
      end
    end
  end

  # optimization hint, currently user only needs to pull pseudonym from the db
  # if a site admin is making the request or they can manage_students
  def user_json_is_admin?
    if @user_json_is_admin.nil?
      @user_json_is_admin = !!(
        @context.grants_right?(@current_user, :manage_students) ||
        @context.account.membership_for_user(@current_user) || 
        @context.account.grants_right?(@current_user, :manage_sis)
      )
    end
    @user_json_is_admin
  end
end

