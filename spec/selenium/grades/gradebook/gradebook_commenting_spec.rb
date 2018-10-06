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
require_relative '../pages/gradebook_page'

describe "gradebook" do
  include_context "in-process server selenium tests"
  include GradebookCommon

  before(:once) { gradebook_data_setup }
  before(:each) { user_session(@teacher) }

  it "should validate posting a comment to a graded assignment", priority: "1", test_id: 210046 do
    comment_text = "This is a new comment!"

    get "/courses/#{@course.id}/gradebook"

    dialog = Gradebook.open_comment_dialog
    set_value(dialog.find_element(:id, "add_a_comment"), comment_text)
    f("form.submission_details_add_comment_form.clearfix > button.btn").click
    wait_for_ajax_requests

    # make sure it is still there if you reload the page
    refresh_page

    comment = Gradebook.open_comment_dialog.find_element(:css, '.comment')
    expect(comment).to include_text(comment_text)
  end

  it "should let you post a group comment to a group assignment", priority: "1", test_id: 210047 do
    group_assignment = @course.assignments.create!({
      title: 'group assignment',
      due_at: (Time.zone.now + 1.week),
      points_possible: @assignment_3_points,
      submission_types: 'online_text_entry',
      assignment_group: @group,
      group_category: GroupCategory.create!(name: "groups", context: @course),
      grade_group_students_individually: true
    })
    project_group = group_assignment.group_category.groups.create!(name: 'g1', context: @course)
    project_group.users << @student_1
    project_group.users << @student_2

    comment_text = "This is a new group comment!"

    get "/courses/#{@course.id}/gradebook"

    dialog = Gradebook.open_comment_dialog(3)
    set_value(dialog.find_element(:id, "add_a_comment"), comment_text)
    f('label[for="group_comment"]').click
    f("form.submission_details_add_comment_form.clearfix > button.btn").click

    # wait for form submission to finish and dialog to close
    wait_for_ajaximations
    expect(f('body')).not_to contain_css('.submission_details_add_comment_form')

    # make sure it's on the other student's submission
    Gradebook.open_comment_dialog(3, 1)
    comment = fj(".submission_details_dialog:visible .comment")
    expect(comment).to include_text(comment_text)
  end
end
