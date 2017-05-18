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

class AddTableSubmissionVersions < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    create_table :submission_versions do |t|
      t.integer  "context_id", :limit => 8
      t.string   "context_type"
      t.integer  "version_id", :limit => 8
      t.integer  "user_id", :limit => 8
      t.integer  "assignment_id", :limit => 8
    end

    columns = case connection.adapter_name
    when 'PostgreSQL'
      [:context_id, :version_id, :user_id, :assignment_id]
    else
      [:context_id, :context_type, :version_id, :user_id, :assignment_id]
    end

    add_index :submission_versions, columns,
      :name => 'index_submission_versions',
      :where => "context_type='Course'",
      :unique => true
  end

  def self.down
    drop_table :submission_versions
  end
end
