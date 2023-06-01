# frozen_string_literal: true

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
#

require_relative "../../spec_helper"

describe Submissions::AnonymousSubmissionForShow do
  subject { submission_for_show }

  let(:course) do
    course_with_student
    @course.account.enable_service(:avatars)
    @course
  end

  let(:student) do
    course
    @student
  end

  let(:assignment) { course.assignments.create! }
  let(:submission) do
    Timecop.freeze(2.hours.ago) do
      assignment.submit_homework(student, { body: "hello" })
    end
  end

  describe "#assignment" do
    it "returns assignment found with given assignment_id" do
      expect(submission_for_show.assignment).to eql assignment
    end
  end

  describe "#user" do
    it "returns user found with given anonymous_id" do
      expect(submission_for_show.user).to eql student
    end
  end

  describe "#submission" do
    it "returns the submission for the given assignment_id and anonymous_id" do
      expect(submission_for_show.submission).to eql submission
    end

    it "returns a new submission when the given anonymous_id does not match an active record" do
      Submission.delete_all
      submission_for_show = Submissions::AnonymousSubmissionForShow.new(
        anonymous_id: "abc12",
        assignment_id: assignment.id,
        context: course
      )
      expect(submission_for_show.submission).to be_new_record
    end

    context "when the assignment is not a quiz" do
      before :once do
        course_with_student
        @course.account.enable_service(:avatars)
        assignment = @course.assignments.create!
        submission = Timecop.freeze(2.hours.ago) do
          assignment.submit_homework(@student, { body: "hello" })
        end
        Timecop.freeze(1.hour.ago) do
          submission.with_versioning(explicit: true) do
            submission.body = "...world!"
            submission.save!
          end
        end
      end

      it "returns the submission matching the given version" do
        submission_for_show = submission_for_show(preview: true, version: 0)
        expect(submission_for_show.submission.version_number).to be 1
      end

      it "returns the root submission when the given version does not match" do
        submission_for_show = submission_for_show(preview: true, version: 5)
        expect(submission_for_show.submission.version_number).to be 1
      end
    end

    it "returns the root submission for a quiz" do
      quiz = course.quizzes.create!
      quiz_submission = quiz.quiz_submissions.create!(user: student)
      quiz_submission.with_versioning(explicit: true) do
        quiz_submission.update_attribute(:finished_at, 1.hour.ago)
      end
      # version 2 (requested using 1) is the latest version
      submission_for_show = submission_for_show(preview: true, version: 1)
      # version 1 is the first version
      expect(submission_for_show.submission.version_number).to be 1
    end
  end

  def submission_for_show(version: nil, preview: false)
    Submissions::AnonymousSubmissionForShow.new(
      anonymous_id: submission.anonymous_id,
      assignment_id: assignment.id,
      context: course,
      preview:,
      version:
    )
  end
end
