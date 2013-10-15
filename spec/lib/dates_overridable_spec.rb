
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
        overridden.due_at.to_i.should == override.due_at.to_i
      end

      it "returns the same object when the user is nil (e.g. a guest)" do
        overridable.overridden_for(nil).should == overridable
      end
    end

    context "with no overrides" do
      it "returns the original object" do
        @overridden = overridable.overridden_for(@student)
        @overridden.due_at.to_i.should == overridable.due_at.to_i
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

  describe "has_active_overrides?" do
    context "has active overrides" do
      before { override }
      it "returns true" do
        overridable.has_active_overrides?.should == true
      end
    end
    context "when it has deleted overrides" do
      it "returns false" do
        override.delete
        overridable.has_active_overrides?.should == false
      end
    end

  end

  describe "#all_dates_visible_to" do
    let(:user) { stub }
    it "only returns active overrides" do
      override.delete
      # include the default override
      overridable.all_dates_visible_to(user).size.should == 1
    end

    it "returns each override represented using its as_hash method" do
      all_dates = overridable.all_dates_visible_to(user)
      overridable.active_assignment_overrides.map(&:as_hash).each do |o|
        all_dates.should contain o
      end
    end

    it "includes the overridable as a hash" do
      all_dates = overridable.all_dates_visible_to(user)
      last_hash = all_dates.last
      overridable_hash =
        overridable.without_overrides.due_date_hash.merge(:base => true)
      overridable_hash.each do |k,v|
        last_hash[k].should == v
      end
    end
  end

  describe "#dates_hash_visible_to" do

    before :each do
      overridable.active_assignment_overrides.stubs(:visible_to => true)

      override.set = course.default_section
      override.override_due_at(7.days.from_now)
      override.save!

      @section2 = course.course_sections.create!(:name => "Summer session")
    end

    it "only returns active overrides" do
      overridable.dates_hash_visible_to(@teacher).size.should == 2
    end

    it "includes the original date as a hash" do
      dates_hash = overridable.dates_hash_visible_to(@teacher)
      dates_hash.size.should == 2

      override = dates_hash[0]
      original = dates_hash[1]

      dates_hash.sort_by! {|d| d[:title].to_s }
      dates_hash[0][:title].should be_nil
      dates_hash[1][:title].should == "value for name"
    end

    it "not include original dates if all sections are overriden" do
      override2 = assignment_override_model(overridable_type => overridable)
      override2.set = @section2
      override2.override_due_at(8.days.from_now)
      override2.save!

      dates_hash = overridable.dates_hash_visible_to(user)
      dates_hash.size.should == 2

      dates_hash.sort_by! {|d| d[:title] }
      dates_hash[0][:title].should == "Summer session"
      dates_hash[1][:title].should == "value for name"
    end

  end

  describe "without_overrides" do
    it "returns an object with no overrides applied" do
      overridable.without_overrides.overridden.should be_false
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
      lambda{ overridable.overrides_visible_to(@teacher).scoped }.should_not raise_exception
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
      as_student[:due_at].to_i.should == override.due_at.to_i

      if overridable.is_a?(Assignment)
        as_student[:all_day].should == override.all_day
        as_student[:all_day_date].should == override.all_day_date
      end
    end

    it "doesn't use an overridden due date for a nil user's due dates" do
      as_student, _ = overridable.overridden_for(@student).due_dates_for(nil)
      as_student[:due_at].should == overridable.due_at
    end

    it "includes the base due date in the list of due dates" do
      _, as_instructor = overridable.due_dates_for(@teacher)

      expected_params = {
        :base => true,
        :due_at => overridable.due_at,
        :lock_at => overridable.lock_at,
        :unlock_at => overridable.lock_at
      }

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
      intify_timestamps(as_instructor).should include(intify_timestamps({
        :title => @course.default_section.name,
        :due_at => override.due_at,
        :all_day => override.all_day,
        :all_day_date => override.all_day_date,
        :lock_at => override.lock_at,
        :set_id => override.set_id,
        :set_type => override.set_type,
        :unlock_at => override.unlock_at,
        :override => override
      }))
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
    it "returns the due at, lock_at, unlock_at, all day, and all day fields" do
      due = 5.days.from_now
      due_params = {:due_at => due, :lock_at => due, :unlock_at => due}
      a = overridable.class.new(due_params)
      if a.is_a?(Quiz)
        a.assignment = Assignment.new(due_params)
      end
      a.due_date_hash[:due_at].should == due
      a.due_date_hash[:lock_at].should == due
      a.due_date_hash[:unlock_at].should == due
      a.due_date_hash[:all_day].should == false
      a.due_date_hash[:all_day_date].should == nil
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
      as_student[:unlock_at].to_i.should == override.unlock_at.to_i
    end

    it "includes the base unlock date in the list of unlock dates" do
      _, as_instructor = overridable.unlock_ats_for(@teacher)
      base_override = as_instructor.detect{|o| o[:base]}
      base_override[:unlock_at].to_i.should == overridable.unlock_at.to_i
    end

    it "doesn't use an overridden unlock date as the base unlock date" do
      _, as_instructor = overridable.overridden_for(@student).unlock_ats_for(@teacher)
      base_override = as_instructor.detect{|o| o[:base]}
      base_override[:unlock_at].to_i.should == overridable.unlock_at.to_i
    end

    it "includes visible unlock date overrides in the list of unlock dates" do
      _, as_instructor = overridable.unlock_ats_for(@teacher)
      section_override = as_instructor.detect{|o| o[:title] == @course.default_section.name }
      section_override[:unlock_at].to_i.should == override.unlock_at.to_i
      section_override[:override].should == override
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

    it "doesn't use an overridden lock date as the base lock date" do
      _, as_instructor = overridable.overridden_for(@student).lock_ats_for(@teacher)
      as_instructor.should include({ :base => true, :lock_at => overridable.lock_at})
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

  describe "multiple_due_dates?" do
    before do
      course_with_student(:course => course)
      override.set = course.default_section
      override.override_due_at(2.days.ago)
      override.save!
    end

    context "when the object has been overridden" do
      context "and it has multiple due dates" do
        it "returns true" do
          overridable.overridden_for(@teacher).multiple_due_dates?.should == true
        end
      end

      context "and it has one due date" do
        it "returns false" do
          overridable.overridden_for(@student).multiple_due_dates?.should == false
        end
      end
    end

    context "when the object hasn't been overridden" do
      it "raises an exception because it doesn't have any context" do
        expect { overridden.multiple_due_dates? }.to raise_exception
      end
    end

    context "when the object has been overridden for a guest" do
      it "returns false" do
        overridable.overridden_for(nil).multiple_due_dates?.should == false
      end
    end
  end

  describe "due_dates" do
    before do
      course_with_student(:course => course)
      override.set = course.default_section
      override.override_due_at(2.days.ago)
      override.save!
    end

    context "when the object has been overridden" do
      context "for a teacher" do
        it "returns all relevant dates" do
          overridable.overridden_for(@teacher).due_dates.size.should == 2
        end
      end

      context "for a student" do
        it "returns one date" do
          overridable.overridden_for(@student).due_dates.size.should == 1
        end
      end
    end

    context "when the object hasn't been overridden" do
      it "raises an exception because it doesn't have any context" do
        expect { overridden.due_dates }.to raise_exception
      end
    end    
  end

  describe "overridden_for?" do
    before do
      course_with_student(:course => course)
    end

    context "when overridden for the user" do
      it "returns true" do
        overridable.overridden_for(@teacher).overridden_for?(@teacher).should be_true
      end
    end

    context "when overridden for a different user" do
      it "returns false" do
        overridable.overridden_for(@teacher).overridden_for?(@student).should be_false
      end
    end

    context "when overridden for a nil user" do
      it "returns true" do
        overridable.overridden_for(nil).overridden_for?(nil).should be_true
      end
    end

    context "when not overridden" do
      it "returns false" do
        overridable.overridden_for?(nil).should be_false
      end
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
