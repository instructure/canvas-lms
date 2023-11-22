# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

describe Api::V1::SubmissionComment do
  subject(:fake_controller) do
    Class.new do
      include Api
      include Api::V1::Submission
      include Api::V1::SubmissionComment
      include Rails.application.routes.url_helpers

      attr_writer :current_user

      private

      def default_url_options
        { host: :localhost }
      end
    end.new
  end

  before(:once) do
    course = Course.create!
    @student = User.create!
    course.enroll_student(@student, active_all: true)
    assignment = course.assignments.create!
    submission = assignment.submissions.find_by(user_id: @student)
    @submission_comment = submission.submission_comments.create!
    @comment = Object.new.extend(Api::V1::SubmissionComment, Api::V1::User)
  end

  let(:comment_json) { @comment.submission_comment_json(@submission_comment, @student) }

  describe "#submission_comment_json" do
    it "includes the 'edited_at' key" do
      expect(comment_json).to have_key "edited_at"
    end

    it "'edited_at' is set if the submission comment has been edited" do
      now = Time.zone.now
      @submission_comment.edited_at = now
      expect(comment_json[:edited_at]).to be now
    end

    it "'edited_at' is nil if the submission comment has not been edited" do
      expect(comment_json[:edited_at]).to be_nil
    end

    it "media_type in submission comment json has video instead of the specific mime type" do
      @submission_comment.media_comment_id = 1
      @submission_comment.media_comment_type = "video/mp4"
      fake_controller.current_user = @student
      submission_comment_json = fake_controller.submission_comment_json(@submission_comment, @student)
      expect(submission_comment_json["media_comment"]["media_type"]).to eq("video")
    end

    it "media_type in submission comment json has audio instead of the specific mime type" do
      @submission_comment.media_comment_id = 1
      @submission_comment.media_comment_type = "audio/mp4"
      fake_controller.current_user = @student
      submission_comment_json = fake_controller.submission_comment_json(@submission_comment, @student)
      expect(submission_comment_json["media_comment"]["media_type"]).to eq("audio")
    end
  end

  describe "#anonymous_moderated_submission_comments_json" do
    let(:course) { Course.create! }
    let(:assignment) { course.assignments.create!(anonymous_grading: true) }
    let(:student) { course.enroll_user(User.create!, "StudentEnrollment", enrollment_state: "active").user }
    let(:student_sub) { assignment.submissions.find_by!(user: student) }
    let(:student2) { course.enroll_user(User.create!, "StudentEnrollment", enrollment_state: "active").user }
    let(:student3) { course.enroll_user(User.create!, "StudentEnrollment", enrollment_state: "active").user }
    let(:teacher) { course.enroll_user(User.create!, "TeacherEnrollment", enrollment_state: "active").user }

    before do
      student_sub.add_comment(author: student, comment: "I'm Student")
    end

    it "contains anonymous ids for students that have comments on a submission" do
      student_sub.add_comment(author: student2, comment: "I'm Student2")
      student2_sub = assignment.submissions.find_by!(user: student2)
      anonymous_ids = @comment.anonymous_moderated_submission_comments_json(
        assignment:,
        avatars: nil,
        course:,
        current_user: teacher,
        submissions: [student_sub],
        submission_comments: student_sub.submission_comments
      ).pluck(:anonymous_id)

      expect(anonymous_ids).to match_array([student_sub.anonymous_id, student2_sub.anonymous_id])
    end

    it "does not contain entries for students that did not comment on the submission" do
      student3_sub = assignment.submissions.find_by!(user: student3)
      student3_comment = @comment.anonymous_moderated_submission_comments_json(
        assignment:,
        avatars: nil,
        course:,
        current_user: teacher,
        submissions: [student_sub],
        submission_comments: student_sub.submission_comments
      ).find { |comment| comment[:anonymous_id] == student3_sub.anonymous_id }

      expect(student3_comment).to be_nil
    end

    it "comments retain author data when the viewing user wrote the comment" do
      student_sub.add_comment(author: student, comment: "I'm Student")
      student_comment = @comment.anonymous_moderated_submission_comments_json(
        assignment:,
        avatars: nil,
        course:,
        current_user: student,
        submissions: [student_sub],
        submission_comments: student_sub.submission_comments
      ).find { |comment| comment[:author_id] == student_sub.user_id }

      expect(student_comment["author_name"]).to eq student.name
    end
  end
end
