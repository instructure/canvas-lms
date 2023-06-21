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

describe Messages::AssignmentResubmitted::TwitterPresenter do
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
    let(:presenter) { Messages::AssignmentResubmitted::TwitterPresenter.new(message) }

    context "when the assignment is not anonymously graded" do
      it "#body includes the name of the student" do
        expect(presenter.body).to include("Adam Jones")
      end

      it "#link is a url for the submission" do
        expect(presenter.link).to eql(
          message.course_assignment_submission_url(course, assignment, submission.user_id)
        )
      end
    end

    context "when the assignment is anonymously graded" do
      before do
        assignment.update!(anonymous_grading: true)
      end

      context "when grades have not been posted" do
        it "#body excludes the name of the student" do
          expect(presenter.body).not_to include("Adam Jones")
        end

        it "#link is a url to SpeedGrader" do
          expect(presenter.link).to eq(
            message.speed_grader_course_gradebook_url(course, assignment_id: assignment.id, anonymous_id: submission.anonymous_id)
          )
        end
      end

      context "when grades have been posted" do
        before do
          submission
          assignment.unmute!
        end

        it "#body includes the name of the student" do
          expect(presenter.body).to include("Adam Jones")
        end

        it "#link is a url for the submission" do
          expect(presenter.link).to eql(
            message.course_assignment_submission_url(course, assignment, submission.user_id)
          )
        end
      end
    end
  end

  describe "generated message" do
    let(:message) { generate_message(:assignment_resubmitted, :twitter, submission, {}) }
    let(:presenter) do
      msg = Message.new(context: submission, user: teacher)
      Messages::AssignmentResubmitted::TwitterPresenter.new(msg)
    end

    context "when the assignment is not anonymously graded" do
      it "#body includes the name of the student" do
        expect(message.body).to include("Adam Jones")
      end

      it "#url is a url for the submission" do
        expect(message.url).to include(presenter.link)
      end
    end

    context "when the assignment is anonymously graded" do
      before do
        assignment.update!(anonymous_grading: true)
      end

      context "when grades have not been posted" do
        it "#body excludes the name of the student" do
          expect(message.body).not_to include("Adam Jones")
        end

        it "#url is a url to SpeedGrader" do
          expect(message.url).to include(presenter.link)
        end
      end

      context "when grades have been posted" do
        before do
          submission
          assignment.unmute!
        end

        it "#body includes the name of the student" do
          expect(message.body).to include("Adam Jones")
        end

        it "#url is a url for the submission" do
          expect(message.url).to include(presenter.link)
        end
      end
    end
  end
end
