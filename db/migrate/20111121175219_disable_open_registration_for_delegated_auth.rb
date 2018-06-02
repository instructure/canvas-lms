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

class DisableOpenRegistrationForDelegatedAuth < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    scope = Account.root_accounts.joins("INNER JOIN #{connection.quote_table_name('account_authorization_configs')} ON account_id=accounts.id").readonly(false)
    scope.where('account_authorization_configs.auth_type' => ['cas', 'saml']).each do |account|
      account.settings = { :open_registration => false }
      account.save!
    end
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
