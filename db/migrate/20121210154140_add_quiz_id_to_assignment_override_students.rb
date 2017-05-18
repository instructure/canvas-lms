#
# Copyright (C) 2012 - present Instructure, Inc.
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

class AddQuizIdToAssignmentOverrideStudents < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :assignment_override_students, :quiz_id, :integer, :limit => 8
    add_index :assignment_override_students, :quiz_id
    change_column :assignment_override_students, :assignment_id, :integer, :limit => 8, :null => true
  end

  def self.down
    remove_column :assignment_override_students, :quiz_id
    remove_index :assignment_override_students, :quiz_id
    change_column :assignment_override_students, :assignment_id, :integer, :limit => 8, :null => false
  end
end
