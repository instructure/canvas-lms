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

class CreateGradebookCsv < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    create_table :gradebook_csvs do |t|
      t.integer :user_id, limit: 8, null: false
      t.integer :attachment_id, limit: 8, null: false
      t.integer :progress_id, limit: 8, null: false
      t.integer :course_id, limit: 8, null: false
    end

    add_foreign_key :gradebook_csvs, :users
    add_foreign_key :gradebook_csvs, :attachments
    add_foreign_key :gradebook_csvs, :progresses
    add_foreign_key :gradebook_csvs, :courses

    add_index :gradebook_csvs, [:user_id, :course_id]
  end
end
