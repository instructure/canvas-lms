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
  end
end
