#
# Copyright (C) 2015 - present Instructure, Inc.
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

class PopulateUnknownUserUrl < ActiveRecord::Migration[4.2]
  tag :predeploy

  class AuthenticationProvider < ActiveRecord::Base
    self.table_name = 'account_authorization_configs'

    belongs_to :account
  end

  def up
    AuthenticationProvider.select("*, unknown_user_url AS uuu").find_each do |aac|
      account = aac.account
      if account.unknown_user_url.blank? && aac['uuu'].present?
        account.unknown_user_url = aac['uuu']
        account.save!
      end
    end
  end
end
