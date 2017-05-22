#
# Copyright (C) 2013 - present Instructure, Inc.
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

class CreateMigrationIssues < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    create_table :migration_issues do |t|
      t.integer :content_migration_id, :limit => 8
      t.string :description
      t.string :workflow_state
      t.string :fix_issue_html_url
      t.string :issue_type
      t.integer :error_report_id, :limit => 8
      t.string :error_message

      t.timestamps null: true
    end
    add_index :migration_issues, :content_migration_id
  end

  def self.down
    drop_table :migration_issues
  end
end
