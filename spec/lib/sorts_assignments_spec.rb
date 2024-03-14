# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

describe SortsAssignments do
  around do |example|
    Timecop.freeze(&example)
  end

  before do
    @course = course_factory(active_all: true)
    @student = student_in_course(course: @course, active_all: true).user
    @assignment = @course.assignments.create!(due_at: 1.day.ago, submission_types: "online_text_entry")
  end

  context "as a student" do
    let(:sorter) do
      SortsAssignments.new(
        assignments_scope: @course.assignments,
        user: @student,
        session: nil,
        course: @course
      )
    end

    describe "past" do
      it "excludes assignments that do not have a due date" do
        create_adhoc_override_for_assignment(@assignment, @student, due_at: nil)
        expect(sorter.assignments(:past)).to be_empty
      end

      it "excludes assignments due in the future" do
        create_adhoc_override_for_assignment(@assignment, @student, due_at: 1.day.from_now)
        expect(sorter.assignments(:past)).to be_empty
      end

      it "includes assignments due in the past" do
        @assignment.update!(due_at: 1.day.from_now)
        create_adhoc_override_for_assignment(@assignment, @student, due_at: 1.day.ago)
        expect(sorter.assignments(:past)).to include @assignment
      end
    end

    describe "overdue" do
      it "excludes assignments that do not have a due date" do
        create_adhoc_override_for_assignment(@assignment, @student, due_at: nil)
        expect(sorter.assignments(:overdue)).to be_empty
      end

      it "excludes assignments due in the future" do
        create_adhoc_override_for_assignment(@assignment, @student, due_at: 1.day.from_now)
        expect(sorter.assignments(:overdue)).to be_empty
      end

      it "excludes assignments that don't expect a submission" do
        @assignment.update!(submission_types: "on_paper")
        create_adhoc_override_for_assignment(@assignment, @student, due_at: 1.day.ago)
        expect(sorter.assignments(:overdue)).to be_empty
      end

      it "excludes assignments that the student does not have permission to submit to" do
        # excused students can not submit to an assignment
        @assignment.grade_student(@student, grader: @teacher, excused: true)
        create_adhoc_override_for_assignment(@assignment, @student, due_at: 1.day.ago)
        expect(sorter.assignments(:overdue)).to be_empty
      end

      it "excludes assignments that the student has submitted to" do
        create_adhoc_override_for_assignment(@assignment, @student, due_at: 1.day.ago)
        @assignment.submit_homework(@student, body: "my submission")
        expect(sorter.assignments(:overdue)).to be_empty
      end

      it "includes past due assignments, expecting a submission, that the student has not submitted to" do
        create_adhoc_override_for_assignment(@assignment, @student, due_at: 1.day.ago)
        expect(sorter.assignments(:overdue)).to include @assignment
      end
    end

    describe "undated" do
      it "excludes assignments that have a due date" do
        @assignment.update!(due_at: nil)
        create_adhoc_override_for_assignment(@assignment, @student, due_at: 1.day.from_now)
        expect(sorter.assignments(:undated)).to be_empty
      end

      it "includes assignments that do not have a due date" do
        create_adhoc_override_for_assignment(@assignment, @student, due_at: nil)
        expect(sorter.assignments(:undated)).to include @assignment
      end
    end

    describe "ungraded" do
      it "excludes assignments that don't expect a submission" do
        @assignment.update!(submission_types: "on_paper")
        expect(sorter.assignments(:ungraded)).to be_empty
      end

      it "excludes assignments that have been graded and posted" do
        @assignment.submit_homework(@student, body: "my submission")
        @assignment.grade_student(@student, grader: @teacher, score: 10)
        expect(sorter.assignments(:ungraded)).to be_empty
      end

      it "excludes assignments where the student has not turned anything in" do
        expect(sorter.assignments(:ungraded)).to be_empty
      end

      it "includes assignments where the student has turned something in and has not been graded" do
        @assignment.submit_homework(@student, body: "my submission")
        expect(sorter.assignments(:ungraded)).to include @assignment
      end
    end

    describe "unsubmitted" do
      it "excludes assignments that don't expect a submission" do
        @assignment.update!(submission_types: "on_paper")
        expect(sorter.assignments(:unsubmitted)).to be_empty
      end

      it "excludes external tool assignments" do
        @assignment.update!(submission_types: "external_tool")
        expect(sorter.assignments(:unsubmitted)).to be_empty
      end

      it "includes assignments that expect a submission that the student has not submitted to" do
        expect(sorter.assignments(:unsubmitted)).to include @assignment
      end
    end

    describe "upcoming" do
      it "excludes assignments that don't have a due date" do
        @assignment.update!(due_at: 1.day.from_now)
        create_adhoc_override_for_assignment(@assignment, @student, due_at: nil)
        expect(sorter.assignments(:upcoming)).to be_empty
      end

      it "excludes assignments that are due in the past" do
        @assignment.update!(due_at: 1.day.from_now)
        create_adhoc_override_for_assignment(@assignment, @student, due_at: 1.day.ago)
        expect(sorter.assignments(:upcoming)).to be_empty
      end

      it "excludes assignments that are due more than one week out" do
        @assignment.update!(due_at: 1.day.from_now)
        create_adhoc_override_for_assignment(@assignment, @student, due_at: 8.days.from_now)
        expect(sorter.assignments(:upcoming)).to be_empty
      end

      it "includes assignments that are due within the next week" do
        create_adhoc_override_for_assignment(@assignment, @student, due_at: 1.day.from_now)
        expect(sorter.assignments(:upcoming)).to include @assignment
      end
    end

    describe "future" do
      it "excludes assignments due in the past" do
        @assignment.update!(due_at: 1.day.from_now)
        create_adhoc_override_for_assignment(@assignment, @student, due_at: 1.day.ago)
        expect(sorter.assignments(:future)).to be_empty
      end

      it "includes assignments without a due date" do
        create_adhoc_override_for_assignment(@assignment, @student, due_at: nil)
        expect(sorter.assignments(:future)).to include @assignment
      end

      it "includes assignments with a due date in the future" do
        create_adhoc_override_for_assignment(@assignment, @student, due_at: 1.day.from_now)
        expect(sorter.assignments(:future)).to include @assignment
      end
    end
  end

  context "as an observer" do
    before do
      @observer = observer_in_course(course: @course, associated_user_id: @student, active_all: true).user
    end

    let(:sorter) do
      SortsAssignments.new(
        assignments_scope: @course.assignments,
        user: @observer,
        session: nil,
        course: @course
      )
    end

    context "observing a single student in a course" do
      describe "past" do
        it "excludes assignments that do not have a due date for the student" do
          create_adhoc_override_for_assignment(@assignment, @student, due_at: nil)
          expect(sorter.assignments(:past)).to be_empty
        end

        it "excludes assignments due in the future for the student" do
          create_adhoc_override_for_assignment(@assignment, @student, due_at: 1.day.from_now)
          expect(sorter.assignments(:past)).to be_empty
        end

        it "includes assignments due in the past for the student" do
          @assignment.update!(due_at: 1.day.from_now)
          create_adhoc_override_for_assignment(@assignment, @student, due_at: 1.day.ago)
          expect(sorter.assignments(:past)).to include @assignment
        end
      end

      describe "overdue" do
        it "excludes assignments that do not have a due date for the student" do
          create_adhoc_override_for_assignment(@assignment, @student, due_at: nil)
          expect(sorter.assignments(:overdue)).to be_empty
        end

        it "excludes assignments due in the future for the student" do
          create_adhoc_override_for_assignment(@assignment, @student, due_at: 1.day.from_now)
          expect(sorter.assignments(:overdue)).to be_empty
        end

        it "excludes assignments that don't expect a submission for the student" do
          @assignment.update!(submission_types: "on_paper")
          create_adhoc_override_for_assignment(@assignment, @student, due_at: 1.day.ago)
          expect(sorter.assignments(:overdue)).to be_empty
        end

        it "excludes assignments that the student does not have permission to submit to" do
          # excused students can not submit to an assignment
          @assignment.grade_student(@student, grader: @teacher, excused: true)
          create_adhoc_override_for_assignment(@assignment, @student, due_at: 1.day.ago)
          expect(sorter.assignments(:overdue)).to be_empty
        end

        it "excludes assignments that the student has submitted to" do
          create_adhoc_override_for_assignment(@assignment, @student, due_at: 1.day.ago)
          @assignment.submit_homework(@student, body: "my submission")
          expect(sorter.assignments(:overdue)).to be_empty
        end

        it "includes past due assignments, expecting a submission, that the student has not submitted to" do
          create_adhoc_override_for_assignment(@assignment, @student, due_at: 1.day.ago)
          expect(sorter.assignments(:overdue)).to include @assignment
        end
      end

      describe "undated" do
        it "excludes assignments that have a due date for the student" do
          @assignment.update!(due_at: nil)
          create_adhoc_override_for_assignment(@assignment, @student, due_at: 1.day.from_now)
          expect(sorter.assignments(:undated)).to be_empty
        end

        it "includes assignments that do not have a due date for the student" do
          create_adhoc_override_for_assignment(@assignment, @student, due_at: nil)
          expect(sorter.assignments(:undated)).to include @assignment
        end
      end

      describe "ungraded" do
        it "excludes assignments that don't expect a submission for the student" do
          @assignment.update!(submission_types: "on_paper")
          expect(sorter.assignments(:ungraded)).to be_empty
        end

        it "excludes assignments that have been graded and posted for the student" do
          @assignment.submit_homework(@student, body: "my submission")
          @assignment.grade_student(@student, grader: @teacher, score: 10)
          expect(sorter.assignments(:ungraded)).to be_empty
        end

        it "excludes assignments where the student has not turned anything in" do
          expect(sorter.assignments(:ungraded)).to be_empty
        end

        it "includes assignments where the student has turned something in and has not been graded" do
          @assignment.submit_homework(@student, body: "my submission")
          expect(sorter.assignments(:ungraded)).to include @assignment
        end
      end

      describe "unsubmitted" do
        it "excludes assignments that don't expect a submission for the student" do
          @assignment.update!(submission_types: "on_paper")
          expect(sorter.assignments(:unsubmitted)).to be_empty
        end

        it "excludes external tool assignments" do
          @assignment.update!(submission_types: "external_tool")
          expect(sorter.assignments(:unsubmitted)).to be_empty
        end

        it "includes assignments that expect a submission that the student has not submitted to" do
          expect(sorter.assignments(:unsubmitted)).to include @assignment
        end
      end

      describe "upcoming" do
        it "excludes assignments that don't have a due date for the student" do
          @assignment.update!(due_at: 1.day.from_now)
          create_adhoc_override_for_assignment(@assignment, @student, due_at: nil)
          expect(sorter.assignments(:upcoming)).to be_empty
        end

        it "excludes assignments that are due in the past for the student" do
          @assignment.update!(due_at: 1.day.from_now)
          create_adhoc_override_for_assignment(@assignment, @student, due_at: 1.day.ago)
          expect(sorter.assignments(:upcoming)).to be_empty
        end

        it "excludes assignments that are due more than a week out for the student" do
          @assignment.update!(due_at: 1.day.from_now)
          create_adhoc_override_for_assignment(@assignment, @student, due_at: 8.days.from_now)
          expect(sorter.assignments(:upcoming)).to be_empty
        end

        it "includes assignments that are due within the next week for the student" do
          create_adhoc_override_for_assignment(@assignment, @student, due_at: 1.day.from_now)
          expect(sorter.assignments(:upcoming)).to include @assignment
        end
      end

      describe "future" do
        it "excludes assignments due in the past for the student" do
          @assignment.update!(due_at: 1.day.from_now)
          create_adhoc_override_for_assignment(@assignment, @student, due_at: 1.day.ago)
          expect(sorter.assignments(:future)).to be_empty
        end

        it "includes assignments without a due date for the student" do
          create_adhoc_override_for_assignment(@assignment, @student, due_at: nil)
          expect(sorter.assignments(:future)).to include @assignment
        end

        it "includes assignments with a due date in the future for the student" do
          create_adhoc_override_for_assignment(@assignment, @student, due_at: 1.day.from_now)
          expect(sorter.assignments(:future)).to include @assignment
        end
      end
    end

    context "observing multiple students in a course" do
      before do
        @first_student = @student
        @second_section = @course.course_sections.create!
        @second_student = student_in_course(course: @course, section: @second_section, active_all: true).user
        @third_student = student_in_course(course: @course, active_all: true).user
        observer_in_course(
          user: @observer,
          course: @course,
          allow_multiple_enrollments: true,
          associated_user_id: @second_student,
          active_all: true
        )
      end

      it "does not return duplicate assignments" do
        create_adhoc_override_for_assignment(@assignment, @first_student, due_at: 2.days.ago)
        expect(sorter.assignments(:past).count).to eq 1
      end

      it "does not consider assigned deactivated students" do
        create_adhoc_override_for_assignment(@assignment, @first_student, due_at: 2.days.ago)
        create_adhoc_override_for_assignment(@assignment, @second_student, due_at: 1.day.from_now)
        @course.enrollments.find_by(user: @first_student).deactivate
        expect(sorter.assignments(:past)).to be_empty
      end

      it "does not consider assigned concluded students" do
        create_adhoc_override_for_assignment(@assignment, @first_student, due_at: 2.days.ago)
        create_adhoc_override_for_assignment(@assignment, @second_student, due_at: 1.day.from_now)
        @course.enrollments.find_by(user: @first_student).conclude
        expect(sorter.assignments(:past)).to be_empty
      end

      describe "past" do
        it "excludes assignments where no observed students have a due date in the past" do
          create_adhoc_override_for_assignment(@assignment, @first_student, due_at: nil)
          create_section_override_for_assignment(@assignment, course_section: @second_section, due_at: 1.day.from_now)
          expect(sorter.assignments(:past)).to be_empty
        end

        it "includes assignments due in the past for at least one observed student" do
          @assignment.update!(due_at: 1.day.from_now)
          create_adhoc_override_for_assignment(@assignment, @second_student, due_at: 1.day.ago)
          expect(sorter.assignments(:past)).to include @assignment
        end
      end

      describe "overdue" do
        it "excludes assignments where no observed students are overdue" do
          create_adhoc_override_for_assignment(@assignment, @first_student, due_at: nil)
          create_adhoc_override_for_assignment(@assignment, @second_student, due_at: 1.day.from_now)
          expect(sorter.assignments(:overdue)).to be_empty
        end

        it "includes assignments where at least one observed student is overdue" do
          create_adhoc_override_for_assignment(@assignment, @first_student, due_at: 1.day.from_now)
          create_adhoc_override_for_assignment(@assignment, @second_student, due_at: 1.day.ago)
          expect(sorter.assignments(:overdue)).to include @assignment
        end
      end

      describe "undated" do
        it "excludes assignments where no observed students have a blank due date" do
          @assignment.update!(due_at: nil)
          create_adhoc_override_for_assignment(@assignment, @first_student, due_at: 1.day.from_now)
          create_adhoc_override_for_assignment(@assignment, @second_student, due_at: 1.day.ago)
          expect(sorter.assignments(:undated)).to be_empty
        end

        it "includes assignments where at least one observed student has a blank due date" do
          create_adhoc_override_for_assignment(@assignment, @first_student, due_at: nil)
          expect(sorter.assignments(:undated)).to include @assignment
        end
      end

      describe "ungraded" do
        it "excludes assignments where no observed students require grading" do
          @assignment.update!(submission_types: "on_paper")
          expect(sorter.assignments(:ungraded)).to be_empty
        end

        it "includes assignments where at least one observed student has turned something in and has not been graded" do
          @assignment.submit_homework(@second_student, body: "my submission")
          expect(sorter.assignments(:ungraded)).to include @assignment
        end
      end

      describe "unsubmitted" do
        it "excludes assignments that don't expect a submission" do
          @assignment.update!(submission_types: "on_paper")
          expect(sorter.assignments(:unsubmitted)).to be_empty
        end

        it "excludes external tool assignments" do
          @assignment.update!(submission_types: "external_tool")
          expect(sorter.assignments(:unsubmitted)).to be_empty
        end

        it "excludes assignments where all observed students have submitted" do
          @assignment.submit_homework(@first_student, body: "my submission")
          @assignment.submit_homework(@second_student, body: "my submission")
          expect(sorter.assignments(:unsubmitted)).to be_empty
        end

        it "includes assignments that expect a submission where at least one observed student has not submitted" do
          @assignment.submit_homework(@second_student, body: "my submission")
          expect(sorter.assignments(:unsubmitted)).to include @assignment
        end
      end

      describe "upcoming" do
        it "excludes assignments where no observed students are due within the next week" do
          @assignment.update!(due_at: 1.day.from_now)
          create_adhoc_override_for_assignment(@assignment, @first_student, due_at: nil)
          create_adhoc_override_for_assignment(@assignment, @second_student, due_at: 8.days.from_now)
          expect(sorter.assignments(:upcoming)).to be_empty
        end

        it "includes assignments where at least one observed student is due within the next week" do
          create_adhoc_override_for_assignment(@assignment, @second_student, due_at: 1.day.from_now)
          expect(sorter.assignments(:upcoming)).to include @assignment
        end
      end

      describe "future" do
        it "excludes assignments where no observed students are due in the future" do
          @assignment.update!(due_at: 1.day.from_now)
          create_adhoc_override_for_assignment(@assignment, @first_student, due_at: 1.day.ago)
          create_adhoc_override_for_assignment(@assignment, @second_student, due_at: 2.days.ago)
          expect(sorter.assignments(:future)).to be_empty
        end

        it "includes assignments where at least one observed student is without a due date" do
          create_adhoc_override_for_assignment(@assignment, @first_student, due_at: nil)
          expect(sorter.assignments(:future)).to include @assignment
        end

        it "includes assignments where at least one observed student has a due date in the future" do
          create_adhoc_override_for_assignment(@assignment, @first_student, due_at: 1.day.from_now)
          expect(sorter.assignments(:future)).to include @assignment
        end
      end
    end
  end

  context "as a teacher" do
    before do
      @first_student = @student
      @second_section = @course.course_sections.create!
      @second_student = student_in_course(course: @course, section: @second_section, active_all: true).user
      @teacher = teacher_in_course(active_all: true, course: @course).user
    end

    let(:sorter) do
      SortsAssignments.new(
        assignments_scope: @course.assignments,
        user: @teacher,
        session: nil,
        course: @course
      )
    end

    it "does not return duplicate assignments (when the given scope does not have duplicates)" do
      create_adhoc_override_for_assignment(@assignment, @first_student, due_at: 2.days.ago)
      expect(sorter.assignments(:past).count).to eq 1
    end

    it "returns the original scope" do
      scope_with_groups = @course.assignments.joins(:assignment_group)
      sorter = SortsAssignments.new(
        assignments_scope: scope_with_groups,
        user: @teacher,
        session: nil,
        course: @course
      )
      sorted = sorter.assignments(:past)
      expect(sorted.pluck("assignment_groups.id")).to eq [@assignment.assignment_group_id]
    end

    it "can optionally be passed a block to modify and return the scope used for sorting" do
      earlier_assignment = @course.assignments.create!(due_at: 2.days.ago)
      create_adhoc_override_for_assignment(earlier_assignment, @first_student, due_at: 1.hour.ago)
      sorted = sorter.assignments(:past) do |assignments|
        assignments.group("assignments.id").order("MIN(submissions.cached_due_date)")
      end
      expect(sorted.pluck(:id)).to eq [earlier_assignment.id, @assignment.id]
    end

    it "does not consider assigned deactivated students" do
      create_adhoc_override_for_assignment(@assignment, @first_student, due_at: 2.days.ago)
      create_adhoc_override_for_assignment(@assignment, @second_student, due_at: 1.day.from_now)
      @course.enrollments.find_by(user: @first_student).deactivate
      expect(sorter.assignments(:past)).to be_empty
    end

    it "does not consider assigned concluded students" do
      create_adhoc_override_for_assignment(@assignment, @first_student, due_at: 2.days.ago)
      create_adhoc_override_for_assignment(@assignment, @second_student, due_at: 1.day.from_now)
      @course.enrollments.find_by(user: @first_student).conclude
      expect(sorter.assignments(:past)).to be_empty
    end

    describe "past" do
      it "excludes assignments where no assigned students have a due date in the past" do
        create_adhoc_override_for_assignment(@assignment, @first_student, due_at: nil)
        create_section_override_for_assignment(@assignment, course_section: @second_section, due_at: 1.day.from_now)
        expect(sorter.assignments(:past)).to be_empty
      end

      it "includes assignments due in the past for at least one assigned student" do
        @assignment.update!(due_at: 1.day.from_now)
        create_adhoc_override_for_assignment(@assignment, @second_student, due_at: 1.day.ago)
        expect(sorter.assignments(:past)).to include @assignment
      end
    end

    describe "overdue" do
      it "excludes assignments where no assigned students are overdue" do
        create_adhoc_override_for_assignment(@assignment, @first_student, due_at: nil)
        create_adhoc_override_for_assignment(@assignment, @second_student, due_at: 1.day.from_now)
        expect(sorter.assignments(:overdue)).to be_empty
      end

      it "includes assignments where at least one assigned student is overdue" do
        create_adhoc_override_for_assignment(@assignment, @first_student, due_at: 1.day.from_now)
        create_adhoc_override_for_assignment(@assignment, @second_student, due_at: 1.day.ago)
        expect(sorter.assignments(:overdue)).to include @assignment
      end
    end

    describe "undated" do
      it "excludes assignments where no assigned students have a blank due date" do
        @assignment.update!(due_at: nil)
        create_adhoc_override_for_assignment(@assignment, @first_student, due_at: 1.day.from_now)
        create_adhoc_override_for_assignment(@assignment, @second_student, due_at: 1.day.ago)
        expect(sorter.assignments(:undated)).to be_empty
      end

      it "includes assignments where at least one assigned student has a blank due date" do
        create_adhoc_override_for_assignment(@assignment, @first_student, due_at: nil)
        expect(sorter.assignments(:undated)).to include @assignment
      end
    end

    describe "ungraded" do
      it "excludes assignments where no assigned students require grading" do
        @assignment.update!(submission_types: "on_paper")
        expect(sorter.assignments(:ungraded)).to be_empty
      end

      it "includes assignments where at least one assigned student has turned something in and has not been graded" do
        @assignment.submit_homework(@second_student, body: "my submission")
        expect(sorter.assignments(:ungraded)).to include @assignment
      end
    end

    describe "unsubmitted" do
      it "excludes assignments that don't expect a submission" do
        @assignment.update!(submission_types: "on_paper")
        expect(sorter.assignments(:unsubmitted)).to be_empty
      end

      it "excludes external tool assignments" do
        @assignment.update!(submission_types: "external_tool")
        expect(sorter.assignments(:unsubmitted)).to be_empty
      end

      it "excludes assignments where all assigned students have submitted" do
        @assignment.submit_homework(@first_student, body: "my submission")
        @assignment.submit_homework(@second_student, body: "my submission")
        expect(sorter.assignments(:unsubmitted)).to be_empty
      end

      it "includes assignments that expect a submission where at least one assigned student has not submitted" do
        @assignment.submit_homework(@second_student, body: "my submission")
        expect(sorter.assignments(:unsubmitted)).to include @assignment
      end
    end

    describe "upcoming" do
      it "excludes assignments where no assigned students are due within the next week" do
        @assignment.update!(due_at: 1.day.from_now)
        create_adhoc_override_for_assignment(@assignment, @first_student, due_at: nil)
        create_adhoc_override_for_assignment(@assignment, @second_student, due_at: 8.days.from_now)
        expect(sorter.assignments(:upcoming)).to be_empty
      end

      it "includes assignments where at least one assigned student is due within the next week" do
        create_adhoc_override_for_assignment(@assignment, @second_student, due_at: 1.day.from_now)
        expect(sorter.assignments(:upcoming)).to include @assignment
      end
    end

    describe "future" do
      it "excludes assignments where no assigned students are due in the future" do
        @assignment.update!(due_at: 1.day.from_now)
        create_adhoc_override_for_assignment(@assignment, @first_student, due_at: 1.day.ago)
        create_adhoc_override_for_assignment(@assignment, @second_student, due_at: 2.days.ago)
        expect(sorter.assignments(:future)).to be_empty
      end

      it "includes assignments where at least one assigned student is without a due date" do
        create_adhoc_override_for_assignment(@assignment, @first_student, due_at: nil)
        expect(sorter.assignments(:future)).to include @assignment
      end

      it "includes assignments where at least one assigned student has a due date in the future" do
        create_adhoc_override_for_assignment(@assignment, @first_student, due_at: 1.day.from_now)
        expect(sorter.assignments(:future)).to include @assignment
      end
    end
  end

  context "as an admin" do
    before do
      @first_student = @student
      @second_section = @course.course_sections.create!
      @second_student = student_in_course(course: @course, section: @second_section, active_all: true).user
      @admin = account_admin_user
    end

    let(:sorter) do
      SortsAssignments.new(
        assignments_scope: @course.assignments,
        user: @admin,
        session: nil,
        course: @course
      )
    end

    it "does not return duplicate assignments" do
      create_adhoc_override_for_assignment(@assignment, @first_student, due_at: 2.days.ago)
      expect(sorter.assignments(:past).count).to eq 1
    end

    it "does not consider assigned deactivated students" do
      create_adhoc_override_for_assignment(@assignment, @first_student, due_at: 2.days.ago)
      create_adhoc_override_for_assignment(@assignment, @second_student, due_at: 1.day.from_now)
      @course.enrollments.find_by(user: @first_student).deactivate
      expect(sorter.assignments(:past)).to be_empty
    end

    it "does not consider assigned concluded students" do
      create_adhoc_override_for_assignment(@assignment, @first_student, due_at: 2.days.ago)
      create_adhoc_override_for_assignment(@assignment, @second_student, due_at: 1.day.from_now)
      @course.enrollments.find_by(user: @first_student).conclude
      expect(sorter.assignments(:past)).to be_empty
    end

    describe "past" do
      it "excludes assignments where no assigned students have a due date in the past" do
        create_adhoc_override_for_assignment(@assignment, @first_student, due_at: nil)
        create_section_override_for_assignment(@assignment, course_section: @second_section, due_at: 1.day.from_now)
        expect(sorter.assignments(:past)).to be_empty
      end

      it "includes assignments due in the past for at least one assigned student" do
        @assignment.update!(due_at: 1.day.from_now)
        create_adhoc_override_for_assignment(@assignment, @second_student, due_at: 1.day.ago)
        expect(sorter.assignments(:past)).to include @assignment
      end
    end

    describe "overdue" do
      it "excludes assignments where no assigned students are overdue" do
        create_adhoc_override_for_assignment(@assignment, @first_student, due_at: nil)
        create_adhoc_override_for_assignment(@assignment, @second_student, due_at: 1.day.from_now)
        expect(sorter.assignments(:overdue)).to be_empty
      end

      it "includes assignments where at least one assigned student is overdue" do
        create_adhoc_override_for_assignment(@assignment, @first_student, due_at: 1.day.from_now)
        create_adhoc_override_for_assignment(@assignment, @second_student, due_at: 1.day.ago)
        expect(sorter.assignments(:overdue)).to include @assignment
      end
    end

    describe "undated" do
      it "excludes assignments where no assigned students have a blank due date" do
        @assignment.update!(due_at: nil)
        create_adhoc_override_for_assignment(@assignment, @first_student, due_at: 1.day.from_now)
        create_adhoc_override_for_assignment(@assignment, @second_student, due_at: 1.day.ago)
        expect(sorter.assignments(:undated)).to be_empty
      end

      it "includes assignments where at least one assigned student has a blank due date" do
        create_adhoc_override_for_assignment(@assignment, @first_student, due_at: nil)
        expect(sorter.assignments(:undated)).to include @assignment
      end
    end

    describe "ungraded" do
      it "excludes assignments where no assigned students require grading" do
        @assignment.update!(submission_types: "on_paper")
        expect(sorter.assignments(:ungraded)).to be_empty
      end

      it "includes assignments where at least one assigned student has turned something in and has not been graded" do
        @assignment.submit_homework(@second_student, body: "my submission")
        expect(sorter.assignments(:ungraded)).to include @assignment
      end
    end

    describe "unsubmitted" do
      it "excludes assignments that don't expect a submission" do
        @assignment.update!(submission_types: "on_paper")
        expect(sorter.assignments(:unsubmitted)).to be_empty
      end

      it "excludes external tool assignments" do
        @assignment.update!(submission_types: "external_tool")
        expect(sorter.assignments(:unsubmitted)).to be_empty
      end

      it "excludes assignments where all assigned students have submitted" do
        @assignment.submit_homework(@first_student, body: "my submission")
        @assignment.submit_homework(@second_student, body: "my submission")
        expect(sorter.assignments(:unsubmitted)).to be_empty
      end

      it "includes assignments that expect a submission where at least one assigned student has not submitted" do
        @assignment.submit_homework(@second_student, body: "my submission")
        expect(sorter.assignments(:unsubmitted)).to include @assignment
      end
    end

    describe "upcoming" do
      it "excludes assignments where no assigned students are due within the next week" do
        @assignment.update!(due_at: 1.day.from_now)
        create_adhoc_override_for_assignment(@assignment, @first_student, due_at: nil)
        create_adhoc_override_for_assignment(@assignment, @second_student, due_at: 8.days.from_now)
        expect(sorter.assignments(:upcoming)).to be_empty
      end

      it "includes assignments where at least one assigned student is due within the next week" do
        create_adhoc_override_for_assignment(@assignment, @second_student, due_at: 1.day.from_now)
        expect(sorter.assignments(:upcoming)).to include @assignment
      end
    end

    describe "future" do
      it "excludes assignments where no assigned students are due in the future" do
        @assignment.update!(due_at: 1.day.from_now)
        create_adhoc_override_for_assignment(@assignment, @first_student, due_at: 1.day.ago)
        create_adhoc_override_for_assignment(@assignment, @second_student, due_at: 2.days.ago)
        expect(sorter.assignments(:future)).to be_empty
      end

      it "includes assignments where at least one assigned student is without a due date" do
        create_adhoc_override_for_assignment(@assignment, @first_student, due_at: nil)
        expect(sorter.assignments(:future)).to include @assignment
      end

      it "includes assignments where at least one assigned student has a due date in the future" do
        create_adhoc_override_for_assignment(@assignment, @first_student, due_at: 1.day.from_now)
        expect(sorter.assignments(:future)).to include @assignment
      end
    end
  end
end
