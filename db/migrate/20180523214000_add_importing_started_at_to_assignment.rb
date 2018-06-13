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

class AddImportingStartedAtToAssignment < ActiveRecord::Migration[5.1]
  tag :predeploy
  disable_ddl_transaction!

  def change
    add_column :assignments, :importing_started_at, :datetime
    add_index :assignments,
              :importing_started_at,
              where: "importing_started_at IS NOT NULL AND workflow_state = 'importing'",
              algorithm: :concurrently
  end
end
