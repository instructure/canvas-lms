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


class TweakDashboardIndexes < ActiveRecord::Migration[5.2]
  tag :predeploy
  disable_ddl_transaction!

  def up
    remove_index :assignments, algorithm: :concurrently, name: "index_assignments_with_submissions", if_exists: true
    add_index :assignments, :context_id,
              where: "context_type='Course' AND workflow_state<>'deleted'",
              algorithm: :concurrently, name: "index_assignments_active", if_not_exists: true
    add_index :submissions, [:user_id, :course_id],
              where: "(score IS NOT NULL OR grade IS NOT NULL) AND workflow_state<>'deleted'",
              algorithm: :concurrently, name: "index_submissions_with_grade", if_not_exists: true
  end

  def down
    remove_index :assignments, name: "index_assignments_active", algorithm: :concurrently, if_exists: true
    remove_index :submissions, name: "index_submissions_with_grade", algorithm: :concurrently, if_exists: true
  end
end
