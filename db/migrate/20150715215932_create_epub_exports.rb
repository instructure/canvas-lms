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

class CreateEpubExports < ActiveRecord::Migration[4.2]
  tag :predeploy
  def self.up
    create_table :epub_exports do |t|
      t.integer :content_export_id, :course_id, :user_id, limit: 8
      t.string :workflow_state, default: "created"
      t.timestamps null: true
    end

    add_foreign_key_if_not_exists :epub_exports, :users, delay_validation: true
    add_foreign_key_if_not_exists :epub_exports, :courses, delay_validation: true
    add_foreign_key_if_not_exists :epub_exports, :content_exports, delay_validation: true

    add_index :epub_exports, :user_id
    add_index :epub_exports, :course_id
    add_index :epub_exports, :content_export_id

  end

  def self.down
    drop_table :epub_exports
  end
end
