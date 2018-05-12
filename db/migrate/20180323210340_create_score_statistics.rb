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

class CreateScoreStatistics < ActiveRecord::Migration[5.1]
  tag :predeploy

  def change
    create_table :score_statistics do |t|
      t.belongs_to :assignment, null: false, index: { unique: true }, foreign_key: true
      t.float :minimum, null: false
      t.float :maximum, null: false
      t.float :mean, null: false
      t.integer :count, null: false

      t.timestamps
    end
  end
end
