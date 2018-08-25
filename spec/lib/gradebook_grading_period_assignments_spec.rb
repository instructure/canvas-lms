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

require File.expand_path(File.dirname(__FILE__) + "/../spec_helper.rb")

describe GradebookGradingPeriodAssignments do
  before(:once) do
    @example_course = Course.create!
  end

  describe "#to_h" do
    before(:once) do
      @student1 = student_in_course(course: @example_course, active_all: true).user
      @student2 = student_in_course(course: @example_course, active_all: true).user
      @assignment1_in_gp1 = @example_course.assignments.create!(due_at: 3.months.ago)
      @assignment2_in_gp2 = @example_course.assignments.create!(due_at: 1.day.from_now)
      @assignment3_in_gp2 = @example_course.assignments.create!(due_at: 2.days.from_now)
      @assignment4 = @example_course.assignments.create!(due_at: 6.months.from_now)
    end

    let(:hash) { GradebookGradingPeriodAssignments.new(@example_course, {}).to_h }

    context "with grading periods" do
      before(:once) do
        @group = Factories::GradingPeriodGroupHelper.new.create_for_account(@example_course.account)
        @group.enrollment_terms << @example_course.enrollment_term
        @period1, @period2, @period3 = Factories::GradingPeriodHelper.new.create_presets_for_group(
          @group, :past, :current, :future
        )
        [@assignment1_in_gp1, @assignment2_in_gp2, @assignment3_in_gp2, @assignment4].each do |assignment|
          DueDateCacher.recompute(assignment)
        end
      end

      it "includes the grading period ids as keys on the hash" do
        @example_course.assignments.create!(due_at: 3.months.from_now)
        expect(hash.keys).to match_array([@period1.id, @period2.id, @period3.id])
      end

      it "lists the related assignment ids as strings for the grading periods" do
        expect(hash[@period1.id]).to match_array([@assignment1_in_gp1.id.to_s])
      end

      it "includes all assignments due in a given grading period" do
        expect(hash[@period2.id]).to include(@assignment2_in_gp2.id.to_s)
        expect(hash[@period2.id]).to include(@assignment3_in_gp2.id.to_s)
      end

      it "includes assignments with due dates in multiple grading periods" do
        override = @assignment1_in_gp1.assignment_overrides.create!(due_at: 1.day.ago, due_at_overridden: true)
        override.assignment_override_students.create!(user: @student2)
        expect(hash[@period1.id]).to include(@assignment1_in_gp1.id.to_s)
        expect(hash[@period2.id]).to include(@assignment1_in_gp1.id.to_s)
      end

      it "excludes assignments due outside of any grading period" do
        expect(hash[@period1.id]).not_to include(@assignment4.id.to_s)
        expect(hash[@period2.id]).not_to include(@assignment4.id.to_s)
      end

      it "excludes grading periods without assignments" do
        expect(hash.keys).not_to include(@period3.id)
      end

      it "excludes deleted submissions" do
        assignment_in_gp2 = @example_course.assignments.create!(due_at: 1.day.from_now)
        assignment_in_gp2.destroy
        assignment_in_gp2.submissions.preload(:all_submission_comments, :lti_result, :versions).map(&:destroy)
        expect(hash[@period2.id]).not_to include(assignment_in_gp2.id.to_s)
      end

      it "excludes submissions for deleted assignments" do
        assignment_in_gp2 = @example_course.assignments.create!(due_at: 1.day.from_now)
        assignment_in_gp2.destroy
        expect(hash[@period2.id]).not_to include(assignment_in_gp2.id.to_s)
      end

      it "excludes assignments from other courses" do
        course = Course.create!
        student_in_course(course: course, active_all: true).user
        @group.enrollment_terms << course.enrollment_term
        assignment = course.assignments.create!(due_at: 1.day.from_now)
        expect(hash[@period2.id]).not_to include(assignment.id.to_s)
      end

      context 'with students that are not active' do
        before(:once) do
          @course = Course.create!
          @student_enrollment = student_in_course(course: @course, active_all: true)
          @assignment = @course.assignments.create!(due_at: @period2.end_date)
          @settings = {}
        end

        let(:hash) { GradebookGradingPeriodAssignments.new(@course, @settings).to_h }


        describe 'concluded students' do
          before(:once) do
            @student_enrollment.conclude
          end

          it 'does not include assignments assigned exclusively to concluded students' do
            expect(hash[@period2.id]).to be_nil
          end

          it 'ignores deleted enrollments' do
            # update_columns in order to avoid callbacks that would soft-delete the submission
            @student_enrollment.update_columns(workflow_state: :deleted)
            expect(hash[@period2.id]).to be_nil
          end

          it 'ignores enrollments in other courses' do
            new_course = Course.create!
            new_course.enroll_student(@student_enrollment.user, active_all: true)
            expect(hash[@period2.id]).to be_nil
          end

          it 'ignores non-student enrollments' do
            @course.enroll_ta(@student_enrollment.user, active_all: true)
            expect(hash[@period2.id]).to be_nil
          end

          it 'optionally includes assignments assigned exclusively to concluded students' do
            @settings[@course.id] = { 'show_concluded_enrollments' => 'true' }
            expect(hash[@period2.id]).to include @assignment.id.to_s
          end

          it 'optionally excludes assignments assigned exclusively to concluded students' do
            @settings[@course.id] = { 'show_concluded_enrollments' => 'false' }
            expect(hash[@period2.id]).to be_nil
          end
        end

        describe 'deactivated students' do
          before(:once) do
            @student_enrollment.deactivate
          end

          it 'does not include assignments assigned exclusively to deactivated students' do
            expect(hash[@period2.id]).to be_nil
          end

          it 'ignores deleted enrollments' do
            # update_columns in order to avoid callbacks that would soft-delete the submission
            @student_enrollment.update_columns(workflow_state: :deleted)
            expect(hash[@period2.id]).to be_nil
          end

          it 'ignores enrollments in other courses' do
            new_course = Course.create!
            new_course.enroll_student(@student_enrollment.user, active_all: true)
            expect(hash[@period2.id]).to be_nil
          end

          it 'ignores non-student enrollments' do
            @course.enroll_ta(@student_enrollment.user, active_all: true)
            expect(hash[@period2.id]).to be_nil
          end

          it 'optionally includes assignments assigned exclusively to deactivated students' do
            @settings[@course.id] = { 'show_inactive_enrollments' => 'true' }
            expect(hash[@period2.id]).to include @assignment.id.to_s
          end

          it 'optionally excludes assignments assigned exclusively to deactivated students' do
            @settings[@course.id] = { 'show_inactive_enrollments' => 'false' }
            expect(hash[@period2.id]).to be_nil
          end
        end
      end
    end

    it "returns an empty hash when grading periods are not in use" do
      expect(hash).to eq({})
    end
  end

  it "raises an exception if context is not a course" do
    expect { GradebookGradingPeriodAssignments.new({}, {}) }.to raise_error("Context must be a course")
  end

  it "raises an exception if context has no id" do
    expect { GradebookGradingPeriodAssignments.new(Course.new, {}) }.to raise_error("Context must have an id")
  end
end
