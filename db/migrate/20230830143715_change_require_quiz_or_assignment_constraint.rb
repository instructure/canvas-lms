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

class ChangeRequireQuizOrAssignmentConstraint < ActiveRecord::Migration[7.0]
  tag :predeploy
  disable_ddl_transaction!

  def up
    remove_check_constraint(:assignment_overrides, name: "require_quiz_or_assignment", if_exists: true)
    # Split constraint creation and validation to reduce exclusive locking time
    add_check_constraint(:assignment_overrides,
                         "workflow_state='deleted' OR quiz_id IS NOT NULL OR assignment_id IS NOT NULL OR context_module_id IS NOT NULL",
                         name: "require_quiz_or_assignment_or_module",
                         if_not_exists: true,
                         validate: false)
    validate_constraint(:assignment_overrides, :require_quiz_or_assignment_or_module)
  end

  def down
    remove_check_constraint(:assignment_overrides, name: "require_quiz_or_assignment_or_module", if_exists: true)
    add_check_constraint(:assignment_overrides,
                         "workflow_state='deleted' OR quiz_id IS NOT NULL OR assignment_id IS NOT NULL",
                         name: "require_quiz_or_assignment",
                         if_not_exists: true,
                         validate: false)
    validate_constraint(:assignment_overrides, :require_quiz_or_assignment)
  end
end
