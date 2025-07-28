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

COURSE_STATUS = "active"

describe Courses::OffPace::Students::Reporter do
  describe "#call" do
    let(:course) { course_model }
    let(:john_doe) { user_model(name: "John Doe") }
    let(:jane_doe) { user_model(name: "Jane Doe") }
    let(:john_smith) { user_model(name: "John Smith") }
    let(:jane_smith) { user_model(name: "Jane Smith") }
    let(:all_students) { [john_doe, jane_doe, john_smith, jane_smith] }
    let(:off_pace_students) { [john_doe, jane_smith] }
    let(:yielded_students) { [] }

    before do
      setup_enrollments
      setup_assignments
      setup_submissions

      described_class.new(course:).call do |student|
        yielded_students << student
      end
    end

    it "yields each off pace student" do
      expect(yielded_students).to include(*off_pace_students)
    end

    it "does not yield students with submissions for past due assignments" do
      expect(yielded_students).not_to include(jane_doe, john_smith)
    end

    private

    def setup_enrollments
      all_students.each { |student| course.enroll_student(student, enrollment_state: COURSE_STATUS) }
    end

    def setup_assignments
      assignment_model(course:, due_at: 1.day.ago.midnight)
      assignment_model(course:, due_at: 1.day.from_now.midnight)
    end

    def setup_submissions
      assignment_past, assignment_future = course.assignments

      all_students.each do |student|
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
