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

describe DataFixup::BackfillPostedAtOnSubmissions do
  let(:course) { Course.create! }
  let(:assignment) { course.assignments.create!(title: "fred") }
  let(:student) { course.enroll_student(User.create!).user }
  let(:submission) { assignment.submission_for_student(student) }

  def do_backfill
    DataFixup::BackfillPostedAtOnSubmissions.run(submission.id, submission.id + 1)
    submission.reload
  end
  private :do_backfill

  it "sets the posted_at date to the graded_at date if graded_at is non-nil" do
    submission.update!(graded_at: 2.days.ago)
    do_backfill

    expect(submission.posted_at).to eq(submission.graded_at)
  end

  it "does not set the posted_at date if graded_at is nil" do
    do_backfill

    expect(submission.posted_at).to be_nil
  end

  it "does not change the posted_at date if it is already non-nil" do
    posted_at = 1.day.ago
    submission.update!(graded_at: 2.days.ago, posted_at: posted_at)
    submission.reload

    expect { do_backfill }.not_to change { submission.posted_at }
  end
end
