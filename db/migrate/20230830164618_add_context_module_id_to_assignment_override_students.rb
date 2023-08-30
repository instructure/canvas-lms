# frozen_string_literal: true

#
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
#

class AddContextModuleIdToAssignmentOverrideStudents < ActiveRecord::Migration[7.0]
  tag :predeploy
  disable_ddl_transaction!

  def change
    add_reference :assignment_override_students,
                  :context_module,
                  if_not_exists: true,
                  foreign_key: true,
                  index: false

    add_index :assignment_override_students,
              [:context_module_id, :user_id],
              where: "context_module_id IS NOT NULL",
              unique: true,
              algorithm: :concurrently,
              if_not_exists: true,
              name: "index_assignment_override_students_on_context_module_and_user"
  end
end
