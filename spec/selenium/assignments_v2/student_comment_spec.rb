# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

require_relative "page_objects/student_assignment_page_v2"
require_relative "../common"

describe "assignments" do
  include_context "in-process server selenium tests"

  context "as a student" do
    before(:once) do
      Account.default.enable_feature!(:assignments_2_student)
      course_with_student(course: @course, active_all: true)
      @assignment = @course.assignments.create!(
        name: "assignment",
        due_at: 5.days.ago,
        points_possible: 10,
        submission_types: "online_upload"
      )
      @course.enroll_teacher(user_factory)
      @submission = @assignment.submit_homework(@student)
      @attachment = Attachment.create!(context: @assignment, uploaded_data: default_uploaded_data)
      # create more than 20 submission comments to test pagination
      @submission.add_comment(author: @teacher, comment: "First")
      (1..20).each do |i|
        @submission.add_comment(author: @teacher, comment: i.to_s)
      end
      @submission.add_comment(author: @teacher, comment: "Nice Work!", attachments: [@attachment])
    end

    before do
      user_session(@student)
      StudentAssignmentPageV2.visit(@course, @assignment)
    end

    it "allows a student to submit a comment when there is no submission" do
      StudentAssignmentPageV2.leave_a_comment("test comment")

      expect(StudentAssignmentPageV2.comment_container).to include_text("test comment")
    end

    it "notifies student of the number of unread submission comments" do
      expect(StudentAssignmentPageV2.view_feedback_badge).to include_text("22")
    end

    it "allows student to read submission comments by in view feedback tray" do
      expect(StudentAssignmentPageV2.comment_container).to include_text("Nice Work!")
      expect(StudentAssignmentPageV2.tray_close_button).to be_displayed
      StudentAssignmentPageV2.tray_close_button.click
    end

    it "displays submission comment attachments in feedback tray" do
      expect(StudentAssignmentPageV2.comment_container).to include_text("doc.doc")
    end

    it "allows students to post media submission comments with media modal" do
      StudentAssignmentPageV2.media_comment_button.click

      expect(StudentAssignmentPageV2.media_modal).to be_displayed
    end

    it "paginates the comments starting with most recent into batches of 20 with a button to load more comments" do
      expect(StudentAssignmentPageV2.comment_container).to include_text("20")
      expect(StudentAssignmentPageV2.comment_container).to_not include_text("First")
      StudentAssignmentPageV2.load_more_comments_button.click

      expect(StudentAssignmentPageV2.comment_container).to include_text("First")
    end
  end
end
