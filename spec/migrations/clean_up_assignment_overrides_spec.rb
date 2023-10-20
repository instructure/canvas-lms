# frozen_string_literal: true

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
#

require_relative "../../db/migrate/20180611205754_clean_up_assignment_overrides"
require_relative "../../db/migrate/20230830143715_change_require_quiz_or_assignment_constraint"

describe "CleanUpAssignmentOverrides" do
  it "cleans up invalid overrides and orphaned override students" do
    ChangeRequireQuizOrAssignmentConstraint.new.migrate(:down)
    CleanUpAssignmentOverrides.down

    course_with_student.user
    assignment_model context: @course
    override1 = @assignment.assignment_overrides.create! set_type: "ADHOC"
    override2 = @assignment.assignment_overrides.create! set_type: "ADHOC"
    aos = AssignmentOverrideStudent.create! user_id: @student.id, assignment_id: @assignment.id, assignment_override_id: override2.id

    override1.update_attribute(:assignment_id, nil)        # invalid, as in ADMIN-1058
    override2.update_attribute(:workflow_state, "deleted") # leaving aos orphaned

    CleanUpAssignmentOverrides.up
    ChangeRequireQuizOrAssignmentConstraint.new.migrate(:up)

    expect(override1.reload).to be_deleted
    expect(aos.reload).to be_deleted

    # ensure the check constraint prevents detaching AssignmentOverrides from an assignment or quiz
    override3 = @assignment.assignment_overrides.create! set_type: "ADHOC"
    expect { override3.update_attribute(:assignment_id, nil) }.to raise_error(ActiveRecord::StatementInvalid)
  ensure
    CleanUpAssignmentOverrides.up
  end
end
