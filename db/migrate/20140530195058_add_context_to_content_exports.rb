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

class AddContextToContentExports < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :content_exports, :context_type, :string
    add_column :content_exports, :context_id, :integer, :limit => 8

    remove_foreign_key :content_exports, :courses

    change_column_default :content_exports, :context_type, 'Course'

    while ContentExport.where("context_id IS NULL AND course_id IS NOT NULL").limit(1000).
        update_all("context_id = course_id, context_type = 'Course'") > 0; end
  end

  def self.down
    while ContentExport.where("course_id IS NULL AND context_id IS NOT NULL AND context_type = ?", "Course").
        limit(1000).update_all("course_id = context_id") > 0; end

    add_foreign_key :content_exports, :courses

    remove_column :content_exports, :context_type
    remove_column :content_exports, :context_id
  end
end
