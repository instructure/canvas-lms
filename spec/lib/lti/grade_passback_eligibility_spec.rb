# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

describe Lti::GradePassbackEligibility do
  subject { test_class.new }

  let(:test_class) do
    Class.new do
      include Lti::GradePassbackEligibility
    end
  end

  before do
    course_with_student(active_all: true)
  end

  describe "#grade_passback_allowed?" do
    def add_student_to_active_section
      section = @course.course_sections.create!(
        name: "Active Section",
        start_at: 2.days.ago,
        end_at: 1.day.from_now,
        restrict_enrollments_to_section_dates: true # section dates can override term dates only if this is true (see EnrollmentDateBuilder.build)
      )
      student_in_section(section, { user: @student })
    end

    context "when course participation is limited to term and the term has passed" do
      before do
        @course.enrollment_term.start_at = 2.days.ago
        @course.enrollment_term.end_at = 1.day.ago
        @course.enrollment_term.save!
      end

      it "does not allow grade passback when student enrollment is concluded by term dates" do
        expect(subject.grade_passback_allowed?(@course, @student)).to be false
      end

      it "allows grade passback when teachers have term overrides" do
        @course.enrollment_term.enrollment_dates_overrides.create!(
          enrollment_type: "TeacherEnrollment",
          enrollment_term: @course.enrollment_term,
          end_at: 1.day.from_now,
          context: @course.account
        )

        expect(subject.grade_passback_allowed?(@course, @student)).to be true
      end

      it "allows grade passback if student has active section enrollment" do
        add_student_to_active_section

        expect(subject.grade_passback_allowed?(@course, @student)).to be true
      end
    end

    context "when course is manually completed" do
      before do
        @course.complete!
      end

      it "does not allow grade passback when course workflow_state is completed" do
        expect(subject.grade_passback_allowed?(@course, @student)).to be false
      end

      it "does not allow grade passback even if student has active section enrollment" do
        add_student_to_active_section

        expect(subject.grade_passback_allowed?(@course, @student)).to be false
      end
    end

    context "when course participation is limited to course start and end dates and these are in the past" do
      before do
        @course.start_at = 3.days.ago
        @course.conclude_at = 1.day.ago
        @course.restrict_enrollments_to_course_dates = true
        @course.save!
      end

      it "does not allow grade passback when course dates have concluded" do
        expect(subject.grade_passback_allowed?(@course, @student)).to be false
      end

      it "allows grade passback if student has active section enrollment" do
        add_student_to_active_section

        expect(subject.grade_passback_allowed?(@course, @student)).to be true
      end
    end
  end
end
