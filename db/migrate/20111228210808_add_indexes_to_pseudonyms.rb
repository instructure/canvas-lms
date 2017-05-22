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

class AddIndexesToPseudonyms < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    if connection.adapter_name == 'PostgreSQL'
      remove_index :pseudonyms, :unique_id
      connection.execute("CREATE INDEX index_pseudonyms_on_unique_id ON #{Pseudonym.quoted_table_name} (LOWER(unique_id))")
    end
    add_index :pseudonyms, :sis_user_id
  end

  def self.down
    remove_index :pseudonyms, :sis_user_id
    if connection.adapter_name == 'PostgreSQL'
      connection.execute("DROP INDEX index_pseudonyms_on_unique_id")
      add_index :pseudonyms, :unique_id
    end
  end
end
