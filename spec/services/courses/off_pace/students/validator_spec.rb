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

describe Courses::OffPace::Students::Validator do
  describe "#call" do
    subject { described_class.call(student:, course_id:) }

    let(:student) { user_model }
    let(:course) { course_model }
    let(:course_id) { course.id }
    let(:overdue_assignment) { assignment_model(due_at: 1.day.ago.midnight, course:) }

    it "returns true if the student has an overdue assignment without submission for the given course" do
      submission_model(assignment: overdue_assignment, user: student, submission_type: nil)
      expect(subject).to be true
    end

    it "returns false if the student has an overdue assignment with submission for the given course" do
      submission_model(assignment: overdue_assignment, user: student, submission_type: "online_text_entry")
      expect(subject).to be false
    end

    it "returns false if the student has no overdue assignments for the given course" do
      future_assignment = assignment_model(due_at: 1.day.from_now.midnight, course:)
      submission_model(assignment: overdue_assignment, user: student, submission_type: "online_text_entry")
      submission_model(assignment: future_assignment, user: student, submission_type: nil)
      expect(subject).to be false
    end

    context "when student is not passed" do
      let(:student) { nil }

      it "raises an ArgumentError" do
        expect { subject }.to raise_error(ArgumentError, "student is required")
      end
    end

    context "when course_id is not passed" do
      let(:course_id) { nil }

      it "raises an ArgumentError" do
        expect { subject }.to raise_error(ArgumentError, "course_id is required")
      end
    end
  end
end
