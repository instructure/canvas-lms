#
# Copyright (C) 2012 - present Instructure, Inc.
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

class ChangeAuthOverTlsToString < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    # existing Rails process will continue seeing it as boolean until they restart;
    # this is fine, since they fetch as a string anyway
    change_column :account_authorization_configs, :auth_over_tls, :string
  end

  def self.down
    # technically it is reversible, but requires db specific syntax in postgres
    raise ActiveRecord::IrreversibleMigration
  end
end
