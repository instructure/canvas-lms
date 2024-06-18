# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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
require_relative "../../helpers/assignments_common"
require_relative "../pages/speedgrader_page"

describe "SpeedGrader" do
  include_context "in-process server selenium tests"
  include AssignmentsCommon

  before(:once) do
    Account.site_admin.enable_feature!(:assignment_comment_library)
    course_with_teacher(name: "Teacher1", active_user: true, active_enrollment: true, active_course: true).user
    student_in_course(name: "Student1", active_user: true).user

    @assignment = @course.assignments.create(name: "assignment with rubric", points_possible: 10)
    submission_model(user: @student, assignment: @assignment, body: "first student submission text")
  end

  before do
    user_session(@teacher)
    Speedgrader.visit(@course.id, @assignment.id)
    Speedgrader.add_comment_to_library("First Comment")
  end

  context "comment library" do
    it "allows a comment to be added to the comment library" do
      Speedgrader.comment_library_link.click
      Speedgrader.comment_library_text_area.send_keys("New Comment")
      Speedgrader.comment_library_add_button.click
      f(".flashalert-message button").click

      expect(Speedgrader.comment_library_area).to include_text("New Comment")
      Speedgrader.comment_library_close_button.click
      expect(Speedgrader.comment_library_count).to eq("2")
    end

    it "allows a comment to be deleted from the comment library" do
      Speedgrader.comment_library_link.click
      Speedgrader.comment_library_delete_button.click
      accept_alert
      f(".flashalert-message button").click
      Speedgrader.comment_library_close_button.click

      expect(Speedgrader.comment_library_count).to eq("0")
    end

    it "allows a comment to be edited from the comment library" do
      Speedgrader.comment_library_link.click
      Speedgrader.comment_library_edit_button.click
      Speedgrader.comment_library_edit_text_area.clear
      Speedgrader.comment_library_edit_text_area.send_keys("Edited")
      Speedgrader.comment_library_save_button.click
      f(".flashalert-message button").click

      expect(Speedgrader.comment_library_area).not_to include_text("First Comment")
      expect(Speedgrader.comment_library_area).to include_text("Edited")

      Speedgrader.comment_library_close_button.click
      expect(Speedgrader.comment_library_count).to eq("1")
    end

    it "allows suggestions to be displayed while typing" do
      Speedgrader.add_comment_to_library("Great work!")
      Speedgrader.comment_library_link.click
      Speedgrader.comment_library_suggestions_toggle.click
      Speedgrader.comment_library_close_button.click

      Speedgrader.new_comment_text_area.send_keys("Gre")
      expect(Speedgrader.comment_library_suggestion).to include_text("Great work!")
      expect(Speedgrader.comment_library_suggestion).not_to include_text("First Comment")
      Speedgrader.comment_library_suggestion.click
      expect(Speedgrader.new_comment_text_area).to include_text("Great work!")
    end
  end
end
