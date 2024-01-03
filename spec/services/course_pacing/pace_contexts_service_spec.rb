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
      let!(:section_one) { add_section("Section One", course:) }
      let!(:inactive_section) { add_section("Section Two", course:) }

      before { inactive_section.destroy! }

      it "returns an array of the active sections" do
        expect(subject.contexts_of_type("section")).to match_array [default_section, section_one]
      end

      it "returns specific sections" do
        params = { contexts: [default_section.id] }
        filtered_contexts = subject.contexts_of_type("section", params:)
        expect(filtered_contexts).to match_array [default_section]
        expect(filtered_contexts).not_to include section_one
      end
    end

    context "for type 'student_enrollment'" do
      let(:student) { user_model(name: "Foo Bar") }
      let(:student_two) { user_model(name: "Bar Foo") }
      let(:student_three) { user_model(name: "Bar") }
      let(:fake_student) { user_model(name: "Fake Student") }
      let!(:enrollment) { course.enroll_student(student, enrollment_state: "active") }
      let!(:enrollment_two) { course.enroll_student(student_two, enrollment_state: "active") }
      let!(:enrollment_three) { course.enroll_student(student_three) }
      let!(:fake_enrollment) { course.enroll_user(fake_student, "StudentViewEnrollment") }

      it "returns an array of the student enrollments" do
        expect(subject.contexts_of_type("student_enrollment")).to match_array [enrollment, enrollment_two, enrollment_three]
        expect(subject.contexts_of_type("student_enrollment")).not_to include fake_enrollment
      end

      it "returns specific student enrollments" do
        params = { contexts: [enrollment_two.id] }
        filtered_contexts = subject.contexts_of_type("student_enrollment", params:)
        expect(filtered_contexts).to match_array [enrollment_two]
        expect(filtered_contexts).not_to include enrollment
      end

      it "returns active and invited enrollments for unpublished courses" do
        enrollment_three.update! workflow_state: "invited"
        enrollment_two.update! workflow_state: "creation_pending"

        expect(course).to be_unpublished
        expect(enrollment_three.reload.state).to be(:invited)
        expect(subject.contexts_of_type("student_enrollment")).to match_array [enrollment, enrollment_two, enrollment_three]
      end

      context "when a user has multiple enrollment sources in a course" do
        let(:section_one) { add_section("Section One", course:) }

        before do
          Timecop.freeze(2.weeks.ago) do
            course.enroll_student(student_two, allow_multiple_enrollments: true, section: section_one, enrollment_state: "active")
          end
        end

        it "returns only the most recently created enrollment" do
          expect(subject.contexts_of_type("student_enrollment")).to match_array [enrollment, enrollment_two, enrollment_three]
        end
      end
    end

    context "for anything else" do
      it "raise for an invalid type" do
        expect { subject.contexts_of_type("foobar") }.to raise_error(ArgumentError)
      end
    end
  end
end
