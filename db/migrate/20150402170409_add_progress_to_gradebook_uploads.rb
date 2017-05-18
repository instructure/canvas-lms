#
# Copyright (C) 2015 - present Instructure, Inc.
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

class AddProgressToGradebookUploads < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    add_column :gradebook_uploads, :course_id, :integer, limit: 8, null: false
    add_column :gradebook_uploads, :user_id, :integer, limit: 8, null: false
    add_column :gradebook_uploads, :progress_id, :integer, limit: 8, null: false
    add_column :gradebook_uploads, :gradebook, :text, limit: 10.megabytes

    add_index :gradebook_uploads, [:course_id, :user_id], unique: true
    add_index :gradebook_uploads, :progress_id

    add_foreign_key :gradebook_uploads, :courses
    add_foreign_key :gradebook_uploads, :users
    add_foreign_key :gradebook_uploads, :progresses
  end
end

