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
#

require "spec_helper"

describe Messages::AssignmentSubmitted::SMSPresenter do
  let(:course) { course_model(name: "MATH-101") }
  let(:assignment) { course.assignments.create!(name: "Introductions", due_at: 1.day.ago) }
  let(:teacher) { course_with_teacher(course:, active_all: true).user }

  let(:student) do
    course_with_user("StudentEnrollment", course:, name: "Adam Jones", active_all: true).user
  end
  let(:submission) do
    @submission = assignment.submit_homework(student)
    assignment.grade_student(student, grade: 5, grader: teacher)
    @submission.reload
  end

  describe "Presenter instance" do
    let(:message) { Message.new(context: submission, user: teacher) }
    let(:presenter) { Messages::AssignmentSubmitted::SMSPresenter.new(message) }

    it "#subject includes the name of the student when the assignment is not anonymously graded" do
      expect(presenter.subject).to include("Adam Jones")
    end

    context "when the assignment is anonymously graded" do
      before do
        assignment.update!(anonymous_grading: true)
      end

      it "#subject excludes the name of the student when grades have not been posted" do
        assignment.update!(anonymous_grading: true)
        expect(presenter.subject).not_to include("Adam Jones")
      end

      it "#subject includes the name of the student when grades have been posted" do
        submission
        assignment.unmute!
        expect(presenter.subject).to include("Adam Jones")
      end
    end
  end

  describe "generated message" do
    let(:message) { generate_message(:assignment_submitted, :sms, submission, {}) }

    it "#body includes the name of the student when the assignment is not anonymously graded" do
      expect(message.body).to include("Adam Jones")
    end

    context "when the assignment is anonymously graded" do
      before do
        assignment.update!(anonymous_grading: true)
      end

      it "#body excludes the name of the student when grades have not been posted" do
        assignment.update!(anonymous_grading: true)
        expect(message.body).not_to include("Adam Jones")
      end

      it "#body includes the name of the student when grades have been posted" do
        submission
        assignment.unmute!
        expect(message.body).to include("Adam Jones")
      end
    end
  end
end
