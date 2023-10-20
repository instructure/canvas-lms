# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

require_relative "../graphql_spec_helper"

describe Types::EnrollmentType do
  let_once(:enrollment) { student_in_course(active_all: true) }
  let_once(:teacher_enrollment) { teacher_in_course(active_all: true) }

  let(:enrollment_type) { GraphQLTypeTester.new(enrollment, current_user: @student) }
  let(:teacher_enrollment_type) { GraphQLTypeTester.new(teacher_enrollment, current_user: @teacher) }

  it "works" do
    expect(enrollment_type.resolve("_id")).to eq enrollment.id.to_s
    expect(enrollment_type.resolve("type")).to eq "StudentEnrollment"
    expect(enrollment_type.resolve("state")).to eq "active"
    expect(enrollment_type.resolve("sisImportId")).to eq enrollment.sis_batch_id
  end

  describe Types::GradesType do
    before(:once) do
      gpg = GradingPeriodGroup.create!(account_id: Account.default)
      @course.enrollment_term.update_attribute :grading_period_group, gpg
      @gp1 = gpg.grading_periods.create! title: "asdf", start_date: Date.yesterday, end_date: Date.tomorrow
      @gp2 = gpg.grading_periods.create! title: "zxcv", start_date: 2.days.from_now, end_date: 1.year.from_now
    end

    it "uses the current grading period by default" do
      expect(
        enrollment_type.resolve(
          "grades { gradingPeriod { _id } }"
        )
      ).to eq @gp1.id.to_s
    end

    it "lets you specify a different grading period" do
      expect(
        enrollment_type.resolve(<<~GQL, current_user: @teacher)
          grades(gradingPeriodId: "#{@gp2.id}") {
            gradingPeriod { _id }
          }
        GQL
      ).to eq @gp2.id.to_s
    end

    it "returns the overall course grade when gradingPeriodId is null" do
      expect(
        enrollment_type.resolve(<<~GQL, current_user: @teacher)
          grades(gradingPeriodId: null) {
            finalScore
          }
        GQL
      ).to eq enrollment.computed_final_score
    end

    it "works for courses with no grading periods" do
      @course.enrollment_term.update_attribute :grading_period_group, nil
      expect(
        enrollment_type.resolve(
          "grades { gradingPeriod { _id } }",
          current_user: @teacher
        )
      ).to be_nil
    end

    it "works even when no scores exist" do
      ScoreMetadata.delete_all
      Score.delete_all

      expect(
        enrollment_type.resolve(
          "grades { currentScore }",
          current_user: @teacher
        )
      ).to be_nil
    end

    describe Types::GradingPeriodType do
      it "works" do
        expect(
          enrollment_type.resolve(<<~GQL, current_user: @teacher)
            grades { gradingPeriod { title } }
          GQL
        ).to eq @gp1.title

        expect(
          enrollment_type.resolve(<<~GQL, current_user: @teacher)
            grades { gradingPeriod { startDate } }
          GQL
        ).to eq @gp1.start_date.iso8601

        expect(
          enrollment_type.resolve(<<~GQL, current_user: @teacher)
            grades { gradingPeriod { endDate } }
          GQL
        ).to eq @gp1.end_date.iso8601
      end
    end
  end

  context "section" do
    it "works" do
      expect(
        enrollment_type.resolve("section { _id }")
      ).to eq enrollment.course_section.id.to_s
      expect(enrollment_type.resolve("courseSectionId")).to eq enrollment.course_section.id.to_s
    end
  end

  context "concluded" do
    context "teacher enrollment" do
      it "returns false if the enrollment is not completed" do
        expect(teacher_enrollment_type.resolve("concluded")).to be false
      end

      it "returns true if the date is past the enrollment term end at time" do
        course = teacher_enrollment.course
        course.enrollment_term.update_attribute :end_at, 1.day.ago
        expect(teacher_enrollment_type.resolve("concluded")).to be true
      end

      it "returns false if the date is before the enrollment term end at time" do
        course = teacher_enrollment.course
        course.enrollment_term.update_attribute :end_at, 5.days.from_now
        expect(teacher_enrollment_type.resolve("concluded")).to be false
      end

      it "returns false when section override is past course end date" do
        course = teacher_enrollment.course
        # Course is soft concluded
        course.start_at = 2.days.ago
        course.conclude_at = 1.day.ago
        course.restrict_enrollments_to_course_dates = true

        # Section override is past course end date
        my_section = course.course_sections.first
        my_section.start_at = 1.day.ago
        my_section.end_at = 5.days.from_now
        my_section.restrict_enrollments_to_section_dates = true
        my_section.save!
        course.save!

        my_section.enroll_user(@teacher, "TeacherEnrollment", enrollment_state: "active")

        expect(teacher_enrollment_type.resolve("concluded")).to be false
      end

      it "returns true when section override ends before course end date" do
        course = teacher_enrollment.course
        # Course is not soft concluded
        course.start_at = 2.days.ago
        course.conclude_at = 5.days.from_now
        course.restrict_enrollments_to_course_dates = true
        course.save!
        # Section override is past course end date
        my_section = course.course_sections.first
        my_section.start_at = 2.days.ago
        my_section.end_at = 1.day.ago
        my_section.restrict_enrollments_to_section_dates = true
        my_section.save!

        my_section.enroll_user(@teacher, "TeacherEnrollment", enrollment_state: "active")

        expect(teacher_enrollment_type.resolve("concluded")).to be true
      end

      it "does not errors out when course conclude_at is nil and returns correct value" do
        course = teacher_enrollment.course

        # Course is not soft concluded and has a nil conclude_at
        course.start_at = 2.days.ago
        course.conclude_at = nil
        course.restrict_enrollments_to_course_dates = true
        course.save!

        course.enroll_user(@teacher, "TeacherEnrollment", enrollment_state: "active")

        expect(teacher_enrollment_type.resolve("concluded")).to be false
      end

      it "does not errors out when section end_at is nil and returns correct value" do
        course = teacher_enrollment.course

        # Course is not soft concluded and has a nil conclude_at
        course.start_at = 2.days.ago
        course.conclude_at = nil
        course.restrict_enrollments_to_course_dates = true
        course.save!

        # Section end_at is nil
        my_section = course.course_sections.first
        my_section.start_at = 2.days.ago
        my_section.end_at = nil
        my_section.restrict_enrollments_to_section_dates = true
        my_section.save!

        my_section.enroll_user(@teacher, "TeacherEnrollment", enrollment_state: "active")

        expect(teacher_enrollment_type.resolve("concluded")).to be false
      end

      it "returns true when enrollment is concluded" do
        teacher_enrollment.complete!
        expect(teacher_enrollment_type.resolve("concluded")).to be true
      end

      it "returns true when course is soft_concluded" do
        course = teacher_enrollment.course
        course.start_at = 2.days.ago
        course.conclude_at = 1.day.ago
        course.restrict_enrollments_to_course_dates = true
        course.save!
        expect(teacher_enrollment_type.resolve("concluded")).to be true
      end

      it "returns true when course is hard_concluded" do
        teacher_enrollment.course.complete!
        expect(teacher_enrollment_type.resolve("concluded")).to be true
      end
    end

    context "student enrollment" do
      it "returns false if the enrollment is not completed" do
        expect(enrollment_type.resolve("concluded")).to be false
      end

      it "returns true if the date is past the enrollment term end at time" do
        course = enrollment.course
        course.enrollment_term.update_attribute :end_at, 1.day.ago
        expect(enrollment_type.resolve("concluded")).to be true
      end

      it "returns false if the date is before the enrollment term end at time" do
        course = enrollment.course
        course.enrollment_term.update_attribute :end_at, 5.days.from_now
        expect(enrollment_type.resolve("concluded")).to be false
      end

      it "returns false when section override is past course end date" do
        course = enrollment.course
        # Course is soft concluded
        course.start_at = 2.days.ago
        course.conclude_at = 1.day.ago
        course.restrict_enrollments_to_course_dates = true

        # Section override is past course end date
        my_section = course.course_sections.first
        my_section.start_at = 1.day.ago
        my_section.end_at = 5.days.from_now
        my_section.restrict_enrollments_to_section_dates = true
        my_section.save!
        course.save!

        my_section.enroll_user(@student, "StudentEnrollment", enrollment_state: "active")

        expect(enrollment_type.resolve("concluded")).to be false
      end

      it "returns true when section override ends before course end date" do
        course = enrollment.course
        # Course is not soft concluded
        course.start_at = 2.days.ago
        course.conclude_at = 5.days.from_now
        course.restrict_enrollments_to_course_dates = true
        course.save!
        # Section override is past course end date
        my_section = course.course_sections.first
        my_section.start_at = 2.days.ago
        my_section.end_at = 1.day.ago
        my_section.restrict_enrollments_to_section_dates = true
        my_section.save!

        my_section.enroll_user(@student, "StudentEnrollment", enrollment_state: "active")

        expect(enrollment_type.resolve("concluded")).to be true
      end

      it "returns true when enrollment is concluded" do
        enrollment.complete!
        expect(enrollment_type.resolve("concluded")).to be true
      end

      it "returns true when course is soft_concluded" do
        course = enrollment.course
        course.start_at = 2.days.ago
        course.conclude_at = 1.day.ago
        course.restrict_enrollments_to_course_dates = true
        course.save!
        expect(enrollment_type.resolve("concluded")).to be true
      end

      it "returns true when course is hard_concluded" do
        enrollment.course.complete!
        expect(enrollment_type.resolve("concluded")).to be true
      end
    end
  end

  describe "associated_user" do
    it "returns the associated user when one exists" do
      observer = User.create!
      observer_enrollment = observer_in_course(course: @course, user: observer)
      observer_enrollment.update!(associated_user: @student)

      tester = GraphQLTypeTester.new(observer_enrollment, current_user: @observer)
      expect(tester.resolve("associatedUser { _id }")).to eq @student.id.to_s
    end

    it "returns nil when no associated user exists" do
      expect(enrollment_type.resolve("associatedUser { _id }")).to be_nil
    end
  end
end
