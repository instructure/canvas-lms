#
# Copyright (C) 2011 Instructure, Inc.
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

describe AssignmentOverrideApplicator do
  describe "overrides_for_assignment_and_user" do
    before :each do
      student_in_course
      @assignment = assignment_model(:course => @course, :due_at => 5.days.from_now)
    end

    it "should cache by assignment and user" do
      enable_cache do
        overrides1 = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @student)
        overrides2 = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @student)
        overrides1.object_id.should == overrides2.object_id
      end
    end

    it "should distinguish cache by assignment" do
      enable_cache do
        overrides1 = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @student)
        overrides2 = AssignmentOverrideApplicator.overrides_for_assignment_and_user(assignment_model, @student)
        overrides1.object_id.should_not == overrides2.object_id
      end
    end

    it "should distinguish cache by assignment version" do
      @assignment.due_at = 7.days.from_now
      @assignment.save!
      @assignment.versions.count.should == 2
      enable_cache do
        overrides1 = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment.versions.first.model, @student)
        overrides2 = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment.versions.current.model, @student)
        overrides1.object_id.should_not == overrides2.object_id
      end
    end

    it "should distinguish cache by user" do
      enable_cache do
        overrides1 = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @student)
        overrides2 = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, user_model)
        overrides1.object_id.should_not == overrides2.object_id
      end
    end

    it "should include adhoc override for the user" do
      @override = assignment_override_model(:assignment => @assignment)
      @override_student = @override.assignment_override_students.build
      @override_student.user = @student
      @override_student.save!

      overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @student)
      overrides.should == [@override]
    end

    it "should not include adhoc overrides that don't include the user" do
      @override = assignment_override_model(:assignment => @assignment)
      overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @student)
      overrides.should be_empty
    end

    context "group overrides" do
      before :each do
        @category = @course.group_categories.create!
        @group = @category.groups.create!

        @assignment.group_category = @category
        @assignment.save!

        @override = assignment_override_model(:assignment => @assignment)
        @override.set = @group
        @override.save!

        @membership = @group.add_user(@student)
      end

      it "should include group override for the user" do
        overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @student)
        overrides.should == [@override]
      end

      it "should not include group override for groups other than the user's" do
        @override.set = @category.groups.create!
        @override.save!

        overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @student)
        overrides.should be_empty
      end

      it "should not include group override for deleted groups" do
        @group.destroy

        overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @student)
        overrides.should be_empty
      end

      it "should not include group override for deleted group memberships" do
        @membership.destroy

        overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @student)
        overrides.should be_empty
      end
    end

    context "section overrides" do
      before :each do
        @override = assignment_override_model(:assignment => @assignment)
        @override.set = @course.default_section
        @override.save!
      end

      it "should include section overrides for sections with an active student enrollment" do
        overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @student)
        overrides.should == [@override]
      end

      it "should include section overrides for sections with an active observer enrollment" do
        course_with_observer(:course => @course, :active_all => true)
        overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @observer)
        overrides.should == [@override]
      end

      it "should not include section overrides for sections without an enrollment" do
        @override.set = @course.course_sections.create!
        @override.save!

        overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @student)
        overrides.should be_empty
      end

      it "should not include section overrides for sections with deleted enrollments" do
        @student.student_enrollments.first.destroy

        overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @student)
        overrides.should be_empty
      end

      it "should not include section overrides for sections with non-student enrollments" do
        @enrollment = @student.student_enrollments.first
        @enrollment.type = 'TeacherEnrollment'
        @enrollment.save!

        overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @student)
        overrides.should be_empty
      end

      it "should include all relevant section overrides" do
        @override2 = assignment_override_model(:assignment => @assignment)
        @override2.set = @course.course_sections.create!
        @override2.save!

        @course.enroll_student(@student, :section => @override2.set, :allow_multiple_enrollments => true)

        overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @student)
        overrides.size.should == 2
        overrides.should include(@override)
        overrides.should include(@override2)
      end

      it "should only use the latest due_date for student_view_student" do
        due_at = 3.days.from_now

        override1 = @override
        override1.override_due_at(due_at)
        override1.save!

        cs = @course.course_sections.create!
        override2 = assignment_override_model(:assignment => @assignment)
        override2.set = cs
        override2.override_due_at(due_at - 1.day)
        override2.save!

        @fake_student = @course.student_view_student
        overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @fake_student)
        overrides.should == [override1, override2]
        AssignmentOverrideApplicator.collapsed_overrides(@assignment, overrides)[:due_at].should == due_at
      end
    end

    it "should order adhoc override before group override" do
      @category = @course.group_categories.create!
      @group = @category.groups.create!
      @membership = @group.add_user(@student)
      @assignment.group_category = @category
      @assignment.save!

      @group_override = assignment_override_model(:assignment => @assignment)
      @group_override.set = @group
      @group_override.save!

      @adhoc_override = assignment_override_model(:assignment => @assignment)
      @override_student = @adhoc_override.assignment_override_students.build
      @override_student.user = @student
      @override_student.save!

      overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @student)
      overrides.size.should == 2
      overrides.first.should == @adhoc_override
      overrides.last.should == @group_override
    end

    it "should order group override before section overrides" do
      @category = @course.group_categories.create!
      @group = @category.groups.create!
      @membership = @group.add_user(@student)
      @assignment.group_category = @category
      @assignment.save!

      @section_override = assignment_override_model(:assignment => @assignment)
      @section_override.set = @course.default_section
      @section_override.save!

      @group_override = assignment_override_model(:assignment => @assignment)
      @group_override.set = @group
      @group_override.save!

      overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @student)
      overrides.size.should == 2
      overrides.first.should == @group_override
      overrides.last.should == @section_override
    end

    it "should order section overrides by position" # see TODO in implementation

    context "versioning" do
      it "should use the appropriate version of an override" do
        @override = assignment_override_model(:assignment => @assignment)
        @override_student = @override.assignment_override_students.build
        @override_student.user = @student
        @override_student.save!

        original_override_version_number = @override.version_number

        @assignment.due_at = 3.days.from_now
        @assignment.save!

        @override.override_due_at(5.days.from_now)
        @override.save!

        overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @student)
        overrides.first.version_number.should == @override.version_number

        overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment.versions.first.model, @student)
        overrides.first.version_number.should == original_override_version_number
      end

      it "should use the most-recent override version for the given assignment version" do
        @override = assignment_override_model(:assignment => @assignment)
        @override_student = @override.assignment_override_students.build
        @override_student.user = @student
        @override_student.save!

        first_version = @override.version_number

        @override.override_due_at(7.days.from_now)
        @override.save!

        second_version = @override.version_number
        first_version.should_not == second_version

        overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @student)
        overrides.first.version_number.should == second_version
      end

      it "should exclude overrides that weren't created until a later assignment version" do
        @assignment.due_at = 3.days.from_now
        @assignment.save!

        @override = assignment_override_model(:assignment => @assignment)
        @override_student = @override.assignment_override_students.build
        @override_student.user = @student
        @override_student.save!

        overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment.versions.first.model, @student)
        overrides.should be_empty
      end

      it "should exclude overrides that were deleted as of the assignment version" do
        @override = assignment_override_model(:assignment => @assignment)
        @override_student = @override.assignment_override_students.build
        @override_student.user = @student
        @override_student.save!

        @override.destroy

        overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @student)
        overrides.should be_empty
      end

      it "should include now-deleted overrides that weren't deleted yet as of the assignment version" do
        @override = assignment_override_model(:assignment => @assignment)
        @override.set = @course.default_section
        @override.save!

        @assignment.due_at = 3.days.from_now
        @assignment.save!

        @override.destroy

        overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment.versions.first.model, @student)
        overrides.should == [@override]
        overrides.first.should_not be_deleted
      end
    end
  end

  describe "assignment_with_overrides" do
    before :each do
      Time.zone == 'Alaska'
      @assignment = assignment_model(
        :due_at => 5.days.from_now,
        :unlock_at => 4.days.from_now,
        :lock_at => 6.days.from_now,
        :title => 'Some Title')
      @override = assignment_override_model(:assignment => @assignment)
      @override.override_due_at(7.days.from_now)
      @overridden = AssignmentOverrideApplicator.assignment_with_overrides(@assignment, [@override])
    end

    it "should return a new assignment object" do
      @overridden.class.should == @assignment.class
      @overridden.object_id.should_not == @assignment.object_id
    end

    it "should preserve assignment id" do
      @overridden.id.should == @assignment.id
    end

    it "should be new_record? iff the original assignment is" do
      @overridden.should_not be_new_record

      @assignment = Assignment.new
      @overridden = AssignmentOverrideApplicator.assignment_with_overrides(@assignment, [])
      @overridden.should be_new_record
    end

    it "should apply overrides to the returned assignment object" do
      @overridden.due_at.should == @override.due_at
    end

    it "should not change the original assignment object" do
      @assignment.due_at.should_not == @overridden.due_at
    end

    it "should inherit other values from the original assignment object" do
      @overridden.title.should == @assignment.title
    end

    it "should return a readonly assignment object" do
      @overridden.should be_readonly
      lambda{ @overridden.save! }.should raise_exception ActiveRecord::ReadOnlyRecord
    end

    it "should cast datetimes to the active time zone" do
      @overridden.due_at.time_zone.should == Time.zone
      @overridden.unlock_at.time_zone.should == Time.zone
      @overridden.lock_at.time_zone.should == Time.zone
    end

    it "should not cast dates to zoned datetimes" do
      @overridden.all_day_date.class.should == Date
    end
  end

  describe "collapsed_overrides" do
    it "should cache by assignment and overrides" do
      @assignment = assignment_model
      @override = assignment_override_model(:assignment => @assignment)
      enable_cache do
        overrides1 = AssignmentOverrideApplicator.collapsed_overrides(@assignment, [@override])
        overrides2 = AssignmentOverrideApplicator.collapsed_overrides(@assignment, [@override])
        overrides1.object_id.should == overrides2.object_id
      end
    end

    it "should distinguish cache by assignment" do
      @assignment = assignment_model
      @override = assignment_override_model(:assignment => @assignment)
      enable_cache do
        overrides1 = AssignmentOverrideApplicator.collapsed_overrides(@assignment, [@override])
        overrides2 = AssignmentOverrideApplicator.collapsed_overrides(assignment_model, [@override])
        overrides1.object_id.should_not == overrides2.object_id
      end
    end

    it "should distinguish cache by assignment version" do
      @assignment = assignment_model
      @assignment.due_at = 5.days.from_now
      @assignment.save!
      @assignment.versions.count.should == 2
      @override = assignment_override_model(:assignment => @assignment)
      enable_cache do
        overrides1 = AssignmentOverrideApplicator.collapsed_overrides(@assignment.versions.first.model, [@override])
        overrides2 = AssignmentOverrideApplicator.collapsed_overrides(@assignment.versions.current.model, [@override])
        overrides1.object_id.should_not == overrides2.object_id
      end
    end

    it "should distinguish cache by overrides" do
      @assignment = assignment_model
      @override1 = assignment_override_model(:assignment => @assignment)
      @override2 = assignment_override_model(:assignment => @assignment)
      enable_cache do
        overrides1 = AssignmentOverrideApplicator.collapsed_overrides(@assignment, [@override1])
        overrides2 = AssignmentOverrideApplicator.collapsed_overrides(@assignment, [@override2])
        overrides1.object_id.should_not == overrides2.object_id
      end
    end

    it "should have a collapsed value for each recognized field" do
      @assignment = assignment_model
      @override = assignment_override_model(:assignment => @assignment)
      overrides = AssignmentOverrideApplicator.collapsed_overrides(@assignment, [@override])
      overrides.class.should == Hash
      overrides.keys.to_set.should == [:due_at, :all_day, :all_day_date, :unlock_at, :lock_at].to_set
    end

    it "should use raw UTC time for datetime fields" do
      Time.zone = 'Alaska'
      @assignment = assignment_model(
        :due_at => 5.days.from_now,
        :unlock_at => 6.days.from_now,
        :lock_at => 7.days.from_now)
      collapsed = AssignmentOverrideApplicator.collapsed_overrides(@assignment, [])
      collapsed[:due_at].class.should == Time; collapsed[:due_at].should == @assignment.due_at.utc
      collapsed[:unlock_at].class.should == Time; collapsed[:unlock_at].should == @assignment.unlock_at.utc
      collapsed[:lock_at].class.should == Time; collapsed[:lock_at].should == @assignment.lock_at.utc
    end

    it "should not use raw UTC time for date fields" do
      Time.zone = 'Alaska'
      @assignment = assignment_model(:due_at => 5.days.from_now)
      collapsed = AssignmentOverrideApplicator.collapsed_overrides(@assignment, [])
      collapsed[:all_day_date].class.should == Date
      collapsed[:all_day_date].should == @assignment.all_day_date
    end
  end

  describe "overrides_hash" do
    it "should be consistent for the same overrides" do
      overrides = 5.times.map{ assignment_override_model }
      hash1 = AssignmentOverrideApplicator.overrides_hash(overrides)
      hash2 = AssignmentOverrideApplicator.overrides_hash(overrides)
      hash1.should == hash2
    end

    it "should be unique for different overrides" do
      overrides1 = 5.times.map{ assignment_override_model }
      overrides2 = 5.times.map{ assignment_override_model }
      hash1 = AssignmentOverrideApplicator.overrides_hash(overrides1)
      hash2 = AssignmentOverrideApplicator.overrides_hash(overrides2)
      hash1.should_not == hash2
    end

    it "should be unique for different versions of the same overrides" do
      overrides = 5.times.map{ assignment_override_model }
      hash1 = AssignmentOverrideApplicator.overrides_hash(overrides)
      overrides.first.override_due_at(5.days.from_now)
      overrides.first.save!
      hash2 = AssignmentOverrideApplicator.overrides_hash(overrides)
      hash1.should_not == hash2
    end

    it "should be unique for different orders of the same overrides" do
      overrides = 5.times.map{ assignment_override_model }
      hash1 = AssignmentOverrideApplicator.overrides_hash(overrides)
      hash2 = AssignmentOverrideApplicator.overrides_hash(overrides.reverse)
      hash1.should_not == hash2
    end
  end

  def fancy_midnight(opts={})
    zone = opts[:zone] || Time.zone
    Time.use_zone(zone) do
      time = opts[:time] || Time.zone.now
      time.in_time_zone.midnight + 1.day - 1.minute
    end
  end

  describe "overridden_due_at" do
    before :each do
      @assignment = assignment_model(:due_at => 5.days.from_now)
      @override = assignment_override_model(:assignment => @assignment)
    end

    it "should use overrides that override due_at" do
      @override.override_due_at(7.days.from_now)
      due_at = AssignmentOverrideApplicator.overridden_due_at(@assignment, [@override])
      due_at.should == @override.due_at
    end

    it "should skip overrides that don't override due_at" do
      @override2 = assignment_override_model(:assignment => @assignment)
      @override2.override_due_at(7.days.from_now)
      due_at = AssignmentOverrideApplicator.overridden_due_at(@assignment, [@override, @override2])
      due_at.should == @override2.due_at
    end

    it "should prefer most lenient override" do
      @override.override_due_at(6.days.from_now)
      @override2 = assignment_override_model(:assignment => @assignment)
      @override2.override_due_at(7.days.from_now)
      due_at = AssignmentOverrideApplicator.overridden_due_at(@assignment, [@override, @override2])
      due_at.should == @override2.due_at
    end

    it "should consider no due date as most lenient" do
      @override.override_due_at(nil)
      @override2 = assignment_override_model(:assignment => @assignment)
      @override2.override_due_at(7.days.from_now)
      due_at = AssignmentOverrideApplicator.overridden_due_at(@assignment, [@override, @override2])
      due_at.should == @override.due_at
    end

    it "should not consider empty original due date as more lenient than an override due date" do
      @assignment.due_at = nil
      @override.override_due_at(6.days.from_now)
      due_at = AssignmentOverrideApplicator.overridden_due_at(@assignment, [@override])
      due_at.should == @override.due_at
    end

    it "prefers overrides even when earlier when determining most lenient due date" do
      earlier = 6.days.from_now
      @assignment.due_at = 7.days.from_now
      @override.override_due_at(earlier)
      due_at = AssignmentOverrideApplicator.overridden_due_at(@assignment, [@override])
      due_at.should == earlier
    end

    it "should fallback on the assignment's due_at" do
      due_at = AssignmentOverrideApplicator.overridden_due_at(@assignment, [@override])
      due_at.should == @assignment.due_at
    end

    it "should recognize overrides with overridden-but-nil due_at" do
      @override.override_due_at(nil)
      due_at = AssignmentOverrideApplicator.overridden_due_at(@assignment, [@override])
      due_at.should == @override.due_at
    end
  end

  # specs for overridden_due_at cover all_day and all_day_date, since they're
  # pulled from the same assignment/override the due_at is

  describe "overridden_unlock_at" do
    before :each do
      @assignment = assignment_model(:unlock_at => 10.days.from_now)
      @override = assignment_override_model(:assignment => @assignment)
    end

    it "should use overrides that override unlock_at" do
      @override.override_unlock_at(7.days.from_now)
      unlock_at = AssignmentOverrideApplicator.overridden_unlock_at(@assignment, [@override])
      unlock_at.should == @override.unlock_at
    end

    it "should skip overrides that don't override unlock_at" do
      @override2 = assignment_override_model(:assignment => @assignment)
      @override2.override_unlock_at(7.days.from_now)
      unlock_at = AssignmentOverrideApplicator.overridden_unlock_at(@assignment, [@override, @override2])
      unlock_at.should == @override2.unlock_at
    end

    it "should prefer most lenient override" do
      @override.override_unlock_at(7.days.from_now)
      @override2 = assignment_override_model(:assignment => @assignment)
      @override2.override_unlock_at(6.days.from_now)
      unlock_at = AssignmentOverrideApplicator.overridden_unlock_at(@assignment, [@override, @override2])
      unlock_at.should == @override2.unlock_at
    end

    it "should consider no unlock date as most lenient" do
      @override.override_unlock_at(nil)
      @override2 = assignment_override_model(:assignment => @assignment)
      @override2.override_unlock_at(7.days.from_now)
      unlock_at = AssignmentOverrideApplicator.overridden_unlock_at(@assignment, [@override, @override2])
      unlock_at.should == @override.unlock_at
    end

    it "should not consider empty original unlock date as more lenient than an override unlock date" do
      @assignment.unlock_at = nil
      @override.override_unlock_at(6.days.from_now)
      unlock_at = AssignmentOverrideApplicator.overridden_unlock_at(@assignment, [@override])
      unlock_at.should == @override.unlock_at
    end

    it "prefers overrides even when later when determining most lenient unlock date" do
      later = 7.days.from_now
      @assignment.unlock_at = 6.days.from_now
      @override.override_unlock_at(later)
      unlock_at = AssignmentOverrideApplicator.overridden_unlock_at(@assignment, [@override])
      unlock_at.should == later
    end

    it "should fallback on the assignment's unlock_at" do
      unlock_at = AssignmentOverrideApplicator.overridden_unlock_at(@assignment, [@override])
      unlock_at.should == @assignment.unlock_at
    end

    it "should recognize overrides with overridden-but-nil unlock_at" do
      @override.override_unlock_at(nil)
      unlock_at = AssignmentOverrideApplicator.overridden_unlock_at(@assignment, [@override])
      unlock_at.should == @override.unlock_at
    end
  end

  describe "overridden_lock_at" do
    before :each do
      @assignment = assignment_model(:lock_at => 5.days.from_now)
      @override = assignment_override_model(:assignment => @assignment)
    end

    it "should use overrides that override lock_at" do
      @override.override_lock_at(7.days.from_now)
      lock_at = AssignmentOverrideApplicator.overridden_lock_at(@assignment, [@override])
      lock_at.should == @override.lock_at
    end

    it "should skip overrides that don't override lock_at" do
      @override2 = assignment_override_model(:assignment => @assignment)
      @override2.override_lock_at(7.days.from_now)
      lock_at = AssignmentOverrideApplicator.overridden_lock_at(@assignment, [@override, @override2])
      lock_at.should == @override2.lock_at
    end

    it "should prefer most lenient override" do
      @override.override_lock_at(6.days.from_now)
      @override2 = assignment_override_model(:assignment => @assignment)
      @override2.override_lock_at(7.days.from_now)
      lock_at = AssignmentOverrideApplicator.overridden_lock_at(@assignment, [@override, @override2])
      lock_at.should == @override2.lock_at
    end

    it "should consider no lock date as most lenient" do
      @override.override_lock_at(nil)
      @override2 = assignment_override_model(:assignment => @assignment)
      @override2.override_lock_at(7.days.from_now)
      lock_at = AssignmentOverrideApplicator.overridden_lock_at(@assignment, [@override, @override2])
      lock_at.should == @override.lock_at
    end

    it "should not consider empty original lock date as more lenient than an override lock date" do
      @assignment.lock_at = nil
      @override.override_lock_at(6.days.from_now)
      lock_at = AssignmentOverrideApplicator.overridden_lock_at(@assignment, [@override])
      lock_at.should == @override.lock_at
    end

    it "prefers overrides even when earlier when determining most lenient lock date" do
      earlier = 6.days.from_now
      @assignment.lock_at = 7.days.from_now
      @override.override_lock_at(earlier)
      lock_at = AssignmentOverrideApplicator.overridden_lock_at(@assignment, [@override])
      lock_at.should == earlier
    end

    it "should fallback on the assignment's lock_at" do
      lock_at = AssignmentOverrideApplicator.overridden_lock_at(@assignment, [@override])
      lock_at.should == @assignment.lock_at
    end

    it "should recognize overrides with overridden-but-nil lock_at" do
      @override.override_lock_at(nil)
      lock_at = AssignmentOverrideApplicator.overridden_lock_at(@assignment, [@override])
      lock_at.should == @override.lock_at
    end
  end

  describe "assignment_overridden_for" do
    before :each do
      student_in_course
      @assignment = assignment_model(:course => @course)
    end

    it "should note the user id for whom overrides were applied" do
      @adhoc_override = assignment_override_model(:assignment => @assignment)
      @override_student = @adhoc_override.assignment_override_students.build
      @override_student.user = @student
      @override_student.save!
      @adhoc_override.override_due_at(7.days.from_now)
      @adhoc_override.save!
      @overridden_assignment = AssignmentOverrideApplicator.assignment_overridden_for(@assignment, @student)
      @overridden_assignment.overridden_for_user.id.should == @student.id
    end

    it "should note the user id for whom overrides were not found" do
      @overridden_assignment = AssignmentOverrideApplicator.assignment_overridden_for(@assignment, @student)
      @overridden_assignment.overridden_for_user.id.should == @student.id
    end

    it "should apply new overrides if an overridden assignment is overridden for a new user" do
      @student1 = @student
      @overridden_assignment = AssignmentOverrideApplicator.assignment_overridden_for(@assignment, @student1)
      @overridden_assignment.overridden_for_user.id.should == @student1.id
      student_in_course
      @student2 = @student
      AssignmentOverrideApplicator.expects(:overrides_for_assignment_and_user).with(@overridden_assignment, @student2).returns([])
      @reoverridden_assignment = AssignmentOverrideApplicator.assignment_overridden_for(@overridden_assignment, @student2)
    end

    it "should not attempt to apply overrides if an overridden assignment is overridden for the same user" do
      @overridden_assignment = AssignmentOverrideApplicator.assignment_overridden_for(@assignment, @student)
      @overridden_assignment.overridden_for_user.id.should == @student.id
      AssignmentOverrideApplicator.expects(:overrides_for_assignment_and_user).never
      @reoverridden_assignment = AssignmentOverrideApplicator.assignment_overridden_for(@overridden_assignment, @student)
    end
  end

  describe "without_overrides" do
    before :each do
      student_in_course
      @assignment = assignment_model(:course => @course)
    end

    it "should return an unoverridden copy of an overridden assignment" do
      @overridden_assignment = AssignmentOverrideApplicator.assignment_overridden_for(@assignment, @student)
      @overridden_assignment.overridden_for_user.id.should == @student.id
      @unoverridden_assignment = @overridden_assignment.without_overrides
      @unoverridden_assignment.overridden_for_user.should == nil
    end
  end
  
  it "should use the full stack" do
    student_in_course
    original_due_at = 3.days.from_now
    @assignment = assignment_model(:course => @course)
    @assignment.due_at = original_due_at
    @assignment.save!

    @section_override = assignment_override_model(:assignment => @assignment)
    @section_override.set = @course.default_section
    @section_override.override_due_at(5.days.from_now)
    @section_override.save!

    @adhoc_override = assignment_override_model(:assignment => @assignment)
    @override_student = @adhoc_override.assignment_override_students.build
    @override_student.user = @student
    @override_student.save!

    @adhoc_override.override_due_at(7.days.from_now)
    @adhoc_override.save!
    @overridden_assignment = AssignmentOverrideApplicator.assignment_overridden_for(@assignment, @student)
    @overridden_assignment.due_at.should == @adhoc_override.due_at

    @adhoc_override.clear_due_at_override
    @adhoc_override.save!

    @overridden_assignment = AssignmentOverrideApplicator.assignment_overridden_for(@assignment, @student)
    @overridden_assignment.due_at.should == @section_override.due_at
  end
end
