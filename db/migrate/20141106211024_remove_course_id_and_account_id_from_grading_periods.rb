#
# Copyright (C) 2014 - present Instructure, Inc.
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

class RemoveCourseIdAndAccountIdFromGradingPeriods < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def up
    remove_column :grading_periods, :course_id
    remove_column :grading_periods, :account_id
  end

  def down
    add_column :grading_periods, :course_id, :integer, :limit => 8
    add_column :grading_periods, :account_id, :integer, :limit => 8
    add_foreign_key :grading_periods, :courses
    add_foreign_key :grading_periods, :accounts
    add_index :grading_periods, :course_id
    add_index :grading_periods, :account_id
  end
end
