require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe Course do
  before(:once) do
    @test_course = Course.create!
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

  describe '#to_hash' do
    before(:once) do
      @now = Time.zone.now
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

    it 'maps id if the assignments are already loaded' do
      args = @test_course.active_assignments.to_a
      Assignment.any_instance.expects(:id).times(3).returns(1)
      edd = EffectiveDueDates.for_course(@test_course, args)
      edd.to_hash
    end

    it 'uses sql if the assignments are still a relation' do
      args = @test_course.active_assignments
      Assignment.any_instance.expects(:id).never
      edd = EffectiveDueDates.for_course(@test_course, args)
      edd.to_hash
    end

    it 'memoizes the result' do
      args = @test_course.active_assignments.to_a
      Assignment.any_instance.expects(:id).times(3).returns(1)
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

    it 'ignores enrollments that are not active' do
      @student1_enrollment.deactivate
      edd = EffectiveDueDates.for_course(@test_course, @assignment1)
      result = edd.to_hash
      student_ids = result[@assignment1.id].keys
      expect(student_ids).not_to include @student1.id
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
        @now = Time.zone.now
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

      it 'ignores overrides without due_at_overridden' do
        override = @assignment1.assignment_overrides.create!(due_at: nil)
        override.assignment_override_students.create!(user: @student3)

        edd = EffectiveDueDates.for_course(@test_course, @assignment1)
        expect(edd.to_hash).to eq({})
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

      it 'includes not-assigned students with existing graded submissions' do
        @assignment1.submissions.create!(user: @student1, submission_type: 'online_text_entry', workflow_state: 'graded')

        edd = EffectiveDueDates.for_course(@test_course, @assignment1)
        result = edd.to_hash
        expected = {
          @assignment1.id => {
            @student1.id => {
              due_at: nil,
              grading_period_id: nil,
              in_closed_grading_period: false,
              override_id: nil,
              override_source: 'Submission'
            }
          }
        }
        expect(result).to eq expected
      end

      it 'uses assigned date instead of submission date even if submission was late' do
        override = @assignment1.assignment_overrides.create!(due_at: 3.days.from_now(@now), due_at_overridden: true)
        override.assignment_override_students.create!(user: @student1)
        @assignment1.submissions.create!(
          user: @student1,
          submitted_at: 1.week.from_now(@now),
          submission_type: 'online_text_entry',
          workflow_state: 'graded'
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
        @assignment2.submissions.create!(
          user: @student1,
          submitted_at: 1.week.from_now(@now),
          submission_type: 'online_text_entry',
          workflow_state: 'graded'
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
        @assignment2.submissions.create!(
          user: @student1,
          submitted_at: 1.week.from_now(@now),
          submission_type: 'online_text_entry',
          workflow_state: 'graded'
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
        @assignment1.submissions.create!(user: @student1, submission_type: 'online_text_entry', workflow_state: 'submitted')

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

      context 'with multiple grading periods' do
        before(:once) do
          @test_course.enable_feature! :multiple_grading_periods
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

          it 'is false if the due date is only due to a graded submission even if the last grading period is closed' do
            Factories::GradingPeriodHelper.new.create_for_group(@gp_group, {
              start_date: 50.days.ago(@now),
              end_date: 35.days.ago(@now),
              close_date: 30.days.from_now(@now)
            })
            Factories::GradingPeriodHelper.new.create_for_group(@gp_group, {
              start_date: 20.days.ago(@now),
              end_date: 15.days.ago(@now),
              close_date: 10.days.ago(@now)
            })
            @assignment1.submissions.create!(
              user: @student1,
              submitted_at: 1.week.from_now(@now),
              submission_type: 'online_text_entry',
              workflow_state: 'graded'
            )

            edd = EffectiveDueDates.for_course(@test_course, @assignment1)
            result = edd.to_hash
            expected = {
              @assignment1.id => {
                @student1.id => {
                  due_at: nil,
                  grading_period_id: nil,
                  in_closed_grading_period: false,
                  override_id: nil,
                  override_source: 'Submission'
                }
              }
            }
            expect(result).to eq expected
          end
        end
      end
    end
  end

  describe '#any_in_closed_grading_period?' do
    before(:once) do
      @now = Time.zone.now
      @test_course = Course.create!
      @student1 = student_in_course(course: @test_course, active_all: true).user
      @student2 = student_in_course(course: @test_course, active_all: true).user
      @assignment1 = @test_course.assignments.create!(due_at: 2.weeks.from_now(@now))
      @assignment2 = @test_course.assignments.create!
      @gp_group = Factories::GradingPeriodGroupHelper.new.create_for_account(@test_course.account)
      @gp_group.enrollment_terms << @test_course.enrollment_term
    end

    it 'returns false if multiple grading periods is disabled' do
      Factories::GradingPeriodHelper.new.create_for_group(@gp_group, {
        start_date: 20.days.ago(@now),
        end_date: 15.days.ago(@now),
        close_date: 10.days.ago(@now)
      })
      @assignment2.due_at = 17.days.ago(@now)
      @assignment2.only_visible_to_overrides = false
      @assignment2.save!

      @test_course.disable_feature! :multiple_grading_periods
      edd = EffectiveDueDates.for_course(@test_course)
      edd.expects(:to_hash).never
      expect(edd.any_in_closed_grading_period?).to eq(false)
    end

    context 'with multiple grading periods' do
      before(:once) do
        @test_course.enable_feature! :multiple_grading_periods
      end

      it 'returns true if any students in any assignments have a due date in a closed grading period' do
        Factories::GradingPeriodHelper.new.create_for_group(@gp_group, {
          start_date: 20.days.ago(@now),
          end_date: 15.days.ago(@now),
          close_date: 10.days.ago(@now)
        })
        @assignment2.due_at = 1.day.ago(@now)
        @assignment2.only_visible_to_overrides = false
        @assignment2.save!
        override = @assignment2.assignment_overrides.create!(due_at: 19.days.ago(@now), due_at_overridden: true)
        override.assignment_override_students.create!(user: @student2)

        edd = EffectiveDueDates.for_course(@test_course)
        expect(edd.any_in_closed_grading_period?).to eq(true)
      end

      it 'returns false if no student in any assignments has a due date in a closed grading period' do
        Factories::GradingPeriodHelper.new.create_for_group(@gp_group, {
          start_date: 20.days.ago(@now),
          end_date: 15.days.ago(@now),
          close_date: 10.days.ago(@now)
        })
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
        edd.expects(:to_hash).once.returns({})
        2.times { edd.any_in_closed_grading_period? }
      end
    end
  end

  describe '#in_closed_grading_period?' do
    before(:once) do
      @now = Time.zone.now
      @test_course = Course.create!
      @student1 = student_in_course(course: @test_course, active_all: true).user
      @student2 = student_in_course(course: @test_course, active_all: true).user
      @assignment1 = @test_course.assignments.create!(due_at: 2.weeks.from_now(@now))
      @assignment2 = @test_course.assignments.create!
      @gp_group = Factories::GradingPeriodGroupHelper.new.create_for_account(@test_course.account)
      @gp_group.enrollment_terms << @test_course.enrollment_term
    end

    it 'returns false if multiple grading periods is disabled' do
      Factories::GradingPeriodHelper.new.create_for_group(@gp_group, {
        start_date: 20.days.ago(@now),
        end_date: 15.days.ago(@now),
        close_date: 10.days.ago(@now)
      })
      @assignment2.due_at = 17.days.ago(@now)
      @assignment2.only_visible_to_overrides = false
      @assignment2.save!

      @test_course.disable_feature! :multiple_grading_periods
      edd = EffectiveDueDates.for_course(@test_course)
      edd.expects(:to_hash).never
      expect(edd.in_closed_grading_period?(@assignment2)).to eq(false)
    end

    it 'returns false if assignment id is nil' do
      edd = EffectiveDueDates.for_course(@test_course, @assignment1)
      edd.expects(:to_hash).never
      expect(edd.in_closed_grading_period?(nil)).to eq(false)
    end

    context 'with multiple grading periods' do
      before(:once) do
        @test_course.enable_feature! :multiple_grading_periods
      end

      before(:each) do
        Factories::GradingPeriodHelper.new.create_for_group(@gp_group, {
          start_date: 20.days.ago(@now),
          end_date: 15.days.ago(@now),
          close_date: 10.days.ago(@now)
        })
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

      it 'returns false if the specified student has a due date in an open grading period' do
        override = @assignment2.assignment_overrides.create!(due_at: 1.day.from_now(@now), due_at_overridden: true)
        override.assignment_override_students.create!(user: @student1)

        expect(@edd.in_closed_grading_period?(@assignment2, @student1)).to be_falsey
        expect(@edd.in_closed_grading_period?(@assignment2, @student1.id)).to be_falsey
      end
    end
  end
end
