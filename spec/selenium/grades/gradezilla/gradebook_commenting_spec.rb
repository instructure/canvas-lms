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

require_relative '../../helpers/gradezilla_common'
require_relative '../pages/gradezilla_cells_page'
require_relative '../pages/gradezilla_page'

describe "Gradezilla" do
  include_context "in-process server selenium tests"
  include GradezillaCommon

  let(:assignment) { @course.assignments.first }

  before(:once) do
    gradebook_data_setup

    @comment_text = "This is a new group comment!"
  end
  before(:each) { user_session(@teacher) }

  it "should validate posting a comment to a graded assignment", priority: "1", test_id: 210046 do
    Gradezilla.visit(@course)

    Gradezilla::Cells.open_tray(@student_1, assignment)
    Gradezilla::GradeDetailTray.add_new_comment(@comment_text)

    # make sure it is still there if you reload the page
    refresh_page

    Gradezilla::Cells.open_tray(@student_1, assignment)
    expect(Gradezilla::GradeDetailTray.comment(@comment_text)).to be_displayed
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

    Gradezilla.visit(@course)

    Gradezilla::Cells.open_tray(@student_1, group_assignment)
    Gradezilla::GradeDetailTray.add_new_comment(@comment_text)

    Gradezilla::GradeDetailTray.close_tray_button.click

    # make sure it's on the other student's submission
    Gradezilla::Cells.open_tray(@student_2, group_assignment)
    expect(Gradezilla::GradeDetailTray.comment(@comment_text)).to be_displayed
  end
end
