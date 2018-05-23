#
# Copyright (C) 2018 - present Instructure, Inc.
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

class RenameAccountAuthorizationConfigsToAuthenticationProviders < ActiveRecord::Migration[5.1]
  tag :postdeploy

  def up
    execute("DROP VIEW #{connection.quote_table_name('authentication_providers')}")
    rename_table :account_authorization_configs, :authentication_providers
  end

  def down
    rename_table :authentication_providers, :account_authorization_configs
    execute("CREATE VIEW #{connection.quote_table_name('authentication_providers')} AS SELECT * FROM #{connection.quote_table_name('account_authorization_configs')}")
  end
end
