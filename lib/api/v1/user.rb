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

  ADMIN_JSON_FIELDS = JSON_FIELDS.merge({
    :methods => %w(sis_user_id)
  })

  def user_json(user)
    if user_json_is_admin?
      user.as_json(ADMIN_JSON_FIELDS)
    else
      user.as_json(JSON_FIELDS)
    end
  end

  # optimization hint, currently user only needs to pull pseudonym from the db
  # if a site admin is making the request
  def user_json_is_admin?
    if @user_json_is_admin.nil?
      @user_json_is_admin = Account.site_admin_user?(@current_user, :manage)
    end
    @user_json_is_admin
  end
end

