# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

class AddCourseScoreStatistics < ActiveRecord::Migration[5.2]
  tag :predeploy

  def change
    create_table :course_score_statistics do |t|
      t.belongs_to :course, null: false, index: { unique: true }, foreign_key: true
      t.decimal :average, precision: 8, scale: 2, null: false
      t.integer :score_count, null: false

      t.timestamps
    end
  end
end
