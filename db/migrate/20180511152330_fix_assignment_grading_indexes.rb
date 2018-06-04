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

class FixAssignmentGradingIndexes < ActiveRecord::Migration[5.1]
  tag :postdeploy
  disable_ddl_transaction!

  def up
    remove_index :assignments, :grader_section_id if index_exists?(:assignments, :grader_section_id)
    remove_index :assignments, :final_grader_id if index_exists?(:assignments, :final_grader_id)
    add_index :assignments, :grader_section_id, where: "grader_section_id IS NOT NULL", algorithm: :concurrently
    add_index :assignments, :final_grader_id, where: "final_grader_id IS NOT NULL", algorithm: :concurrently
  end
end
