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

require "spec_helper"

describe GradebookUserIds do
  before(:once) do
    @course = Course.create!
    @teacher = teacher_in_course(course: @course, active_all: true).user
    @teacher.preferences[:gradebook_settings] = {}
    @teacher.preferences[:gradebook_settings][@course.id] = {
      show_inactive_enrollments: "false",
      show_concluded_enrollments: "false",
      sort_rows_by_column_id: "student",
      sort_rows_by_setting_key: "name",
      sort_rows_by_direction: "ascending",
      filter_columns_by: {},
      filter_rows_by: {}
    }
    @student1 = student_in_course(
      course: @course,
      active_all: true,
      allow_multiple_enrollments: true
    ).user
    @student1.update!(sortable_name: "Bert")
    @student2 = student_in_course(
      course: @course,
      active_all: true
    ).user
    @student2.update!(sortable_name: "Ernie")
    @student3 = student_in_course(
      course: @course,
      active_all: true
    ).user
    @student3.update!(sortable_name: "Carl")
    inactive_enrollment = student_in_course(
      course: @course,
      active_all: true
    )
    inactive_enrollment.deactivate
    @inactive_student = inactive_enrollment.user
    @inactive_student.update!(sortable_name: "Inactive Student")
    concluded_enrollment = student_in_course(
      course: @course,
      active_all: true,
      name: "Concluded Student"
    )
    concluded_enrollment.conclude
    @concluded_student = concluded_enrollment.user
    @concluded_student.update!(sortable_name: "Concluded Student")
    @fake_student_enrollment = course_with_user('StudentViewEnrollment', course: @course, active_all: true)
    @fake_student = @fake_student_enrollment.user
  end

  let(:gradebook_user_ids) { GradebookUserIds.new(@course, @teacher) }

  it "sorts by sortable name ascending if the user does not have any saved sort preferences" do
    @teacher.preferences[:gradebook_settings] = {}
    expect(gradebook_user_ids.user_ids).to eq([@student1.id, @student3.id, @student2.id, @fake_student.id])
  end

  it "sorts by sortable name ascending if the user's sort preferences are not supported" do
    @teacher.preferences[:gradebook_settings][@course.id][:sort_rows_by_column_id] = "some_new_column"
    expect(gradebook_user_ids.user_ids).to eq([@student1.id, @student3.id, @student2.id, @fake_student.id])
  end

  it "does not return duplicate user ids for students with multiple enrollments" do
    section = @course.course_sections.create!
    student_in_course(
      course: @course,
      user: @student1,
      section: section,
      active_all: true,
      allow_multiple_enrollments: true
    )
    expect(gradebook_user_ids.user_ids).to eq([@student1.id, @student3.id, @student2.id, @fake_student.id])
  end

  it "only returns users belonging to the selected section" do
    section = @course.course_sections.create!
    student_in_course(
      course: @course,
      user: @student1,
      section: section,
      active_all: true,
      allow_multiple_enrollments: true
    )
    @teacher.preferences[:gradebook_settings][@course.id][:filter_rows_by][:section_id] = section.id.to_s
    expect(gradebook_user_ids.user_ids).to eq([@student1.id])
  end

  describe "student sortable name sorting" do
    it "sorts by student sortable name ascending" do
      expect(gradebook_user_ids.user_ids).to eq([@student1.id, @student3.id, @student2.id, @fake_student.id])
    end

    it "excludes fake students if they are deactivated" do
      @fake_student_enrollment.deactivate
      expect(gradebook_user_ids.user_ids).not_to include @fake_student.id
    end

    it "sorts by student sortable name descending" do
      @teacher.preferences[:gradebook_settings][@course.id][:sort_rows_by_direction] = "descending"
      expect(gradebook_user_ids.user_ids).to eq([@student2.id, @student3.id, @student1.id, @fake_student.id])
    end

    it "includes inactive student ids if the user preferences include show_inactive_enrollments" do
      @teacher.preferences[:gradebook_settings][@course.id][:show_inactive_enrollments] = "true"
      expect(gradebook_user_ids.user_ids).to include @inactive_student.id
    end

    it "includes concluded student ids if the user preferences include show_concluded_enrollments" do
      @teacher.preferences[:gradebook_settings][@course.id][:show_concluded_enrollments] = "true"
      expect(gradebook_user_ids.user_ids).to include @concluded_student.id
    end

    it "includes concluded students ids if the course is concluded" do
      @course.complete!
      expect(gradebook_user_ids.user_ids).to eq(
        [@student1.id, @student3.id, @concluded_student.id, @student2.id, @fake_student.id]
      )
    end
  end

  describe "assignment sorting" do
    before(:once) do
      @assignment = @course.assignments.create!(points_possible: 10)
    end

    describe "sort by missing" do
      before(:once) do
        @assignment.grade_student(@student1, grade: 8, grader: @teacher)
        @assignment.grade_student(@student2, grade: 1, grader: @teacher)
        @assignment.grade_student(@student3, grade: 9, grader: @teacher)
        @teacher.preferences[:gradebook_settings][@course.id][:sort_rows_by_column_id] = "assignment_#{@assignment.id}"
        @teacher.preferences[:gradebook_settings][@course.id][:sort_rows_by_setting_key] = "missing"
      end

      it "returns user ids for users with missing submissions first" do
        @assignment.submissions.find_by(user_id: @student3).update!(late_policy_status: "missing")
        expect(gradebook_user_ids.user_ids.first).to eq(@student3.id)
      end

      it "excludes fake students if they are deactivated" do
        @fake_student_enrollment.deactivate
        expect(gradebook_user_ids.user_ids).not_to include @fake_student.id
      end

      it "includes inactive student ids if the user preferences include show_inactive_enrollments" do
        @teacher.preferences[:gradebook_settings][@course.id][:show_inactive_enrollments] = "true"
        expect(gradebook_user_ids.user_ids).to include @inactive_student.id
      end

      it "includes concluded student ids if the user preferences include show_concluded_enrollments" do
        @teacher.preferences[:gradebook_settings][@course.id][:show_concluded_enrollments] = "true"
        expect(gradebook_user_ids.user_ids).to include @concluded_student.id
      end

      it "includes concluded students ids if the course is concluded" do
        @course.complete!
        expect(gradebook_user_ids.user_ids).to match_array(
          [@student1.id, @student2.id, @student3.id, @concluded_student.id, @fake_student.id]
        )
      end
    end

    describe "sort by late" do
      before(:once) do
        @assignment.grade_student(@student1, grade: 8, grader: @teacher)
        @assignment.grade_student(@student2, grade: 1, grader: @teacher)
        @assignment.grade_student(@student3, grade: 9, grader: @teacher)
        @teacher.preferences[:gradebook_settings][@course.id][:sort_rows_by_column_id] = "assignment_#{@assignment.id}"
        @teacher.preferences[:gradebook_settings][@course.id][:sort_rows_by_setting_key] = "late"
      end

      it "returns user ids for users with late submissions first" do
        @assignment.submissions.find_by(user_id: @student3).update!(late_policy_status: "late")
        expect(gradebook_user_ids.user_ids.first).to eq(@student3.id)
      end

      it "excludes fake students if they are deactivated" do
        @fake_student_enrollment.deactivate
        expect(gradebook_user_ids.user_ids).not_to include @fake_student.id
      end

      it "includes inactive student ids if the user preferences include show_inactive_enrollments" do
        @teacher.preferences[:gradebook_settings][@course.id][:show_inactive_enrollments] = "true"
        expect(gradebook_user_ids.user_ids).to include @inactive_student.id
      end

      it "includes concluded student ids if the user preferences include show_concluded_enrollments" do
        @teacher.preferences[:gradebook_settings][@course.id][:show_concluded_enrollments] = "true"
        expect(gradebook_user_ids.user_ids).to include @concluded_student.id
      end

      it "includes concluded students ids if the course is concluded" do
        @course.complete!
        expect(gradebook_user_ids.user_ids).to match_array(
          [@student1.id, @student2.id, @student3.id, @concluded_student.id, @fake_student.id]
        )
      end
    end

    describe "sort by grade" do
      before(:once) do
        @assignment.grade_student(@student1, grade: 8, grader: @teacher)
        @assignment.grade_student(@student2, grade: 1, grader: @teacher)
        @assignment.grade_student(@student3, grade: 9, grader: @teacher)
        @teacher.preferences[:gradebook_settings][@course.id][:sort_rows_by_column_id] = "assignment_#{@assignment.id}"
        @teacher.preferences[:gradebook_settings][@course.id][:sort_rows_by_setting_key] = "grade"
      end

      it "includes concluded students ids if the course is concluded" do
        @course.complete!
        expect(gradebook_user_ids.user_ids).to match_array(
          [@student1.id, @student2.id, @student3.id, @concluded_student.id, @fake_student.id]
        )
      end

      context "ascending" do
        before(:once) do
          @teacher.preferences[:gradebook_settings][@course.id][:sort_rows_by_direction] = "ascending"
        end

        it "returns user ids sorted by grade on the assignment" do
          expect(gradebook_user_ids.user_ids).to eq([@student2.id, @student1.id, @student3.id, @fake_student.id])
        end

        it "excludes fake students if they are deactivated" do
          @fake_student_enrollment.deactivate
          expect(gradebook_user_ids.user_ids).not_to include @fake_student.id
        end

        it "places students without submissions at the end, but before fake students" do
          student4 = student_in_course(course: @course, active_all: true).user
          expect(gradebook_user_ids.user_ids).to eq(
            [@student2.id, @student1.id, @student3.id, student4.id, @fake_student.id]
          )
        end

        it "places students that have been graded with nil grades at the end, but before fake students" do
          @assignment.grade_student(@student1, grade: nil, grader: @teacher)
          expect(gradebook_user_ids.user_ids).to eq([@student2.id, @student3.id, @student1.id, @fake_student.id])
        end

        it "places students that are not assigned at the end, but before fake students" do
          @assignment.update!(only_visible_to_overrides: true)
          create_adhoc_override_for_assignment(@assignment, [@student1, @student3, @student2], due_at: nil)
          student4 = student_in_course(course: @course, active_all: true).user
          expect(gradebook_user_ids.user_ids).to eq(
            [@student2.id, @student1.id, @student3.id, student4.id, @fake_student.id]
          )
        end
      end

      context "descending" do
        before(:once) do
          @teacher.preferences[:gradebook_settings][@course.id][:sort_rows_by_direction] = "descending"
        end

        it "returns user ids sorted by grade on the assignment" do
          expect(gradebook_user_ids.user_ids).to eq([@student3.id, @student1.id, @student2.id, @fake_student.id])
        end

        it "excludes fake students if they are deactivated" do
          @fake_student_enrollment.deactivate
          expect(gradebook_user_ids.user_ids).not_to include @fake_student.id
        end

        it "places students without submissions at the end, but before fake students" do
          student4 = student_in_course(course: @course, active_all: true).user
          expect(gradebook_user_ids.user_ids).to eq(
            [@student3.id, @student1.id, @student2.id, student4.id, @fake_student.id]
          )
        end

        it "places students that have been graded with a nil grade at the end, but before fake students" do
          student3 = student_in_course(course: @course, active_all: true).user
          @assignment.grade_student(student3, grade: nil, grader: @teacher)
          expect(gradebook_user_ids.user_ids).to eq(
            [@student3.id, @student1.id, @student2.id, student3.id, @fake_student.id]
          )
        end

        it "places students that are not assigned at the end, but before fake students" do
          @assignment.update!(only_visible_to_overrides: true)
          create_adhoc_override_for_assignment(@assignment, [@student1, @student3, @student2], due_at: nil)
          student3 = student_in_course(course: @course, active_all: true).user
          expect(gradebook_user_ids.user_ids).to eq(
            [@student3.id, @student1.id, @student2.id, student3.id, @fake_student.id]
          )
        end
      end

      it "includes inactive student ids if the user preferences include show_inactive_enrollments" do
        @teacher.preferences[:gradebook_settings][@course.id][:show_inactive_enrollments] = "true"
        expect(gradebook_user_ids.user_ids).to include @inactive_student.id
      end

      it "includes concluded student ids if the user preferences include show_concluded_enrollments" do
        @teacher.preferences[:gradebook_settings][@course.id][:show_concluded_enrollments] = "true"
        expect(gradebook_user_ids.user_ids).to include @concluded_student.id
      end
    end
  end

  describe "total grade sorting" do
    before(:once) do
      @now = Time.zone.now
      @assignment1 = @course.assignments.create!(points_possible: 10, due_at: 1.month.from_now(@now))
      @assignment2 = @course.assignments.create!(points_possible: 100, due_at: 3.months.from_now(@now))

      @assignment1.grade_student(@student1, grade: 1, grader: @teacher)
      @assignment1.grade_student(@student2, grade: 10, grader: @teacher)
      @assignment1.grade_student(@student3, grade: 5, grader: @teacher)

      @assignment2.grade_student(@student1, grade: 5, grader: @teacher)
      @assignment2.grade_student(@student2, grade: 1, grader: @teacher)
      @assignment2.grade_student(@student3, grade: 100, grader: @teacher)

      @teacher.preferences[:gradebook_settings][@course.id][:sort_rows_by_column_id] = "total_grade"
      @teacher.preferences[:gradebook_settings][@course.id][:sort_rows_by_setting_key] = "grade"
    end

    it "includes concluded students ids if the course is concluded" do
      @course.complete!
      expect(gradebook_user_ids.user_ids).to match_array(
        [@student1.id, @student2.id, @student3.id, @concluded_student.id, @fake_student.id]
      )
    end

    it "sorts by total grade ascending" do
      expect(gradebook_user_ids.user_ids).to eq([@student1.id, @student2.id, @student3.id, @fake_student.id])
    end

    it "excludes fake students if they are deactivated" do
      @fake_student_enrollment.deactivate
      expect(gradebook_user_ids.user_ids).not_to include @fake_student.id
    end

    it "sorts by total grade descending" do
      @teacher.preferences[:gradebook_settings][@course.id][:sort_rows_by_direction] = "descending"
      expect(gradebook_user_ids.user_ids).to eq([@student3.id, @student2.id, @student1.id, @fake_student.id])
    end

    it "includes inactive student ids if the user preferences include show_inactive_enrollments" do
      @teacher.preferences[:gradebook_settings][@course.id][:show_inactive_enrollments] = "true"
      expect(gradebook_user_ids.user_ids).to include @inactive_student.id
    end

    it "includes concluded student ids if the user preferences include show_concluded_enrollments" do
      @teacher.preferences[:gradebook_settings][@course.id][:show_concluded_enrollments] = "true"
      expect(gradebook_user_ids.user_ids).to include @concluded_student.id
    end

    context "Multiple Grading Periods" do
      before(:once) do
        term = @course.enrollment_term
        set = @course.root_account.grading_period_groups.create!
        set.enrollment_terms << term
        @current_period = set.grading_periods.create!(
          title: "Current Period",
          start_date: 1.month.ago(@now),
          end_date: 2.months.from_now(@now)
        )
        @future_period = set.grading_periods.create!(
          title: "Future Period",
          start_date: 2.months.from_now(@now),
          end_date: 4.months.from_now(@now)
        )
      end

      context "ascending" do
        it "sorts by the current grading period totals if no selected grading period is in user preferences" do
          @course.stubs(:grading_periods?).returns(true)
          expect(gradebook_user_ids.user_ids).to eq([@student1.id, @student3.id, @student2.id, @fake_student.id])
        end

        it "sorts by the current grading period totals if a grading period ID of 'null' is in user preferences" do
          @course.stubs(:grading_periods?).returns(true)
          @teacher.preferences[:gradebook_settings][@course.id][:filter_columns_by][:grading_period_id] = "null"
          expect(gradebook_user_ids.user_ids).to eq([@student1.id, @student3.id, @student2.id, @fake_student.id])
        end

        it "sorts by the selected grading period totals if a selected grading period is in user preferences" do
          @course.stubs(:grading_periods?).returns(true)
          @teacher.preferences[:gradebook_settings][@course.id][:filter_columns_by][:grading_period_id] =
            @future_period.id.to_s
          expect(gradebook_user_ids.user_ids).to eq([@student2.id, @student1.id, @student3.id, @fake_student.id])
        end

        it "sorts by 'All Grading Periods' if a grading period ID of '0' is in user preferences" do
          @course.stubs(:grading_periods?).returns(true)
          @teacher.preferences[:gradebook_settings][@course.id][:filter_columns_by][:grading_period_id] = "0"
          expect(gradebook_user_ids.user_ids).to eq([@student1.id, @student2.id, @student3.id, @fake_student.id])
        end
      end

      context "descending" do
        before(:once) do
          @teacher.preferences[:gradebook_settings][@course.id][:sort_rows_by_direction] = "descending"
        end

        it "sorts by the current grading period totals if no selected grading period is in user preferences" do
          @course.stubs(:grading_periods?).returns(true)
          expect(gradebook_user_ids.user_ids).to eq([@student2.id, @student3.id, @student1.id, @fake_student.id])
        end

        it "sorts by the current grading period totals if a grading period ID of 'null' is in user preferences" do
          @course.stubs(:grading_periods?).returns(true)
          @teacher.preferences[:gradebook_settings][@course.id][:filter_columns_by][:grading_period_id] = "null"
          expect(gradebook_user_ids.user_ids).to eq([@student2.id, @student3.id, @student1.id, @fake_student.id])
        end

        it "sorts by the selected grading period totals if a selected grading period is in user preferences" do
          @course.stubs(:grading_periods?).returns(true)
          @teacher.preferences[:gradebook_settings][@course.id][:filter_columns_by][:grading_period_id] =
            @future_period.id.to_s
          expect(gradebook_user_ids.user_ids).to eq([@student3.id, @student1.id, @student2.id, @fake_student.id])
        end

        it "sorts by 'All Grading Periods' if a grading period ID of '0' is in user preferences" do
          @course.stubs(:grading_periods?).returns(true)
          @teacher.preferences[:gradebook_settings][@course.id][:filter_columns_by][:grading_period_id] = "0"
          expect(gradebook_user_ids.user_ids).to eq([@student3.id, @student2.id, @student1.id, @fake_student.id])
        end
      end
    end
  end
end
