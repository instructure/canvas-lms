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

describe Messages::SubmissionCommentForTeacher::EmailPresenter do
  let_once(:course) { course_model(name: "MATH-101") }
  let_once(:teacher) { course_with_teacher(course:, active_all: true).user }
  let_once(:submitter) do
    course_with_user("StudentEnrollment", course:, name: "Adam Jones", active_all: true).user
  end
  let_once(:commenter) do
    course_with_user("StudentEnrollment", course:, name: "Betty Ford", active_all: true).user
  end

  let(:assignment) { course.assignments.create!(name: "Introductions", due_at: 1.day.ago) }
  let(:submission) { assignment.submit_homework(submitter) }
  let(:commenter_submission) { assignment.submissions.find_by!(user: commenter) }
  let(:submission_comment) { submission.add_comment(author: commenter, comment: "Looks good!") }

  describe "Presenter instance" do
    let(:message) { Message.new(context: submission_comment, user: teacher) }
    let(:presenter) { Messages::SubmissionCommentForTeacher::EmailPresenter.new(message) }

    context "when the assignment is not anonymously graded" do
      it "#body includes the name of the submitter" do
        expect(presenter.body).to include("Adam Jones")
      end

      it "#body includes the name of the comment author" do
        expect(presenter.body).to include("Betty Ford")
      end

      it "#link is a url for the submission" do
        expect(presenter.link).to eql(
          message.course_assignment_submission_url(course, assignment, submission.user_id)
        )
      end

      it "#subject includes the name of the submitter" do
        expect(presenter.subject).to include("Adam Jones")
      end
    end

    context "when the assignment is anonymously graded" do
      before do
        assignment.update!(anonymous_grading: true)
      end

      context "when grades have not been posted" do
        it "#body excludes the name of the submitter" do
          expect(presenter.body).not_to include("Adam Jones")
        end

        it "#body includes the anonymous id of the submitter" do
          expect(presenter.body).to include(submission.anonymous_id)
        end

        it "#body excludes the name of the comment author" do
          expect(presenter.body).not_to include("Betty Ford")
        end

        it "#body includes the anonymous id of the comment author" do
          expect(presenter.body).to include(commenter_submission.anonymous_id)
        end

        it "#body excludes the author identity when not able to anonymously mention them" do
          anonymous_id = commenter_submission.anonymous_id
          commenter_submission.destroy!
          expect(presenter.body).not_to include(anonymous_id)
        end

        it "#link is a url to SpeedGrader" do
          expect(presenter.link).to eq(
            message.speed_grader_course_gradebook_url(course, assignment_id: assignment.id, anonymous_id: submission.anonymous_id)
          )
        end

        it "#subject excludes the name of the submitter" do
          expect(presenter.subject).not_to include("Adam Jones")
        end

        it "#subject includes the anonymous id of the submitter" do
          expect(presenter.subject).to include(submission.anonymous_id)
        end
      end

      context "when grades have been posted" do
        before do
          assignment.unmute!
        end

        it "#body includes the name of the submitter" do
          expect(presenter.body).to include("Adam Jones")
        end

        it "#body includes the name of the comment author" do
          expect(presenter.body).to include("Betty Ford")
        end

        it "#link is a url for the submission" do
          expect(presenter.link).to eql(
            message.course_assignment_submission_url(course, assignment, submission.user_id)
          )
        end

        it "#subject includes the name of the submitter" do
          expect(presenter.subject).to include("Adam Jones")
        end
      end
    end
  end

  describe "HTML message" do
    let(:message) { generate_message("Submission Comment For Teacher", :email, submission_comment, {}) }
    let(:presenter) do
      msg = Message.new(context: submission_comment, user: teacher)
      Messages::SubmissionCommentForTeacher::EmailPresenter.new(msg)
    end

    context "when the assignment is not anonymously graded" do
      it "#from_name is the name of the comment author" do
        message.infer_defaults
        expect(message.from_name).to eql("Betty Ford")
      end

      it "#html_body includes the name of the submitter" do
        expect(message.html_body).to include("Adam Jones")
      end

      it "#html_body includes the name of the comment author" do
        expect(message.html_body).to include("Betty Ford")
      end

      it "#html_body includes a link for the submission" do
        expect(message.html_body).to include(presenter.link)
      end

      it "#subject includes the name of the submitter" do
        expect(message.subject).to include("Adam Jones")
      end
    end

    context "when the assignment is anonymously graded" do
      before do
        assignment.update!(anonymous_grading: true)
      end

      context "when grades have not been posted" do
        it "#from_name is anonymous" do
          message.infer_defaults
          expect(message.from_name).to eql("Anonymous User")
        end

        it "#html_body excludes the name of the submitter" do
          expect(message.html_body).not_to include("Adam Jones")
        end

        it "#html_body includes the anonymous id of the submitter" do
          expect(message.html_body).to include(submission.anonymous_id)
        end

        it "#html_body excludes the name of the comment author" do
          expect(message.html_body).not_to include("Betty Ford")
        end

        it "#html_body includes the anonymous id of the comment author" do
          expect(message.html_body).to include(commenter_submission.anonymous_id)
        end

        it "#html_body excludes the author identity when not able to anonymously mention them" do
          anonymous_id = commenter_submission.anonymous_id
          commenter_submission.destroy!
          expect(message.html_body).not_to include(anonymous_id)
        end

        it "#html_body includes an html-escaped link to SpeedGrader" do
          expect(message.html_body).to include(CGI.escapeHTML(presenter.link))
        end

        it "#subject excludes the name of the submitter" do
          expect(message.subject).not_to include("Adam Jones")
        end

        it "#subject includes the anonymous id of the submitter" do
          expect(message.subject).to include(submission.anonymous_id)
        end
      end

      context "when grades have been posted" do
        before do
          assignment.unmute!
        end

        it "#from_name is the name of the comment author" do
          message.infer_defaults
          expect(message.from_name).to eql("Betty Ford")
        end

        it "#html_body includes the name of the submitter" do
          expect(message.html_body).to include("Adam Jones")
        end

        it "#html_body includes the name of the comment author" do
          expect(message.html_body).to include("Betty Ford")
        end

        it "#html_body includes a link for the submission" do
          expect(message.html_body).to include(presenter.link)
        end

        it "#subject includes the name of the submitter" do
          expect(message.subject).to include("Adam Jones")
        end
      end
    end
  end

  describe "Plain Text message" do
    let(:message) { generate_message("Submission Comment For Teacher", :email, submission_comment, {}) }
    let(:presenter) do
      msg = Message.new(context: submission_comment, user: teacher)
      Messages::SubmissionCommentForTeacher::EmailPresenter.new(msg)
    end

    it "#body includes the 'can reply' message when the recipient can reply" do
      IncomingMailProcessor::MailboxAccount.reply_to_enabled = true
      expect(message.body).to include("You can reply to this comment")
    end

    it "#body excludes the 'can reply' message when the recipient cannot reply" do
      IncomingMailProcessor::MailboxAccount.reply_to_enabled = false
      expect(message.body).not_to include("You can reply to this comment")
    end

    context "when the assignment is not anonymously graded" do
      it "#body includes the name of the submitter" do
        expect(message.body).to include("Adam Jones")
      end

      it "#body includes the name of the comment author" do
        expect(message.body).to include("Betty Ford")
      end

      it "#body includes a link for the submission" do
        expect(message.body).to include(presenter.link)
      end

      it "#subject includes the name of the submitter" do
        expect(message.subject).to include("Adam Jones")
      end
    end

    context "when the assignment is anonymously graded" do
      before do
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

        it "#body includes a link to SpeedGrader" do
          expect(message.body).to include(presenter.link)
        end

        it "#subject excludes the name of the submitter" do
          expect(message.subject).not_to include("Adam Jones")
        end
      end

      context "when grades have been posted" do
        before do
          assignment.unmute!
        end

        it "#body includes the name of the submitter" do
          expect(message.body).to include("Adam Jones")
        end

        it "#body includes the name of the comment author" do
          expect(message.body).to include("Betty Ford")
        end

        it "#body includes a link for the submission" do
          expect(message.body).to include(presenter.link)
        end

        it "#subject includes the name of the submitter" do
          expect(message.subject).to include("Adam Jones")
        end
      end
    end
  end
end
