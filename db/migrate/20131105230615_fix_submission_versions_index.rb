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

class FixSubmissionVersionsIndex < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    if connection.adapter_name == 'PostgreSQL' && connection.select_value("SELECT 1 FROM pg_index WHERE indexrelid='#{connection.quote_table_name('index_submission_versions')}'::regclass AND NOT indisunique")
      columns = [:context_id, :version_id, :user_id, :assignment_id]
      SubmissionVersion.select(columns).where(context_type: 'Course').group(columns).having("COUNT(*) > 1").find_each do |sv|
        scope = SubmissionVersion.where(Hash[columns.map { |c| [c, sv[c]]}]).where(context_type: 'Course')
        keeper = scope.first
        scope.where("id<>?", keeper).delete_all
      end
      add_index :submission_versions, columns,
                :name => 'index_submission_versions2',
                :where => { :context_type => 'Course' },
                :unique => true,
                :algorithm => :concurrently
      connection.execute("DROP INDEX IF EXISTS #{connection.quote_table_name('index_submission_versions')}")
      rename_index :submission_versions, 'index_submission_versions2', 'index_submission_versions'
    end
  end
end
