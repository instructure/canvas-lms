# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

require_relative '../../helpers/gradebook_common'
require_relative '../pages/gradebook_cells_page'
require_relative '../pages/gradebook_page'

describe "Gradebook" do
  include_context "in-process server selenium tests"
  include GradebookCommon

  let(:assignment) { @course.assignments.first }

  before(:once) do
    gradebook_data_setup

    @comment_text = "This is a new group comment!"
  end
  before(:each) { user_session(@teacher) }

  it "should validate posting a comment to a graded assignment", priority: "1", test_id: 210046 do
    Gradebook.visit(@course)

    Gradebook::Cells.open_tray(@student_1, assignment)
    Gradebook::GradeDetailTray.add_new_comment(@comment_text)

    # make sure it is still there if you reload the page
    refresh_page

    Gradebook::Cells.open_tray(@student_1, assignment)
    expect(Gradebook::GradeDetailTray.comment(@comment_text)).to be_displayed
  end

  it "should let you post a group comment to a group assignment", priority: "1", test_id: 210047 do
    group_assignment = @course.assignments.create!({
                                                     title: 'group assignment',
                                                     due_at: (Time.zone.now + 1.week),
                                                     points_possible: @assignment_3_points,
                                                     submission_types: 'online_text_entry',
                                                     assignment_group: @group,
                                                     group_category: GroupCategory.create!(name: "groups", context: @course),
                                                     grade_group_students_individually: false
                                                   })

    project_group = group_assignment.group_category.groups.create!(name: 'g1', context: @course)
    project_group.users << @student_1
    project_group.users << @student_2

    Gradebook.visit(@course)

    Gradebook::Cells.open_tray(@student_1, group_assignment)
    Gradebook::GradeDetailTray.add_new_comment(@comment_text)

    Gradebook::GradeDetailTray.close_tray_button.click

    # make sure it's on the other student's submission
    Gradebook::Cells.open_tray(@student_2, group_assignment)
    expect(Gradebook::GradeDetailTray.comment(@comment_text)).to be_displayed
  end
end
