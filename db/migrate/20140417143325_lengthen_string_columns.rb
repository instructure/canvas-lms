#
# Copyright (C) 2014 - present Instructure, Inc.
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

class LengthenStringColumns < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    change_column :context_external_tools, :consumer_key, :text
    change_column :context_external_tools, :shared_secret, :text
    change_column :migration_issues, :fix_issue_html_url, :text
    change_column :submission_comments, :attachment_ids, :text
  end

  def self.down
    change_column :context_external_tools, :consumer_key, :string, :limit => 255
    change_column :context_external_tools, :shared_secret, :string, :limit => 255
    change_column :migration_issues, :fix_issue_html_url, :string, :limit => 255
    change_column :submission_comments, :attachment_ids, :string, :limit => 255
  end
end
