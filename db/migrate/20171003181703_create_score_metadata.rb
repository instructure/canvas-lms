#
# Copyright (C) 2017 - present Instructure, Inc.
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

class CreateScoreMetadata < ActiveRecord::Migration[5.0]
  tag :predeploy

  def change
    create_table :score_metadata do |t|
      t.integer :score_id, limit: 8, null: false
      t.json :calculation_details, default: {}, null: false

      t.timestamps
    end

    add_foreign_key :score_metadata, :scores
    add_index :score_metadata, :score_id, unique: true
  end
end
