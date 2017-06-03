#
# Copyright (C) 2016 - present Instructure, Inc.
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

class AddGradingPeriodGroupIdToEnrollmentTerm < ActiveRecord::Migration[4.2]
  tag :predeploy

  def up
    add_column :enrollment_terms, :grading_period_group_id, :integer, :limit => 8
    add_index :enrollment_terms, :grading_period_group_id
    add_foreign_key :enrollment_terms, :grading_period_groups
  end

  def down
    remove_column :enrollment_terms, :grading_period_group_id
  end
end
