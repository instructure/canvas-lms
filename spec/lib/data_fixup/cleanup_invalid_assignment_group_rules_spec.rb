# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

describe DataFixup::CleanupInvalidAssignmentGroupRules do
  before(:once) do
    course_with_student

    rule1 = "drop_lowest:1\ndrop_highest:2\nnever_drop:1\nnever_drop:2\n"
    @assignment_group_model1 = @course.assignment_groups.create!(rules: rule1)

    rule2 = "null"
    @assignment_group_model2 = @course.assignment_groups.create!(rules: rule2)

    rule3 = "{drop_lowest: 1}"
    @assignment_group_model3 = @course.assignment_groups.create!(rules: rule3)

    @assignment1 = assignment_model(context: @course, assignment_group: @assignment_group_model1)
    @assignment2 = assignment_model(context: @course, assignment_group: @assignment_group_model2)
    @assignment3 = assignment_model(context: @course, assignment_group: @assignment_group_model3)
  end

  it "changes only bad rule formats to nil" do
    expect do
      DataFixup::CleanupInvalidAssignmentGroupRules.run
    end.to_not change { @assignment_group_model1.reload.rules }
    expect(@assignment_group_model2.reload.rules).to eql(nil)
    expect(@assignment_group_model3.reload.rules).to eql(nil)
  end
end
