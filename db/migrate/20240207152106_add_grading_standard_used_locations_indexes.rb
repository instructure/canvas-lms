# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

class AddGradingStandardUsedLocationsIndexes < ActiveRecord::Migration[7.0]
  tag :postdeploy
  disable_ddl_transaction!

  def up
    add_index :courses, :grading_standard_id, name: "index_courses_on_grading_standard", algorithm: :concurrently, if_not_exists: true
    add_index :assignments, %i[context_id grading_standard_id grading_type], name: "index_assignments_on_context_grading_standard_grading_type", algorithm: :concurrently, if_not_exists: true
    add_index :submissions, :assignment_id, name: "index_graded_submissions_on_assignments", algorithm: :concurrently, if_not_exists: true, where: "workflow_state='graded'"
  end

  def down
    remove_index :courses, name: "index_courses_on_grading_standard", if_exists: true
    remove_index :assignments, name: "index_assignments_on_context_grading_standard_grading_type", if_exists: true
    remove_index :submissions, name: "index_graded_submissions_on_assignments", if_exists: true
  end
end
