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

    let(:hash) { GradebookGradingPeriodAssignments.new(@example_course).to_h }

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
        assignment_in_gp2.submissions.map(&:destroy)
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
    end

    it "returns an empty hash when grading periods are not in use" do
      expect(hash).to eq({})
    end
  end

  it "raises an exception if context is not a course" do
    expect { GradebookGradingPeriodAssignments.new({}) }.to raise_error("Context must be a course")
  end

  it "raises an exception if context has no id" do
    expect { GradebookGradingPeriodAssignments.new(Course.new) }.to raise_error("Context must have an id")
  end
end
