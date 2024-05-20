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

describe CoursePacing::StudentEnrollmentPaceService do
  let(:course) { course_model }
  let(:student) { user_model }
  let(:student_enrollment) { course.enroll_student(student, enrollment_state: "active") }
  let(:extra_enrollment) { course.enroll_student(user_model, enrollment_state: "active") }
  let!(:pace) { student_enrollment_pace_model(student_enrollment:) }
  let!(:course_pace) { course_pace_model(course:) }

  describe ".paces_in_course" do
    it "returns the paces for the provided course" do
      expect(
        CoursePacing::StudentEnrollmentPaceService.paces_in_course(course)
      ).to match_array [pace]
    end

    it "does not include deleted paces" do
      pace.destroy!
      expect(
        CoursePacing::StudentEnrollmentPaceService.paces_in_course(course)
      ).to be_empty
    end
  end

  describe ".pace_in_context" do
    it "returns the matching pace" do
      expect(
        CoursePacing::StudentEnrollmentPaceService.pace_in_context(student_enrollment)
      ).to eq pace
    end

    it "returns nil" do
      expect(
        CoursePacing::StudentEnrollmentPaceService.pace_in_context(extra_enrollment)
      ).to be_nil
    end
  end

  describe ".template_pace_for" do
    context "the enrollment is within a section" do
      let(:section) { add_section("Section One", course:) }
      let(:student_enrollment) { multiple_student_enrollment(student, section, course:) }

      context "when the section has a pace" do
        let!(:section_pace) { section_pace_model(section:) }

        it "returns the section pace" do
          expect(CoursePacing::StudentEnrollmentPaceService.template_pace_for(student_enrollment)).to eq section_pace
        end
      end

      context "when the section does not have a pace" do
        context "when the course has a pace" do
          it "returns the course pace" do
            expect(CoursePacing::StudentEnrollmentPaceService.template_pace_for(student_enrollment)).to eq course_pace
          end
        end

        context "when the course does not have a pace" do
          before { course_pace.destroy! }

          it "returns nil" do
            expect(CoursePacing::StudentEnrollmentPaceService.template_pace_for(student_enrollment)).to be_nil
          end
        end
      end
    end

    context "when the enrollment is not within a section" do
      context "when the course has a pace" do
        it "returns the course pace" do
          expect(CoursePacing::StudentEnrollmentPaceService.template_pace_for(student_enrollment)).to eq course_pace
        end
      end

      context "when the course does not have a pace" do
        before { course_pace.destroy! }

        it "returns nil" do
          expect(CoursePacing::StudentEnrollmentPaceService.template_pace_for(student_enrollment)).to be_nil
        end
      end
    end
  end

  describe ".create_in_context" do
    context "when the context already has a pace" do
      it "returns the pace" do
        expect(CoursePacing::StudentEnrollmentPaceService.create_in_context(student_enrollment)).to eq pace
      end
    end

    context "when the context does not have a pace" do
      it "creates a pace in the context" do
        expect do
          CoursePacing::StudentEnrollmentPaceService.create_in_context(extra_enrollment)
        end.to change {
          extra_enrollment.course_paces.count
        }.by 1
      end
    end
  end

  describe ".update_pace" do
    let(:update_params) { { exclude_weekends: false } }

    context "the update is successful" do
      it "returns the updated pace" do
        expect do
          expect(
            CoursePacing::StudentEnrollmentPaceService.update_pace(pace, update_params)
          ).to eq pace
        end.to change {
          pace.exclude_weekends
        }.to false
      end
    end

    context "the update failed" do
      it "returns false" do
        allow(pace).to receive(:update).and_return false
        expect(
          CoursePacing::StudentEnrollmentPaceService.update_pace(pace, update_params)
        ).to be false
      end
    end
  end

  describe ".delete_in_context" do
    it "deletes the matching pace" do
      expect do
        CoursePacing::StudentEnrollmentPaceService.delete_in_context(student_enrollment)
      end.to change {
        student_enrollment.course_paces.not_deleted.count
      }.by(-1)
    end

    it "raises RecordNotFound when the pace is not found" do
      expect do
        CoursePacing::StudentEnrollmentPaceService.delete_in_context(extra_enrollment)
      end.to raise_error ActiveRecord::RecordNotFound
    end
  end

  describe ".valid_context?" do
    before :once do
      section_one = add_section("Section One", course:)
      @first_student_enrollment = course.enroll_student(student, enrollment_state: "active", allow_multiple_enrollments: true)
      @last_student_enrollment = course.enroll_student(student, enrollment_state: "active", section: section_one, allow_multiple_enrollments: true)
    end

    it "returns false for enrollments other than the student's most recent" do
      expect(
        CoursePacing::StudentEnrollmentPaceService.valid_context?(@first_student_enrollment)
      ).to be false
    end

    it "returns true for the most recent student enrollment" do
      expect(
        CoursePacing::StudentEnrollmentPaceService.valid_context?(@last_student_enrollment)
      ).to be true
    end

    it "returns false if there is no active student enrollment for the given student enrollment" do
      extra_enrollment = course.enroll_student(user_model, enrollment_state: "deleted")
      expect(
        CoursePacing::StudentEnrollmentPaceService.valid_context?(extra_enrollment)
      ).to be false
    end
  end
end
