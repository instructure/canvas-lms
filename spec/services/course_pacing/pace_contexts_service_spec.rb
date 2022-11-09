# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

describe CoursePacing::PaceContextsService do
  subject { CoursePacing::PaceContextsService.new(course) }

  let(:course) { course_model(name: "My Course") }

  describe ".contexts_of_type" do
    context "for type 'course'" do
      it "returns the course" do
        expect(subject.contexts_of_type("course")).to match_array [course]
      end
    end

    context "for type 'section'" do
      let!(:default_section) { course.default_section }
      let!(:section_one) { add_section("Section One", course: course) }
      let!(:inactive_section) { add_section("Section Two", course: course) }

      before { inactive_section.destroy! }

      it "returns an array of the active sections" do
        expect(subject.contexts_of_type("section")).to match_array [default_section, section_one]
      end
    end

    context "for type 'student_enrollment'" do
      let(:student) { user_model(name: "Foo Bar") }
      let(:student_two) { user_model(name: "Bar Foo") }
      let!(:enrollment) { course.enroll_student(student, enrollment_state: "active") }
      let!(:enrollment_two) { course.enroll_student(student_two, enrollment_state: "active") }

      it "returns an array of the student enrollments" do
        expect(subject.contexts_of_type("student_enrollment")).to match_array [enrollment, enrollment_two]
      end

      context "when a user has multiple enrollment sources in a course" do
        let(:section_one) { add_section("Section One", course: course) }

        before do
          Timecop.freeze(2.weeks.ago) do
            course.enroll_student(student_two, allow_multiple_enrollments: true, section: section_one, enrollment_state: "active")
          end
        end

        it "returns only the most recently created enrollment" do
          expect(subject.contexts_of_type("student_enrollment")).to match_array [enrollment, enrollment_two]
        end
      end
    end

    context "for anything else" do
      it "captures the invalid type" do
        expect(Canvas::Errors).to receive(:capture_exception).with(:pace_contexts_service, "Expected a value of 'course', 'section', or 'student_enrollment', got 'foobar'")
        subject.contexts_of_type("foobar")
      end
    end
  end
end
