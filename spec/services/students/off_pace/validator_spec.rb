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

describe Students::OffPace::Validator do
  describe "#call" do
    subject { described_class.call(student:) }

    let(:student) { user_model }

    before do
      setup_submissions
    end

    context "when the student has an overdue assignment without submission" do
      let(:overdue_assignment) { assignment_model(due_at: 1.day.ago.midnight) }

      def setup_submissions
        submission_model(assignment: overdue_assignment, user: student, submission_type: nil)
      end

      it "returns true" do
        expect(subject).to be true
      end
    end

    context "when the student has an overdue assignment with submission" do
      let(:overdue_assignment) { assignment_model(due_at: 1.day.ago.midnight) }

      def setup_submissions
        submission_model(assignment: overdue_assignment, user: student, submission_type: "online_text_entry")
      end

      it "returns false" do
        expect(subject).to be false
      end
    end

    context "when the student has no overdue assignments" do
      let(:future_assignment) { assignment_model(due_at: 1.day.from_now.midnight) }

      def setup_submissions
        submission_model(assignment: future_assignment, user: student, submission_type: nil)
      end

      it "returns false" do
        expect(subject).to be false
      end
    end
  end
end
