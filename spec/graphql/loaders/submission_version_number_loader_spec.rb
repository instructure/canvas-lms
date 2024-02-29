# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

describe Loaders::SubmissionVersionNumberLoader do
  before do
    account = Account.create!
    course = account.courses.create!
    @student = course.enroll_student(User.create!, enrollment_state: "active").user
    @assignment = course.assignments.create!(title: "Example Assignment")
  end

  let(:submission) { @assignment.submissions.find_by(user: @student) }
  let(:loader) { Loaders::SubmissionVersionNumberLoader }

  it "returns 0 if the student has not submitted" do
    GraphQL::Batch.batch do
      loader.load(submission).then do |version_number|
        expect(version_number).to eq 0
      end
    end
  end

  it "returns the most recent version number" do
    @assignment.submit_homework(
      @student,
      submission_type: "online_text_entry",
      body: "body"
    )

    GraphQL::Batch.batch do
      loader.load(submission).then do |version_number|
        expect(version_number).to eq 1
      end
    end
  end

  it "works when dealing with different attempts for the same submission" do
    @assignment.submit_homework(
      @student,
      submission_type: "online_text_entry",
      body: "1st submission"
    )

    Timecop.travel(1.minute.from_now) do
      @assignment.submit_homework(
        @student,
        submission_type: "online_text_entry",
        body: "2nd submission"
      )
    end

    first_attempt, second_attempt = submission.submission_history
    GraphQL::Batch.batch do
      loader.load(first_attempt).then do |version_number|
        expect(version_number).to eq 1
      end

      loader.load(second_attempt).then do |version_number|
        expect(version_number).to eq 2
      end
    end
  end
end
