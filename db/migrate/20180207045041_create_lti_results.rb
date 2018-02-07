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

class CreateLtiResults < ActiveRecord::Migration[5.0]
  tag :predeploy

  def change
    return if connection.table_exists? :lti_results

    create_table :lti_results do |t|
      t.float :result_score
      t.float :result_maximum
      t.text :comment
      t.string :activity_progress
      t.string :grading_progress
      t.references :lti_line_item, foreign_key: true, null: false, limit: 8
      t.references :submission, foreign_key: true, limit: 8
      t.references :user, foreign_key: true, null: false, limit: 8
      t.timestamps
    end

    add_index :lti_results, %i(lti_line_item_id user_id), unique: true
  end
end
