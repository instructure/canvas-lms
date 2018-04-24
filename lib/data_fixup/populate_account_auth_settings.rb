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

module DataFixup::PopulateAccountAuthSettings
  class AuthenticationProvider < ActiveRecord::Base
    belongs_to :account
  end

  def self.run
    AuthenticationProvider.table_name = if AuthenticationProvider.connection.table_exists?('account_authorization_configs')
      'account_authorization_configs'
    else
      'authentication_providers'
    end

    AuthenticationProvider.select("*, login_handle_name AS lhn, change_password_url AS cpu").find_each do |aac|
      account = aac.account
      if account.login_handle_name.blank? && aac['lhn'].present?
        account.login_handle_name = aac['lhn']
      end

      if account.change_password_url.blank? && aac['cpu'].present?
        account.change_password_url = aac['cpu']
      end
      account.save!
    end
  end

end
