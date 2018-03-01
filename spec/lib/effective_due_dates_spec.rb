#
# Copyright (C) 2016 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe Course do
  before(:once) do
    @test_course = Course.create!
    course_with_teacher(course: @test_course, active_all: true)
    @teacher = @user
  end

  describe 'for_course' do
    it 'raises error if context is not a course' do
      expect { EffectiveDueDates.for_course({}) }.to raise_error('Context must be a course')
    end

    it 'raises error if context has no id' do
      expect { EffectiveDueDates.for_course(Course.new) }.to raise_error('Context must have an id')
    end

    it 'saves context' do
      edd = EffectiveDueDates.for_course(@test_course)
      expect(edd.context).to eq(@test_course)
    end
  end

  describe '#filter_students_to' do
    let(:edd) { EffectiveDueDates.for_course(@test_course) }

    it 'defaults to no filtered students' do
      expect(edd.filtered_students).to be_nil
    end

    it 'saves an array of students' do
      user1, user2 = User.create, User.create
      edd.filter_students_to([user1, user2])
      expect(edd.filtered_students).to eq [user1.id, user2.id]
    end

    it 'saves a list of students' do
      user1, user2 = User.create, User.create
      edd.filter_students_to(user1, user2)
      expect(edd.filtered_students).to eq [user1.id, user2.id]
    end

    it 'saves a list of student ids' do
      edd.filter_students_to(15, 20, 2)
      expect(edd.filtered_students).to eq [15, 20, 2]
    end

    it 'does nothing if no students are passed' do
      edd.filter_students_to
      expect(edd.filtered_students).to be_nil
    end

    it 'allows chaining' do
      expect(edd.filter_students_to(5)).to eq edd
    end
  end

  describe '#to_hash' do
    before(:once) do
      @now = Time.zone.now.change(sec: 0)
      @student1_enrollment = student_in_course(course: @test_course, active_all: true)
      @student1 = @student1_enrollment.user
      @student2 = student_in_course(course: @test_course, active_all: true).user
      @student3 = student_in_course(course: @test_course, active_all: true).user
      @other_course = Course.create!
      @student_in_other_course = student_in_course(course: @other_course, active_all: true).user
      @assignment1 = @test_course.assignments.create!(due_at: 2.weeks.from_now(@now))
      @assignment2 = @test_course.assignments.create!
      @assignment3 = @test_course.assignments.create!
      @deleted_assignment = @test_course.assignments.create!
      @deleted_assignment.destroy
      @assignment_in_other_course = @other_course.assignments.create!
    end

    it 'properly converts timezones' do
      Time.zone = 'Alaska'
      default_due = DateTime.parse("01 Jan 2011 14:00 AKST")
      @assignment4 = @test_course.assignments.create!(title: "some assignment", due_at: default_due, submission_types: ['online_text_entry'])

      edd = EffectiveDueDates.for_course(@test_course, @assignment4)
      result = edd.to_hash
      expect(result[@assignment4.id][@student1.id][:due_at]).to eq default_due
    end

    it 'returns the effective due dates per assignment per student' do
      edd = EffectiveDueDates.for_course(@test_course)
      result = edd.to_hash
      expected = {
        @assignment1.id => {
          @student1.id => {
            due_at: 2.weeks.from_now(@now),
            grading_period_id: nil,
            in_closed_grading_period: false,
            override_id: nil,
            override_source: 'Everyone Else'
          },
          @student2.id => {
            due_at: 2.weeks.from_now(@now),
            grading_period_id: nil,
            in_closed_grading_period: false,
            override_id: nil,
            override_source: 'Everyone Else'
          },
          @student3.id => {
            due_at: 2.weeks.from_now(@now),
            grading_period_id: nil,
            in_closed_grading_period: false,
            override_id: nil,
            override_source: 'Everyone Else'
          }
        },
        @assignment2.id => {
          @student1.id => {
            due_at: nil,
            grading_period_id: nil,
            in_closed_grading_period: false,
            override_id: nil,
            override_source: 'Everyone Else'
          },
          @student2.id => {
            due_at: nil,
            grading_period_id: nil,
            in_closed_grading_period: false,
            override_id: nil,
            override_source: 'Everyone Else'
          },
          @student3.id => {
            due_at: nil,
            grading_period_id: nil,
            in_closed_grading_period: false,
            override_id: nil,
            override_source: 'Everyone Else'
          }
        },
        @assignment3.id => {
          @student1.id => {
            due_at: nil,
            grading_period_id: nil,
            in_closed_grading_period: false,
            override_id: nil,
            override_source: 'Everyone Else'
          },
          @student2.id => {
            due_at: nil,
            grading_period_id: nil,
            in_closed_grading_period: false,
            override_id: nil,
            override_source: 'Everyone Else'
          },
          @student3.id => {
            due_at: nil,
            grading_period_id: nil,
            in_closed_grading_period: false,
            override_id: nil,
            override_source: 'Everyone Else'
          }
        }
      }
      expect(result).to eq expected
    end

    it 'returns the effective due dates per assignment for select students when filtered' do
      edd = EffectiveDueDates.for_course(@test_course).filter_students_to(@student1, @student3)
      result = edd.to_hash
      expected = {
        @assignment1.id => {
          @student1.id => {
            due_at: 2.weeks.from_now(@now),
            grading_period_id: nil,
            in_closed_grading_period: false,
            override_id: nil,
            override_source: 'Everyone Else'
          },
          @student3.id => {
            due_at: 2.weeks.from_now(@now),
            grading_period_id: nil,
            in_closed_grading_period: false,
            override_id: nil,
            override_source: 'Everyone Else'
          }
        },
        @assignment2.id => {
          @student1.id => {
            due_at: nil,
            grading_period_id: nil,
            in_closed_grading_period: false,
            override_id: nil,
            override_source: 'Everyone Else'
          },
          @student3.id => {
            due_at: nil,
            grading_period_id: nil,
            in_closed_grading_period: false,
            override_id: nil,
            override_source: 'Everyone Else'
          }
        },
        @assignment3.id => {
          @student1.id => {
            due_at: nil,
            grading_period_id: nil,
            in_closed_grading_period: false,
            override_id: nil,
            override_source: 'Everyone Else'
          },
          @student3.id => {
            due_at: nil,
            grading_period_id: nil,
            in_closed_grading_period: false,
            override_id: nil,
            override_source: 'Everyone Else'
          }
        }
      }
      expect(result).to eq expected
    end

    it 'maps id if the assignments are already loaded' do
      args = @test_course.active_assignments.to_a
      expect(args[0]).to receive(:id).once
      expect(args[1]).to receive(:id).once
      expect(args[2]).to receive(:id).once
      edd = EffectiveDueDates.for_course(@test_course, args)
      edd.to_hash
    end

    it 'uses sql if the assignments are still a relation' do
      args = @test_course.active_assignments
      expect_any_instance_of(Assignment).to receive(:id).never
      edd = EffectiveDueDates.for_course(@test_course, args)
      edd.to_hash
    end

    it 'memoizes the result' do
      args = @test_course.active_assignments.to_a
      expect(args[0]).to receive(:id).once
      expect(args[1]).to receive(:id).once
      expect(args[2]).to receive(:id).once
      edd = EffectiveDueDates.for_course(@test_course, args)
      2.times { edd.to_hash }
    end

    it 'can be passed a list of keys to only return those attributes' do
      due_dates = EffectiveDueDates.for_course(@test_course)
      due_dates_hash = due_dates.to_hash([:due_at, :override_source])
      attributes_returned = due_dates_hash[@assignment1.id][@student1.id].keys
      expect(attributes_returned).to contain_exactly(:due_at, :override_source)
    end

    describe 'initializes with' do
      it 'no arguments and defaults to all active course assignments' do
        edd = EffectiveDueDates.for_course(@test_course)
        result = edd.to_hash
        expect(result.keys).to contain_exactly(@assignment1.id, @assignment2.id, @assignment3.id)
      end

      it 'a list of ActiveRecord Assignment models' do
        edd = EffectiveDueDates.for_course(@test_course, @assignment1, @assignment3)
        result = edd.to_hash
        expect(result.keys).to contain_exactly(@assignment3.id, @assignment1.id)
      end

      it 'an array of ActiveRecord Assignment models' do
        edd = EffectiveDueDates.for_course(@test_course, [@assignment1, @assignment3])
        result = edd.to_hash
        expect(result.keys).to contain_exactly(@assignment3.id, @assignment1.id)
      end

      it 'a list of ids' do
        edd = EffectiveDueDates.for_course(@test_course, @assignment1.id, @assignment3.id)
        result = edd.to_hash
        expect(result.keys).to contain_exactly(@assignment3.id, @assignment1.id)
      end

      it 'an array of ids' do
        edd = EffectiveDueDates.for_course(@test_course, [@assignment1.id, @assignment3.id])
        result = edd.to_hash
        expect(result.keys).to contain_exactly(@assignment3.id, @assignment1.id)
      end

      it 'a single ActiveRecord relation' do
        edd = EffectiveDueDates.for_course(@test_course, @test_course.assignments)
        result = edd.to_hash
        expect(result.keys).to contain_exactly(@assignment3.id, @assignment2.id, @assignment1.id)
      end

      it 'nil' do
        edd = EffectiveDueDates.for_course(@test_course, nil)
        result = edd.to_hash
        expect(result).to be_empty
      end

      it 'new Assignment objects that do not have an ID' do
        new_assignment = @test_course.assignments.build
        edd = EffectiveDueDates.for_course(@test_course, new_assignment)
        result = edd.to_hash
        expect(result).to be_empty
      end
    end

    it 'ignores students who are not in the course' do
      edd = EffectiveDueDates.for_course(@test_course, @assignment1)
      result = edd.to_hash
      student_ids = result[@assignment1.id].keys
      expect(student_ids).not_to include @student_in_other_course.id
    end

    it 'ignores assignments that are not in this course' do
      edd = EffectiveDueDates.for_course(@test_course, @assignment_in_other_course)
      result = edd.to_hash
      expect(result).to be_empty
    end

    it 'ignores assignments that are soft-deleted' do
      edd = EffectiveDueDates.for_course(@test_course, @deleted_assignment)
      result = edd.to_hash
      expect(result).to be_empty
    end

    it 'ignores enrollments that rejected the course invitation' do
      @student1_enrollment.reject
      edd = EffectiveDueDates.for_course(@test_course, @assignment1)
      student_ids = edd.to_hash[@assignment1.id].keys
      expect(student_ids).not_to include @student1.id
    end

    it 'includes deactivated enrollments' do
      @student1_enrollment.deactivate
      edd = EffectiveDueDates.for_course(@test_course, @assignment1)
      student_ids = edd.to_hash[@assignment1.id].keys
      expect(student_ids).to include @student1.id
    end

    it 'includes concluded enrollments' do
      @student1_enrollment.conclude
      edd = EffectiveDueDates.for_course(@test_course, @assignment1)
      student_ids = edd.to_hash[@assignment1.id].keys
      expect(student_ids).to include @student1.id
    end

    it 'ignores enrollments that are not students' do
      @student1_enrollment.type = 'TeacherEnrollment'
      @student1_enrollment.save!
      edd = EffectiveDueDates.for_course(@test_course, @assignment1)
      result = edd.to_hash
      student_ids = result[@assignment1.id].keys
      expect(student_ids).not_to include @student1.id
    end

    it 'ignores soft deleted students' do
      @student1_enrollment.destroy
      edd = EffectiveDueDates.for_course(@test_course, @assignment1)
      result = edd.to_hash
      student_ids = result[@assignment1.id].keys
      expect(student_ids).not_to include @student1.id
    end

    context 'when only visible to overrides' do
      before(:once) do
        @assignment1.only_visible_to_overrides = true
        @assignment1.save!
      end

      it 'ignores inactive overrides' do
        override = @assignment1.assignment_overrides.create!(due_at: 5.days.from_now(@now), due_at_overridden: true)
        override.assignment_override_students.create!(user: @student2)
        override.destroy!

        edd = EffectiveDueDates.for_course(@test_course, @assignment1)
        expect(edd.to_hash).to eq({})
      end

      it 'ignores noop overrides' do
        @assignment1.assignment_overrides.create!(set_type: 'Noop')
        edd = EffectiveDueDates.for_course(@test_course, @assignment1)
        expect(edd.to_hash).to eq({})
      end

      it 'includes overrides with null due dates' do
        override = @assignment1.assignment_overrides.create!(due_at: nil, due_at_overridden: true)
        override.assignment_override_students.create!(user: @student3)

        edd = EffectiveDueDates.for_course(@test_course, @assignment1)
        result = edd.to_hash
        expected = {
          @assignment1.id => {
            @student3.id => {
              due_at: nil,
              grading_period_id: nil,
              in_closed_grading_period: false,
              override_id: override.id,
              override_source: 'ADHOC'
            }
          }
        }
        expect(result).to eq expected
      end

      it 'includes overrides without due_at_overridden, and uses the due_at from the assignment' do
        override = @assignment1.assignment_overrides.create!(due_at: nil)
        override.assignment_override_students.create!(user: @student3)

        edd = EffectiveDueDates.for_course(@test_course, @assignment1)
        expect(edd.to_hash[@assignment1.id][@student3.id][:due_at]).to eq(@assignment1.due_at)
      end

      it 'uses the due_at from the assignment when the assignment is only visible to overrides and no overrides for the student have due_at_overridden' do
        @assignment1.update!(due_at: @now)
        override = @assignment1.assignment_overrides.create!(due_at: 2.days.from_now(@now))
        override.assignment_override_students.create!(user: @student3)

        edd = EffectiveDueDates.for_course(@test_course, @assignment1)
        expect(edd.to_hash[@assignment1.id][@student3.id][:due_at]).to eq(@now)
      end

      it 'uses the due_at from the assignment when the assignment is visible to everyone and no overrides for the student have due_at_overridden' do
        @assignment1.update!(only_visible_to_overrides: false, due_at: @now)
        override = @assignment1.assignment_overrides.create!(due_at: 2.days.from_now(@now))
        override.assignment_override_students.create!(user: @student3)

        edd = EffectiveDueDates.for_course(@test_course, @assignment1)
        expect(edd.to_hash[@assignment1.id][@student3.id][:due_at]).to eq(@now)
      end

      it 'does not consider the due_at from overrides without due_at_overridden when the override due_at is nil' do
        override = @assignment1.assignment_overrides.create!(due_at: nil)
        override.assignment_override_students.create!(user: @student3)

        section = CourseSection.create!(name: 'My Awesome Section', course: @test_course)
        student_in_section(section, user: @student3)
        section_override = @assignment1.assignment_overrides.create!(
          due_at: 1.day.from_now(@now),
          due_at_overridden: true,
          set: section
        )

        edd = EffectiveDueDates.for_course(@test_course, @assignment1)
        expect(edd.to_hash[@assignment1.id][@student3.id][:due_at]).to eq(1.day.from_now(@now))
      end

      it 'does not consider the due_at from overrides without due_at_overridden even if the due date is more lenient than other dates' do
        override = @assignment1.assignment_overrides.create!(due_at: 2.days.from_now(@now))
        override.assignment_override_students.create!(user: @student3)

        section = CourseSection.create!(name: 'My Awesome Section', course: @test_course)
        student_in_section(section, user: @student3)
        section_override = @assignment1.assignment_overrides.create!(
          due_at: 1.day.from_now(@now),
          due_at_overridden: true,
          set: section
        )

        edd = EffectiveDueDates.for_course(@test_course, @assignment1)
        expect(edd.to_hash[@assignment1.id][@student3.id][:due_at]).to eq(1.day.from_now(@now))
      end

      it 'applies adhoc overrides' do
        override = @assignment1.assignment_overrides.create!(due_at: 3.days.from_now(@now), due_at_overridden: true)
        override.assignment_override_students.create!(user: @student1)

        edd = EffectiveDueDates.for_course(@test_course, @assignment1)
        result = edd.to_hash
        expected = {
          @assignment1.id => {
            @student1.id => {
              due_at: 3.days.from_now(@now),
              grading_period_id: nil,
              in_closed_grading_period: false,
              override_id: override.id,
              override_source: 'ADHOC'
            }
          }
        }
        expect(result).to eq expected
      end

      it 'ignores soft-deleted adhoc overrides' do
        override = @assignment1.assignment_overrides.create!(due_at: 7.days.from_now(@now), due_at_overridden: true)
        override_student = override.assignment_override_students.create!(user: @student1)
        override_student.update!(workflow_state: 'deleted')

        override = @assignment1.assignment_overrides.create!(due_at: 3.days.from_now(@now), due_at_overridden: true)
        override.assignment_override_students.create!(user: @student1)

        edd = EffectiveDueDates.for_course(@test_course, @assignment1)
        result = edd.to_hash
        expected = {
          @assignment1.id => {
            @student1.id => {
              due_at: 3.days.from_now(@now),
              grading_period_id: nil,
              in_closed_grading_period: false,
              override_id: override.id,
              override_source: 'ADHOC'
            }
          }
        }
        expect(result).to eq(expected)
      end

      it 'correctly matches adhoc overrides for different assignments' do
        @assignment2.only_visible_to_overrides = true
        @assignment2.save!
        override2 = @assignment2.assignment_overrides.create!(due_at: 3.days.from_now(@now), due_at_overridden: true)
        override2.assignment_override_students.create!(user: @student1)
        override1 = @assignment1.assignment_overrides.create!(due_at: 7.days.from_now(@now), due_at_overridden: true)
        override1.assignment_override_students.create!(user: @student1)

        edd = EffectiveDueDates.for_course(@test_course, @assignment1, @assignment2)
        result = edd.to_hash
        expected = {
          @assignment1.id => {
            @student1.id => {
              due_at: 7.days.from_now(@now),
              grading_period_id: nil,
              in_closed_grading_period: false,
              override_id: override1.id,
              override_source: 'ADHOC'
            }
          },
          @assignment2.id => {
            @student1.id => {
              due_at: 3.days.from_now(@now),
              grading_period_id: nil,
              in_closed_grading_period: false,
              override_id: override2.id,
              override_source: 'ADHOC'
            }
          }
        }
        expect(result).to eq expected
      end

      it 'correctly matches adhoc overrides for different students' do
        override1 = @assignment1.assignment_overrides.create!(due_at: 7.days.from_now(@now), due_at_overridden: true)
        override1.assignment_override_students.create!(user: @student1)
        override2 = @assignment1.assignment_overrides.create!(due_at: 1.day.from_now(@now), due_at_overridden: true)
        override2.assignment_override_students.create!(user: @student2)

        edd = EffectiveDueDates.for_course(@test_course, @assignment1)
        result = edd.to_hash
        expected = {
          @assignment1.id => {
            @student1.id => {
              due_at: 7.days.from_now(@now),
              grading_period_id: nil,
              in_closed_grading_period: false,
              override_id: override1.id,
              override_source: 'ADHOC'
            },
            @student2.id => {
              due_at: 1.day.from_now(@now),
              grading_period_id: nil,
              in_closed_grading_period: false,
              override_id: override2.id,
              override_source: 'ADHOC'
            }
          }
        }
        expect(result).to eq expected
      end

      it 'applies group overrides' do
        group_with_user(user: @student3, active_all: true)
        @group.users << @student2
        override = @assignment1.assignment_overrides.create!(
          due_at: 4.days.from_now(@now),
          due_at_overridden: true,
          set: @group
        )

        edd = EffectiveDueDates.for_course(@test_course, @assignment1)
        result = edd.to_hash
        expected = {
          @assignment1.id => {
            @student2.id => {
              due_at: 4.days.from_now(@now),
              grading_period_id: nil,
              in_closed_grading_period: false,
              override_id: override.id,
              override_source: 'Group'
            },
            @student3.id => {
              due_at: 4.days.from_now(@now),
              grading_period_id: nil,
              in_closed_grading_period: false,
              override_id: override.id,
              override_source: 'Group'
            }
          }
        }
        expect(result).to eq expected
      end

      it 'ignores overrides for soft-deleted groups' do
        group_with_user(user: @student3, active_all: true)
        @assignment1.assignment_overrides.create!(due_at: 4.days.from_now(@now), due_at_overridden: true, set: @group)
        @group.destroy!

        edd = EffectiveDueDates.for_course(@test_course, @assignment1)
        expect(edd.to_hash).to eq({})
      end

      it 'only applies group overrides to students that have accepted the group invitation' do
        group
        @group.add_user(@student1, 'rejected')
        @assignment1.assignment_overrides.create!(due_at: 4.days.from_now(@now), due_at_overridden: true, set: @group)

        edd = EffectiveDueDates.for_course(@test_course, @assignment1)
        expect(edd.to_hash).to eq({})
      end

      it 'applies section overrides' do
        section = CourseSection.create!(name: 'My Awesome Section', course: @test_course)
        student_in_section(section, user: @student2)
        student_in_section(section, user: @student1)
        override = @assignment1.assignment_overrides.create!(
          due_at: 1.day.from_now(@now),
          due_at_overridden: true,
          set: section
        )

        edd = EffectiveDueDates.for_course(@test_course, @assignment1)
        result = edd.to_hash
        expected = {
          @assignment1.id => {
            @student1.id => {
              due_at: 1.day.from_now(@now),
              grading_period_id: nil,
              in_closed_grading_period: false,
              override_id: override.id,
              override_source: 'CourseSection'
            },
            @student2.id => {
              due_at: 1.day.from_now(@now),
              grading_period_id: nil,
              in_closed_grading_period: false,
              override_id: override.id,
              override_source: 'CourseSection'
            }
          }
        }
        expect(result).to eq expected
      end

      it 'ignores section overrides for TAs' do
        section = CourseSection.create!(name: 'My Awesome Section', course: @test_course)
        ta_in_section(section, user: @student2)
        @assignment1.assignment_overrides.create!(due_at: 1.day.from_now(@now), due_at_overridden: true, set: section)

        edd = EffectiveDueDates.for_course(@test_course, @assignment1)
        expect(edd.to_hash).to eq({})
      end

      it 'ignores overrides for soft-deleted sections' do
        section = CourseSection.create!(name: 'My Awesome Section', course: @test_course)
        student_in_section(section, user: @student2)
        @assignment1.assignment_overrides.create!(due_at: 1.day.from_now(@now), due_at_overridden: true, set: section)
        section.destroy!

        edd = EffectiveDueDates.for_course(@test_course, @assignment1)
        expect(edd.to_hash).to eq({})
      end

      it 'ignores not-assigned students with existing graded submissions' do
        @assignment1.grade_student(@student1, grade: 5, grader: @teacher)

        edd = EffectiveDueDates.for_course(@test_course, @assignment1)
        result = edd.to_hash
        expect(result).to be_empty
      end

      it 'uses assigned date instead of submission date even if submission was late' do
        override = @assignment1.assignment_overrides.create!(due_at: 3.days.from_now(@now), due_at_overridden: true)
        override.assignment_override_students.create!(user: @student1)
        @assignment1.grade_student(@student1, grade: 5, grader: @teacher)
        @assignment1.submissions.find_by!(user: @student1).update!(
          submitted_at: 1.week.from_now(@now),
          submission_type: 'online_text_entry'
        )

        edd = EffectiveDueDates.for_course(@test_course, @assignment1)
        result = edd.to_hash
        expected = {
          @assignment1.id => {
            @student1.id => {
              due_at: 3.days.from_now(@now),
              grading_period_id: nil,
              in_closed_grading_period: false,
              override_id: override.id,
              override_source: 'ADHOC'
            }
          }
        }
        expect(result).to eq expected
      end

      it 'prioritizes the override due date if it exists over the Everyone Else date' do
        override = @assignment2.assignment_overrides.create!(due_at: 3.days.from_now(@now), due_at_overridden: true)
        override.assignment_override_students.create!(user: @student1)
        @assignment2.due_at = 4.days.from_now(@now)
        @assignment2.save!

        edd = EffectiveDueDates.for_course(@test_course, @assignment2)
        result = edd.to_hash
        expected = {
          @assignment2.id => {
            @student1.id => {
              due_at: 3.days.from_now(@now),
              grading_period_id: nil,
              in_closed_grading_period: false,
              override_id: override.id,
              override_source: 'ADHOC'
            },
            @student2.id => {
              due_at: 4.days.from_now(@now),
              grading_period_id: nil,
              in_closed_grading_period: false,
              override_id: nil,
              override_source: 'Everyone Else'
            },
            @student3.id => {
              due_at: 4.days.from_now(@now),
              grading_period_id: nil,
              in_closed_grading_period: false,
              override_id: nil,
              override_source: 'Everyone Else'
            }
          }
        }
        expect(result).to eq expected
      end

      # this might look like a strange test to have, but it is a result of how we are joining different tables in sql.
      it 'prioritizes the override due date even if it is earlier than the Everyone Else date and the student has a graded submission that does not qualify' do
        override = @assignment2.assignment_overrides.create!(due_at: 3.days.ago(@now), due_at_overridden: true)
        override.assignment_override_students.create!(user: @student1)
        @assignment2.grade_student(@student1, grade: 5, grader: @teacher)
        @assignment2.submissions.find_by!(user: @student1).update!(
          submitted_at: 1.week.from_now(@now),
          submission_type: 'online_text_entry'
        )
        @assignment2.due_at = 4.days.from_now(@now)
        @assignment2.save!

        edd = EffectiveDueDates.for_course(@test_course, @assignment2)
        result = edd.to_hash
        expected = {
          @assignment2.id => {
            @student1.id => {
              due_at: 3.days.ago(@now),
              grading_period_id: nil,
              in_closed_grading_period: false,
              override_id: override.id,
              override_source: 'ADHOC'
            },
            @student2.id => {
              due_at: 4.days.from_now(@now),
              grading_period_id: nil,
              in_closed_grading_period: false,
              override_id: nil,
              override_source: 'Everyone Else'
            },
            @student3.id => {
              due_at: 4.days.from_now(@now),
              grading_period_id: nil,
              in_closed_grading_period: false,
              override_id: nil,
              override_source: 'Everyone Else'
            }
          }
        }
        expect(result).to eq expected
      end

      it 'prioritizes the Everyone Else due date if it exists over the submission NULL date' do
        @assignment2.due_at = 4.days.from_now(@now)
        @assignment2.save!
        @assignment2.grade_student(@student1, grade: 5, grader: @teacher)
        @assignment2.submissions.find_by!(user: @student1).update!(
          submitted_at: 1.week.from_now(@now),
          submission_type: 'online_text_entry'
        )

        edd = EffectiveDueDates.for_course(@test_course, @assignment2)
        result = edd.to_hash
        expected = {
          @assignment2.id => {
            @student1.id => {
              due_at: 4.days.from_now(@now),
              grading_period_id: nil,
              in_closed_grading_period: false,
              override_id: nil,
              override_source: 'Everyone Else'
            },
            @student2.id => {
              due_at: 4.days.from_now(@now),
              grading_period_id: nil,
              in_closed_grading_period: false,
              override_id: nil,
              override_source: 'Everyone Else'
            },
            @student3.id => {
              due_at: 4.days.from_now(@now),
              grading_period_id: nil,
              in_closed_grading_period: false,
              override_id: nil,
              override_source: 'Everyone Else'
            }
          }
        }
        expect(result).to eq expected
      end

      it 'ignores not-assigned students with ungraded submissions' do
        @assignment1.all_submissions.find_by!(user: @student1).update!(
          submission_type: 'online_text_entry',
          workflow_state: 'submitted'
        )

        edd = EffectiveDueDates.for_course(@test_course, @assignment1)
        expect(edd.to_hash).to eq({})
      end

      it 'picks the due date that gives the student the most amount of time to submit' do
        # adhoc
        override = @assignment2.assignment_overrides.create!(due_at: 3.days.from_now(@now), due_at_overridden: true)
        override.assignment_override_students.create!(user: @student1)

        # group
        group_with_user(user: @student1, active_all: true)
        group_override = @assignment2.assignment_overrides.create!(
          due_at: 6.days.from_now(@now),
          due_at_overridden: true,
          set: @group
        )

        # everyone else
        @assignment2.due_at = 4.days.from_now(@now)
        @assignment2.save!

        edd = EffectiveDueDates.for_course(@test_course, @assignment2)
        result = edd.to_hash
        expected = {
          @assignment2.id => {
            @student1.id => {
              due_at: 6.days.from_now(@now),
              grading_period_id: nil,
              in_closed_grading_period: false,
              override_id: group_override.id,
              override_source: 'Group'
            },
            @student2.id => {
              due_at: 4.days.from_now(@now),
              grading_period_id: nil,
              in_closed_grading_period: false,
              override_id: nil,
              override_source: 'Everyone Else'
            },
            @student3.id => {
              due_at: 4.days.from_now(@now),
              grading_period_id: nil,
              in_closed_grading_period: false,
              override_id: nil,
              override_source: 'Everyone Else'
            }
          }
        }
        expect(result).to eq expected
      end

      it 'treats null due dates as the most permissive due date for a student' do
        # adhoc
        override = @assignment2.assignment_overrides.create!(due_at: nil, due_at_overridden: true)
        override.assignment_override_students.create!(user: @student1)

        # group
        group_with_user(user: @student1, active_all: true)
        @assignment2.assignment_overrides.create!(due_at: 6.days.from_now(@now), due_at_overridden: true, set: @group)

        # everyone else
        @assignment2.due_at = 4.days.from_now(@now)
        @assignment2.save!

        edd = EffectiveDueDates.for_course(@test_course, @assignment2)
        result = edd.to_hash
        expected = {
          @assignment2.id => {
            @student1.id => {
              due_at: nil,
              grading_period_id: nil,
              in_closed_grading_period: false,
              override_id: override.id,
              override_source: 'ADHOC'
            },
            @student2.id => {
              due_at: 4.days.from_now(@now),
              grading_period_id: nil,
              in_closed_grading_period: false,
              override_id: nil,
              override_source: 'Everyone Else'
            },
            @student3.id => {
              due_at: 4.days.from_now(@now),
              grading_period_id: nil,
              in_closed_grading_period: false,
              override_id: nil,
              override_source: 'Everyone Else'
            }
          }
        }
        expect(result).to eq expected
      end

      it 'returns all students in the course if the assignment is assigned to everybody' do
        @assignment2.due_at = 4.days.from_now(@now)
        @assignment2.save!

        edd = EffectiveDueDates.for_course(@test_course, @assignment2)
        result = edd.to_hash
        expected = {
          @assignment2.id => {
            @student1.id => {
              due_at: 4.days.from_now(@now),
              grading_period_id: nil,
              in_closed_grading_period: false,
              override_id: nil,
              override_source: 'Everyone Else'
            },
            @student2.id => {
              due_at: 4.days.from_now(@now),
              grading_period_id: nil,
              in_closed_grading_period: false,
              override_id: nil,
              override_source: 'Everyone Else'
            },
            @student3.id => {
              due_at: 4.days.from_now(@now),
              grading_period_id: nil,
              in_closed_grading_period: false,
              override_id: nil,
              override_source: 'Everyone Else'
            }
          }
        }
        expect(result).to eq expected
      end

      context 'with grading periods' do
        before(:once) do
          @gp_group = Factories::GradingPeriodGroupHelper.new.create_for_account(@test_course.account)
          @gp_group.enrollment_terms << @test_course.enrollment_term
        end

        it 'uses account grading periods if no course grading periods exist' do
          gp = Factories::GradingPeriodHelper.new.create_for_group(@gp_group, {
            start_date: 20.days.ago(@now),
            end_date: 15.days.ago(@now),
            close_date: 10.days.ago(@now)
          })
          @assignment2.due_at = 17.days.ago(@now)
          @assignment2.only_visible_to_overrides = false
          @assignment2.save!

          edd = EffectiveDueDates.for_course(@test_course, @assignment2)
          result = edd.to_hash
          expected = {
            @assignment2.id => {
              @student1.id => {
                due_at: 17.days.ago(@now),
                grading_period_id: gp.id,
                in_closed_grading_period: true,
                override_id: nil,
                override_source: 'Everyone Else'
              },
              @student2.id => {
                due_at: 17.days.ago(@now),
                grading_period_id: gp.id,
                in_closed_grading_period: true,
                override_id: nil,
                override_source: 'Everyone Else'
              },
              @student3.id => {
                due_at: 17.days.ago(@now),
                grading_period_id: gp.id,
                in_closed_grading_period: true,
                override_id: nil,
                override_source: 'Everyone Else'
              }
            }
          }
          expect(result).to eq expected
        end

        it 'uses only course grading periods if any exist (legacy)' do
          Factories::GradingPeriodHelper.new.create_for_group(@gp_group, {
            start_date: 20.days.ago(@now),
            end_date: 15.days.ago(@now),
            close_date: 10.days.ago(@now)
          })
          legacy_group = Factories::GradingPeriodGroupHelper.new.legacy_create_for_course(@test_course)
          gp = Factories::GradingPeriodHelper.new.create_for_group(legacy_group, {
            start_date: 10.days.ago(@now),
            end_date: 5.days.ago(@now),
            close_date: 1.day.ago(@now)
          })
          @assignment2.due_at = 17.days.ago(@now)
          @assignment2.only_visible_to_overrides = false
          @assignment2.save!

          override = @assignment2.assignment_overrides.create!(due_at: 7.days.ago(@now), due_at_overridden: true)
          override.assignment_override_students.create!(user: @student2)

          edd = EffectiveDueDates.for_course(@test_course, @assignment2)
          result = edd.to_hash
          expected = {
            @assignment2.id => {
              @student1.id => {
                due_at: 17.days.ago(@now),
                grading_period_id: nil,
                in_closed_grading_period: false,
                override_id: nil,
                override_source: 'Everyone Else'
              },
              @student2.id => {
                due_at: 7.days.ago(@now),
                grading_period_id: gp.id,
                in_closed_grading_period: true,
                override_id: override.id,
                override_source: 'ADHOC'
              },
              @student3.id => {
                due_at: 17.days.ago(@now),
                grading_period_id: nil,
                in_closed_grading_period: false,
                override_id: nil,
                override_source: 'Everyone Else'
              }
            }
          }
          expect(result).to eq expected
        end

        it 'ignores account grading periods for unrelated enrollment terms' do
          gp_group = Factories::GradingPeriodGroupHelper.new.create_for_account_with_term(@test_course.account, 'Term')
          Factories::GradingPeriodHelper.new.create_for_group(gp_group, {
            start_date: 20.days.ago(@now),
            end_date: 15.days.ago(@now),
            close_date: 10.days.ago(@now)
          })
          @assignment2.due_at = 17.days.ago(@now)
          @assignment2.only_visible_to_overrides = false
          @assignment2.save!

          edd = EffectiveDueDates.for_course(@test_course, @assignment2)
          result = edd.to_hash
          expected = {
            @assignment2.id => {
              @student1.id => {
                due_at: 17.days.ago(@now),
                grading_period_id: nil,
                in_closed_grading_period: false,
                override_id: nil,
                override_source: 'Everyone Else'
              },
              @student2.id => {
                due_at: 17.days.ago(@now),
                grading_period_id: nil,
                in_closed_grading_period: false,
                override_id: nil,
                override_source: 'Everyone Else'
              },
              @student3.id => {
                due_at: 17.days.ago(@now),
                grading_period_id: nil,
                in_closed_grading_period: false,
                override_id: nil,
                override_source: 'Everyone Else'
              }
            }
          }
          expect(result).to eq expected
        end

        it 'uses the effective due date to find a closed grading period' do
          gp = Factories::GradingPeriodHelper.new.create_for_group(@gp_group, {
            start_date: 20.days.ago(@now),
            end_date: 15.days.ago(@now),
            close_date: 10.days.ago(@now)
          })
          @assignment2.due_at = 1.day.ago(@now)
          @assignment2.only_visible_to_overrides = false
          @assignment2.save!
          override = @assignment2.assignment_overrides.create!(due_at: 19.days.ago(@now), due_at_overridden: true)
          override.assignment_override_students.create!(user: @student3)

          edd = EffectiveDueDates.for_course(@test_course, @assignment2)
          result = edd.to_hash
          expected = {
            @assignment2.id => {
              @student1.id => {
                due_at: 1.day.ago(@now),
                grading_period_id: nil,
                in_closed_grading_period: false,
                override_id: nil,
                override_source: 'Everyone Else'
              },
              @student2.id => {
                due_at: 1.day.ago(@now),
                grading_period_id: nil,
                in_closed_grading_period: false,
                override_id: nil,
                override_source: 'Everyone Else'
              },
              @student3.id => {
                due_at: 19.days.ago(@now),
                grading_period_id: gp.id,
                in_closed_grading_period: true,
                override_id: override.id,
                override_source: 'ADHOC'
              }
            }
          }
          expect(result).to eq expected
        end

        it 'truncates seconds when comparing override due dates to grading period dates' do
          end_date = 15.days.ago(@now)
          grading_period = Factories::GradingPeriodHelper.new.create_for_group(
            @gp_group,
            start_date: 20.days.ago(@now),
            end_date: end_date,
            close_date: 10.days.ago(@now)
          )
          override = @assignment2.assignment_overrides.create!(
            due_at: 59.seconds.from_now(end_date),
            due_at_overridden: true
          )
          override.assignment_override_students.create!(user: @student3)

          effective_due_dates = EffectiveDueDates.for_course(@test_course, @assignment2).to_hash
          submission_grading_period_id = effective_due_dates[@assignment2.id][@student3.id][:grading_period_id]
          expect(submission_grading_period_id).to eq grading_period.id
        end

        it 'ignores soft-deleted grading period groups' do
          Factories::GradingPeriodHelper.new.create_for_group(@gp_group, {
            start_date: 20.days.ago(@now),
            end_date: 15.days.ago(@now),
            close_date: 10.days.ago(@now)
          })
          @gp_group.destroy!
          @assignment2.due_at = 17.days.ago(@now)
          @assignment2.only_visible_to_overrides = false
          @assignment2.save!

          edd = EffectiveDueDates.for_course(@test_course, @assignment2)
          result = edd.to_hash
          expected = {
            @assignment2.id => {
              @student1.id => {
                due_at: 17.days.ago(@now),
                grading_period_id: nil,
                in_closed_grading_period: false,
                override_id: nil,
                override_source: 'Everyone Else'
              },
              @student2.id => {
                due_at: 17.days.ago(@now),
                grading_period_id: nil,
                in_closed_grading_period: false,
                override_id: nil,
                override_source: 'Everyone Else'
              },
              @student3.id => {
                due_at: 17.days.ago(@now),
                grading_period_id: nil,
                in_closed_grading_period: false,
                override_id: nil,
                override_source: 'Everyone Else'
              }
            }
          }
          expect(result).to eq expected
        end

        it 'ignores soft-deleted grading periods' do
          gp = Factories::GradingPeriodHelper.new.create_for_group(@gp_group, {
            start_date: 20.days.ago(@now),
            end_date: 15.days.ago(@now),
            close_date: 10.days.ago(@now)
          })
          gp.destroy!
          @assignment2.due_at = 17.days.ago(@now)
          @assignment2.only_visible_to_overrides = false
          @assignment2.save!

          edd = EffectiveDueDates.for_course(@test_course, @assignment2)
          result = edd.to_hash
          expected = {
            @assignment2.id => {
              @student1.id => {
                due_at: 17.days.ago(@now),
                grading_period_id: nil,
                in_closed_grading_period: false,
                override_id: nil,
                override_source: 'Everyone Else'
              },
              @student2.id => {
                due_at: 17.days.ago(@now),
                grading_period_id: nil,
                in_closed_grading_period: false,
                override_id: nil,
                override_source: 'Everyone Else'
              },
              @student3.id => {
                due_at: 17.days.ago(@now),
                grading_period_id: nil,
                in_closed_grading_period: false,
                override_id: nil,
                override_source: 'Everyone Else'
              }
            }
          }
          expect(result).to eq expected
        end

        describe 'in_closed_grading_period attribute' do
          it 'is true if the associated grading period is closed' do
            gp = Factories::GradingPeriodHelper.new.create_for_group(@gp_group, {
              start_date: 20.days.ago(@now),
              end_date: 15.days.ago(@now),
              close_date: 10.days.ago(@now)
            })
            @assignment2.due_at = 17.days.ago(@now)
            @assignment2.only_visible_to_overrides = false
            @assignment2.save!

            edd = EffectiveDueDates.for_course(@test_course, @assignment2)
            result = edd.to_hash
            expected = {
              @assignment2.id => {
                @student1.id => {
                  due_at: 17.days.ago(@now),
                  grading_period_id: gp.id,
                  in_closed_grading_period: true,
                  override_id: nil,
                  override_source: 'Everyone Else'
                },
                @student2.id => {
                  due_at: 17.days.ago(@now),
                  grading_period_id: gp.id,
                  in_closed_grading_period: true,
                  override_id: nil,
                  override_source: 'Everyone Else'
                },
                @student3.id => {
                  due_at: 17.days.ago(@now),
                  grading_period_id: gp.id,
                  in_closed_grading_period: true,
                  override_id: nil,
                  override_source: 'Everyone Else'
                }
              }
            }
            expect(result).to eq expected
          end

          it 'is false if the associated grading period is open' do
            gp = Factories::GradingPeriodHelper.new.create_for_group(@gp_group, {
              start_date: 20.days.ago(@now),
              end_date: 15.days.ago(@now),
              close_date: 4.days.from_now(@now)
            })
            @assignment2.due_at = 17.days.ago(@now)
            @assignment2.only_visible_to_overrides = false
            @assignment2.save!

            edd = EffectiveDueDates.for_course(@test_course, @assignment2)
            result = edd.to_hash
            expected = {
              @assignment2.id => {
                @student1.id => {
                  due_at: 17.days.ago(@now),
                  grading_period_id: gp.id,
                  in_closed_grading_period: false,
                  override_id: nil,
                  override_source: 'Everyone Else'
                },
                @student2.id => {
                  due_at: 17.days.ago(@now),
                  grading_period_id: gp.id,
                  in_closed_grading_period: false,
                  override_id: nil,
                  override_source: 'Everyone Else'
                },
                @student3.id => {
                  due_at: 17.days.ago(@now),
                  grading_period_id: gp.id,
                  in_closed_grading_period: false,
                  override_id: nil,
                  override_source: 'Everyone Else'
                }
              }
            }
            expect(result).to eq expected
          end

          it 'is false if the due date does not fall in a grading period' do
            Factories::GradingPeriodHelper.new.create_for_group(@gp_group, {
              start_date: 20.days.ago(@now),
              end_date: 15.days.ago(@now),
              close_date: 10.days.ago(@now)
            })
            @assignment2.due_at = 12.days.ago(@now)
            @assignment2.only_visible_to_overrides = false
            @assignment2.save!

            edd = EffectiveDueDates.for_course(@test_course, @assignment2)
            result = edd.to_hash
            expected = {
              @assignment2.id => {
                @student1.id => {
                  due_at: 12.days.ago(@now),
                  grading_period_id: nil,
                  in_closed_grading_period: false,
                  override_id: nil,
                  override_source: 'Everyone Else'
                },
                @student2.id => {
                  due_at: 12.days.ago(@now),
                  grading_period_id: nil,
                  in_closed_grading_period: false,
                  override_id: nil,
                  override_source: 'Everyone Else'
                },
                @student3.id => {
                  due_at: 12.days.ago(@now),
                  grading_period_id: nil,
                  in_closed_grading_period: false,
                  override_id: nil,
                  override_source: 'Everyone Else'
                }
              }
            }
            expect(result).to eq expected
          end

          it 'is true if the due date is null and the last grading period is closed' do
            Factories::GradingPeriodHelper.new.create_for_group(@gp_group, {
              start_date: 50.days.ago(@now),
              end_date: 35.days.ago(@now),
              close_date: 30.days.from_now(@now)
            })
            gp = Factories::GradingPeriodHelper.new.create_for_group(@gp_group, {
              start_date: 20.days.ago(@now),
              end_date: 15.days.ago(@now),
              close_date: 10.days.ago(@now)
            })
            @assignment2.due_at = nil
            @assignment2.only_visible_to_overrides = false
            @assignment2.save!

            edd = EffectiveDueDates.for_course(@test_course, @assignment2)
            result = edd.to_hash
            expected = {
              @assignment2.id => {
                @student1.id => {
                  due_at: nil,
                  grading_period_id: gp.id,
                  in_closed_grading_period: true,
                  override_id: nil,
                  override_source: 'Everyone Else'
                },
                @student2.id => {
                  due_at: nil,
                  grading_period_id: gp.id,
                  in_closed_grading_period: true,
                  override_id: nil,
                  override_source: 'Everyone Else'
                },
                @student3.id => {
                  due_at: nil,
                  grading_period_id: gp.id,
                  in_closed_grading_period: true,
                  override_id: nil,
                  override_source: 'Everyone Else'
                }
              }
            }
            expect(result).to eq expected
          end

          it 'is false if the due date is null and the last grading period is open' do
            Factories::GradingPeriodHelper.new.create_for_group(@gp_group, {
              start_date: 50.days.ago(@now),
              end_date: 35.days.ago(@now),
              close_date: 30.days.ago(@now)
            })
            gp = Factories::GradingPeriodHelper.new.create_for_group(@gp_group, {
              start_date: 20.days.ago(@now),
              end_date: 15.days.ago(@now),
              close_date: 10.days.from_now(@now)
            })
            @assignment2.due_at = nil
            @assignment2.only_visible_to_overrides = false
            @assignment2.save!

            edd = EffectiveDueDates.for_course(@test_course, @assignment2)
            result = edd.to_hash
            expected = {
              @assignment2.id => {
                @student1.id => {
                  due_at: nil,
                  grading_period_id: gp.id,
                  in_closed_grading_period: false,
                  override_id: nil,
                  override_source: 'Everyone Else'
                },
                @student2.id => {
                  due_at: nil,
                  grading_period_id: gp.id,
                  in_closed_grading_period: false,
                  override_id: nil,
                  override_source: 'Everyone Else'
                },
                @student3.id => {
                  due_at: nil,
                  grading_period_id: gp.id,
                  in_closed_grading_period: false,
                  override_id: nil,
                  override_source: 'Everyone Else'
                }
              }
            }
            expect(result).to eq expected
          end
        end
      end
    end
  end

  context 'grading periods' do
    before(:once) do
      @now = Time.zone.now.change(sec: 0)
      @test_course = Course.create!
      @student1 = student_in_course(course: @test_course, active_all: true).user
      @student2 = student_in_course(course: @test_course, active_all: true).user
      @gp_group = Factories::GradingPeriodGroupHelper.new.create_for_account(@test_course.account)
      @gp_group.enrollment_terms << @test_course.enrollment_term
      @grading_period = Factories::GradingPeriodHelper.new.create_for_group(
        @gp_group,
        start_date: 20.days.ago(@now),
        end_date: 15.days.ago(@now),
        close_date: 10.days.ago(@now)
      )
      @assignment1 = @test_course.assignments.create!(due_at: 2.weeks.from_now(@now))
      @assignment2 = @test_course.assignments.create!
    end

    describe '#any_in_closed_grading_period?' do
      it 'returns false if there are no grading periods' do
        @assignment2.due_at = 17.days.ago(@now)
        @assignment2.only_visible_to_overrides = false
        @assignment2.save!

        expect(@test_course).to receive(:grading_periods?).and_return false
        edd = EffectiveDueDates.for_course(@test_course)
        expect(edd).to receive(:to_hash).never
        expect(edd.any_in_closed_grading_period?).to eq(false)
      end

      context 'with grading periods' do
        it 'returns true if any students in any assignments have a due date in a closed grading period' do
          @assignment2.due_at = 1.day.ago(@now)
          @assignment2.only_visible_to_overrides = false
          @assignment2.save!
          override = @assignment2.assignment_overrides.create!(due_at: 19.days.ago(@now), due_at_overridden: true)
          override.assignment_override_students.create!(user: @student2)

          edd = EffectiveDueDates.for_course(@test_course)
          expect(edd.any_in_closed_grading_period?).to eq(true)
        end

        it 'returns false if no student in any assignments has a due date in a closed grading period' do
          @assignment2.due_at = 1.day.ago(@now)
          @assignment2.only_visible_to_overrides = false
          @assignment2.save!
          override = @assignment2.assignment_overrides.create!(due_at: 2.days.ago(@now), due_at_overridden: true)
          override.assignment_override_students.create!(user: @student2)

          edd = EffectiveDueDates.for_course(@test_course)
          expect(edd.any_in_closed_grading_period?).to eq(false)
        end

        it 'memoizes the result' do
          edd = EffectiveDueDates.for_course(@test_course)
          expect(edd).to receive(:to_hash).once.and_return({})
          2.times { edd.any_in_closed_grading_period? }
        end
      end
    end

    describe '#grading_period_id_for' do
      it 'returns the grading_period_id for the given student and assignment' do
        @assignment1.update!(due_at: 2.days.from_now(@grading_period.start_date))
        effective_due_dates = EffectiveDueDates.new(@test_course, @assignment1.id)
        grading_period_id = effective_due_dates.grading_period_id_for(
          student_id: @student1.id,
          assignment_id: @assignment1.id
        )
        expect(grading_period_id).to eq(@grading_period.id)
      end

      it 'returns nil if there if the given student and assignment do not fall in a grading period' do
        effective_due_dates = EffectiveDueDates.new(@test_course, @assignment1.id)
        grading_period_id = effective_due_dates.grading_period_id_for(
          student_id: @student1.id,
          assignment_id: @assignment1.id
        )
        expect(grading_period_id).to be_nil
      end

      it 'returns nil if the assignment is not assigned to the student' do
        @assignment1.update!(
          due_at: 2.days.from_now(@grading_period.start_date),
          only_visible_to_overrides: true
        )
        effective_due_dates = EffectiveDueDates.new(@test_course, @assignment1.id)
        grading_period_id = effective_due_dates.grading_period_id_for(
          student_id: @student1.id,
          assignment_id: @assignment1.id
        )
        expect(grading_period_id).to be_nil
      end
    end

    describe '#in_closed_grading_period?' do
      it 'returns false if there are no grading periods' do
        @assignment2.due_at = 17.days.ago(@now)
        @assignment2.only_visible_to_overrides = false
        @assignment2.save!

        expect(@test_course).to receive(:grading_periods?).and_return false
        edd = EffectiveDueDates.for_course(@test_course)
        expect(edd).to receive(:to_hash).never
        expect(edd.in_closed_grading_period?(@assignment2)).to eq(false)
      end

      it 'returns false if assignment id is nil' do
        edd = EffectiveDueDates.for_course(@test_course, @assignment1)
        expect(edd).to receive(:to_hash).never
        expect(edd.in_closed_grading_period?(nil)).to eq(false)
      end

      context 'with grading periods' do
        before do
          @assignment2.due_at = 1.day.ago(@now)
          @assignment2.only_visible_to_overrides = false
          @assignment2.save!
          override = @assignment2.assignment_overrides.create!(due_at: 19.days.ago(@now), due_at_overridden: true)
          override.assignment_override_students.create!(user: @student2)

          @edd = EffectiveDueDates.for_course(@test_course)
        end

        it 'returns true if any students in the given assignment have a due date in a closed grading period' do
          expect(@edd.in_closed_grading_period?(@assignment2)).to eq(true)
        end

        it 'accepts assignment id as the argument' do
          expect(@edd.in_closed_grading_period?(@assignment2.id)).to eq(true)
        end

        it 'returns false if no student in the given assignment has a due date in a closed grading period' do
          expect(@edd.in_closed_grading_period?(@assignment1)).to eq(false)
        end

        it 'returns true if the specified student has a due date for this assignment' do
          expect(@edd.in_closed_grading_period?(@assignment2, @student2)).to be true
          expect(@edd.in_closed_grading_period?(@assignment2, @student2.id)).to be true
        end

        it 'raises error if the specified student was filtered out of the query' do
          expect { @edd.filter_students_to(@student1).in_closed_grading_period?(@assignment2, @student2) }.
            to raise_error("Student #{@student2.id} was not included in this query")
        end

        it 'returns true if the specified student was included in the query and has a due date for this assignment' do
          expect(@edd.filter_students_to(@student2).in_closed_grading_period?(@assignment2, @student2)).to be true
        end

        it 'returns false if the specified student has a due date in an open grading period' do
          override = @assignment2.assignment_overrides.create!(due_at: 1.day.from_now(@now), due_at_overridden: true)
          override.assignment_override_students.create!(user: @student1)

          expect(@edd.in_closed_grading_period?(@assignment2, @student1)).to be false
          expect(@edd.in_closed_grading_period?(@assignment2, @student1.id)).to be false
        end

        it 'returns false if the specified student does not have a due date for this assignment' do
          @other_course = Course.create!
          @student_in_other_course = student_in_course(course: @other_course, active_all: true).user

          expect(@edd.in_closed_grading_period?(@assignment2, @student_in_other_course)).to be false
          expect(@edd.in_closed_grading_period?(@assignment2, @student_in_other_course.id)).to be false
        end
      end
    end
  end
end
