# frozen_string_literal: true

# Copyright (C) 2023 - present Instructure, Inc.
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

class UpdateAssignmentOverrideModulesIndex < ActiveRecord::Migration[7.0]
  tag :predeploy
  disable_ddl_transaction!

  def change
    add_index :assignment_overrides,
              %i[context_module_id set_id set_type],
              where: "context_module_id IS NOT NULL AND workflow_state = 'active' AND set_id IS NOT NULL",
              unique: true,
              algorithm: :concurrently,
              if_not_exists: true,
              name: "index_assignment_overrides_on_context_module_id_and_set"
    remove_index :assignment_overrides,
                 [:context_module_id, :set_id],
                 where: "context_module_id IS NOT NULL AND workflow_state = 'active' AND set_type IN ('CourseSection', 'Group')",
                 name: "index_assignment_overrides_on_context_module_id_and_set_id",
                 unique: true,
                 algorithm: :concurrently,
                 if_exists: true
  end
end
