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

class CreateOutcomeProficiencyRatings < ActiveRecord::Migration[5.1]
  tag :predeploy

  def change
    create_table :outcome_proficiency_ratings do |t|
      t.references :outcome_proficiency, foreign_key: true, limit: 8, null: false
      t.string :description, null: false, limit: 255
      t.float :points, null: false
      t.boolean :mastery, null: false
      t.string :color, null: false

      t.timestamps
    end

    add_index :outcome_proficiency_ratings,
      [:outcome_proficiency_id, :points],
      name: 'index_outcome_proficiency_ratings_on_proficiency_and_points'
  end
end
