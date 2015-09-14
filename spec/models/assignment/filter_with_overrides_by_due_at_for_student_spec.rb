require_relative '../../spec_helper'
require_relative '../../../app/models/assignment/filter_with_overrides_by_due_at_for_student'

describe Assignment::FilterWithOverridesByDueAtForStudent do
  describe '#filter_assignments' do
    before :all do
      @course = Course.create!
      @assignment = @course.assignments.create!
      group = @course.grading_period_groups.create!
      @grading_period = group.grading_periods.create!(
        title: 'testing is easy, he said',
        start_date: 1.month.ago,
        end_date: 2.months.from_now
      )
      @last_grading_period = group.grading_periods.create!(
        title: 'this is the last time',
        start_date: 3.months.from_now,
        end_date: 28.years.from_now
      )
      @student = User.create!
      @section = @course.course_sections.create!(name: 'Section 1')
      @course.enroll_student(@student, section: @section, enrollment_state: 'active')
    end

    context 'the assignment has one override and the override applies to the student' do
      before :all do
        @assignment.only_visible_to_overrides = true
        @override = @assignment.assignment_overrides.create!
        @override.assignment_override_students.create!(user: @student)
      end

      after :all do
        @assignment.only_visible_to_overrides = false
        @assignment.assignment_overrides.destroy_all
      end

      context 'given that override has a due at' do
        it 'selects the assignment if the override due_at falls within the grading period' do
          @override.due_at = 2.days.from_now
          @override.save!
          filtered_assignments = Assignment::FilterWithOverridesByDueAtForStudent.new(
            assignments: [@assignment],
            grading_period: @grading_period,
            student: @student
          ).filter_assignments
          expect(filtered_assignments).to include @assignment
        end

        it 'does not select assignment if the override due_at does not fall within the grading period' do
          @override.due_at = 3.months.from_now
          @override.save!
          filtered_assignments = Assignment::FilterWithOverridesByDueAtForStudent.new(
            assignments: [@assignment],
            grading_period: @grading_period,
            student: @student
          ).filter_assignments
          expect(filtered_assignments).to_not include @assignment
        end
      end

      context 'given that override does not have a due at' do
        before :all do
          @override.due_at = nil
          @override.save!
        end

        it 'does not select assignment if the grading period is not the last period' do
          filtered_assignments = Assignment::FilterWithOverridesByDueAtForStudent.new(
            assignments: [@assignment],
            grading_period: @grading_period,
            student: @student
          ).filter_assignments

          expect(filtered_assignments).to_not include @assignment
        end

        it 'selects the assignment if the grading period is the last period' do
          filtered_assignments = Assignment::FilterWithOverridesByDueAtForStudent.new(
            assignments: [@assignment],
            grading_period: @last_grading_period,
            student: @student
          ).filter_assignments

          expect(filtered_assignments).to include @assignment
        end
      end
    end

    context 'the assignment has one override and the override does not apply to the student' do
      before :all do
        @assignment.assignment_overrides.create!
      end

      after :all do
        @assignment.assignment_overrides.destroy_all
        @assignment.due_at = nil
        @assignment.only_visible_to_overrides = false
      end

      context 'the assignment has a due at' do
        it 'selects the assignment if it is in the grading period and "Everyone Else" has been assigned' do
          @assignment.due_at = 2.days.from_now
          @assignment.only_visible_to_overrides = false

          filtered_assignments = Assignment::FilterWithOverridesByDueAtForStudent.new(
            assignments: [@assignment],
            grading_period: @grading_period,
            student: @student
          ).filter_assignments

          expect(filtered_assignments).to include @assignment
        end

        it 'does not select the assignment if it is in the grading period, but "Everyone Else" has not been assigned' do
          @assignment.due_at = 2.days.from_now
          @assignment.only_visible_to_overrides = true

          filtered_assignments = Assignment::FilterWithOverridesByDueAtForStudent.new(
            assignments: [@assignment],
            grading_period: @grading_period,
            student: @student
          ).filter_assignments

          expect(filtered_assignments).to_not include @assignment
        end

        it 'does not select the assignment if it is not in the grading period, and "Everyone Else" has been assigned' do
          @assignment.due_at = 3.months.from_now
          @assignment.only_visible_to_overrides = false

          filtered_assignments = Assignment::FilterWithOverridesByDueAtForStudent.new(
            assignments: [@assignment],
            grading_period: @grading_period,
            student: @student
          ).filter_assignments

          expect(filtered_assignments).to_not include @assignment
        end

        it 'does not select the assignment if it is not in the grading period,' \
        ' and "Everyone Else" has not been assigned' do
          @assignment.due_at = 3.months.from_now
          @assignment.only_visible_to_overrides = true

          filtered_assignments = Assignment::FilterWithOverridesByDueAtForStudent.new(
            assignments: [@assignment],
            grading_period: @grading_period,
            student: @student
          ).filter_assignments

          expect(filtered_assignments).to_not include @assignment
        end
      end

      context 'the assignment does not have a due at' do
        it 'does not select the assignment if it is not the last grading period,' \
        ' and "Everyone Else" has been assigned' do
          @assignment.due_at = nil
          @assignment.only_visible_to_overrides = false

          filtered_assignments = Assignment::FilterWithOverridesByDueAtForStudent.new(
            assignments: [@assignment],
            grading_period: @grading_period,
            student: @student
          ).filter_assignments

          expect(filtered_assignments).to_not include @assignment
        end

        it 'does not select the assignment if it is not the last grading period,' \
        ' and "Everyone Else" has not been assigned' do
          @assignment.due_at = nil
          @assignment.only_visible_to_overrides = true

          filtered_assignments = Assignment::FilterWithOverridesByDueAtForStudent.new(
            assignments: [@assignment],
            grading_period: @grading_period,
            student: @student
          ).filter_assignments

          expect(filtered_assignments).to_not include @assignment
        end

        context 'the grading period is the last' do
          it 'selects the assignment if "Everyone Else" has been assigned' do
            @assignment.due_at = nil
            @assignment.only_visible_to_overrides = false

            filtered_assignments = Assignment::FilterWithOverridesByDueAtForStudent.new(
              assignments: [@assignment],
              grading_period: @last_grading_period,
              student: @student
            ).filter_assignments

            expect(filtered_assignments).to include @assignment
          end

          it 'does not select the assignment if "Everyone Else" has not been assigned' do
            @assignment.due_at = nil
            @assignment.only_visible_to_overrides = true

            filtered_assignments = Assignment::FilterWithOverridesByDueAtForStudent.new(
              assignments: [@assignment],
              grading_period: @last_grading_period,
              student: @student
            ).filter_assignments

            expect(filtered_assignments).to_not include @assignment
          end
        end
      end
    end

    context 'the assignment does not have any overrides' do
      after :all do
        @assignment.due_at = nil
      end

      context 'the assignment has a due at' do
        it 'selects the assignment if its due at falls within the grading period' do
          @assignment.due_at = 2.days.from_now

          filtered_assignments = Assignment::FilterWithOverridesByDueAtForStudent.new(
            assignments: [@assignment],
            grading_period: @grading_period,
            student: @student
          ).filter_assignments

          expect(filtered_assignments).to include @assignment
        end

        it 'does not select the assignment if its due is outside of the grading period' do
          @assignment.due_at = 3.months.from_now

          filtered_assignments = Assignment::FilterWithOverridesByDueAtForStudent.new(
            assignments: [@assignment],
            grading_period: @grading_period,
            student: @student
          ).filter_assignments

          expect(filtered_assignments).to_not include @assignment
        end
      end

      context 'the assignment does not have a due at' do
        it 'does not select the assignment if it is not the last grading period' do
          @assignment.due_at = nil

          filtered_assignments = Assignment::FilterWithOverridesByDueAtForStudent.new(
            assignments: [@assignment],
            grading_period: @grading_period,
            student: @student
          ).filter_assignments

          expect(filtered_assignments).to_not include @assignment
        end

        it 'selects the assignment if it is the last grading period' do
          @assignment.due_at = nil

          filtered_assignments = Assignment::FilterWithOverridesByDueAtForStudent.new(
            assignments: [@assignment],
            grading_period: @last_grading_period,
            student: @student
          ).filter_assignments

          expect(filtered_assignments).to include @assignment
        end
      end
    end

    context 'the assignment has two overrides that apply to the student' do
      before :all do
        @student_override = @assignment.assignment_overrides.create!
        @student_override.assignment_override_students.create!(user: @student)

        @section_override = @assignment.assignment_overrides.new
        @section_override.set = @section
        @section_override.save!
      end

      after :all do
        @assignment.assignment_overrides.destroy_all
      end

      context 'both overrides have a due at' do
        it 'selects the assignment if the later due at falls in the grading period' do
          @student_override.due_at = 2.months.ago
          @student_override.save!
          @section_override.due_at = 2.days.from_now
          @section_override.save!
          filtered_assignments = Assignment::FilterWithOverridesByDueAtForStudent.new(
            assignments: [@assignment],
            grading_period: @grading_period,
            student: @student
          ).filter_assignments
          expect(filtered_assignments).to include @assignment
        end

        it 'does not select the assignment if the later due at is outside of the grading period' \
        ' (even if the earlier due at is within the grading period)' do
          @student_override.due_at = 2.days.from_now
          @student_override.save!
          @section_override.due_at = 3.months.from_now
          @section_override.save!
          filtered_assignments = Assignment::FilterWithOverridesByDueAtForStudent.new(
            assignments: [@assignment],
            grading_period: @grading_period,
            student: @student
          ).filter_assignments
          expect(filtered_assignments).to_not include @assignment
        end
      end

      context 'one of the overrides has a due at, one does not' do
        context 'not the last grading period' do
          it 'does not select the assignment if the due at is outside of the grading period' do
            @student_override.due_at = nil
            @student_override.save!
            @section_override.due_at = 3.months.from_now
            @section_override.save!
            filtered_assignments = Assignment::FilterWithOverridesByDueAtForStudent.new(
              assignments: [@assignment],
              grading_period: @grading_period,
              student: @student
            ).filter_assignments
            expect(filtered_assignments).to_not include @assignment
          end

          it 'does not select the assignment even if the due at is within the grading period' do
            @student_override.due_at = nil
            @student_override.save!
            @section_override.due_at = 2.days.from_now
            @section_override.save!
            filtered_assignments = Assignment::FilterWithOverridesByDueAtForStudent.new(
              assignments: [@assignment],
              grading_period: @grading_period,
              student: @student
            ).filter_assignments
            expect(filtered_assignments).to_not include @assignment
          end
        end

        context 'the last grading period' do
          it 'selects the assignment if the due at is within the grading period' do
            @student_override.due_at = nil
            @student_override.save!
            @section_override.due_at = 2.days.from_now
            @section_override.save!
            filtered_assignments = Assignment::FilterWithOverridesByDueAtForStudent.new(
              assignments: [@assignment],
              grading_period: @last_grading_period,
              student: @student
            ).filter_assignments
            expect(filtered_assignments).to include @assignment
          end

          it 'selects the assignment even if the due at is outside of the grading period' do
            @student_override.due_at = nil
            @student_override.save!
            @section_override.due_at = 3.months.from_now
            @section_override.save!
            filtered_assignments = Assignment::FilterWithOverridesByDueAtForStudent.new(
              assignments: [@assignment],
              grading_period: @last_grading_period,
              student: @student
            ).filter_assignments
            expect(filtered_assignments).to include @assignment
          end
        end
      end

      context 'neither override has a due at' do
        before :all do
          @student_override.due_at = nil
          @student_override.save!
          @section_override.due_at = nil
          @section_override.save!
        end

        it 'does not select the assignment if it is not the last grading period' do
          filtered_assignments = Assignment::FilterWithOverridesByDueAtForStudent.new(
            assignments: [@assignment],
            grading_period: @grading_period,
            student: @student
          ).filter_assignments
          expect(filtered_assignments).to_not include @assignment
        end

        it 'selects the assignment if it is the last grading period' do
          filtered_assignments = Assignment::FilterWithOverridesByDueAtForStudent.new(
            assignments: [@assignment],
            grading_period: @last_grading_period,
            student: @student
          ).filter_assignments
          expect(filtered_assignments).to include @assignment
        end
      end
    end
  end
end
