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
#

class CreateLtiLineItems < ActiveRecord::Migration[5.0]
  tag :predeploy

  def change
    return if connection.table_exists? :lti_line_items

    create_table :lti_line_items do |t|
      t.float :score_maximum, null: false
      t.string :label, null: false
      t.string :resource_id, null: true
      t.string :tag, null: true
      t.references :lti_resource_link, foreign_key: true, null: true, limit: 8
      t.references :assignment, foreign_key: true, null: false, limit: 8
      t.timestamps
    end

    add_index :lti_line_items, :tag
    add_index :lti_line_items, :resource_id
  end
end
