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

class RemoveProvisionalGradePosition < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def up
    # the unique index was dropped in a predeploy migration
    remove_column :moderated_grading_provisional_grades, :position
  end

  def down
    add_column :moderated_grading_provisional_grades, :position, :integer, :limit => 8
    add_index :moderated_grading_provisional_grades,
              [:submission_id, :position],
              unique: true,
              name: :idx_mg_provisional_grades_unique_submission_position
  end
end
