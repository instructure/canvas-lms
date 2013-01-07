
#
# Copyright (C) 2012 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

shared_examples_for "an object whose dates are overridable" do
  # let(:overridable) - an Assignment or Quiz
  # let(:overridable_type) - :assignment or :quiz

  let(:course) { overridable.context }
  let(:override) { assignment_override_model(overridable_type => overridable) }

  describe "overridden_for" do
    before do
      student_in_course(:course => course)
    end

    context "when there are overrides" do
      before do
        override.override_due_at(7.days.from_now)
        override.save!

        override_student = override.assignment_override_students.build
        override_student.user = @student
        override_student.save!
      end

      it "returns a clone of the object with the relevant override(s) applied" do
        overridden = overridable.overridden_for(@student)
        overridden.due_at.should == override.due_at
      end
    end

    context "with no overrides" do
      it "returns the original object" do
        @overridden = overridable.overridden_for(@student)
        @overridden.due_at.should == overridable.due_at
      end
    end
  end

  describe "has_overrides?" do
    subject { overridable.has_overrides? }

    context "when it does" do
      before { override }
      it { should be_true }
    end

    context "when it doesn't" do
      it { should be_false }
    end
  end

  describe "#overrides_visible_to(user)" do
    before :each do
      override.set = course.default_section
      override.save!
    end

    it "delegates to visible_to on the active overrides by default" do
      @expected_value = stub("expected value")
      overridable.active_assignment_overrides.expects(:visible_to).with(@teacher, course).returns(@expected_value)
      overridable.overrides_visible_to(@teacher).should == @expected_value
    end

    it "allows overriding the scope" do
      override.destroy
      overridable.overrides_visible_to(@teacher).should be_empty
      overridable.overrides_visible_to(@teacher, overridable.assignment_overrides(true)).should == [override]
    end

    it "skips the visible_to application if the scope is already empty" do
      override.destroy
      overridable.active_assignment_overrides.expects(:visible_to).times(0)
      overridable.overrides_visible_to(@teacher)
    end

    it "returns a scope" do
      # can't use "should respond_to", because that delegates to the instantiated Array
      lambda{ overridable.overrides_visible_to(@teacher).scoped({}) }.should_not raise_exception
    end
  end

  describe "#due_dates_for(user)" do
    before :each do
      course_with_student(:course => course)

      override.set = course.default_section
      override.override_due_at(2.days.ago)
      override.save!
    end

    context "for a student" do
      before do
        @as_student, @as_instructor = overridable.due_dates_for(@student)
      end

      it "does not return instructor dates" do
        @as_instructor.should be_nil
      end

      it "returns a relevant student date" do
        @as_student.should_not be_nil
      end
    end

    context "for a teacher" do
      before do
        @as_student, @as_instructor = overridable.due_dates_for(@teacher)
      end

      it "does not return a student date" do
        @as_student.should be_nil
      end

      it "returns a list of instructor dates" do
        @as_instructor.should_not be_nil
      end
    end

    it "returns both for a user that's both a student and a teacher" do
      course_with_ta(:course => course, :user => @student, :active_all => true)
      as_student, as_instructor = overridable.due_dates_for(@student)
      as_student.should_not be_nil
      as_instructor.should_not be_nil
    end

    it "uses the overridden due date as the applicable due date" do
      as_student, _ = overridable.due_dates_for(@student)
      as_student[:due_at].should == override.due_at

      if overridable.is_a?(Assignment)
        as_student[:all_day].should == override.all_day
        as_student[:all_day_date].should == override.all_day_date
      end
    end

    it "includes the base due date in the list of due dates" do
      _, as_instructor = overridable.due_dates_for(@teacher)

      expected_params = { :base => true, :due_at => overridable.due_at }

      if overridable.is_a?(Assignment)
        expected_params.merge!({
          :all_day => overridable.all_day,
          :all_day_date => overridable.all_day_date
        })
      end

      as_instructor.should include expected_params
    end

    it "includes visible due date overrides in the list of due dates" do
      _, as_instructor = overridable.due_dates_for(@teacher)
      as_instructor.should include({
        :title => @course.default_section.name,
        :due_at => override.due_at,
        :all_day => override.all_day,
        :all_day_date => override.all_day_date,
        :override => override
      })
    end

    it "excludes visible overrides that don't override due_at from the list of due dates" do
      override.clear_due_at_override
      override.save!

      _, as_instructor = overridable.due_dates_for(@teacher)
      as_instructor.size.should == 1
      as_instructor.first[:base].should be_true
    end

    it "excludes overrides that aren't visible from the list of due dates" do
      @enrollment = @teacher.enrollments.first
      @enrollment.limit_privileges_to_course_section = true
      @enrollment.save!

      @section2 = course.course_sections.create!
      override.set = @section2
      override.save!

      _, as_instructor = overridable.due_dates_for(@teacher)
      as_instructor.size.should == 1
      as_instructor.first[:base].should be_true
    end
  end

  describe "due_date_hash" do
    it "returns the due at, all day, and all day date params" do
      due = 5.days.from_now
      a = Assignment.new(:due_at => due)
      a.due_date_hash.should == { :due_at => due, :all_day => false, :all_day_date => nil }
    end
  end

  describe "observed_student_due_dates" do
    it "returns a list of overridden due date hashes" do
      a = Assignment.new
      u = User.new
      student1, student2 = [mock, mock]

      { student1 => '1', student2 => '2' }.each do |student, value|
        a.expects(:overridden_for).with(student).returns \
          mock(:due_date_hash => { :student => value })
      end
      
      ObserverEnrollment.expects(:observed_students).returns({student1 => [], student2 => []})

      override_hashes = a.observed_student_due_dates(u)
      override_hashes.should =~ [ { :student => '1' }, { :student => '2' } ]
    end
  end

  describe "#unlock_ats_for(user)" do
    before :each do
      course_with_student(:course => course, :active_all => true)

      overridable.update_attributes(:unlock_at => 2.days.ago)

      override.set = course.default_section
      override.override_unlock_at(5.days.ago)
      override.save!
    end

    context "for a student" do
      before do
        @as_student, @as_instructor = overridable.unlock_ats_for(@student)
      end

      it "does not return instructor dates" do
        @as_instructor.should be_nil
      end

      it "returns a relevant student date" do
        @as_student.should_not be_nil
      end
    end

    context "for a teacher" do
      before do
        @as_student, @as_instructor = overridable.unlock_ats_for(@teacher)
      end

      it "does not return a student date" do
        @as_student.should be_nil
      end

      it "returns a list of instructor dates" do
        @as_instructor.should_not be_nil
      end
    end

    it "returns both for a user that's both a student and a teacher" do
      course_with_ta(:course => course, :user => @student, :active_all => true)
      as_student, as_instructor = overridable.unlock_ats_for(@student)
      as_student.should_not be_nil
      as_instructor.should_not be_nil
    end

    it "uses the overridden unlock date as the applicable unlock date" do
      as_student, _ = overridable.unlock_ats_for(@student)
      as_student.should == { :unlock_at => override.unlock_at }
    end

    it "includes the base unlock date in the list of unlock dates" do
      _, as_instructor = overridable.unlock_ats_for(@teacher)
      as_instructor.should include({ :base => true, :unlock_at => overridable.unlock_at })
    end

    it "includes visible unlock date overrides in the list of unlock dates" do
      _, as_instructor = overridable.unlock_ats_for(@teacher)
      as_instructor.should include({
        :title => @course.default_section.name,
        :unlock_at => override.unlock_at,
        :override => override
      })
    end

    it "excludes visible overrides that don't override unlock_at from the list of unlock dates" do
      override.clear_unlock_at_override
      override.save!

      _, as_instructor = overridable.unlock_ats_for(@teacher)
      as_instructor.size.should == 1
      as_instructor.first[:base].should be_true
    end

    it "excludes overrides that aren't visible from the list of unlock dates" do
      @enrollment = @teacher.enrollments.first
      @enrollment.limit_privileges_to_course_section = true
      @enrollment.save!

      @section2 = @course.course_sections.create!
      override.set = @section2
      override.save!

      _, as_instructor = overridable.unlock_ats_for(@teacher)
      as_instructor.size.should == 1
      as_instructor.first[:base].should be_true
    end
  end

  describe "#lock_ats_for(user)" do
    before :each do
      course_with_student(:course => course, :active_all => true)

      overridable.update_attributes(:unlock_at => 5.days.ago)

      override.set = course.default_section
      override.override_lock_at(2.days.ago)
      override.save!
    end

    context "for a student" do
      before do
        @as_student, @as_instructor = overridable.lock_ats_for(@student)
      end

      it "does not return instructor dates" do
        @as_instructor.should be_nil
      end

      it "returns a relevant student date" do
        @as_student.should_not be_nil
      end
    end

    context "for a teacher" do
      before do
        @as_student, @as_instructor = overridable.lock_ats_for(@teacher)
      end

      it "does not return a student date" do
        @as_student.should be_nil
      end

      it "returns a list of instructor dates" do
        @as_instructor.should_not be_nil
      end
    end

    it "returns both for a user that's both a student and a teacher" do
      course_with_ta(:course => course, :user => @student, :active_all => true)
      as_student, as_instructor = overridable.lock_ats_for(@student)
      as_student.should_not be_nil
      as_instructor.should_not be_nil
    end

    it "uses the overridden lock date as the applicable lock date" do
      as_student, _ = overridable.lock_ats_for(@student)
      as_student.should == { :lock_at => override.lock_at }
    end

    it "includes the base lock date in the list of lock dates" do
      _, as_instructor = overridable.lock_ats_for(@teacher)
      as_instructor.should include({ :base => true, :lock_at => overridable.lock_at })
    end

    it "includes visible lock date overrides in the list of lock dates" do
      _, as_instructor = overridable.lock_ats_for(@teacher)
      as_instructor.detect { |a| a[:override].present? }.should == {
        :title => course.default_section.name,
        :lock_at => override.lock_at,
        :override => override
      }
    end

    it "excludes visible overrides that don't override lock_at from the list of lock dates" do
      override.clear_lock_at_override
      override.save!

      _, as_instructor = overridable.lock_ats_for(@teacher)
      as_instructor.size.should == 1
      as_instructor.first[:base].should be_true
    end

    it "excludes overrides that aren't visible from the list of lock dates" do
      @enrollment = @teacher.enrollments.first
      @enrollment.limit_privileges_to_course_section = true
      @enrollment.save!

      @section2 = course.course_sections.create!
      override.set = @section2
      override.save!

      _, as_instructor = overridable.lock_ats_for(@teacher)
      as_instructor.size.should == 1
      as_instructor.first[:base].should be_true
    end
  end
end

describe Assignment do
  it_should_behave_like "an object whose dates are overridable"

  let(:overridable) { assignment_model(:due_at => 5.days.ago) }
  let(:overridable_type) { :assignment }
end

describe Quiz do
  it_should_behave_like "an object whose dates are overridable"

  let(:overridable) { quiz_model(:due_at => 5.days.ago) }
  let(:overridable_type) { :quiz }
end