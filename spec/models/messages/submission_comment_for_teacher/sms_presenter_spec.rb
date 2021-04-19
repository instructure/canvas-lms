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

describe Messages::SubmissionCommentForTeacher::SMSPresenter do
  let_once(:course) { course_model(name: "MATH-101") }
  let_once(:teacher) { course_with_teacher(course: course, active_all: true).user }
  let_once(:submitter) do
    course_with_user("StudentEnrollment", course: course, name: "Adam Jones", active_all: true).user
  end
  let_once(:commenter) do
    course_with_user("StudentEnrollment", course: course, name: "Betty Ford", active_all: true).user
  end

  let(:assignment) { course.assignments.create!(name: "Introductions", due_at: 1.day.ago) }
  let(:submission) { assignment.submit_homework(submitter) }
  let(:commenter_submission) { assignment.submissions.find_by!(user: commenter) }
  let(:submission_comment) { submission.add_comment(author: commenter, comment: "Looks good!") }

  describe "Presenter instance" do
    let(:message) { Message.new(context: submission_comment, user: teacher) }
    let(:presenter) { Messages::SubmissionCommentForTeacher::SMSPresenter.new(message) }

    context "when the assignment is not anonymously graded" do
      it "#subject includes the name of the submitter" do
        expect(presenter.subject).to include("Adam Jones")
      end

      it "#subject includes the name of the comment author" do
        expect(presenter.subject).to include("Betty Ford")
      end
    end

    context "when the assignment is anonymously graded" do
      before(:each) do
        assignment.update!(anonymous_grading: true)
      end

      context "when grades have not been posted" do
        it "#subject excludes the name of the submitter" do
          expect(presenter.subject).not_to include("Adam Jones")
        end

        it "#subject includes the anonymous id of the submitter" do
          expect(presenter.subject).to include(submission.anonymous_id)
        end

        it "#subject excludes the name of the comment author" do
          expect(presenter.subject).not_to include("Betty Ford")
        end

        it "#subject includes the anonymous id of the comment author" do
          expect(presenter.subject).to include(commenter_submission.anonymous_id)
        end

        it "#subject excludes the author identity when not able to anonymously mention them" do
          anonymous_id = commenter_submission.anonymous_id
          commenter_submission.destroy!
          expect(presenter.subject).not_to include(anonymous_id)
        end
      end

      context "when grades have been posted" do
        before(:each) do
          assignment.unmute!
        end

        it "#subject includes the name of the submitter" do
          expect(presenter.subject).to include("Adam Jones")
        end

        it "#subject includes the name of the comment author" do
          expect(presenter.subject).to include("Betty Ford")
        end
      end
    end
  end

  describe "generated message" do
    let(:message) { generate_message("Submission Comment For Teacher", :sms, submission_comment, {}) }

    context "when the assignment is not anonymously graded" do
      it "#body includes the name of the submitter" do
        expect(message.body).to include("Adam Jones")
      end

      it "#body includes the name of the comment author" do
        expect(message.body).to include("Betty Ford")
      end
    end

    context "when the assignment is anonymously graded" do
      before(:each) do
        assignment.update!(anonymous_grading: true)
      end

      context "when grades have not been posted" do
        it "#body excludes the name of the submitter" do
          expect(message.body).not_to include("Adam Jones")
        end

        it "#body includes the anonymous id of the submitter" do
          expect(message.body).to include(submission.anonymous_id)
        end

        it "#body excludes the name of the comment author" do
          expect(message.body).not_to include("Betty Ford")
        end

        it "#body includes the anonymous id of the comment author" do
          expect(message.body).to include(commenter_submission.anonymous_id)
        end

        it "#body excludes the author identity when not able to anonymously mention them" do
          anonymous_id = commenter_submission.anonymous_id
          commenter_submission.destroy!
          expect(message.body).not_to include(anonymous_id)
        end
      end

      context "when grades have been posted" do
        before(:each) do
          assignment.unmute!
        end

        it "#body includes the name of the submitter" do
          expect(message.body).to include("Adam Jones")
        end

        it "#body includes the name of the comment author" do
          expect(message.body).to include("Betty Ford")
        end
      end
    end
  end
end
