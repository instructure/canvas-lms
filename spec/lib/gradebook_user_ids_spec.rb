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
  let_once :has_pg_collkey do
    status = if User.connection.extension_installed?(:pg_collkey)
      begin
        Bundler.require 'icu'
        true
      rescue LoadError
        skip 'requires icu locally SD-2747'
        false
      end
    end

    status || false
  end

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
    @student4 = student_in_course(
      course: @course,
      active_all: true
    ).user
    @student4.update!(sortable_name: "carl")
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
    @fake_student.update!(sortable_name: "Baker")
  end

  let(:gradebook_user_ids) { GradebookUserIds.new(@course, @teacher) }

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

  context "with viewing user's privileges limited" do
    let!(:viewable_section) { @course.course_sections.create! }

    before(:each) do
      teacher_in_section(
        viewable_section,
        # we omit allow_multiple_enrollments here to clear this user's existing enrollments
        limit_privileges_to_course_section: true,
        user: @teacher
      )

      student_in_section(
        viewable_section,
        user: @student1
      )
    end

    it "only returns users in the teacher's sections" do
      another_viewable_section = @course.course_sections.create!
      teacher_in_section(
        another_viewable_section,
        allow_multiple_enrollments: true,
        limit_privileges_to_course_section: true,
        user: @teacher
      )
      student_in_section(
        another_viewable_section,
        user: @student2
      )

      unviewable_section = @course.course_sections.create!
      student_in_section(
        unviewable_section,
        user: @student3
      )

      expect(gradebook_user_ids.user_ids).to contain_exactly(@student1.id, @student2.id)
    end

    it "returns visible inactive/concluded users" do
      @student1.enrollments.find_by(course_section: viewable_section).deactivate

      student_in_section(
        viewable_section,
        user: @student2
      )
      @student2.enrollments.find_by(course_section: viewable_section).conclude

      @teacher.preferences[:gradebook_settings] = {
        @course.id => {
          show_inactive_enrollments: "true",
          show_concluded_enrollments: "true"
        }
      }
      expect(gradebook_user_ids.user_ids).to contain_exactly(@student1.id, @student2.id)
    end
  end

  context 'with pg_collkey installed' do
    before do
      skip 'requires pg_collkey installed SD-2747' unless has_pg_collkey
    end

    it "sorts by sortable name ascending if the user does not have any saved sort preferences" do
      @teacher.preferences[:gradebook_settings] = {}
      expected_result = [@student1.id, @student4.id, @student3.id, @student2.id, @fake_student.id]
      expect(gradebook_user_ids.user_ids).to eq(expected_result)
    end

    it "sorts by sortable name ascending if the user's sort preferences are not supported" do
      @teacher.preferences[:gradebook_settings][@course.id][:sort_rows_by_column_id] = "some_new_column"
      expected_user_ids = [@student1.id, @student4.id, @student3.id, @student2.id, @fake_student.id]
      expect(gradebook_user_ids.user_ids).to eq(expected_user_ids)
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
      expected_user_ids = [@student1.id, @student4.id, @student3.id, @student2.id, @fake_student.id]
      expect(gradebook_user_ids.user_ids).to eq(expected_user_ids)
    end
  end

  context 'with pg_collkey not installed' do
    before do
      skip 'requires pg_collkey to not be installed SD-2747' if has_pg_collkey
    end

    it "sorts by sortable name ascending if the user does not have any saved sort preferences" do
      @teacher.preferences[:gradebook_settings] = {}
      expected_result = [@student1.id, @student3.id, @student4.id, @student2.id, @fake_student.id]
      expect(gradebook_user_ids.user_ids).to eq(expected_result)
    end

    it "sorts by sortable name ascending if the user's sort preferences are not supported" do
      @teacher.preferences[:gradebook_settings][@course.id][:sort_rows_by_column_id] = "some_new_column"
      expected_user_ids = [@student1.id, @student3.id, @student4.id, @student2.id, @fake_student.id]
      expect(gradebook_user_ids.user_ids).to eq(expected_user_ids)
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
      expected_user_ids = [@student1.id, @student3.id, @student4.id, @student2.id, @fake_student.id]
      expect(gradebook_user_ids.user_ids).to eq(expected_user_ids)
    end
  end

  describe "student sortable name sorting" do
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

    it "does not include concluded student ids if the course is soft concluded" do
      @course.conclude_at = 1.day.ago
      expect(gradebook_user_ids.user_ids).not_to include @concluded_student.id
    end

    context 'with pg_collkey installed' do
      before do
        skip 'requires pg_collkey installed SD-2747' unless has_pg_collkey
      end

      it "sorts by student sortable name ascending" do
        expected_user_ids = [@student1.id, @student4.id, @student3.id, @student2.id, @fake_student.id]
        expect(gradebook_user_ids.user_ids).to eq(expected_user_ids)
      end

      it "sorts by student sortable name descending" do
        @teacher.preferences[:gradebook_settings][@course.id][:sort_rows_by_direction] = "descending"
        expected_user_ids = [@student2.id, @student3.id, @student4.id, @student1.id, @fake_student.id]
        expect(gradebook_user_ids.user_ids).to eq(expected_user_ids)
      end

      it "includes concluded students ids if the course is concluded" do
        @course.complete!
        expect(gradebook_user_ids.user_ids).to eq(
          [@student1.id, @student4.id, @student3.id, @concluded_student.id, @student2.id, @fake_student.id]
        )
      end
    end

    context 'with pg_collkey not installed' do
      before do
        skip 'requires pg_collkey to not be installed SD-2747' if has_pg_collkey
      end

      it "sorts by student sortable name ascending" do
        expected_user_ids = [@student1.id, @student3.id, @student4.id, @student2.id, @fake_student.id]
        expect(gradebook_user_ids.user_ids).to eq(expected_user_ids)
      end

      it "sorts by student sortable name descending" do
        @teacher.preferences[:gradebook_settings][@course.id][:sort_rows_by_direction] = "descending"
        expected_user_ids = [@student2.id, @student4.id, @student3.id, @student1.id, @fake_student.id]
        expect(gradebook_user_ids.user_ids).to eq(expected_user_ids)
      end

      it "includes concluded students ids if the course is concluded" do
        @course.complete!
        expect(gradebook_user_ids.user_ids).to eq(
          [@student1.id, @student3.id, @student4.id, @concluded_student.id, @student2.id, @fake_student.id]
        )
      end
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
        @assignment.grade_student(@student4, grade: 9, grader: @teacher)
        @teacher.preferences[:gradebook_settings][@course.id][:sort_rows_by_column_id] = "assignment_#{@assignment.id}"
        @teacher.preferences[:gradebook_settings][@course.id][:sort_rows_by_setting_key] = "missing"
      end

      it "returns user ids for users with missing submissions first" do
        @assignment.submissions.find_by(user_id: @student3).update!(late_policy_status: "missing")
        expect(gradebook_user_ids.user_ids.first).to eq(@student3.id)
      end

      it "puts fake users at the end, ordered by their sortable_name and user_id" do
        fake_student_enrollment2 = course_with_user('StudentViewEnrollment', course: @course, active_all: true)
        fake_student2 = fake_student_enrollment2.user
        fake_student2.update!(sortable_name: "Alpha")
        # rubocop:disable Rails/SkipsModelValidations
        @assignment.submissions.where(user_id: [@student3]).update_all(late_policy_status: "missing")
        # rubocop:enable Rails/SkipsModelValidations
        expect(gradebook_user_ids.user_ids[-2..-1]).to eq([fake_student2.id, @fake_student.id])
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
          [@student1.id, @student2.id, @student4.id, @student3.id, @concluded_student.id, @fake_student.id]
        )
      end

      it "does not include concluded student ids if the course is soft concluded" do
        @course.conclude_at = 1.day.ago
        expect(gradebook_user_ids.user_ids).not_to include @concluded_student.id
      end

      context 'when pg_collkey is installed' do
        before do
          skip 'requires pg_collkey installed SD-2747' unless has_pg_collkey
        end

        it "orders the missing user_ids by their sortable_name and user_id" do
          # rubocop:disable Rails/SkipsModelValidations
          @assignment.submissions.where(user: [@student2, @student3, @student4]).update_all(late_policy_status: "missing")
          # rubocop:enable Rails/SkipsModelValidations
          expect(gradebook_user_ids.user_ids[0..2]).to eq([@student4.id, @student3.id, @student2.id])
        end

        it "puts non-missing, real users in the middle, ordered by their sortable_name and user_id" do
          # rubocop:disable Rails/SkipsModelValidations
          @assignment.submissions.where(user_id: [@student2]).update_all(late_policy_status: "missing")
          # rubocop:enable Rails/SkipsModelValidations
          expect(gradebook_user_ids.user_ids[1..3]).to eq([@student1.id, @student4.id, @student3.id])
        end
      end

      context 'when pg_collkey is not installed' do
        before do
          skip 'requires pg_collkey to not be installed SD-2747' if has_pg_collkey
        end

        it "orders the missing user_ids by their sortable_name and user_id" do
          # rubocop:disable Rails/SkipsModelValidations
          @assignment.submissions.where(user: [@student2, @student3, @student4]).update_all(late_policy_status: "missing")
          # rubocop:enable Rails/SkipsModelValidations
          expect(gradebook_user_ids.user_ids[0..2]).to eq([@student3.id, @student4.id, @student2.id])
        end

        it "puts non-missing, real users in the middle, ordered by their sortable_name and user_id" do
          # rubocop:disable Rails/SkipsModelValidations
          @assignment.submissions.where(user_id: [@student2]).update_all(late_policy_status: "missing")
          # rubocop:enable Rails/SkipsModelValidations
          expect(gradebook_user_ids.user_ids[1..3]).to eq([@student1.id, @student3.id, @student4.id])
        end
      end
    end

    describe "sort by late" do
      before(:once) do
        @assignment.grade_student(@student1, grade: 8, grader: @teacher)
        @assignment.grade_student(@student2, grade: 1, grader: @teacher)
        @assignment.grade_student(@student3, grade: 9, grader: @teacher)
        @assignment.grade_student(@student4, grade: 9, grader: @teacher)
        @teacher.preferences[:gradebook_settings][@course.id][:sort_rows_by_column_id] = "assignment_#{@assignment.id}"
        @teacher.preferences[:gradebook_settings][@course.id][:sort_rows_by_setting_key] = "late"
      end

      it "returns user ids for users with late submissions first" do
        @assignment.submissions.find_by(user_id: @student3).update!(late_policy_status: "late")
        expect(gradebook_user_ids.user_ids.first).to eq(@student3.id)
      end

      it "puts fake users at the end, ordered by their sortable_name and user_id" do
        fake_student_enrollment2 = course_with_user('StudentViewEnrollment', course: @course, active_all: true)
        fake_student2 = fake_student_enrollment2.user
        fake_student2.update!(sortable_name: "Alpha")
        # rubocop:disable Rails/SkipsModelValidations
        @assignment.submissions.where(user_id: [@student3]).update_all(late_policy_status: "late")
        # rubocop:enable Rails/SkipsModelValidations
        expect(gradebook_user_ids.user_ids[-2..-1]).to eq([fake_student2.id, @fake_student.id])
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
          [@student1.id, @student2.id, @student4.id, @student3.id, @concluded_student.id, @fake_student.id]
        )
      end

      it "does not include concluded student ids if the course is soft concluded" do
        @course.conclude_at = 1.day.ago
        expect(gradebook_user_ids.user_ids).not_to include @concluded_student.id
      end

      context 'when pg_collkey is installed' do
        before do
          skip 'requires pg_collkey installed SD-2747' unless has_pg_collkey
        end

        it "orders the missing user_ids by their sortable_name and user_id" do
          # rubocop:disable Rails/SkipsModelValidations
          @assignment.submissions.where(user: [@student2, @student3, @student4]).update_all(late_policy_status: "late")
          # rubocop:enable Rails/SkipsModelValidations
          expect(gradebook_user_ids.user_ids[0..2]).to eq([@student4.id, @student3.id, @student2.id])
        end

        it "puts non-late, real users in the middle, ordered by their sortable_name and user_id" do
          # rubocop:disable Rails/SkipsModelValidations
          @assignment.submissions.where(user_id: [@student2]).update_all(late_policy_status: "late")
          # rubocop:enable Rails/SkipsModelValidations
          expect(gradebook_user_ids.user_ids[1..3]).to eq([@student1.id, @student4.id, @student3.id])
        end
      end

      context 'when pg_collkey is not installed' do
        before do
          skip 'requires pg_collkey to not be installed SD-2747' if has_pg_collkey
        end

        it "orders the missing user_ids by their sortable_name and user_id" do
          # rubocop:disable Rails/SkipsModelValidations
          @assignment.submissions.where(user: [@student2, @student3, @student4]).update_all(late_policy_status: "late")
          # rubocop:enable Rails/SkipsModelValidations
          expect(gradebook_user_ids.user_ids[0..2]).to eq([@student3.id, @student4.id, @student2.id])
        end

        it "puts non-late, real users in the middle, ordered by their sortable_name and user_id" do
          # rubocop:disable Rails/SkipsModelValidations
          @assignment.submissions.where(user_id: [@student2]).update_all(late_policy_status: "late")
          # rubocop:enable Rails/SkipsModelValidations
          expect(gradebook_user_ids.user_ids[1..3]).to eq([@student1.id, @student3.id, @student4.id])
        end
      end
    end

    describe "sort by grade" do
      before(:once) do
        @assignment.grade_student(@student1, grade: 8, grader: @teacher)
        @assignment.grade_student(@student2, grade: 1, grader: @teacher)
        @assignment.grade_student(@student3, grade: 9, grader: @teacher)
        @assignment.grade_student(@student4, grade: 9, grader: @teacher)
        @teacher.preferences[:gradebook_settings][@course.id][:sort_rows_by_column_id] = "assignment_#{@assignment.id}"
        @teacher.preferences[:gradebook_settings][@course.id][:sort_rows_by_setting_key] = "grade"
      end

      it "includes concluded students ids if the course is concluded" do
        @course.complete!
        expect(gradebook_user_ids.user_ids).to match_array(
          [@student1.id, @student2.id, @student4.id, @student3.id, @concluded_student.id, @fake_student.id]
        )
      end

      it "does not include concluded student ids if the course is soft concluded" do
        @course.conclude_at = 1.day.ago
        expect(gradebook_user_ids.user_ids).not_to include @concluded_student.id
      end

      context "ascending" do
        before(:once) do
          @teacher.preferences[:gradebook_settings][@course.id][:sort_rows_by_direction] = "ascending"
        end

        it "excludes fake students if they are deactivated" do
          @fake_student_enrollment.deactivate
          expect(gradebook_user_ids.user_ids).not_to include @fake_student.id
        end

        context 'when pg_collkey is installed' do
          before do
            skip 'requires pg_collkey installed SD-2747' unless has_pg_collkey
          end

          it "returns user ids sorted by grade on the assignment" do
            expected_user_ids = [@student2.id, @student1.id, @student4.id, @student3.id, @fake_student.id]
            expect(gradebook_user_ids.user_ids).to eq(expected_user_ids)
          end

          it "places students without submissions at the end, but before fake students" do
            student5 = student_in_course(course: @course, active_all: true).user
            expect(gradebook_user_ids.user_ids).to eq(
              [@student2.id, @student1.id, @student4.id, @student3.id, student5.id, @fake_student.id]
            )
          end

          it "places students that have been graded with nil grades at the end, but before fake students" do
            @assignment.grade_student(@student1, grade: nil, grader: @teacher)
            expected_user_ids = [@student2.id, @student4.id, @student3.id, @student1.id, @fake_student.id]
            expect(gradebook_user_ids.user_ids).to eq(expected_user_ids)
          end

          it "places students that are not assigned at the end, but before fake students" do
            @assignment.update!(only_visible_to_overrides: true)
            create_adhoc_override_for_assignment(@assignment, [@student1, @student3, @student2], due_at: nil)
            expect(gradebook_user_ids.user_ids).to eq(
              [@student2.id, @student1.id, @student3.id, @student4.id, @fake_student.id]
            )
          end

          it "returns all students even if only a subset is assigned" do
            assignment = @course.assignments.create!(points_possible: 10, only_visible_to_overrides: true)
            create_adhoc_override_for_assignment(assignment, [@student1, @student3], due_at: nil)
            @teacher.preferences[:gradebook_settings][@course.id][:sort_rows_by_column_id] =
              "assignment_#{assignment.id}"

            expect(gradebook_user_ids.user_ids).to eq(
              [@student1.id, @student3.id, @student4.id, @student2.id, @fake_student.id]
            )
          end
        end

        context 'when pg_collkey is not installed' do
          before do
            skip 'requires pg_collkey to not be installed SD-2747' if has_pg_collkey
          end

          it "returns user ids sorted by grade on the assignment" do
            expected_user_ids = [@student2.id, @student1.id, @student3.id, @student4.id, @fake_student.id]
            expect(gradebook_user_ids.user_ids).to eq(expected_user_ids)
          end

          it "places students without submissions at the end, but before fake students" do
            student5 = student_in_course(course: @course, active_all: true).user
            expect(gradebook_user_ids.user_ids).to eq(
              [@student2.id, @student1.id, @student3.id, @student4.id, student5.id, @fake_student.id]
            )
          end

          it "places students that have been graded with nil grades at the end, but before fake students" do
            @assignment.grade_student(@student1, grade: nil, grader: @teacher)
            expected_user_ids = [@student2.id, @student3.id, @student4.id, @student1.id, @fake_student.id]
            expect(gradebook_user_ids.user_ids).to eq(expected_user_ids)
          end

          it "places students that are not assigned at the end, but before fake students" do
            @assignment.update!(only_visible_to_overrides: true)
            create_adhoc_override_for_assignment(@assignment, [@student1, @student3, @student2], due_at: nil)
            expect(gradebook_user_ids.user_ids).to eq(
              [@student2.id, @student1.id, @student3.id, @student4.id, @fake_student.id]
            )
          end
        end
      end

      context "descending" do
        before(:once) do
          @teacher.preferences[:gradebook_settings][@course.id][:sort_rows_by_direction] = "descending"
        end

        it "excludes fake students if they are deactivated" do
          @fake_student_enrollment.deactivate
          expect(gradebook_user_ids.user_ids).not_to include @fake_student.id
        end

        context 'when pg_collkey is installed' do
          before do
            skip 'requires pg_collkey installed SD-2747' unless has_pg_collkey
          end

          it "returns user ids sorted by grade on the assignment" do
            expected_user_ids = [@student3.id, @student4.id, @student1.id, @student2.id, @fake_student.id]
            expect(gradebook_user_ids.user_ids).to eq(expected_user_ids)
          end

          it "places students without submissions at the end, but before fake students" do
            student4 = student_in_course(course: @course, active_all: true).user
            expect(gradebook_user_ids.user_ids).to eq(
              [@student3.id, @student4.id, @student1.id, @student2.id, student4.id, @fake_student.id]
            )
          end

          it "places students that have been graded with a nil grade at the end, but before fake students" do
            student3 = student_in_course(course: @course, active_all: true).user
            @assignment.grade_student(student3, grade: nil, grader: @teacher)
            expect(gradebook_user_ids.user_ids).to eq(
              [@student3.id, @student4.id, @student1.id, @student2.id, student3.id, @fake_student.id]
            )
          end

          it "places students that are not assigned at the end, but before fake students" do
            @assignment.update!(only_visible_to_overrides: true)
            create_adhoc_override_for_assignment(@assignment, [@student1, @student3, @student2], due_at: nil)
            expect(gradebook_user_ids.user_ids).to eq(
              [@student3.id, @student1.id, @student2.id, @student4.id, @fake_student.id]
            )
          end
        end

        context 'when pg_collkey is not installed' do
          before do
            skip 'requires pg_collkey to not be installed SD-2747' if has_pg_collkey
          end

          it "returns user ids sorted by grade on the assignment" do
            expected_user_ids = [@student4.id, @student3.id, @student1.id, @student2.id, @fake_student.id]
            expect(gradebook_user_ids.user_ids).to eq(expected_user_ids)
          end

          it "places students without submissions at the end, but before fake students" do
            student4 = student_in_course(course: @course, active_all: true).user
            expect(gradebook_user_ids.user_ids).to eq(
              [@student4.id, @student3.id, @student1.id, @student2.id, student4.id, @fake_student.id]
            )
          end

          it "places students that have been graded with a nil grade at the end, but before fake students" do
            student3 = student_in_course(course: @course, active_all: true).user
            @assignment.grade_student(student3, grade: nil, grader: @teacher)
            expect(gradebook_user_ids.user_ids).to eq(
              [@student4.id, @student3.id, @student1.id, @student2.id, student3.id, @fake_student.id]
            )
          end

          it "places students that are not assigned at the end, but before fake students" do
            @assignment.update!(only_visible_to_overrides: true)
            create_adhoc_override_for_assignment(@assignment, [@student1, @student3, @student2], due_at: nil)
            expect(gradebook_user_ids.user_ids).to eq(
              [@student3.id, @student1.id, @student2.id, @student4.id, @fake_student.id]
            )
          end
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

  describe "score sorting" do
    before(:once) do
      @now = Time.zone.now
      @assignment1 = @course.assignments.create!(points_possible: 10, due_at: 1.month.from_now(@now))
      @second_assignment_group = @course.assignment_groups.create(name: 'second group')
      @assignment2 = @course.assignments.create!(
        points_possible: 100, due_at: 3.months.from_now(@now), assignment_group: @second_assignment_group
      )

      @assignment1.grade_student(@student1, grade: 1, grader: @teacher)
      @assignment1.grade_student(@student2, grade: 10, grader: @teacher)
      @assignment1.grade_student(@student3, grade: 5, grader: @teacher)
      @assignment1.grade_student(@student4, grade: 6, grader: @teacher)

      @assignment2.grade_student(@student1, grade: 5, grader: @teacher)
      @assignment2.grade_student(@student2, grade: 1, grader: @teacher)
      @assignment2.grade_student(@student3, grade: 100, grader: @teacher)
      @assignment2.grade_student(@student4, grade: 99, grader: @teacher)

      @teacher.preferences[:gradebook_settings][@course.id][:sort_rows_by_column_id] = "total_grade"
      @teacher.preferences[:gradebook_settings][@course.id][:sort_rows_by_setting_key] = "grade"
    end

    context 'when pg_collkey is installed' do
      before do
        skip 'requires pg_collkey installed SD-2747' unless has_pg_collkey
      end

      context "with total grade" do
        it "sorts by total grade ascending" do
          expected_user_ids = [@student1.id, @student2.id, @student4.id, @student3.id, @fake_student.id]
          expect(gradebook_user_ids.user_ids).to eq(expected_user_ids)
        end

        it "sorts by total grade descending" do
          @teacher.preferences[:gradebook_settings][@course.id][:sort_rows_by_direction] = "descending"
          expected_user_ids = [@student3.id, @student4.id, @student2.id, @student1.id, @fake_student.id]
          expect(gradebook_user_ids.user_ids).to eq(expected_user_ids)
        end

        it "includes concluded students ids if the course is concluded" do
          @course.complete!
          all_students = [@student1.id, @student2.id, @student4.id, @student3.id,
                          @concluded_student.id, @fake_student.id]
          expect(gradebook_user_ids.user_ids).to eq(all_students)
        end
      end

      context "with assignment group" do
        before(:once) do
          @teacher.preferences[:gradebook_settings][@course.id][:sort_rows_by_column_id] =
            "assignment_group_#{@second_assignment_group.id}"
        end

        it "sorts by assignment group grade ascending" do
          expected_user_ids = [@student2.id, @student1.id, @student4.id, @student3.id, @fake_student.id]
          expect(gradebook_user_ids.user_ids).to eq(expected_user_ids)
        end

        it "sorts by assignment group grade descending" do
          @teacher.preferences[:gradebook_settings][@course.id][:sort_rows_by_direction] = "descending"
          expected_user_ids = [@student3.id, @student4.id, @student1.id, @student2.id, @fake_student.id]
          expect(gradebook_user_ids.user_ids).to eq(expected_user_ids)
        end

        it "includes concluded students ids if the course is concluded" do
          @course.complete!
          all_students = [@student2.id, @student1.id, @student4.id, @student3.id,
                          @concluded_student.id, @fake_student.id]
          expect(gradebook_user_ids.user_ids).to eq(all_students)
        end
      end
    end

    context 'when pg_collkey is not installed' do
      before do
        skip 'requires no pg_collkey installed SD-2747' if has_pg_collkey
      end

      context "with total grade" do
        it "sorts by total grade ascending" do
          expected_user_ids = [@student1.id, @student2.id, @student3.id, @student4.id, @fake_student.id]
          expect(gradebook_user_ids.user_ids).to eq(expected_user_ids)
        end

        it "sorts by total grade descending" do
          @teacher.preferences[:gradebook_settings][@course.id][:sort_rows_by_direction] = "descending"
          expected_user_ids = [@student4.id, @student3.id, @student2.id, @student1.id, @fake_student.id]
          expect(gradebook_user_ids.user_ids).to eq(expected_user_ids)
        end

        it "includes concluded students ids if the course is concluded" do
          @course.complete!
          all_students = [@student1.id, @student2.id, @student3.id, @student4.id,
                          @concluded_student.id, @fake_student.id]
          expect(gradebook_user_ids.user_ids).to eq(all_students)
        end
      end

      context "with assignment groups" do
        before(:once) do
          @teacher.preferences[:gradebook_settings][@course.id][:sort_rows_by_column_id] =
            "assignment_group_#{@second_assignment_group.id}"
        end

        it "sorts by assignment group grade ascending" do
          expected_user_ids = [@student2.id, @student1.id, @student4.id, @student3.id, @fake_student.id]
          expect(gradebook_user_ids.user_ids).to eq(expected_user_ids)
        end

        it "sorts by assignment group grade descending" do
          @teacher.preferences[:gradebook_settings][@course.id][:sort_rows_by_direction] = "descending"
          expected_user_ids = [@student3.id, @student4.id, @student1.id, @student2.id, @fake_student.id]
          expect(gradebook_user_ids.user_ids).to eq(expected_user_ids)
        end

        it "includes concluded students ids if the course is concluded" do
          @course.complete!
          all_students = [@student2.id, @student1.id, @student4.id, @student3.id,
                          @concluded_student.id, @fake_student.id]
          expect(gradebook_user_ids.user_ids).to eq(all_students)
        end
      end
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

    it "does not include concluded student ids if the course is soft concluded" do
      @course.conclude_at = 1.day.ago
      expect(gradebook_user_ids.user_ids).not_to include @concluded_student.id
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
          allow(@course).to receive(:grading_periods?).and_return(true)
          expected_user_ids = [@student1.id, @student3.id, @student4.id, @student2.id, @fake_student.id]
          expect(gradebook_user_ids.user_ids).to eq(expected_user_ids)
        end

        it "sorts by the current grading period totals if a grading period ID of 'null' is in user preferences" do
          allow(@course).to receive(:grading_periods?).and_return(true)
          @teacher.preferences[:gradebook_settings][@course.id][:filter_columns_by][:grading_period_id] = "null"
          expected_user_ids = [@student1.id, @student3.id, @student4.id, @student2.id, @fake_student.id]
          expect(gradebook_user_ids.user_ids).to eq(expected_user_ids)
        end

        it "sorts by the selected grading period totals if a selected grading period is in user preferences" do
          allow(@course).to receive(:grading_periods?).and_return(true)
          @teacher.preferences[:gradebook_settings][@course.id][:filter_columns_by][:grading_period_id] =
            @future_period.id.to_s
          expected_user_ids = [@student2.id, @student1.id, @student4.id, @student3.id, @fake_student.id]
          expect(gradebook_user_ids.user_ids).to eq(expected_user_ids)
        end

        context 'when pg_collkey is installed' do
          before do
            skip 'requires pg_collkey installed SD-2747' unless has_pg_collkey
          end

          it "sorts by 'All Grading Periods' if a grading period ID of '0' is in user preferences" do
            allow(@course).to receive(:grading_periods?).and_return(true)
            @teacher.preferences[:gradebook_settings][@course.id][:filter_columns_by][:grading_period_id] = "0"
            expected_user_ids = [@student1.id, @student2.id, @student4.id, @student3.id, @fake_student.id]
            expect(gradebook_user_ids.user_ids).to eq(expected_user_ids)
          end
        end

        context 'when pg_collkey is not installed' do
          before do
            skip 'requires no pg_collkey installed SD-2747' if has_pg_collkey
          end

          it "sorts by 'All Grading Periods' if a grading period ID of '0' is in user preferences" do
            allow(@course).to receive(:grading_periods?).and_return(true)
            @teacher.preferences[:gradebook_settings][@course.id][:filter_columns_by][:grading_period_id] = "0"
            expected_user_ids = [@student1.id, @student2.id, @student3.id, @student4.id, @fake_student.id]
            expect(gradebook_user_ids.user_ids).to eq(expected_user_ids)
          end
        end
      end

      context "descending" do
        before(:once) do
          @teacher.preferences[:gradebook_settings][@course.id][:sort_rows_by_direction] = "descending"
        end

        it "sorts by the current grading period totals if no selected grading period is in user preferences" do
          allow(@course).to receive(:grading_periods?).and_return(true)
          expected_user_ids = [@student2.id, @student4.id, @student3.id, @student1.id, @fake_student.id]
          expect(gradebook_user_ids.user_ids).to eq(expected_user_ids)
        end

        it "sorts by the current grading period totals if a grading period ID of 'null' is in user preferences" do
          allow(@course).to receive(:grading_periods?).and_return(true)
          @teacher.preferences[:gradebook_settings][@course.id][:filter_columns_by][:grading_period_id] = "null"
          expected_user_ids = [@student2.id, @student4.id, @student3.id, @student1.id, @fake_student.id]
          expect(gradebook_user_ids.user_ids).to eq(expected_user_ids)
        end

        it "sorts by the selected grading period totals if a selected grading period is in user preferences" do
          allow(@course).to receive(:grading_periods?).and_return(true)
          @teacher.preferences[:gradebook_settings][@course.id][:filter_columns_by][:grading_period_id] =
            @future_period.id.to_s
          expected_user_ids = [@student3.id, @student4.id, @student1.id, @student2.id, @fake_student.id]
          expect(gradebook_user_ids.user_ids).to eq(expected_user_ids)
        end

        context 'when pg_collkey is installed' do
          before do
            skip 'requires pg_collkey installed SD-2747' unless has_pg_collkey
          end

          it "sorts by 'All Grading Periods' if a grading period ID of '0' is in user preferences" do
            allow(@course).to receive(:grading_periods?).and_return(true)
            @teacher.preferences[:gradebook_settings][@course.id][:filter_columns_by][:grading_period_id] = "0"
            expected_user_ids = [@student3.id, @student4.id, @student2.id, @student1.id, @fake_student.id]
            expect(gradebook_user_ids.user_ids).to eq(expected_user_ids)
          end
        end

        context 'when pg_collkey is not installed' do
          before do
            skip 'requires no pg_collkey installed SD-2747' if has_pg_collkey
          end

          it "sorts by 'All Grading Periods' if a grading period ID of '0' is in user preferences" do
            allow(@course).to receive(:grading_periods?).and_return(true)
            @teacher.preferences[:gradebook_settings][@course.id][:filter_columns_by][:grading_period_id] = "0"
            expected_user_ids = [@student4.id, @student3.id, @student2.id, @student1.id, @fake_student.id]
            expect(gradebook_user_ids.user_ids).to eq(expected_user_ids)
          end
        end
      end
    end
  end
end
