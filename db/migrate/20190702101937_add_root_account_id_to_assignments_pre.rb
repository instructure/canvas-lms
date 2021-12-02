# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

class AddRootAccountIdToAssignmentsPre < ActiveRecord::Migration[5.1]
  tag :predeploy
  disable_ddl_transaction!

  def up
    fk = connection.send(:foreign_key_name, "assignments", :column => "root_account_id")
    execute("ALTER TABLE #{Assignment.quoted_table_name} ADD COLUMN root_account_id bigint CONSTRAINT #{fk} REFERENCES #{Account.quoted_table_name}(id)")
  end

  def down
    execute("ALTER TABLE #{Assignment.quoted_table_name} DROP COLUMN root_account_id")
  end
end
