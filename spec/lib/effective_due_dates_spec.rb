# frozen_string_literal: true

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

describe Course do
  before(:once) do
    @test_course = Course.create!
    course_with_teacher(course: @test_course, active_all: true)
    @teacher = @user
  end

  describe "for_course" do
    it "raises error if context is not a course" do
      expect { EffectiveDueDates.for_course({}) }.to raise_error("Context must be a course")
    end

    it "raises error if context has no id" do
      expect { EffectiveDueDates.for_course(Course.new) }.to raise_error("Context must have an id")
    end

    it "saves context" do
      edd = EffectiveDueDates.for_course(@test_course)
      expect(edd.context).to eq(@test_course)
    end
  end

  describe "#filter_students_to" do
    let(:edd) { EffectiveDueDates.for_course(@test_course) }

    it "defaults to no filtered students" do
      expect(edd.filtered_students).to be_nil
    end

    it "saves an array of students" do
      user1, user2 = User.create, User.create
      edd.filter_students_to([user1, user2])
      expect(edd.filtered_students).to eq [user1.id, user2.id]
    end

    it "saves a list of students" do
      user1, user2 = User.create, User.create
      edd.filter_students_to(user1, user2)
      expect(edd.filtered_students).to eq [user1.id, user2.id]
    end

    it "saves a list of student ids" do
      edd.filter_students_to(15, 20, 2)
      expect(edd.filtered_students).to eq [15, 20, 2]
    end

    it "does nothing if no students are passed" do
      edd.filter_students_to
      expect(edd.filtered_students).to be_nil
    end

    it "allows chaining" do
      expect(edd.filter_students_to(5)).to eq edd
    end
  end

  describe "#to_hash" do
    before(:once) do
      @now = Time.zone.now.change(sec: 0)
      @student1_enrollment = student_in_course(course: @test_course, active_all: true, name: "Student 1")
      @student1 = @student1_enrollment.user
      @student2 = student_in_course(course: @test_course, active_all: true, name: "Student 2").user
      @student3 = student_in_course(course: @test_course, active_all: true, name: "Student 3").user
      @other_course = Course.create!
      @student_in_other_course = student_in_course(course: @other_course, active_all: true, name: "Student in other course").user
      @assignment1 = @test_course.assignments.create!(due_at: 2.weeks.from_now(@now))
      @assignment2 = @test_course.assignments.create!
      @assignment3 = @test_course.assignments.create!
      @deleted_assignment = @test_course.assignments.create!
      @deleted_assignment.destroy
      @assignment_in_other_course = @other_course.assignments.create!
    end

    context "sharding" do
      specs_require_sharding

      before do
        @shard1.activate do
          account = Account.create!
          course_with_student(account:, active_all: true)
          assignment_model(course: @course)
        end
      end

      it "handles being passed global assignment IDs" do
        @shard1.activate do
          edd = EffectiveDueDates.for_course(@course, @assignment.global_id)
          expect(edd.to_hash[@assignment.id]).to have_key @student.id
        end
      end

      it "handles being passed local assignment IDs" do
        @shard1.activate do
          edd = EffectiveDueDates.for_course(@course, @assignment.id)
          expect(edd.to_hash[@assignment.id]).to have_key @student.id
        end
      end
    end

    it "properly converts timezones" do
      Time.zone = "Alaska"
      default_due = Time.zone.parse("01 Jan 2011 14:00 AKST")
      @assignment4 = @test_course.assignments.create!(title: "some assignment", due_at: default_due, submission_types: ["online_text_entry"])

      edd = EffectiveDueDates.for_course(@test_course, @assignment4)
      result = edd.to_hash
      expect(result[@assignment4.id][@student1.id][:due_at]).to eq default_due
    end

    it "returns the effective due dates per assignment per student" do
      edd = EffectiveDueDates.for_course(@test_course)
      result = edd.to_hash
      expected = {
        @assignment1.id => {
          @student1.id => {
            due_at: 2.weeks.from_now(@now),
            grading_period_id: nil,
            in_closed_grading_period: false,
            override_id: nil,
            override_source: "Everyone Else"
          },
          @student2.id => {
            due_at: 2.weeks.from_now(@now),
            grading_period_id: nil,
            in_closed_grading_period: false,
            override_id: nil,
            override_source: "Everyone Else"
          },
          @student3.id => {
            due_at: 2.weeks.from_now(@now),
            grading_period_id: nil,
            in_closed_grading_period: false,
            override_id: nil,
            override_source: "Everyone Else"
          }
        },
        @assignment2.id => {
          @student1.id => {
            due_at: nil,
            grading_period_id: nil,
            in_closed_grading_period: false,
            override_id: nil,
            override_source: "Everyone Else"
          },
          @student2.id => {
            due_at: nil,
            grading_period_id: nil,
            in_closed_grading_period: false,
            override_id: nil,
            override_source: "Everyone Else"
          },
          @student3.id => {
            due_at: nil,
            grading_period_id: nil,
            in_closed_grading_period: false,
            override_id: nil,
            override_source: "Everyone Else"
          }
        },
        @assignment3.id => {
          @student1.id => {
            due_at: nil,
            grading_period_id: nil,
            in_closed_grading_period: false,
            override_id: nil,
            override_source: "Everyone Else"
          },
          @student2.id => {
            due_at: nil,
            grading_period_id: nil,
            in_closed_grading_period: false,
            override_id: nil,
            override_source: "Everyone Else"
          },
          @student3.id => {
            due_at: nil,
            grading_period_id: nil,
            in_closed_grading_period: false,
            override_id: nil,
            override_source: "Everyone Else"
          }
        }
      }
      expect(result).to eq expected
    end

    it "returns the effective due dates per assignment for select students when filtered" do
      edd = EffectiveDueDates.for_course(@test_course).filter_students_to(@student1, @student3)
      result = edd.to_hash
      expected = {
        @assignment1.id => {
          @student1.id => {
            due_at: 2.weeks.from_now(@now),
            grading_period_id: nil,
            in_closed_grading_period: false,
            override_id: nil,
            override_source: "Everyone Else"
          },
          @student3.id => {
            due_at: 2.weeks.from_now(@now),
            grading_period_id: nil,
            in_closed_grading_period: false,
            override_id: nil,
            override_source: "Everyone Else"
          }
        },
        @assignment2.id => {
          @student1.id => {
            due_at: nil,
            grading_period_id: nil,
            in_closed_grading_period: false,
            override_id: nil,
            override_source: "Everyone Else"
          },
          @student3.id => {
            due_at: nil,
            grading_period_id: nil,
            in_closed_grading_period: false,
            override_id: nil,
            override_source: "Everyone Else"
          }
        },
        @assignment3.id => {
          @student1.id => {
            due_at: nil,
            grading_period_id: nil,
            in_closed_grading_period: false,
            override_id: nil,
            override_source: "Everyone Else"
          },
          @student3.id => {
            due_at: nil,
            grading_period_id: nil,
            in_closed_grading_period: false,
            override_id: nil,
            override_source: "Everyone Else"
          }
        }
      }
      expect(result).to eq expected
    end

    it "maps id if the assignments are already loaded" do
      args = @test_course.active_assignments.to_a
      expect(args[0]).to receive(:id).once
      expect(args[1]).to receive(:id).once
      expect(args[2]).to receive(:id).once
      edd = EffectiveDueDates.for_course(@test_course, args)
      edd.to_hash
    end

    it "uses sql if the assignments are still a relation" do
      args = @test_course.active_assignments
      expect_any_instance_of(Assignment).not_to receive(:id)
      edd = EffectiveDueDates.for_course(@test_course, args)
      edd.to_hash
    end

    it "memoizes the result" do
      args = @test_course.active_assignments.to_a
      expect(args[0]).to receive(:id).once
      expect(args[1]).to receive(:id).once
      expect(args[2]).to receive(:id).once
      edd = EffectiveDueDates.for_course(@test_course, args)
      2.times { edd.to_hash }
    end

    it "can be passed a list of keys to only return those attributes" do
      due_dates = EffectiveDueDates.for_course(@test_course)
      due_dates_hash = due_dates.to_hash([:due_at, :override_source])
      attributes_returned = due_dates_hash[@assignment1.id][@student1.id].keys
      expect(attributes_returned).to contain_exactly(:due_at, :override_source)
    end

    describe "initializes with" do
      it "no arguments and defaults to all active course assignments" do
        edd = EffectiveDueDates.for_course(@test_course)
        result = edd.to_hash
        expect(result.keys).to contain_exactly(@assignment1.id, @assignment2.id, @assignment3.id)
      end

      it "a list of ActiveRecord Assignment models" do
        edd = EffectiveDueDates.for_course(@test_course, @assignment1, @assignment3)
        result = edd.to_hash
        expect(result.keys).to contain_exactly(@assignment3.id, @assignment1.id)
      end

      it "an array of ActiveRecord Assignment models" do
        edd = EffectiveDueDates.for_course(@test_course, [@assignment1, @assignment3])
        result = edd.to_hash
        expect(result.keys).to contain_exactly(@assignment3.id, @assignment1.id)
      end

      it "a list of ids" do
        edd = EffectiveDueDates.for_course(@test_course, @assignment1.id, @assignment3.id)
        result = edd.to_hash
        expect(result.keys).to contain_exactly(@assignment3.id, @assignment1.id)
      end

      it "an array of ids" do
        edd = EffectiveDueDates.for_course(@test_course, [@assignment1.id, @assignment3.id])
        result = edd.to_hash
        expect(result.keys).to contain_exactly(@assignment3.id, @assignment1.id)
      end

      it "a single ActiveRecord relation" do
        edd = EffectiveDueDates.for_course(@test_course, @test_course.assignments)
        result = edd.to_hash
        expect(result.keys).to contain_exactly(@assignment3.id, @assignment2.id, @assignment1.id)
      end

      it "nil" do
        edd = EffectiveDueDates.for_course(@test_course, nil)
        result = edd.to_hash
        expect(result).to be_empty
      end

      it "new Assignment objects that do not have an ID" do
        new_assignment = @test_course.assignments.build
        edd = EffectiveDueDates.for_course(@test_course, new_assignment)
        result = edd.to_hash
        expect(result).to be_empty
      end
    end

    it "ignores students who are not in the course" do
      edd = EffectiveDueDates.for_course(@test_course, @assignment1)
      result = edd.to_hash
      student_ids = result[@assignment1.id].keys
      expect(student_ids).not_to include @student_in_other_course.id
    end

    it "ignores assignments that are not in this course" do
      edd = EffectiveDueDates.for_course(@test_course, @assignment_in_other_course)
      result = edd.to_hash
      expect(result).to be_empty
    end

    it "ignores assignments that are soft-deleted" do
      edd = EffectiveDueDates.for_course(@test_course, @deleted_assignment)
      result = edd.to_hash
      expect(result).to be_empty
    end

    it "ignores enrollments that rejected the course invitation" do
      @student1_enrollment.reject
      edd = EffectiveDueDates.for_course(@test_course, @assignment1)
      student_ids = edd.to_hash[@assignment1.id].keys
      expect(student_ids).not_to include @student1.id
    end

    it "includes deactivated enrollments" do
      @student1_enrollment.deactivate
      edd = EffectiveDueDates.for_course(@test_course, @assignment1)
      student_ids = edd.to_hash[@assignment1.id].keys
      expect(student_ids).to include @student1.id
    end

    it "includes concluded enrollments" do
      @student1_enrollment.conclude
      edd = EffectiveDueDates.for_course(@test_course, @assignment1)
      student_ids = edd.to_hash[@assignment1.id].keys
      expect(student_ids).to include @student1.id
    end

    it "ignores enrollments that are not students" do
      @student1_enrollment.type = "TeacherEnrollment"
      @student1_enrollment.save!
      edd = EffectiveDueDates.for_course(@test_course, @assignment1)
      result = edd.to_hash
      student_ids = result[@assignment1.id].keys
      expect(student_ids).not_to include @student1.id
    end

    it "ignores soft deleted students" do
      @student1_enrollment.destroy
      edd = EffectiveDueDates.for_course(@test_course, @assignment1)
      result = edd.to_hash
      student_ids = result[@assignment1.id].keys
      expect(student_ids).not_to include @student1.id
    end

    it "includes everyone else if there no modules and no overrides" do
      edd = EffectiveDueDates.for_course(@test_course, @assignment1)
      result = edd.to_hash
      expected = {
        @assignment1.id => {
          @student1.id => {
            due_at: @assignment1.due_at,
            grading_period_id: nil,
            in_closed_grading_period: false,
            override_id: nil,
            override_source: "Everyone Else"
          },
          @student2.id => {
            due_at: @assignment1.due_at,
            grading_period_id: nil,
            in_closed_grading_period: false,
            override_id: nil,
            override_source: "Everyone Else"
          },
          @student3.id => {
            due_at: @assignment1.due_at,
            grading_period_id: nil,
            in_closed_grading_period: false,
            override_id: nil,
            override_source: "Everyone Else"
          }
        }
      }
      expect(result).to eq expected
    end

    it "does not include student with unassign_item ADHOC override" do
      override = @assignment1.assignment_overrides.create!(due_at: 3.days.from_now(@now), due_at_overridden: true)
      override.assignment_override_students.create!(user: @student1)

      override.unassign_item = true
      override.save!

      edd = EffectiveDueDates.for_course(@test_course, @assignment1)
      result = edd.to_hash
      expected = {
        @assignment1.id => {
          @student2.id => {
            due_at: @assignment1.due_at,
            grading_period_id: nil,
            in_closed_grading_period: false,
            override_id: nil,
            override_source: "Everyone Else"
          },
          @student3.id => {
            due_at: @assignment1.due_at,
            grading_period_id: nil,
            in_closed_grading_period: false,
            override_id: nil,
            override_source: "Everyone Else"
          }
        }
      }
      expect(result).to eq expected
    end

    context "when only visible to overrides" do
      before(:once) do
        @assignment1.only_visible_to_overrides = true
        @assignment1.save!
      end

      context "when adhoc (student) overrides apply" do
        it "ignores inactive overrides" do
          override = @assignment1.assignment_overrides.create!(due_at: 5.days.from_now(@now), due_at_overridden: true)
          override.assignment_override_students.create!(user: @student2)
          override.destroy!

          edd = EffectiveDueDates.for_course(@test_course, @assignment1)
          expect(edd.to_hash).to eq({})
        end

        it "includes overrides with null due dates" do
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
                override_source: "ADHOC"
              }
            }
          }
          expect(result).to eq expected
        end

        it "includes overrides without due_at_overridden, and uses the due_at from the assignment" do
          override = @assignment1.assignment_overrides.create!(due_at: nil)
          override.assignment_override_students.create!(user: @student3)

          edd = EffectiveDueDates.for_course(@test_course, @assignment1)
          expect(edd.to_hash[@assignment1.id][@student3.id][:due_at]).to eq(@assignment1.due_at)
        end

        it "uses the due_at from the assignment when the assignment is only visible to overrides and no overrides for the student have due_at_overridden" do
          @assignment1.update!(due_at: @now)
          override = @assignment1.assignment_overrides.create!(due_at: 2.days.from_now(@now))
          override.assignment_override_students.create!(user: @student3)

          edd = EffectiveDueDates.for_course(@test_course, @assignment1)
          expect(edd.to_hash[@assignment1.id][@student3.id][:due_at]).to eq(@now)
        end

        it "uses the due_at from the assignment when the assignment is visible to everyone and no overrides for the student have due_at_overridden" do
          @assignment1.update!(only_visible_to_overrides: false, due_at: @now)
          override = @assignment1.assignment_overrides.create!(due_at: 2.days.from_now(@now))
          override.assignment_override_students.create!(user: @student3)

          edd = EffectiveDueDates.for_course(@test_course, @assignment1)
          expect(edd.to_hash[@assignment1.id][@student3.id][:due_at]).to eq(@now)
        end

        it "does not consider the due_at from overrides without due_at_overridden when the override due_at is nil" do
          override = @assignment1.assignment_overrides.create!(due_at: nil)
          override.assignment_override_students.create!(user: @student3)

          section = CourseSection.create!(name: "My Awesome Section", course: @test_course)
          student_in_section(section, user: @student3)
          @assignment1.assignment_overrides.create!(
            due_at: 1.day.from_now(@now),
            due_at_overridden: true,
            set: section
          )

          edd = EffectiveDueDates.for_course(@test_course, @assignment1)
          expect(edd.to_hash[@assignment1.id][@student3.id][:due_at]).to eq(1.day.from_now(@now))
        end

        it "does not consider the due_at from overrides without due_at_overridden even if the due date is more lenient than other dates" do
          override = @assignment1.assignment_overrides.create!(due_at: 2.days.from_now(@now))
          override.assignment_override_students.create!(user: @student3)

          section = CourseSection.create!(name: "My Awesome Section", course: @test_course)
          student_in_section(section, user: @student3)
          @assignment1.assignment_overrides.create!(
            due_at: 1.day.from_now(@now),
            due_at_overridden: true,
            set: section
          )

          edd = EffectiveDueDates.for_course(@test_course, @assignment1)
          expect(edd.to_hash[@assignment1.id][@student3.id][:due_at]).to eq(1.day.from_now(@now))
        end

        it "applies adhoc overrides" do
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
                override_source: "ADHOC"
              }
            }
          }
          expect(result).to eq expected
        end

        it "doesn't apply adhoc overrides with unassign_item but does apply section override" do
          override = @assignment1.assignment_overrides.create!(due_at: 3.days.from_now(@now), due_at_overridden: true)
          override.assignment_override_students.create!(user: @student1)

          section = CourseSection.create!(name: "My Awesome Section", course: @test_course)
          student_in_section(section, user: @student1)
          section_override = @assignment1.assignment_overrides.create!(
            due_at: 1.day.from_now(@now),
            due_at_overridden: true,
            set: section
          )

          override.unassign_item = true
          override.save!

          edd = EffectiveDueDates.for_course(@test_course, @assignment1)
          result = edd.to_hash
          expected = {
            @assignment1.id => {
              @student1.id => {
                due_at: 1.day.from_now(@now),
                grading_period_id: nil,
                in_closed_grading_period: false,
                override_id: section_override.id,
                override_source: "CourseSection"
              }
            }
          }
          expect(result).to eq expected
        end

        it "applies adhoc overrides with section unassign_item override" do
          override = @assignment1.assignment_overrides.create!(due_at: 3.days.from_now(@now), due_at_overridden: true)
          override.assignment_override_students.create!(user: @student1)

          section = CourseSection.create!(name: "My Awesome Section", course: @test_course)
          student_in_section(section, user: @student1)
          @assignment1.assignment_overrides.create!(
            due_at: 1.day.from_now(@now),
            due_at_overridden: true,
            set: section,
            unassign_item: true
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
                override_source: "ADHOC"
              }
            }
          }
          expect(result).to eq expected
        end

        context "with context module overrides" do
          before(:once) do
            @assignment1.only_visible_to_overrides = false
            @assignment1.save!
            @module = @test_course.context_modules.create!(name: "Module 1")
            @assignment1_tag = @assignment1.context_module_tags.create! context_module: @module, context: @test_course, tag_type: "context_module"

            @module_override = @module.assignment_overrides.create!
            @module_override.assignment_override_students.create!(user: @student1)
          end

          it "applies context module adhoc overrides" do
            @assignment2.only_visible_to_overrides = false
            @assignment2.save!
            @assignment2.context_module_tags.create! context_module: @module, context: @test_course, tag_type: "context_module"

            edd = EffectiveDueDates.for_course(@test_course, @assignment1, @assignment2)
            result = edd.to_hash
            expected = {
              @assignment1.id => {
                @student1.id => {
                  due_at: @assignment1.due_at,
                  grading_period_id: nil,
                  in_closed_grading_period: false,
                  override_id: @module_override.id,
                  override_source: "ADHOC"
                }
              },
              @assignment2.id => {
                @student1.id => {
                  due_at: @assignment2.due_at,
                  grading_period_id: nil,
                  in_closed_grading_period: false,
                  override_id: @module_override.id,
                  override_source: "ADHOC"
                }
              }
            }
            expect(result).to eq expected
          end

          it "correctly shows assignment not in a module with another assignment in a module" do
            @assignment2.only_visible_to_overrides = false
            @assignment2.save!

            edd = EffectiveDueDates.for_course(@test_course, @assignment1, @assignment2)
            result = edd.to_hash
            expected = {
              @assignment1.id => {
                @student1.id => {
                  due_at: @assignment1.due_at,
                  grading_period_id: nil,
                  in_closed_grading_period: false,
                  override_id: @module_override.id,
                  override_source: "ADHOC"
                }
              },
              @assignment2.id => {
                @student1.id => {
                  due_at: @assignment2.due_at,
                  grading_period_id: nil,
                  in_closed_grading_period: false,
                  override_id: nil,
                  override_source: "Everyone Else"
                },
                @student2.id => {
                  due_at: @assignment2.due_at,
                  grading_period_id: nil,
                  in_closed_grading_period: false,
                  override_id: nil,
                  override_source: "Everyone Else"
                },
                @student3.id => {
                  due_at: @assignment2.due_at,
                  grading_period_id: nil,
                  in_closed_grading_period: false,
                  override_id: nil,
                  override_source: "Everyone Else"
                }
              }
            }
            expect(result).to eq expected
          end

          it "correctly shows quiz not in a module with another assignment in a module" do
            @assignment2.only_visible_to_overrides = false
            @assignment2.save!
            @quiz = quiz_model(course: @test_course, assignment: @assignment2)

            edd = EffectiveDueDates.for_course(@test_course, @assignment1, @assignment2)
            result = edd.to_hash
            expected = {
              @assignment1.id => {
                @student1.id => {
                  due_at: @assignment1.due_at,
                  grading_period_id: nil,
                  in_closed_grading_period: false,
                  override_id: @module_override.id,
                  override_source: "ADHOC"
                }
              },
              @assignment2.id => {
                @student1.id => {
                  due_at: @assignment2.due_at,
                  grading_period_id: nil,
                  in_closed_grading_period: false,
                  override_id: nil,
                  override_source: "Everyone Else"
                },
                @student2.id => {
                  due_at: @assignment2.due_at,
                  grading_period_id: nil,
                  in_closed_grading_period: false,
                  override_id: nil,
                  override_source: "Everyone Else"
                },
                @student3.id => {
                  due_at: @assignment2.due_at,
                  grading_period_id: nil,
                  in_closed_grading_period: false,
                  override_id: nil,
                  override_source: "Everyone Else"
                }
              }
            }
            expect(result).to eq expected
          end

          it "applies unpublished context module adhoc overrides" do
            @module.workflow_state = "unpublished"
            @module.save!

            edd = EffectiveDueDates.for_course(@test_course, @assignment1)
            result = edd.to_hash
            expected = {
              @assignment1.id => {
                @student1.id => {
                  due_at: @assignment1.due_at,
                  grading_period_id: nil,
                  in_closed_grading_period: false,
                  override_id: @module_override.id,
                  override_source: "ADHOC"
                }
              }
            }
            expect(result).to eq expected
          end

          it "applies an assignment's quiz's context module overrides" do
            module2 = @test_course.context_modules.create!(name: "Module 2")
            module2_override = module2.assignment_overrides.create!
            module2_override.assignment_override_students.create!(user: @student1)

            @quiz = quiz_model(course: @test_course, assignment: @assignment2)
            @quiz.context_module_tags.create! context_module: module2, context: @test_course, tag_type: "context_module"

            edd = EffectiveDueDates.for_course(@test_course, @assignment2)
            result = edd.to_hash
            expected = {
              @assignment2.id => {
                @student1.id => {
                  due_at: @assignment2.due_at,
                  grading_period_id: nil,
                  in_closed_grading_period: false,
                  override_id: module2_override.id,
                  override_source: "ADHOC"
                }
              }
            }
            expect(result).to eq expected
          end

          it "applies an assignment's discussion topics's context module overrides" do
            module2 = @test_course.context_modules.create!(name: "Module 2")
            module2_override = module2.assignment_overrides.create!
            module2_override.assignment_override_students.create!(user: @student1)

            @discussion = @test_course.discussion_topics.create!
            @discussion.assignment = @assignment2
            @discussion.save!
            @discussion.context_module_tags.create! context_module: module2, context: @test_course, tag_type: "context_module"

            edd = EffectiveDueDates.for_course(@test_course, @discussion.assignment)
            result = edd.to_hash
            expected = {
              @assignment2.id => {
                @student1.id => {
                  due_at: @assignment2.due_at,
                  grading_period_id: nil,
                  in_closed_grading_period: false,
                  override_id: module2_override.id,
                  override_source: "ADHOC"
                }
              }
            }
            expect(result).to eq expected
          end

          it "applies correct context module overrides for multiple assignments and modules" do
            module2 = @test_course.context_modules.create!(name: "Module 2")
            module2_override = module2.assignment_overrides.create!
            module2_override.assignment_override_students.create!(user: @student1)

            @assignment2.only_visible_to_overrides = false
            @assignment2.save!
            @assignment2.context_module_tags.create! context_module: module2, context: @test_course, tag_type: "context_module"

            edd = EffectiveDueDates.for_course(@test_course, @assignment1, @assignment2)
            result = edd.to_hash
            expected = {
              @assignment1.id => {
                @student1.id => {
                  due_at: @assignment1.due_at,
                  grading_period_id: nil,
                  in_closed_grading_period: false,
                  override_id: @module_override.id,
                  override_source: "ADHOC"
                }
              },
              @assignment2.id => {
                @student1.id => {
                  due_at: @assignment2.due_at,
                  grading_period_id: nil,
                  in_closed_grading_period: false,
                  override_id: module2_override.id,
                  override_source: "ADHOC"
                }
              }
            }
            expect(result).to eq expected
          end

          it "applies correct context module overrides for multiple assignments and one override" do
            module2 = @test_course.context_modules.create!(name: "Module 2")

            @assignment2.only_visible_to_overrides = false
            @assignment2.save!
            @assignment2.context_module_tags.create! context_module: module2, context: @test_course, tag_type: "context_module"

            edd = EffectiveDueDates.for_course(@test_course, @assignment1, @assignment2)
            result = edd.to_hash
            expected = {
              @assignment1.id => {
                @student1.id => {
                  due_at: @assignment1.due_at,
                  grading_period_id: nil,
                  in_closed_grading_period: false,
                  override_id: @module_override.id,
                  override_source: "ADHOC"
                }
              },
              @assignment2.id => {
                @student1.id => {
                  due_at: @assignment2.due_at,
                  grading_period_id: nil,
                  in_closed_grading_period: false,
                  override_id: nil,
                  override_source: "Everyone Else"
                },
                @student2.id => {
                  due_at: @assignment2.due_at,
                  grading_period_id: nil,
                  in_closed_grading_period: false,
                  override_id: nil,
                  override_source: "Everyone Else"
                },
                @student3.id => {
                  due_at: @assignment2.due_at,
                  grading_period_id: nil,
                  in_closed_grading_period: false,
                  override_id: nil,
                  override_source: "Everyone Else"
                }
              }
            }
            expect(result).to eq expected
          end

          it "does not include deleted content tags" do
            @assignment1_tag.destroy
            edd = EffectiveDueDates.for_course(@test_course, @assignment1)
            result = edd.to_hash
            expected = {
              @assignment1.id => {
                @student1.id => {
                  due_at: @assignment1.due_at,
                  grading_period_id: nil,
                  in_closed_grading_period: false,
                  override_id: nil,
                  override_source: "Everyone Else"
                },
                @student2.id => {
                  due_at: @assignment1.due_at,
                  grading_period_id: nil,
                  in_closed_grading_period: false,
                  override_id: nil,
                  override_source: "Everyone Else"
                },
                @student3.id => {
                  due_at: @assignment1.due_at,
                  grading_period_id: nil,
                  in_closed_grading_period: false,
                  override_id: nil,
                  override_source: "Everyone Else"
                }
              }
            }
            expect(result).to eq expected
          end

          it "ignores soft-deleted context module adhoc overrides" do
            @module_override.update!(workflow_state: "deleted")

            edd = EffectiveDueDates.for_course(@test_course, @assignment1)
            result = edd.to_hash
            expected = {
              @assignment1.id => {
                @student1.id => {
                  due_at: @assignment1.due_at,
                  grading_period_id: nil,
                  in_closed_grading_period: false,
                  override_id: nil,
                  override_source: "Everyone Else"
                },
                @student2.id => {
                  due_at: @assignment1.due_at,
                  grading_period_id: nil,
                  in_closed_grading_period: false,
                  override_id: nil,
                  override_source: "Everyone Else"
                },
                @student3.id => {
                  due_at: @assignment1.due_at,
                  grading_period_id: nil,
                  in_closed_grading_period: false,
                  override_id: nil,
                  override_source: "Everyone Else"
                }
              }
            }
            expect(result).to eq expected
          end

          it "includes everyone else if there are modules without overrides" do
            module2 = @test_course.context_modules.create!(name: "Module 2")
            @assignment1.context_module_tags.create! context_module: module2, context: @test_course, tag_type: "context_module"

            edd = EffectiveDueDates.for_course(@test_course, @assignment1)
            result = edd.to_hash
            expected = {
              @assignment1.id => {
                @student1.id => {
                  due_at: @assignment1.due_at,
                  grading_period_id: nil,
                  in_closed_grading_period: false,
                  override_id: @module_override.id,
                  override_source: "ADHOC"
                },
                @student2.id => {
                  due_at: @assignment1.due_at,
                  grading_period_id: nil,
                  in_closed_grading_period: false,
                  override_id: nil,
                  override_source: "Everyone Else"
                },
                @student3.id => {
                  due_at: @assignment1.due_at,
                  grading_period_id: nil,
                  in_closed_grading_period: false,
                  override_id: nil,
                  override_source: "Everyone Else"
                }
              }
            }
            expect(result).to eq expected
          end

          it "does not unassign students with module adhoc overrides when they are deactivated" do
            @student1_enrollment.deactivate

            edd = EffectiveDueDates.for_course(@test_course, @assignment1)
            expect(edd.to_hash).to eq({
                                        @assignment1.id => {
                                          @student1.id => {
                                            due_at: @assignment1.due_at,
                                            grading_period_id: nil,
                                            in_closed_grading_period: false,
                                            override_id: @module_override.id,
                                            override_source: "ADHOC"
                                          }
                                        }
                                      })
          end

          it "does not unassign students with context module adhoc overrides when they are concluded" do
            @student1_enrollment.conclude

            edd = EffectiveDueDates.for_course(@test_course, @assignment1)
            expect(edd.to_hash).to eq({
                                        @assignment1.id => {
                                          @student1.id => {
                                            due_at: @assignment1.due_at,
                                            grading_period_id: nil,
                                            in_closed_grading_period: false,
                                            override_id: @module_override.id,
                                            override_source: "ADHOC"
                                          }
                                        }
                                      })
          end
        end

        it "does not unassign students with adhoc overrides when they are deactivated" do
          override = @assignment1.assignment_overrides.create!(due_at: 3.days.from_now(@now), due_at_overridden: true)
          override.assignment_override_students.create!(user: @student1)
          @student1_enrollment.deactivate

          edd = EffectiveDueDates.for_course(@test_course, @assignment1)
          expect(edd.to_hash).to eq({
                                      @assignment1.id => {
                                        @student1.id => {
                                          due_at: 3.days.from_now(@now),
                                          grading_period_id: nil,
                                          in_closed_grading_period: false,
                                          override_id: override.id,
                                          override_source: "ADHOC"
                                        }
                                      }
                                    })
        end

        it "does not unassign students with adhoc overrides when they are concluded" do
          override = @assignment1.assignment_overrides.create!(due_at: 3.days.from_now(@now), due_at_overridden: true)
          override.assignment_override_students.create!(user: @student1)
          @student1_enrollment.conclude

          edd = EffectiveDueDates.for_course(@test_course, @assignment1)
          expect(edd.to_hash).to eq({
                                      @assignment1.id => {
                                        @student1.id => {
                                          due_at: 3.days.from_now(@now),
                                          grading_period_id: nil,
                                          in_closed_grading_period: false,
                                          override_id: override.id,
                                          override_source: "ADHOC"
                                        }
                                      }
                                    })
        end

        it "ignores soft-deleted adhoc overrides" do
          override = @assignment1.assignment_overrides.create!(due_at: 7.days.from_now(@now), due_at_overridden: true)
          override_student = override.assignment_override_students.create!(user: @student1)
          override_student.update!(workflow_state: "deleted")

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
                override_source: "ADHOC"
              }
            }
          }
          expect(result).to eq(expected)
        end

        it "correctly matches adhoc overrides for different assignments" do
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
                override_source: "ADHOC"
              }
            },
            @assignment2.id => {
              @student1.id => {
                due_at: 3.days.from_now(@now),
                grading_period_id: nil,
                in_closed_grading_period: false,
                override_id: override2.id,
                override_source: "ADHOC"
              }
            }
          }
          expect(result).to eq expected
        end

        it "correctly matches adhoc overrides for different students" do
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
                override_source: "ADHOC"
              },
              @student2.id => {
                due_at: 1.day.from_now(@now),
                grading_period_id: nil,
                in_closed_grading_period: false,
                override_id: override2.id,
                override_source: "ADHOC"
              }
            }
          }
          expect(result).to eq expected
        end

        it "uses assigned date instead of submission date even if submission was late" do
          override = @assignment1.assignment_overrides.create!(due_at: 3.days.from_now(@now), due_at_overridden: true)
          override.assignment_override_students.create!(user: @student1)
          @assignment1.grade_student(@student1, grade: 5, grader: @teacher)
          @assignment1.submissions.find_by!(user: @student1).update!(
            submitted_at: 1.week.from_now(@now),
            submission_type: "online_text_entry"
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
                override_source: "ADHOC"
              }
            }
          }
          expect(result).to eq expected
        end

        it "prioritizes the override due date if it exists over the Everyone Else date" do
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
                override_source: "ADHOC"
              },
              @student2.id => {
                due_at: 4.days.from_now(@now),
                grading_period_id: nil,
                in_closed_grading_period: false,
                override_id: nil,
                override_source: "Everyone Else"
              },
              @student3.id => {
                due_at: 4.days.from_now(@now),
                grading_period_id: nil,
                in_closed_grading_period: false,
                override_id: nil,
                override_source: "Everyone Else"
              }
            }
          }
          expect(result).to eq expected
        end

        # this might look like a strange test to have, but it is a result of how we are joining different tables in sql.
        it "prioritizes the override due date even if it is earlier than the Everyone Else date and the student has a graded submission that does not qualify" do
          override = @assignment2.assignment_overrides.create!(due_at: 3.days.ago(@now), due_at_overridden: true)
          override.assignment_override_students.create!(user: @student1)
          @assignment2.grade_student(@student1, grade: 5, grader: @teacher)
          @assignment2.submissions.find_by!(user: @student1).update!(
            submitted_at: 1.week.from_now(@now),
            submission_type: "online_text_entry"
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
                override_source: "ADHOC"
              },
              @student2.id => {
                due_at: 4.days.from_now(@now),
                grading_period_id: nil,
                in_closed_grading_period: false,
                override_id: nil,
                override_source: "Everyone Else"
              },
              @student3.id => {
                due_at: 4.days.from_now(@now),
                grading_period_id: nil,
                in_closed_grading_period: false,
                override_id: nil,
                override_source: "Everyone Else"
              }
            }
          }
          expect(result).to eq expected
        end
      end

      context "when group overrides apply" do
        it "applies group overrides" do
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
                override_source: "Group"
              },
              @student3.id => {
                due_at: 4.days.from_now(@now),
                grading_period_id: nil,
                in_closed_grading_period: false,
                override_id: override.id,
                override_source: "Group"
              }
            }
          }
          expect(result).to eq expected
        end

        it "doesn't assign group with overrides with unassign_item" do
          group_with_user(user: @student3, active_all: true)
          @group.users << @student2
          @assignment1.assignment_overrides.create!(
            due_at: 4.days.from_now(@now),
            due_at_overridden: true,
            set: @group,
            unassign_item: true
          )

          edd = EffectiveDueDates.for_course(@test_course, @assignment1)
          result = edd.to_hash
          expected = {}
          expect(result).to eq expected
        end

        it "ignores overrides for soft-deleted groups" do
          group_with_user(user: @student3, active_all: true)
          @assignment1.assignment_overrides.create!(due_at: 4.days.from_now(@now), due_at_overridden: true, set: @group)
          @group.destroy!

          edd = EffectiveDueDates.for_course(@test_course, @assignment1)
          expect(edd.to_hash).to eq({})
        end

        it "only applies group overrides to students that have accepted the group invitation" do
          group
          @group.add_user(@student1, "rejected")
          @assignment1.assignment_overrides.create!(due_at: 4.days.from_now(@now), due_at_overridden: true, set: @group)

          edd = EffectiveDueDates.for_course(@test_course, @assignment1)
          expect(edd.to_hash).to eq({})
        end

        it "does not unassign students in the assigned group when they are deactivated" do
          group_with_user(user: @student1, active_all: true)
          override = @assignment1.assignment_overrides.create!(
            due_at: 4.days.from_now(@now),
            due_at_overridden: true,
            set: @group
          )
          @student1_enrollment.deactivate

          edd = EffectiveDueDates.for_course(@test_course, @assignment1)
          expect(edd.to_hash).to eq({
                                      @assignment1.id => {
                                        @student1.id => {
                                          due_at: 4.days.from_now(@now),
                                          grading_period_id: nil,
                                          in_closed_grading_period: false,
                                          override_id: override.id,
                                          override_source: "Group"
                                        }
                                      }
                                    })
        end

        it "does not unassign students in the assigned group when they are concluded" do
          group_with_user(user: @student1, active_all: true)
          override = @assignment1.assignment_overrides.create!(
            due_at: 4.days.from_now(@now),
            due_at_overridden: true,
            set: @group
          )
          @student1_enrollment.conclude

          edd = EffectiveDueDates.for_course(@test_course, @assignment1)
          expect(edd.to_hash).to eq({
                                      @assignment1.id => {
                                        @student1.id => {
                                          due_at: 4.days.from_now(@now),
                                          grading_period_id: nil,
                                          in_closed_grading_period: false,
                                          override_id: override.id,
                                          override_source: "Group"
                                        }
                                      }
                                    })
        end

        context "differentiation tag groups (aka non collaborative groups)" do
          before do
            @assignment1.context.account.enable_feature!(:assign_to_differentiation_tags)
            @assignment1.context.account.settings[:allow_assign_to_differentiation_tags] = { value: true }
            @assignment1.context.account.save!
            @assignment1.context.account.reload

            @module3 = @test_course.context_modules.create!(name: "Module 3 for Non-Collaborative Group")
            @student4 = student_in_course(active_all: true, course: @test_course, name: "Student 4").user

            @group_category = @test_course.group_categories.create!(name: "Non-Collaborative Group", non_collaborative: true)
            @group_category.create_groups(2)
            @differentiation_tag_group_1 = @group_category.groups.first
            @differentiation_tag_group_2 = @group_category.groups.second
          end

          it "applies group overrides for differentiation tag groups" do
            Account.site_admin.enable_feature! :assign_to_differentiation_tags
            @differentiation_tag_group_1.add_user(@student3)
            @differentiation_tag_group_1.add_user(@student2)

            override = @assignment1.assignment_overrides.create!(
              due_at: 4.days.from_now(@now),
              due_at_overridden: true,
              set: @differentiation_tag_group_1
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
                  override_source: "Group"
                },
                @student3.id => {
                  due_at: 4.days.from_now(@now),
                  grading_period_id: nil,
                  in_closed_grading_period: false,
                  override_id: override.id,
                  override_source: "Group"
                }
              }
            }
            expect(result).to eq expected
          end

          it "does not apply group overrides for differentiation tag groups when the feature is off" do
            @differentiation_tag_group_1.add_user(@student3)
            @differentiation_tag_group_1.add_user(@student2)

            @assignment1.assignment_overrides.create!(
              due_at: 4.days.from_now(@now),
              due_at_overridden: true,
              set: @differentiation_tag_group_1
            )

            @test_course.account.disable_feature!(:assign_to_differentiation_tags)

            edd = EffectiveDueDates.for_course(@test_course, @assignment1)
            result = edd.to_hash
            expected = {}
            expect(result).to eq expected
          end

          it "ignores overrides for soft-deleted groups" do
            @differentiation_tag_group_1.add_user(@student3)
            @differentiation_tag_group_1.add_user(@student2)

            @assignment1.assignment_overrides.create!(
              due_at: 4.days.from_now(@now),
              due_at_overridden: true,
              set: @differentiation_tag_group_1
            )
            @differentiation_tag_group_1.destroy!

            edd = EffectiveDueDates.for_course(@test_course, @assignment1)
            expect(edd.to_hash).to eq({})
          end

          it "does apply group overrides for differentiation tag groups when the account setting is off" do
            # When the account setting is off and existing differentiation tag group overrides exist, we should still
            # apply them until the instructor removes them manually or triggers a bulk update to delete all of them.
            # See rollback plan: https://instructure.atlassian.net/wiki/spaces/EGGWIKI/pages/86942646273/Tech+Plan+Assign+To+Hidden+Groups#Rollback-Plan

            @differentiation_tag_group_1.add_user(@student3)
            @differentiation_tag_group_1.add_user(@student2)

            override = @assignment1.assignment_overrides.create!(
              due_at: 4.days.from_now(@now),
              due_at_overridden: true,
              set: @differentiation_tag_group_1
            )

            @test_course.account.settings[:allow_assign_to_differentiation_tags] = { value: false }
            @test_course.account.save
            @test_course.account.reload

            edd = EffectiveDueDates.for_course(@test_course, @assignment1)
            result = edd.to_hash
            expected = {
              @assignment1.id => {
                @student2.id => {
                  due_at: 4.days.from_now(@now),
                  grading_period_id: nil,
                  in_closed_grading_period: false,
                  override_id: override.id,
                  override_source: "Group"
                },
                @student3.id => {
                  due_at: 4.days.from_now(@now),
                  grading_period_id: nil,
                  in_closed_grading_period: false,
                  override_id: override.id,
                  override_source: "Group"
                }
              }
            }
            expect(result).to eq expected
          end

          it "does not unassign students in the assigned group when they are deactivated" do
            @differentiation_tag_group_1.add_user(@student1)

            override = @assignment1.assignment_overrides.create!(
              due_at: 4.days.from_now(@now),
              due_at_overridden: true,
              set: @differentiation_tag_group_1
            )
            @student1_enrollment.deactivate

            edd = EffectiveDueDates.for_course(@test_course, @assignment1)
            expect(edd.to_hash).to eq({
                                        @assignment1.id => {
                                          @student1.id => {
                                            due_at: 4.days.from_now(@now),
                                            grading_period_id: nil,
                                            in_closed_grading_period: false,
                                            override_id: override.id,
                                            override_source: "Group"
                                          }
                                        }
                                      })
          end

          it "does not unassign students in the assigned group when they are concluded" do
            @differentiation_tag_group_1.add_user(@student1)

            override = @assignment1.assignment_overrides.create!(
              due_at: 4.days.from_now(@now),
              due_at_overridden: true,
              set: @differentiation_tag_group_1
            )
            @student1_enrollment.conclude

            edd = EffectiveDueDates.for_course(@test_course, @assignment1)
            expect(edd.to_hash).to eq({
                                        @assignment1.id => {
                                          @student1.id => {
                                            due_at: 4.days.from_now(@now),
                                            grading_period_id: nil,
                                            in_closed_grading_period: false,
                                            override_id: override.id,
                                            override_source: "Group"
                                          }
                                        }
                                      })
          end

          describe "order of precedence" do
            it "applies non-collaborative group overrides over section overrides" do
              # differentiation tag group
              @differentiation_tag_group_1.add_user(@student3)
              @differentiation_tag_group_1.add_user(@student2)

              non_collab_override = @assignment1.assignment_overrides.create!(
                due_at: 4.days.from_now(@now),
                due_at_overridden: true,
                set: @differentiation_tag_group_1
              )

              # course section
              section = CourseSection.create!(name: "My Awesome Section", course: @test_course)
              student_in_section(section, user: @student2)
              student_in_section(section, user: @student1)
              section_override = @assignment1.assignment_overrides.create!(
                due_at: 3.days.from_now(@now),
                due_at_overridden: true,
                set: section
              )

              edd = EffectiveDueDates.for_course(@test_course, @assignment1)
              result = edd.to_hash
              expected = {
                @assignment1.id => {
                  @student1.id => {
                    due_at: 3.days.from_now(@now),
                    grading_period_id: nil,
                    in_closed_grading_period: false,
                    override_id: section_override.id,
                    override_source: "CourseSection"
                  },
                  @student2.id => {
                    due_at: 4.days.from_now(@now),
                    grading_period_id: nil,
                    in_closed_grading_period: false,
                    override_id: non_collab_override.id,
                    override_source: "Group"
                  },
                  @student3.id => {
                    due_at: 4.days.from_now(@now),
                    grading_period_id: nil,
                    in_closed_grading_period: false,
                    override_id: non_collab_override.id,
                    override_source: "Group"
                  }
                }
              }
              expect(result).to eq expected
            end

            it "applies individual student overrides over non-collaborative overrides" do
              # individual / ADHOC
              individual_override = @assignment1.assignment_overrides.create!(
                due_at: 2.days.from_now(@now),
                due_at_overridden: true,
                set_type: "ADHOC"
              )
              individual_override.assignment_override_students.create!(user: @student2)

              # differentiation tag group
              @differentiation_tag_group_1.add_user(@student3)
              @differentiation_tag_group_1.add_user(@student2)

              non_collab_override = @assignment1.assignment_overrides.create!(
                due_at: 4.days.from_now(@now),
                due_at_overridden: true,
                set: @differentiation_tag_group_1
              )

              edd = EffectiveDueDates.for_course(@test_course, @assignment1)
              result = edd.to_hash
              expected = {
                @assignment1.id => {
                  @student2.id => {
                    due_at: 2.days.from_now(@now),
                    grading_period_id: nil,
                    in_closed_grading_period: false,
                    override_id: individual_override.id,
                    override_source: "ADHOC"
                  },
                  @student3.id => {
                    due_at: 4.days.from_now(@now),
                    grading_period_id: nil,
                    in_closed_grading_period: false,
                    override_id: non_collab_override.id,
                    override_source: "Group"
                  }
                }
              }
              expect(result).to eq expected
            end

            describe "selective release" do
              before do
                # differentiation tag group 1
                @differentiation_tag_group_1.add_user(@student3)
                @differentiation_tag_group_1.add_user(@student2)
              end

              it "doesn't assign group with overrides with unassign_item" do
                @assignment1.assignment_overrides.create!(
                  due_at: 4.days.from_now(@now),
                  due_at_overridden: true,
                  set: @differentiation_tag_group_1,
                  unassign_item: true
                )

                edd = EffectiveDueDates.for_course(@test_course, @assignment1)
                result = edd.to_hash
                expected = {}
                expect(result).to eq expected
              end

              describe "applies non collaborative group override over course override" do
                it "if the due dates are the same" do
                  # if the due dates are the same - differentiation tag group override will take precedence
                  course_override = @assignment1.assignment_overrides.create!(
                    due_at: 4.days.from_now(@now),
                    due_at_overridden: true,
                    set_type: "Course",
                    set_id: @test_course.id
                  )

                  non_collab_override_1 = @assignment1.assignment_overrides.create!(
                    due_at: 4.days.from_now(@now),
                    due_at_overridden: true,
                    set: @differentiation_tag_group_1
                  )

                  edd = EffectiveDueDates.for_course(@test_course, @assignment1)
                  result = edd.to_hash
                  expected = {
                    @assignment1.id => {
                      @student4.id => {
                        due_at: 4.days.from_now(@now),
                        grading_period_id: nil,
                        in_closed_grading_period: false,
                        override_id: course_override.id,
                        override_source: "Course"
                      },
                      @student1.id => {
                        due_at: 4.days.from_now(@now),
                        grading_period_id: nil,
                        in_closed_grading_period: false,
                        override_id: course_override.id,
                        override_source: "Course"
                      },
                      @student2.id => {
                        due_at: 4.days.from_now(@now),
                        grading_period_id: nil,
                        in_closed_grading_period: false,
                        override_id: non_collab_override_1.id,
                        override_source: "Group"
                      },
                      @student3.id => {
                        due_at: 4.days.from_now(@now),
                        grading_period_id: nil,
                        in_closed_grading_period: false,
                        override_id: non_collab_override_1.id,
                        override_source: "Group"
                      }
                    }
                  }
                  expect(result).to eq expected
                end

                it "if non collaborative group due date is later than course due date" do
                  # if the due dates are the same - differentiation tag group override will take precedence
                  course_override = @assignment1.assignment_overrides.create!(
                    due_at: 1.day.from_now(@now),
                    due_at_overridden: true,
                    set_type: "Course",
                    set_id: @test_course.id
                  )

                  non_collab_override_1 = @assignment1.assignment_overrides.create!(
                    due_at: 4.days.from_now(@now),
                    due_at_overridden: true,
                    set: @differentiation_tag_group_1
                  )

                  edd = EffectiveDueDates.for_course(@test_course, @assignment1)
                  result = edd.to_hash
                  expected = {
                    @assignment1.id => {
                      @student4.id => {
                        due_at: 1.day.from_now(@now),
                        grading_period_id: nil,
                        in_closed_grading_period: false,
                        override_id: course_override.id,
                        override_source: "Course"
                      },
                      @student1.id => {
                        due_at: 1.day.from_now(@now),
                        grading_period_id: nil,
                        in_closed_grading_period: false,
                        override_id: course_override.id,
                        override_source: "Course"
                      },
                      @student2.id => {
                        due_at: 4.days.from_now(@now),
                        grading_period_id: nil,
                        in_closed_grading_period: false,
                        override_id: non_collab_override_1.id,
                        override_source: "Group"
                      },
                      @student3.id => {
                        due_at: 4.days.from_now(@now),
                        grading_period_id: nil,
                        in_closed_grading_period: false,
                        override_id: non_collab_override_1.id,
                        override_source: "Group"
                      }
                    }
                  }
                  expect(result).to eq expected
                end
              end

              it "applies course override over non collaborative group override" do
                # if course due date is longer than non collaborative group override due date
                # the course override will take precedence
                course_override = @assignment1.assignment_overrides.create!(
                  due_at: 4.days.from_now(@now),
                  due_at_overridden: true,
                  set_type: "Course",
                  set_id: @test_course.id
                )

                @assignment1.assignment_overrides.create!(
                  due_at: 1.day.from_now(@now),
                  due_at_overridden: true,
                  set: @differentiation_tag_group_1
                )

                edd = EffectiveDueDates.for_course(@test_course, @assignment1)
                result = edd.to_hash
                expected = {
                  @assignment1.id => {
                    @student4.id => {
                      due_at: 4.days.from_now(@now),
                      grading_period_id: nil,
                      in_closed_grading_period: false,
                      override_id: course_override.id,
                      override_source: "Course"
                    },
                    @student1.id => {
                      due_at: 4.days.from_now(@now),
                      grading_period_id: nil,
                      in_closed_grading_period: false,
                      override_id: course_override.id,
                      override_source: "Course"
                    },
                    @student2.id => {
                      due_at: 4.days.from_now(@now),
                      grading_period_id: nil,
                      in_closed_grading_period: false,
                      override_id: course_override.id,
                      override_source: "Course"
                    },
                    @student3.id => {
                      due_at: 4.days.from_now(@now),
                      grading_period_id: nil,
                      in_closed_grading_period: false,
                      override_id: course_override.id,
                      override_source: "Course"
                    }
                  }
                }
                expect(result).to eq expected
              end
            end
          end

          describe "picks the due date that gives the student the most time to submit" do
            it "student is in more than 1 non collaborative group override" do
              # differentiation tag group 1
              @differentiation_tag_group_1.add_user(@student3)
              @differentiation_tag_group_1.add_user(@student2)

              non_collab_override_1 = @assignment1.assignment_overrides.create!(
                due_at: 4.days.from_now(@now),
                due_at_overridden: true,
                set: @differentiation_tag_group_1
              )

              # differentiation tag group 2
              non_collab_cat_2 = @test_course.group_categories.create!(name: "Non-Collaborative Group 2", non_collaborative: true)
              non_collab_cat_2.create_groups(1)
              differentiation_tag_group_2 = non_collab_cat_2.groups.first
              differentiation_tag_group_2.add_user(@student2)

              non_collab_override_2 = @assignment1.assignment_overrides.create!(
                due_at: 6.days.from_now(@now),
                due_at_overridden: true,
                set: differentiation_tag_group_2
              )

              edd = EffectiveDueDates.for_course(@test_course, @assignment1)
              result = edd.to_hash
              expected = {
                @assignment1.id => {
                  @student2.id => {
                    due_at: 6.days.from_now(@now),
                    grading_period_id: nil,
                    in_closed_grading_period: false,
                    override_id: non_collab_override_2.id,
                    override_source: "Group"
                  },
                  @student3.id => {
                    due_at: 4.days.from_now(@now),
                    grading_period_id: nil,
                    in_closed_grading_period: false,
                    override_id: non_collab_override_1.id,
                    override_source: "Group"
                  }
                }
              }
              expect(result).to eq expected
            end

            it "student is in more than one selected assignee designation (i.e. course section, diff tag group)" do
              # differentiation tag group 1
              @differentiation_tag_group_1.add_user(@student3)
              @differentiation_tag_group_1.add_user(@student2)

              non_collab_override_1 = @assignment1.assignment_overrides.create!(
                due_at: 4.days.from_now(@now),
                due_at_overridden: true,
                set: @differentiation_tag_group_1
              )

              # course section 1
              section1 = CourseSection.create!(name: "My Awesome Section", course: @test_course)
              student_in_section(section1, user: @student2)
              student_in_section(section1, user: @student1)
              section1_override = @assignment1.assignment_overrides.create!(
                due_at: 5.days.from_now(@now),
                due_at_overridden: true,
                set: section1
              )

              # course section 2
              section2 = CourseSection.create!(name: "My Awesome Section 2", course: @test_course)
              student_in_section(section2, user: @student2)
              section2_override = @assignment1.assignment_overrides.create!(
                due_at: 6.days.from_now(@now),
                due_at_overridden: true,
                set: section2
              )

              edd = EffectiveDueDates.for_course(@test_course, @assignment1)
              result = edd.to_hash
              expected = {
                @assignment1.id => {
                  @student1.id => {
                    due_at: 5.days.from_now(@now),
                    grading_period_id: nil,
                    in_closed_grading_period: false,
                    override_id: section1_override.id,
                    override_source: "CourseSection"
                  },
                  @student2.id => {
                    due_at: 6.days.from_now(@now),
                    grading_period_id: nil,
                    in_closed_grading_period: false,
                    override_id: section2_override.id,
                    override_source: "CourseSection"
                  },
                  @student3.id => {
                    due_at: 4.days.from_now(@now),
                    grading_period_id: nil,
                    in_closed_grading_period: false,
                    override_id: non_collab_override_1.id,
                    override_source: "Group"
                  }
                }
              }
              expect(result).to eq expected
            end
          end
        end
      end

      context "when section overrides apply" do
        it "applies section overrides" do
          section = CourseSection.create!(name: "My Awesome Section", course: @test_course)
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
                override_source: "CourseSection"
              },
              @student2.id => {
                due_at: 1.day.from_now(@now),
                grading_period_id: nil,
                in_closed_grading_period: false,
                override_id: override.id,
                override_source: "CourseSection"
              }
            }
          }
          expect(result).to eq expected
        end

        context "with context module section overrides" do
          before :once do
            section = CourseSection.create!(name: "Section 1", course: @test_course)
            student_in_section(section, user: @student1)
            @module = @test_course.context_modules.create!(name: "Module 1")
            @assignment1.context_module_tags.create! context_module: @module, context: @test_course, tag_type: "context_module"

            @assignment1.only_visible_to_overrides = false
            @assignment1.save!

            @module_override = @module.assignment_overrides.create!
            @module_override.set_type = "CourseSection"
            @module_override.set_id = section
            @module_override.save!
          end

          it "applies context module section overrides" do
            edd = EffectiveDueDates.for_course(@test_course, @assignment1)
            result = edd.to_hash
            expected = {
              @assignment1.id => {
                @student1.id => {
                  due_at: @assignment1.due_at,
                  grading_period_id: nil,
                  in_closed_grading_period: false,
                  override_id: @module_override.id,
                  override_source: "CourseSection"
                }
              }
            }
            expect(result).to eq expected
          end

          it "does not unassign students in the assigned section when they are deactivated" do
            @student1_enrollment.deactivate

            edd = EffectiveDueDates.for_course(@test_course, @assignment1)
            expect(edd.to_hash).to eq({
                                        @assignment1.id => {
                                          @student1.id => {
                                            due_at: @assignment1.due_at,
                                            grading_period_id: nil,
                                            in_closed_grading_period: false,
                                            override_id: @module_override.id,
                                            override_source: "CourseSection"
                                          }
                                        }
                                      })
          end

          it "does not unassign students in the assigned section when they are concluded" do
            @student1_enrollment.conclude

            edd = EffectiveDueDates.for_course(@test_course, @assignment1)
            expect(edd.to_hash).to eq({
                                        @assignment1.id => {
                                          @student1.id => {
                                            due_at: @assignment1.due_at,
                                            grading_period_id: nil,
                                            in_closed_grading_period: false,
                                            override_id: @module_override.id,
                                            override_source: "CourseSection"
                                          }
                                        }
                                      })
          end
        end

        it "doesn't assign section with overrides with unassign_item" do
          section = CourseSection.create!(name: "My Awesome Section", course: @test_course)
          student_in_section(section, user: @student1)
          @assignment1.assignment_overrides.create!(
            due_at: 1.day.from_now(@now),
            due_at_overridden: true,
            set: section,
            unassign_item: true
          )

          edd = EffectiveDueDates.for_course(@test_course, @assignment1)
          result = edd.to_hash
          expected = {}
          expect(result).to eq expected
        end

        it "ignores section overrides for TAs" do
          section = CourseSection.create!(name: "My Awesome Section", course: @test_course)
          ta_in_section(section, user: @student2)
          @assignment1.assignment_overrides.create!(due_at: 1.day.from_now(@now), due_at_overridden: true, set: section)

          edd = EffectiveDueDates.for_course(@test_course, @assignment1)
          expect(edd.to_hash).to eq({})
        end

        it "ignores overrides for soft-deleted sections" do
          section = CourseSection.create!(name: "My Awesome Section", course: @test_course)
          student_in_section(section, user: @student2)
          @assignment1.assignment_overrides.create!(due_at: 1.day.from_now(@now), due_at_overridden: true, set: section)
          section.destroy!

          edd = EffectiveDueDates.for_course(@test_course, @assignment1)
          expect(edd.to_hash).to eq({})
        end

        it "does not unassign students in the assigned section when they are deactivated" do
          section = CourseSection.create!(name: "My Awesome Section", course: @test_course)
          student_in_section(section, user: @student1)
          override = @assignment1.assignment_overrides.create!(
            due_at: 1.day.from_now(@now),
            due_at_overridden: true,
            set: section
          )
          @student1_enrollment.deactivate

          edd = EffectiveDueDates.for_course(@test_course, @assignment1)
          expect(edd.to_hash).to eq({
                                      @assignment1.id => {
                                        @student1.id => {
                                          due_at: 1.day.from_now(@now),
                                          grading_period_id: nil,
                                          in_closed_grading_period: false,
                                          override_id: override.id,
                                          override_source: "CourseSection"
                                        }
                                      }
                                    })
        end

        it "does not unassign students in the assigned section when they are concluded" do
          section = CourseSection.create!(name: "My Awesome Section", course: @test_course)
          student_in_section(section, user: @student1)
          override = @assignment1.assignment_overrides.create!(due_at: 1.day.from_now(@now), due_at_overridden: true, set: section)
          @student1_enrollment.conclude

          edd = EffectiveDueDates.for_course(@test_course, @assignment1)
          expect(edd.to_hash).to eq({
                                      @assignment1.id => {
                                        @student1.id => {
                                          due_at: 1.day.from_now(@now),
                                          grading_period_id: nil,
                                          in_closed_grading_period: false,
                                          override_id: override.id,
                                          override_source: "CourseSection"
                                        }
                                      }
                                    })
        end
      end

      context "when course overrides apply" do
        before :once do
          @override = @assignment1.assignment_overrides.create!(
            due_at: 1.day.from_now(@now),
            due_at_overridden: true,
            set_type: "Course",
            set_id: @test_course.id
          )
          @expected = {
            @assignment1.id => {
              @student1.id => {
                due_at: 1.day.from_now(@now),
                grading_period_id: nil,
                in_closed_grading_period: false,
                override_id: @override.id,
                override_source: "Course"
              },
              @student2.id => {
                due_at: 1.day.from_now(@now),
                grading_period_id: nil,
                in_closed_grading_period: false,
                override_id: @override.id,
                override_source: "Course"
              },
              @student3.id => {
                due_at: 1.day.from_now(@now),
                grading_period_id: nil,
                in_closed_grading_period: false,
                override_id: @override.id,
                override_source: "Course"
              }
            }
          }
        end

        it "applies course overrides" do
          edd = EffectiveDueDates.for_course(@test_course, @assignment1)
          expect(edd.to_hash).to eq @expected
        end

        it "does not unassign students when they are deactivated" do
          @student1_enrollment.deactivate

          edd = EffectiveDueDates.for_course(@test_course, @assignment1)
          expect(edd.to_hash).to eq @expected
        end

        it "does not unassign students when they are concluded" do
          @student1_enrollment.conclude

          edd = EffectiveDueDates.for_course(@test_course, @assignment1)
          expect(edd.to_hash).to eq @expected
        end

        it "does not unassign students with unassign_item override when course override exists" do
          unassigned_override = @assignment1.assignment_overrides.create!(
            due_at: 2.days.from_now(@now),
            due_at_overridden: true,
            set_type: "ADHOC",
            unassign_item: true
          )
          unassigned_override.assignment_override_students.create!(user: @student1)
          edd = EffectiveDueDates.for_course(@test_course, @assignment1)
          expect(edd.to_hash).to eq @expected
        end

        it "includes context module course overrides" do
          @module = @test_course.context_modules.create!(name: "Module 1")
          @assignment1.context_module_tags.create! context_module: @module, context: @test_course, tag_type: "context_module"

          @override.destroy!
          @module_override = @module.assignment_overrides.create!(
            set_type: "Course",
            set_id: @test_course.id
          )

          edd = EffectiveDueDates.for_course(@test_course, @assignment1)
          result = edd.to_hash
          expected = {
            @assignment1.id => {
              @student1.id => {
                due_at: @assignment1.due_at,
                grading_period_id: nil,
                in_closed_grading_period: false,
                override_id: @module_override.id,
                override_source: "Course"
              },
              @student2.id => {
                due_at: @assignment1.due_at,
                grading_period_id: nil,
                in_closed_grading_period: false,
                override_id: @module_override.id,
                override_source: "Course"
              },
              @student3.id => {
                due_at: @assignment1.due_at,
                grading_period_id: nil,
                in_closed_grading_period: false,
                override_id: @module_override.id,
                override_source: "Course"
              }
            }
          }
          expect(result).to eq expected
        end
      end

      context "when multiple override types apply" do
        it "picks the individual override due date, if one exists" do
          # adhoc
          individual_override = @assignment2.assignment_overrides.create!(due_at: 3.days.from_now(@now), due_at_overridden: true)
          individual_override.assignment_override_students.create!(user: @student1)

          # group
          group_with_user(user: @student1, active_all: true)
          @assignment2.assignment_overrides.create!(
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
                due_at: individual_override.due_at,
                grading_period_id: nil,
                in_closed_grading_period: false,
                override_id: individual_override.id,
                override_source: "ADHOC"
              },
              @student2.id => {
                due_at: 4.days.from_now(@now),
                grading_period_id: nil,
                in_closed_grading_period: false,
                override_id: nil,
                override_source: "Everyone Else"
              },
              @student3.id => {
                due_at: 4.days.from_now(@now),
                grading_period_id: nil,
                in_closed_grading_period: false,
                override_id: nil,
                override_source: "Everyone Else"
              }
            }
          }
          expect(result).to eq expected
        end

        it "picks the individual override due date, even with a course override" do
          # adhoc
          individual_override = @assignment2.assignment_overrides.create!(due_at: 3.days.from_now(@now), due_at_overridden: true)
          individual_override.assignment_override_students.create!(user: @student1)

          # course override
          course_override = @assignment2.assignment_overrides.create!(
            due_at: 5.days.from_now(@now),
            due_at_overridden: true,
            set_type: "Course",
            set_id: @test_course.id
          )

          edd = EffectiveDueDates.for_course(@test_course, @assignment2)
          result = edd.to_hash
          expected = {
            @assignment2.id => {
              @student1.id => {
                due_at: individual_override.due_at,
                grading_period_id: nil,
                in_closed_grading_period: false,
                override_id: individual_override.id,
                override_source: "ADHOC"
              },
              @student2.id => {
                due_at: course_override.due_at,
                grading_period_id: nil,
                in_closed_grading_period: false,
                override_id: course_override.id,
                override_source: "Course"
              },
              @student3.id => {
                due_at: course_override.due_at,
                grading_period_id: nil,
                in_closed_grading_period: false,
                override_id: course_override.id,
                override_source: "Course"
              }
            }
          }
          expect(result).to eq expected
        end

        it "picks the due date that gives the student the most time to submit, if no individual override exists" do
          # section
          section = CourseSection.create!(name: "My Awesome Section", course: @test_course)
          student_in_section(section, user: @student1)
          @assignment2.assignment_overrides.create!(
            due_at: 3.days.from_now(@now),
            due_at_overridden: true,
            set: section
          )

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
                due_at: group_override.due_at,
                grading_period_id: nil,
                in_closed_grading_period: false,
                override_id: group_override.id,
                override_source: "Group"
              },
              @student2.id => {
                due_at: 4.days.from_now(@now),
                grading_period_id: nil,
                in_closed_grading_period: false,
                override_id: nil,
                override_source: "Everyone Else"
              },
              @student3.id => {
                due_at: 4.days.from_now(@now),
                grading_period_id: nil,
                in_closed_grading_period: false,
                override_id: nil,
                override_source: "Everyone Else"
              }
            }
          }
          expect(result).to eq expected
        end

        it "deprioritizes due dates from section overrides for nonactive enrollments" do
          # section
          section = CourseSection.create!(name: "My Awesome Section", course: @test_course)
          student_in_section(section, user: @student1)
          @assignment2.assignment_overrides.create!(
            due_at: 6.days.from_now(@now),
            due_at_overridden: true,
            set: section
          )

          # group
          group_with_user(user: @student1, active_all: true)
          group_override = @assignment2.assignment_overrides.create!(
            due_at: 3.days.from_now(@now),
            due_at_overridden: true,
            set: @group
          )

          # everyone else
          @assignment2.due_at = 4.days.from_now(@now)
          @assignment2.save!

          @test_course.enrollments.find_by(user: @student1, course_section: section).deactivate

          edd = EffectiveDueDates.for_course(@test_course, @assignment2)
          result = edd.to_hash
          expected = {
            @assignment2.id => {
              @student1.id => {
                due_at: group_override.due_at,
                grading_period_id: nil,
                in_closed_grading_period: false,
                override_id: group_override.id,
                override_source: "Group"
              },
              @student2.id => {
                due_at: 4.days.from_now(@now),
                grading_period_id: nil,
                in_closed_grading_period: false,
                override_id: nil,
                override_source: "Everyone Else"
              },
              @student3.id => {
                due_at: 4.days.from_now(@now),
                grading_period_id: nil,
                in_closed_grading_period: false,
                override_id: nil,
                override_source: "Everyone Else"
              }
            }
          }
          expect(result).to eq expected
        end

        it "does not deprioritize due dates from section overrides for nonactive enrollments when the flag is disabled" do
          Account.site_admin.disable_feature!(:deprioritize_section_overrides_for_nonactive_enrollments)
          # section
          section = CourseSection.create!(name: "My Awesome Section", course: @test_course)
          student_in_section(section, user: @student1)
          section_override = @assignment2.assignment_overrides.create!(
            due_at: 6.days.from_now(@now),
            due_at_overridden: true,
            set: section
          )

          # group
          group_with_user(user: @student1, active_all: true)
          @assignment2.assignment_overrides.create!(
            due_at: 3.days.from_now(@now),
            due_at_overridden: true,
            set: @group
          )

          # everyone else
          @assignment2.due_at = 4.days.from_now(@now)
          @assignment2.save!

          @test_course.enrollments.find_by(user: @student1, course_section: section).deactivate

          edd = EffectiveDueDates.for_course(@test_course, @assignment2)
          result = edd.to_hash
          expected = {
            @assignment2.id => {
              @student1.id => {
                due_at: section_override.due_at,
                grading_period_id: nil,
                in_closed_grading_period: false,
                override_id: section_override.id,
                override_source: "CourseSection"
              },
              @student2.id => {
                due_at: 4.days.from_now(@now),
                grading_period_id: nil,
                in_closed_grading_period: false,
                override_id: nil,
                override_source: "Everyone Else"
              },
              @student3.id => {
                due_at: 4.days.from_now(@now),
                grading_period_id: nil,
                in_closed_grading_period: false,
                override_id: nil,
                override_source: "Everyone Else"
              }
            }
          }
          expect(result).to eq expected
        end

        it "treats null due dates as the most permissive due date for a student" do
          # section
          section = CourseSection.create!(name: "My Awesome Section", course: @test_course)
          student_in_section(section, user: @student1)
          section_override = @assignment2.assignment_overrides.create!(
            due_at: nil,
            due_at_overridden: true,
            set: section
          )

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
                override_id: section_override.id,
                override_source: "CourseSection"
              },
              @student2.id => {
                due_at: 4.days.from_now(@now),
                grading_period_id: nil,
                in_closed_grading_period: false,
                override_id: nil,
                override_source: "Everyone Else"
              },
              @student3.id => {
                due_at: 4.days.from_now(@now),
                grading_period_id: nil,
                in_closed_grading_period: false,
                override_id: nil,
                override_source: "Everyone Else"
              }
            }
          }
          expect(result).to eq expected
        end
      end

      context "when noop overrides apply" do
        it "ignores noop overrides" do
          @assignment1.assignment_overrides.create!(set_type: "Noop")
          edd = EffectiveDueDates.for_course(@test_course, @assignment1)
          expect(edd.to_hash).to eq({})
        end
      end

      context "with grading periods" do
        before(:once) do
          @gp_group = Factories::GradingPeriodGroupHelper.new.create_for_account(@test_course.account)
          @gp_group.enrollment_terms << @test_course.enrollment_term
        end

        it "uses account grading periods if no course grading periods exist" do
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
                override_source: "Everyone Else"
              },
              @student2.id => {
                due_at: 17.days.ago(@now),
                grading_period_id: gp.id,
                in_closed_grading_period: true,
                override_id: nil,
                override_source: "Everyone Else"
              },
              @student3.id => {
                due_at: 17.days.ago(@now),
                grading_period_id: gp.id,
                in_closed_grading_period: true,
                override_id: nil,
                override_source: "Everyone Else"
              }
            }
          }
          expect(result).to eq expected
        end

        it "uses only course grading periods if any exist (legacy)" do
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
                override_source: "Everyone Else"
              },
              @student2.id => {
                due_at: 7.days.ago(@now),
                grading_period_id: gp.id,
                in_closed_grading_period: true,
                override_id: override.id,
                override_source: "ADHOC"
              },
              @student3.id => {
                due_at: 17.days.ago(@now),
                grading_period_id: nil,
                in_closed_grading_period: false,
                override_id: nil,
                override_source: "Everyone Else"
              }
            }
          }
          expect(result).to eq expected
        end

        it "ignores account grading periods for unrelated enrollment terms" do
          gp_group = Factories::GradingPeriodGroupHelper.new.create_for_account_with_term(@test_course.account, "Term")
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
                override_source: "Everyone Else"
              },
              @student2.id => {
                due_at: 17.days.ago(@now),
                grading_period_id: nil,
                in_closed_grading_period: false,
                override_id: nil,
                override_source: "Everyone Else"
              },
              @student3.id => {
                due_at: 17.days.ago(@now),
                grading_period_id: nil,
                in_closed_grading_period: false,
                override_id: nil,
                override_source: "Everyone Else"
              }
            }
          }
          expect(result).to eq expected
        end

        it "uses the effective due date to find a closed grading period" do
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
                override_source: "Everyone Else"
              },
              @student2.id => {
                due_at: 1.day.ago(@now),
                grading_period_id: nil,
                in_closed_grading_period: false,
                override_id: nil,
                override_source: "Everyone Else"
              },
              @student3.id => {
                due_at: 19.days.ago(@now),
                grading_period_id: gp.id,
                in_closed_grading_period: true,
                override_id: override.id,
                override_source: "ADHOC"
              }
            }
          }
          expect(result).to eq expected
        end

        it "truncates seconds when comparing override due dates to grading period dates" do
          end_date = 15.days.ago(@now)
          grading_period = Factories::GradingPeriodHelper.new.create_for_group(
            @gp_group,
            start_date: 20.days.ago(@now),
            end_date:,
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

        it "ignores soft-deleted grading period groups" do
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
                override_source: "Everyone Else"
              },
              @student2.id => {
                due_at: 17.days.ago(@now),
                grading_period_id: nil,
                in_closed_grading_period: false,
                override_id: nil,
                override_source: "Everyone Else"
              },
              @student3.id => {
                due_at: 17.days.ago(@now),
                grading_period_id: nil,
                in_closed_grading_period: false,
                override_id: nil,
                override_source: "Everyone Else"
              }
            }
          }
          expect(result).to eq expected
        end

        it "ignores soft-deleted grading periods" do
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
                override_source: "Everyone Else"
              },
              @student2.id => {
                due_at: 17.days.ago(@now),
                grading_period_id: nil,
                in_closed_grading_period: false,
                override_id: nil,
                override_source: "Everyone Else"
              },
              @student3.id => {
                due_at: 17.days.ago(@now),
                grading_period_id: nil,
                in_closed_grading_period: false,
                override_id: nil,
                override_source: "Everyone Else"
              }
            }
          }
          expect(result).to eq expected
        end

        describe "in_closed_grading_period attribute" do
          it "is true if the associated grading period is closed" do
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
                  override_source: "Everyone Else"
                },
                @student2.id => {
                  due_at: 17.days.ago(@now),
                  grading_period_id: gp.id,
                  in_closed_grading_period: true,
                  override_id: nil,
                  override_source: "Everyone Else"
                },
                @student3.id => {
                  due_at: 17.days.ago(@now),
                  grading_period_id: gp.id,
                  in_closed_grading_period: true,
                  override_id: nil,
                  override_source: "Everyone Else"
                }
              }
            }
            expect(result).to eq expected
          end

          it "is false if the associated grading period is open" do
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
                  override_source: "Everyone Else"
                },
                @student2.id => {
                  due_at: 17.days.ago(@now),
                  grading_period_id: gp.id,
                  in_closed_grading_period: false,
                  override_id: nil,
                  override_source: "Everyone Else"
                },
                @student3.id => {
                  due_at: 17.days.ago(@now),
                  grading_period_id: gp.id,
                  in_closed_grading_period: false,
                  override_id: nil,
                  override_source: "Everyone Else"
                }
              }
            }
            expect(result).to eq expected
          end

          it "is false if the due date does not fall in a grading period" do
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
                  override_source: "Everyone Else"
                },
                @student2.id => {
                  due_at: 12.days.ago(@now),
                  grading_period_id: nil,
                  in_closed_grading_period: false,
                  override_id: nil,
                  override_source: "Everyone Else"
                },
                @student3.id => {
                  due_at: 12.days.ago(@now),
                  grading_period_id: nil,
                  in_closed_grading_period: false,
                  override_id: nil,
                  override_source: "Everyone Else"
                }
              }
            }
            expect(result).to eq expected
          end

          it "is true if the due date is null and the last grading period is closed" do
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
                  override_source: "Everyone Else"
                },
                @student2.id => {
                  due_at: nil,
                  grading_period_id: gp.id,
                  in_closed_grading_period: true,
                  override_id: nil,
                  override_source: "Everyone Else"
                },
                @student3.id => {
                  due_at: nil,
                  grading_period_id: gp.id,
                  in_closed_grading_period: true,
                  override_id: nil,
                  override_source: "Everyone Else"
                }
              }
            }
            expect(result).to eq expected
          end

          it "is false if the due date is null and the last grading period is open" do
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
                  override_source: "Everyone Else"
                },
                @student2.id => {
                  due_at: nil,
                  grading_period_id: gp.id,
                  in_closed_grading_period: false,
                  override_id: nil,
                  override_source: "Everyone Else"
                },
                @student3.id => {
                  due_at: nil,
                  grading_period_id: gp.id,
                  in_closed_grading_period: false,
                  override_id: nil,
                  override_source: "Everyone Else"
                }
              }
            }
            expect(result).to eq expected
          end
        end
      end

      it "ignores not-assigned students with existing graded submissions" do
        @assignment1.grade_student(@student1, grade: 5, grader: @teacher)

        edd = EffectiveDueDates.for_course(@test_course, @assignment1)
        result = edd.to_hash
        expect(result).to be_empty
      end

      it "prioritizes the Everyone Else due date if it exists over the submission NULL date" do
        @assignment2.due_at = 4.days.from_now(@now)
        @assignment2.save!
        @assignment2.grade_student(@student1, grade: 5, grader: @teacher)
        @assignment2.submissions.find_by!(user: @student1).update!(
          submitted_at: 1.week.from_now(@now),
          submission_type: "online_text_entry"
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
              override_source: "Everyone Else"
            },
            @student2.id => {
              due_at: 4.days.from_now(@now),
              grading_period_id: nil,
              in_closed_grading_period: false,
              override_id: nil,
              override_source: "Everyone Else"
            },
            @student3.id => {
              due_at: 4.days.from_now(@now),
              grading_period_id: nil,
              in_closed_grading_period: false,
              override_id: nil,
              override_source: "Everyone Else"
            }
          }
        }
        expect(result).to eq expected
      end

      it "ignores not-assigned students with ungraded submissions" do
        @assignment1.all_submissions.find_by!(user: @student1).update!(
          submission_type: "online_text_entry",
          workflow_state: "submitted"
        )

        edd = EffectiveDueDates.for_course(@test_course, @assignment1)
        expect(edd.to_hash).to eq({})
      end

      it "returns all students in the course if the assignment is assigned to everybody" do
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
              override_source: "Everyone Else"
            },
            @student2.id => {
              due_at: 4.days.from_now(@now),
              grading_period_id: nil,
              in_closed_grading_period: false,
              override_id: nil,
              override_source: "Everyone Else"
            },
            @student3.id => {
              due_at: 4.days.from_now(@now),
              grading_period_id: nil,
              in_closed_grading_period: false,
              override_id: nil,
              override_source: "Everyone Else"
            }
          }
        }
        expect(result).to eq expected
      end
    end
  end

  context "grading periods" do
    before(:once) do
      @now = Time.zone.now.change(sec: 0)
      @test_course = Course.create!
      @student1 = student_in_course(course: @test_course, active_all: true, name: "Grading Periods Student 1").user
      @student2 = student_in_course(course: @test_course, active_all: true, name: "Grading Periods Student 2").user
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

    describe "#any_in_closed_grading_period?" do
      it "returns false if there are no grading periods" do
        @assignment2.due_at = 17.days.ago(@now)
        @assignment2.only_visible_to_overrides = false
        @assignment2.save!

        expect(@test_course).to receive(:grading_periods?).and_return false
        edd = EffectiveDueDates.for_course(@test_course)
        expect(edd).not_to receive(:to_hash)
        expect(edd.any_in_closed_grading_period?).to be(false)
      end

      context "with grading periods" do
        it "returns true if any students in any assignments have a due date in a closed grading period" do
          @assignment2.due_at = 1.day.ago(@now)
          @assignment2.only_visible_to_overrides = false
          @assignment2.save!
          override = @assignment2.assignment_overrides.create!(due_at: 19.days.ago(@now), due_at_overridden: true)
          override.assignment_override_students.create!(user: @student2)

          edd = EffectiveDueDates.for_course(@test_course)
          expect(edd.any_in_closed_grading_period?).to be(true)
        end

        it "returns false if no student in any assignments has a due date in a closed grading period" do
          @assignment2.due_at = 1.day.ago(@now)
          @assignment2.only_visible_to_overrides = false
          @assignment2.save!
          override = @assignment2.assignment_overrides.create!(due_at: 2.days.ago(@now), due_at_overridden: true)
          override.assignment_override_students.create!(user: @student2)

          edd = EffectiveDueDates.for_course(@test_course)
          expect(edd.any_in_closed_grading_period?).to be(false)
        end

        it "memoizes the result" do
          edd = EffectiveDueDates.for_course(@test_course)
          expect(edd).to receive(:to_hash).once.and_return({})
          2.times { edd.any_in_closed_grading_period? }
        end
      end
    end

    describe "#grading_period_id_for" do
      it "returns the grading_period_id for the given student and assignment" do
        @assignment1.update!(due_at: 2.days.from_now(@grading_period.start_date))
        effective_due_dates = EffectiveDueDates.new(@test_course, @assignment1.id)
        grading_period_id = effective_due_dates.grading_period_id_for(
          student_id: @student1.id,
          assignment_id: @assignment1.id
        )
        expect(grading_period_id).to eq(@grading_period.id)
      end

      it "returns nil if there if the given student and assignment do not fall in a grading period" do
        effective_due_dates = EffectiveDueDates.new(@test_course, @assignment1.id)
        grading_period_id = effective_due_dates.grading_period_id_for(
          student_id: @student1.id,
          assignment_id: @assignment1.id
        )
        expect(grading_period_id).to be_nil
      end

      it "returns nil if the assignment is not assigned to the student" do
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

    describe "#in_closed_grading_period?" do
      it "returns false if there are no grading periods" do
        @assignment2.due_at = 17.days.ago(@now)
        @assignment2.only_visible_to_overrides = false
        @assignment2.save!

        expect(@test_course).to receive(:grading_periods?).and_return false
        edd = EffectiveDueDates.for_course(@test_course)
        expect(edd).not_to receive(:to_hash)
        expect(edd.in_closed_grading_period?(@assignment2)).to be(false)
      end

      it "returns false if assignment id is nil" do
        edd = EffectiveDueDates.for_course(@test_course, @assignment1)
        expect(edd).not_to receive(:to_hash)
        expect(edd.in_closed_grading_period?(nil)).to be(false)
      end

      context "with grading periods" do
        before do
          @assignment2.due_at = 1.day.ago(@now)
          @assignment2.only_visible_to_overrides = false
          @assignment2.save!
          override = @assignment2.assignment_overrides.create!(due_at: 19.days.ago(@now), due_at_overridden: true)
          override.assignment_override_students.create!(user: @student2)

          @edd = EffectiveDueDates.for_course(@test_course)
        end

        it "returns true if any students in the given assignment have a due date in a closed grading period" do
          expect(@edd.in_closed_grading_period?(@assignment2)).to be(true)
        end

        it "accepts assignment id as the argument" do
          expect(@edd.in_closed_grading_period?(@assignment2.id)).to be(true)
        end

        it "returns false if no student in the given assignment has a due date in a closed grading period" do
          expect(@edd.in_closed_grading_period?(@assignment1)).to be(false)
        end

        it "returns true if the specified student has a due date for this assignment" do
          expect(@edd.in_closed_grading_period?(@assignment2, @student2)).to be true
          expect(@edd.in_closed_grading_period?(@assignment2, @student2.id)).to be true
        end

        it "raises error if the specified student was filtered out of the query" do
          expect { @edd.filter_students_to(@student1).in_closed_grading_period?(@assignment2, @student2) }
            .to raise_error("Student #{@student2.id} was not included in this query")
        end

        it "returns true if the specified student was included in the query and has a due date for this assignment" do
          expect(@edd.filter_students_to(@student2).in_closed_grading_period?(@assignment2, @student2)).to be true
        end

        it "returns false if the specified student has a due date in an open grading period" do
          override = @assignment2.assignment_overrides.create!(due_at: 1.day.from_now(@now), due_at_overridden: true)
          override.assignment_override_students.create!(user: @student1)

          expect(@edd.in_closed_grading_period?(@assignment2, @student1)).to be false
          expect(@edd.in_closed_grading_period?(@assignment2, @student1.id)).to be false
        end

        it "returns false if the specified student does not have a due date for this assignment" do
          @other_course = Course.create!
          @student_in_other_course = student_in_course(course: @other_course, active_all: true, name: "Grading Periods Student in other course").user

          expect(@edd.in_closed_grading_period?(@assignment2, @student_in_other_course)).to be false
          expect(@edd.in_closed_grading_period?(@assignment2, @student_in_other_course.id)).to be false
        end
      end
    end
  end
end
