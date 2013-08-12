#
# Copyright (C) 2013 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../sharding_spec_helper.rb')

describe DueDateCacher do
  before do
    course_with_student(:active_all => true)
    assignment_model(:course => @course)
  end

  describe ".recompute" do
    before do
      @instance = stub('instance', :recompute => nil)
      @new_expectation = DueDateCacher.expects(:new).returns(@instance)
    end

    it "should wrap assignment in an array" do
      @new_expectation.with([@assignment])
      DueDateCacher.recompute(@assignment)
    end

    it "should delegate to an instance" do
      @instance.expects(:recompute)
      DueDateCacher.recompute(@assignment)
    end

    it "should queue a delayed job on an assignment-specific singleton strand in production" do
      @instance.expects(:send_later_if_production_enqueue_args).
        with(:recompute, :singleton => "cached_due_date:calculator:#{@assignment.global_id}")
      DueDateCacher.recompute(@assignment)
    end
  end

  describe ".recompute_batch" do
    before do
      @assignments = [@assignment]
      @assignments << assignment_model(:course => @course)
      @instance = stub('instance', :recompute => nil)
      @new_expectation = DueDateCacher.expects(:new).returns(@instance)
    end

    it "should pass along the whole array" do
      @new_expectation.with(@assignments)
      DueDateCacher.recompute_batch(@assignments)
    end

    it "should delegate to an instance" do
      @instance.expects(:recompute)
      DueDateCacher.recompute_batch(@assignments)
    end

    it "should queue a delayed job on a batch-specific singleton strand in production" do
      @instance.expects(:send_later_if_production_enqueue_args).
        with(:recompute, :strand => "cached_due_date:calculator:batch:#{Shard.current.id}",
             :priority => Delayed::LOWER_PRIORITY)
      DueDateCacher.recompute_batch(@assignments)
    end
  end

  describe "#recompute" do
    before do
      @cacher = DueDateCacher.new([@assignment])
      submission_model(:assignment => @assignment, :user => @student)
      Submission.update_all(:cached_due_date => nil)
    end

    context "no overrides" do
      it "should set the cached_due_date to the assignment due_at" do
        @assignment.due_at += 1.day
        @assignment.save!

        @cacher.recompute
        @submission.reload.cached_due_date.should == @assignment.due_at
      end

      it "should set the cached_due_date to nil if the assignment has no due_at" do
        @assignment.due_at = nil
        @assignment.save!

        @cacher.recompute
        @submission.reload.cached_due_date.should be_nil
      end
    end

    context "one applicable override" do
      before do
        assignment_override_model(
          :assignment => @assignment,
          :set => @course.default_section)
      end

      it "should prefer override's due_at over assignment's due_at" do
        @override.override_due_at(@assignment.due_at - 1.day)
        @override.save!

        @cacher.recompute
        @submission.reload.cached_due_date.should == @override.due_at
      end

      it "should prefer override's due_at over assignment's nil" do
        @override.override_due_at(@assignment.due_at - 1.day)
        @override.save!

        @assignment.due_at = nil
        @assignment.save!

        @cacher.recompute
        @submission.reload.cached_due_date.should == @override.due_at
      end

      it "should prefer override's nil over assignment's due_at" do
        @override.override_due_at(nil)
        @override.save!

        @cacher.recompute
        @submission.reload.cached_due_date.should == @override.due_at
      end

      it "should not apply override if it doesn't override due_at" do
        @override.clear_due_at_override
        @override.save!

        @cacher.recompute
        @submission.reload.cached_due_date.should == @assignment.due_at
      end
    end

    context "adhoc override" do
      before do
        @student1 = @student
        @student2 = user
        @course.enroll_student(@student2, :enrollment_state => 'active')

        assignment_override_model(
          :assignment => @assignment,
          :due_at => @assignment.due_at + 1.day)
        @override.assignment_override_students.create!(:user => @student2)

        @submission1 = @submission
        @submission2 = submission_model(:assignment => @assignment, :user => @student2)
        Submission.update_all(:cached_due_date => nil)

        @cacher.recompute
      end

      it "should apply to students in the adhoc set" do
        @submission2.reload.cached_due_date.should == @override.due_at
      end

      it "should not apply to students not in the adhoc set" do
        @submission1.reload.cached_due_date.should == @assignment.due_at
      end
    end

    context "section override" do
      before do
        @student1 = @student
        @student2 = user

        add_section('second section')
        @course.enroll_student(@student2, :enrollment_state => 'active', :section => @course_section)

        assignment_override_model(
          :assignment => @assignment,
          :due_at => @assignment.due_at + 1.day,
          :set => @course_section)

        @submission1 = @submission
        @submission2 = submission_model(:assignment => @assignment, :user => @student2)
        Submission.update_all(:cached_due_date => nil)

        @cacher.recompute
      end

      it "should apply to students in that section" do
        @submission2.reload.cached_due_date.should == @override.due_at
      end

      it "should not apply to students in other sections" do
        @submission1.reload.cached_due_date.should == @assignment.due_at
      end

      it "should not apply to non-active enrollments in that section" do
        @course.enroll_student(@student1,
          :enrollment_state => 'deleted',
          :section => @course_section,
          :allow_multiple_enrollments => true)
        @submission1.reload.cached_due_date.should == @assignment.due_at
      end
    end

    context "group override" do
      before do
        @student1 = @student
        @student2 = user
        @course.enroll_student(@student2, :enrollment_state => 'active')

        @assignment.group_category = group_category
        @assignment.save!

        group_with_user(
          :group_context => @course,
          :group_category => @assignment.group_category,
          :user => @student2,
          :active_all => true)

        assignment_override_model(
          :assignment => @assignment,
          :due_at => @assignment.due_at + 1.day,
          :set => @group)

        @submission1 = @submission
        @submission2 = submission_model(:assignment => @assignment, :user => @student2)
        Submission.update_all(:cached_due_date => nil)

        @cacher.recompute
      end

      it "should apply to students in that group" do
        @submission2.reload.cached_due_date.should == @override.due_at
      end

      it "should not apply to students not in the group" do
        @submission1.reload.cached_due_date.should == @assignment.due_at
      end

      it "should not apply to non-active memberships in that group" do
        @group.add_user(@student1, 'deleted')
        @submission1.reload.cached_due_date.should == @assignment.due_at
      end
    end

    context "multiple overrides" do
      before do
        add_section('second section')
        multiple_student_enrollment(@student, @course_section)

        @override1 = assignment_override_model(
          :assignment => @assignment,
          :due_at => @assignment.due_at + 1.day,
          :set => @course.default_section)

        @override2 = assignment_override_model(
          :assignment => @assignment,
          :due_at => @assignment.due_at + 1.day,
          :set => @course_section)
      end

      it "should prefer first override's due_at if latest" do
        @override1.override_due_at(@assignment.due_at + 2.days)
        @override1.save!

        @cacher.recompute
        @submission.reload.cached_due_date.should == @override1.due_at
      end

      it "should prefer second override's due_at if latest" do
        @override2.override_due_at(@assignment.due_at + 2.days)
        @override2.save!

        @cacher.recompute
        @submission.reload.cached_due_date.should == @override2.due_at
      end

      it "should be nil if first override's nil" do
        @override1.override_due_at(nil)
        @override1.save!

        @cacher.recompute
        @submission.reload.cached_due_date.should be_nil
      end

      it "should be nil if second override's nil" do
        @override2.override_due_at(nil)
        @override2.save!

        @cacher.recompute
        @submission.reload.cached_due_date.should be_nil
      end
    end

    context "multiple submissions with selective overrides" do
      before do
        @student1 = @student
        @student2 = user
        @student3 = user

        add_section('second section')
        @course.enroll_student(@student2, :enrollment_state => 'active', :section => @course_section)
        @course.enroll_student(@student3, :enrollment_state => 'active')
        multiple_student_enrollment(@student3, @course_section)

        @override1 = assignment_override_model(
          :assignment => @assignment,
          :due_at => @assignment.due_at + 2.days,
          :set => @course.default_section)

        @override2 = assignment_override_model(
          :assignment => @assignment,
          :due_at => @assignment.due_at + 2.days,
          :set => @course_section)

        @submission1 = @submission
        @submission2 = submission_model(:assignment => @assignment, :user => @student2)
        @submission3 = submission_model(:assignment => @assignment, :user => @student3)
        Submission.update_all(:cached_due_date => nil)
      end

      it "should use first override where second doesn't apply" do
        @override1.override_due_at(@assignment.due_at + 1.day)
        @override1.save!

        @cacher.recompute
        @submission1.reload.cached_due_date.should == @override1.due_at
      end

      it "should use second override where the first doesn't apply" do
        @override2.override_due_at(@assignment.due_at + 1.day)
        @override2.save!

        @cacher.recompute
        @submission2.reload.cached_due_date.should == @override2.due_at
      end

      it "should use the best override where both apply" do
        @override1.override_due_at(@assignment.due_at + 1.day)
        @override1.save!

        @cacher.recompute
        @submission2.reload.cached_due_date.should == @override2.due_at
      end
    end

    context "multiple assignments, only one overridden" do
      before do
        @assignment1 = @assignment
        @assignment2 = assignment_model(:course => @course)

        assignment_override_model(
          :assignment => @assignment1,
          :due_at => @assignment1.due_at + 1.day)
        @override.assignment_override_students.create!(:user => @student)

        @submission1 = @submission
        @submission2 = submission_model(:assignment => @assignment2, :user => @student)
        Submission.update_all(:cached_due_date => nil)

        DueDateCacher.new([@assignment1, @assignment2]).recompute
      end

      it "should apply to submission on the overridden assignment" do
        @submission1.reload.cached_due_date.should == @override.due_at
      end

      it "should not apply to apply to submission on the other assignment" do
        @submission2.reload.cached_due_date.should == @assignment.due_at
      end
    end
  end
end
