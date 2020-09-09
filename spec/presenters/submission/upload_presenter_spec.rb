#
# Copyright (C) 2020 - present Instructure, Inc.
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
require_relative '../../spec_helper'

describe Submission::UploadPresenter do
  before(:once) do
    @course = Course.create!
    @student = User.create!(name: "John Doe")
    @course.enroll_student(@student, enrollment_state: "active")
  end

  let(:file) { { id: 456 } }
  let(:presenter) { Submission::UploadPresenter.for(@course, @assignment) }
  let(:submission) { @assignment.submissions.find_by(user_id: @student.id) }

  let(:comment) do
    { id: 123, submission: { user_id: @student.id, anonymous_id: submission.anonymous_id, user_name: "John Doe" } }
  end

  context "Anonymous assignment" do
    before(:once) do
      @assignment = @course.assignments.create!(anonymous_grading: true, title: "Anonymous Assignment")
    end

    describe "#file_download_href" do
      it "returns an anonymized file download URL" do
        href = presenter.file_download_href(comment, file)
        expect(href).to include "anonymous_submissions/#{submission.anonymous_id}"
      end

      it "fetches the anonymous ID if it isn't included in the comment hash" do
        comment[:submission].delete(:anonymous_id)
        href = presenter.file_download_href(comment, file)
        expect(href).to include "anonymous_submissions/#{submission.anonymous_id}"
      end
    end

    describe "#progress" do
      it "returns the submissions reupload progress object" do
        progress = Progress.create!(context_type: "Assignment", context_id: @assignment, tag: "submissions_reupload")
        expect(presenter.progress).to eq progress
      end
    end

    describe "#submission_href" do
      it "returns an anonymized submission URL" do
        href = presenter.submission_href(comment)
        expect(href).to include "anonymous_id=#{submission.anonymous_id}"
      end

      it "fetches the anonymous ID if it isn't included in the comment hash" do
        comment[:submission].delete(:anonymous_id)
        href = presenter.submission_href(comment)
        expect(href).to include "anonymous_id=#{submission.anonymous_id}"
      end
    end

    describe "#student_name" do
      it "returns a generic, anonymous name" do
        expect(presenter.student_name(comment)).to eq "Anonymous Student"
      end
    end
  end

  context "Non-anonymous assignment" do
    before(:once) do
      @assignment = @course.assignments.create!(title: "Math Assignment")
    end

    describe "#file_download_href" do
      it "returns a file download URL (not anonymized)" do
        href = presenter.file_download_href(comment, file)
        expect(href).to include "submissions/#{submission.user_id}"
      end
    end

    describe "#progress" do
      it "returns the submissions reupload progress object" do
        progress = Progress.create!(context_type: "Assignment", context_id: @assignment, tag: "submissions_reupload")
        expect(presenter.progress).to eq progress
      end
    end

    describe "#submission_href" do
      it "returns a submission URL (not anonymized)" do
        href = presenter.submission_href(comment)
        expect(href).to include "submissions/#{submission.user_id}"
      end
    end

    describe "#student_name" do
      it "returns the student's name" do
        expect(presenter.student_name(comment)).to eq @student.name
      end
    end
  end
end
