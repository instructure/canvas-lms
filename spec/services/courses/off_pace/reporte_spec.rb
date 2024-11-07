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

describe Courses::OffPace::Students::Reporter do
  describe "#call" do
    subject { described_class.call(course:) }

    let(:course) { course_model }
    let(:john_doe) { user_model(name: "John Doe") }
    let(:jane_doe) { user_model(name: "Jane Doe") }
    let(:john_smith) { user_model(name: "John Smith") }
    let(:jane_smith) { user_model(name: "Jane Smith") }

    before do
      setup_course_with_students
      setup_assignments_and_submissions
    end

    it "returns a list of off pace students" do
      expect(subject).to match_array([jane_smith, john_doe])
    end

    private

    def setup_course_with_students
      course.enroll_student(john_doe, enrollment_state: "active")
      course.enroll_student(jane_doe, enrollment_state: "active")
      course.enroll_student(john_smith, enrollment_state: "active")
      course.enroll_student(jane_smith, enrollment_state: "active")
    end

    def setup_assignments_and_submissions
      assignment_past = assignment_model(course:, due_at: 1.day.ago.midnight)
      assignment_future = assignment_model(course:, due_at: 1.day.from_now.midnight)

      off_pace_students = [john_doe, jane_smith]
      [john_doe, jane_doe, john_smith, jane_smith].each do |student|
        submission_model(assignment: assignment_past,
                         user: student,
                         course:,
                         submission_type: off_pace_students.include?(student) ? nil : "online_url")
        submission_model(assignment: assignment_future,
                         user: student,
                         course:,
                         submission_type: off_pace_students.include?(student) ? "online_text_entry" : nil)
      end
    end
  end
end
