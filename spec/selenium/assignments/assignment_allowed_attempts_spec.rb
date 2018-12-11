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

require_relative '../common'
require_relative '../helpers/assignments_common'

describe "allowed_attempts feature for assignments" do
  include_context "in-process server selenium tests"
  include AssignmentsCommon

  context "as a student" do
    before do
      course_with_student_logged_in
    end

    describe "the assignments page" do
      context "with allowed_attempts on the assignment" do
        before do
          @assignment = @course.assignments.create!({ name: "Test Assignment", allowed_attempts: 2 })
          @assignment.update_attribute(:submission_types, "online_text_entry")
        end

        it "prevents submitting if the student has exceeded the max number of attempts" do
          submission = @assignment.submit_homework(@student, { body: "blah" })
          submission.update_attributes(attempt: 2, submission_type: "online_text_entry")
          get "/courses/#{@course.id}/assignments/#{@assignment.id}"
          expect(f(".student-assignment-overview")).to include_text("Allowed Attempts")
          expect(f('.submit_assignment_link')).to be_disabled
        end

        it "allows submitting if the student has not exceeded the max number of attempts" do
          get "/courses/#{@course.id}/assignments/#{@assignment.id}"
          expect(f(".student-assignment-overview")).to include_text("Allowed Attempts")
          expect(f('.submit_assignment_link')).to_not be_disabled
        end
      end

      context "without allowed_attempts on the assignment" do
        before do
          @assignment = @course.assignments.create!({ name: "Test Assignment", allowed_attempts: -1 })
          @assignment.update_attribute(:submission_types, "online_text_entry")
          @assignment.submit_homework(@student, { body: "blah" })
        end

        it "does not show the attempt data" do
          get "/courses/#{@course.id}/assignments/#{@assignment.id}"
          expect(f(".student-assignment-overview")).to_not include_text("Allowed Attempts")
          expect(f('.submit_assignment_link')).to_not be_disabled
        end
      end
    end

    describe "the assignments detail page" do
      context "with allowed_attempts on the assignment" do
        before do
          @assignment = @course.assignments.create!({ name: "Test Assignment", allowed_attempts: 2 })
          @assignment.update_attribute(:submission_types, "online_text_entry")
          @submission = @assignment.submit_homework(@student, { body: "blah" })
          @submission.update_attributes(submission_type: "online_text_entry")
        end

        it "prevents submitting if the student has exceeded the max number of attempts" do
          @submission.update_attributes(attempt: 2)
          get "/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}"
          expect(f(".submission-details-header__info")).to include_text("Allowed Attempts")
          expect(fln("Re-submit Assignment")).to be_disabled
        end

        it "allows submitting if the student has not exceeded the max number of attempts" do
          get "/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}"
          expect(f(".submission-details-header__info")).to include_text("Allowed Attempts")
          expect(fln("Re-submit Assignment")).to_not be_disabled
        end
      end

      context "without allowed_attempts on the assignment" do
        before do
          @assignment = @course.assignments.create!({ name: "Test Assignment", allowed_attempts: -1 })
          @assignment.update_attribute(:submission_types, "online_text_entry")
          @submission = @assignment.submit_homework(@student, { body: "blah" })
          @submission.update_attributes(attempt: 2, submission_type: "online_text_entry")
        end

        it "does not show the attempt data and allows submitting" do
          get "/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}"
          expect(f(".submission-details-header__info")).to_not include_text("Allowed Attempts")
          expect(fln("Re-submit Assignment")).to_not be_disabled
        end
      end
    end
  end
end
