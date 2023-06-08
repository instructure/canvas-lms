# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

require_relative "../../common"
require_relative "../pages/gradebook_cells_page"
require_relative "../pages/gradebook_grade_detail_tray_page"

describe "concluded/unconcluded" do
  include_context "in-process server selenium tests"

  before do
    username = "nobody@example.com"
    password = "asdfasdf"
    u = user_with_pseudonym(active_user: true,
                            username:,
                            password:)
    u.save!
    @e = course_with_teacher active_course: true,
                             user: u,
                             active_enrollment: true
    @e.save!

    user_model
    @student = @user
    @course.enroll_student(@student).accept
    @group = @course.assignment_groups.create!(name: "default")
    @assignment = @course.assignments.create!(submission_types: "online_quiz", title: "quiz assignment", assignment_group: @group)
    create_session(u.pseudonym)
  end

  it "lets the teacher edit the gradebook by default" do
    get "/courses/#{@course.id}/gradebook"
    wait_for_ajax_requests

    cell = Gradebook::Cells.grading_cell(@student, @assignment)
    cell.click
    expect(cell).to have_class("editable")
  end

  it "does not let the teacher edit the gradebook when concluded" do
    @e.conclude
    get "/courses/#{@course.id}/gradebook"

    cell = Gradebook::Cells.grading_cell(@student, @assignment)
    cell.click
    expect(cell).not_to have_class("editable")
  end

  it "lets the teacher add comments to the gradebook by default" do
    get "/courses/#{@course.id}/gradebook"

    Gradebook::Cells.open_tray(@student, @assignment)
    wait_for_ajaximations
    expect(Gradebook::GradeDetailTray.new_comment_input).to be_displayed
  end

  it "does not let the teacher add comments to the gradebook when concluded" do
    @e.conclude
    get "/courses/#{@course.id}/gradebook"

    cell = Gradebook::Cells.grading_cell(@student, @assignment)
    cell.click
    expect(cell).not_to contain_css(Gradebook::Cells.grade_tray_button_selector)
  end
end
