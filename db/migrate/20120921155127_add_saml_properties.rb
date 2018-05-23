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

class AddSamlProperties < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :account_authorization_configs, :idp_entity_id, :string
    add_column :account_authorization_configs, :position, :integer
    update <<-SQL
      UPDATE #{connection.quote_table_name('account_authorization_configs')} aac
      SET position =
        CASE WHEN (SELECT count(*) FROM #{connection.quote_table_name('account_authorization_configs')} WHERE account_id = aac.account_id) > 1
          THEN aac.id
          ELSE 1
        END;
    SQL
  end

  def self.down
    remove_column :account_authorization_configs, :idp_entity_id
    remove_column :account_authorization_configs, :position
  end
end
