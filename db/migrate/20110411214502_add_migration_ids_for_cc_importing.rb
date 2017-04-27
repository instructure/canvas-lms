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

class AddMigrationIdsForCcImporting < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :context_external_tools, :migration_id, :string
    add_column :external_feeds, :migration_id, :string
    add_column :grading_standards, :migration_id, :string
    add_column :learning_outcome_groups, :migration_id, :string
  end

  def self.down
    remove_column :context_external_tools, :migration_id
    remove_column :external_feeds, :migration_id
    remove_column :grading_standards, :migration_id
    remove_column :learning_outcome_groups, :migration_id
  end
end
