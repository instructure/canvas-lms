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

describe AssignmentOverride do
  it "should soft-delete" do
    @override = assignment_override_model
    @override.destroy
    @override = AssignmentOverride.find_by_id(@override.id)
    @override.should_not be_nil
    @override.workflow_state.should == 'deleted'
  end

  it "should default set_type to adhoc" do
    @override = assignment_override_model
    @override.valid? # trigger bookkeeping
    @override.set_type.should == 'ADHOC'
  end

  it "should allow reading set_id and set when set_type is adhoc" do
    @override = assignment_override_model
    @override.set_type = 'ADHOC'
    @override.set_id.should be_nil
    @override.set.should == []
  end

  it "should return the students as the set when set_type is adhoc" do
    student_in_course
    @override = assignment_override_model(:course => @course)

    @override_student = @override.assignment_override_students.build
    @override_student.user = @student
    @override_student.save!

    @override.reload
    @override.set.should == [@student]
  end

  it "should be versioned" do
    @override = assignment_override_model
    @override.should respond_to :version_number
    old_version = @override.version_number
    @override.override_due_at(5.days.from_now)
    @override.save!
    @override.version_number.should_not == old_version
  end

  it "should keep its assignment version up to date" do
    @override = assignment_override_model

    @override.valid? # trigger bookkeeping
    @override.assignment_version.should == @override.assignment.version_number

    old_version = @override.assignment.version_number
    @override.assignment.due_at = 5.days.from_now
    @override.assignment.save!
    @override.assignment.version_number.should_not == old_version

    @override.valid? # trigger bookkeeping
    @override.assignment_version.should == @override.assignment.version_number
  end

  describe "active scope" do
    it "should include active overrides" do
      5.times.map{ assignment_override_model }
      AssignmentOverride.active.count.should == 5
    end

    it "should exclude deleted overrides" do
      5.times.map{ assignment_override_model.destroy }
      AssignmentOverride.active.count.should == 0
    end
  end

  describe "validations" do
    before :each do
      @override = assignment_override_model
      @override.should be_valid
    end

    def invalid_id_for_model(model)
      (model.scoped(:select => 'max(id) as id').first.id || 0) + 1
    end

    it "should reject non-nil set_id with an adhoc set" do
      @override.set_id = 1
      @override.should_not be_valid
    end

    it "should reject an empty title with an adhoc set" do
      @override.title = nil
      @override.should_not be_valid
    end

    it "should reject an empty assignment" do
      @override.assignment = nil
      @override.should_not be_valid
    end

    it "should reject an invalid assignment" do
      @override.assignment = nil
      @override.assignment_id = invalid_id_for_model(Assignment)
      @override.should_not be_valid
    end

    it "should accept section sets" do
      @override.set = @course.course_sections.create!
      @override.should be_valid
    end

    it "should accept group sets" do
      @category = @course.group_categories.create!
      @override.assignment.group_category = @category
      @override.set = @category.groups.create!
      @override.should be_valid
    end

    it "should reject an empty set_id with a non-adhoc set_type" do
      @override.set = nil
      @override.set_type = 'CourseSection'
      @override.set_id = nil
      @override.should_not be_valid
    end

    it "should reject an invalid set_id with a non-adhoc set_type" do
      @override.set = nil
      @override.set_type = 'CourseSection'
      @override.set_id = invalid_id_for_model(CourseSection)
      @override.should_not be_valid
    end

    it "should reject sections in different course than assignment" do
      @other_course = course_model
      @override.set = @other_course.default_section
      @override.should_not be_valid
    end

    it "should reject groups in different category than assignment" do
      @assignment.group_category = @course.group_categories.create!
      @category = @course.group_categories.create!
      @override.set = @category.groups.create
      @override.should_not be_valid
    end

    # necessary to allow deleting but otherwise keeping assignments that were
    # for an assignment's previous group category when the assignment's group
    # category changes
    it "should not reject groups in different category than assignment when deleted" do
      @assignment.group_category = @course.group_categories.create!
      @category = @course.group_categories.create!
      @override.set = @category.groups.create
      @override.workflow_state = 'deleted'
      @override.should be_valid
    end

    it "should reject unrecognized sets" do
      @override.set = @override.assignment.context
      @override.should_not be_valid
    end

    it "should reject duplicate sets" do
      @override.set = @course.default_section
      @override.save!

      @override = AssignmentOverride.new
      @override.assignment = @assignment
      @override.set = @course.default_section
      @override.should_not be_valid
    end

    it "should allow duplicates of sets where only one is active" do
      @override.set = @course.default_section
      @override.save!
      @override.destroy

      @override = AssignmentOverride.new
      @override.assignment = @assignment
      @override.set = @course.default_section
      @override.should be_valid
      @override.destroy

      @override = AssignmentOverride.new
      @override.assignment = @assignment
      @override.set = @course.default_section
      @override.should be_valid
    end
  end

  describe "title" do
    before :each do
      @override = assignment_override_model
    end

    it "should force title to the name of the section" do
      @section = @course.default_section
      @section.name = 'Section Test Value'
      @override.set = @section
      @override.title = 'Other Value'
      @override.valid? # trigger bookkeeping
      @override.title.should == @section.name
    end

    it "should default title to the name of the group" do
      @assignment.group_category = @course.group_categories.create!
      @group = @assignment.group_category.groups.create!
      @group.name = 'Group Test Value'
      @override.set = @group
      @override.title = 'Other Value'
      @override.valid? # trigger bookkeeping
      @override.title.should == @group.name
    end

    it "should not be changed for adhoc sets" do
      @override.title = 'Other Value'
      @override.valid? # trigger bookkeeping
      @override.title.should == 'Other Value'
    end
  end

  def self.describe_override(field, value1, value2)
    describe "#{field} overrides" do
      before :each do
        @assignment = assignment_model(field.to_sym => value1)
        @override = assignment_override_model(:assignment => @assignment)
      end

      it "should set the override when a override_#{field} is called" do
        @override.send("override_#{field}", value2)
        @override.send("#{field}_overridden").should == true
        @override.send(field).should == value2
      end

      it "should clear the override when clear_#{field}_override is called" do
        @override.send("override_#{field}", value2)
        @override.send("clear_#{field}_override")
        @override.send("#{field}_overridden").should == false
        @override.send(field).should be_nil
      end
    end
  end

  describe_override("due_at", 5.minutes.from_now, 7.minutes.from_now)
  describe_override("unlock_at", 5.minutes.from_now, 7.minutes.from_now)
  describe_override("lock_at", 5.minutes.from_now, 7.minutes.from_now)

  describe "#due_at=" do
    def fancy_midnight(opts={})
      zone = opts[:zone] || Time.zone
      Time.use_zone(zone) do
        time = opts[:time] || Time.zone.now
        time.in_time_zone.midnight + 1.day - 1.minute
      end
    end

    before :each do
      @override = assignment_override_model
    end

    it "should interpret 11:59pm as all day with no prior value" do
      @override.due_at = fancy_midnight(:zone => 'Alaska')
      @override.all_day.should == true
    end

    it "should interpret 11:59pm as all day with same-tz all-day prior value" do
      @override.due_at = fancy_midnight(:zone => 'Alaska') + 1.day
      @override.due_at = fancy_midnight(:zone => 'Alaska')
      @override.all_day.should == true
    end

    it "should interpret 11:59pm as all day with other-tz all-day prior value" do
      @override.due_at = fancy_midnight(:zone => 'Baghdad')
      @override.due_at = fancy_midnight(:zone => 'Alaska')
      @override.all_day.should == true
    end

    it "should interpret 11:59pm as all day with non-all-day prior value" do
      @override.due_at = fancy_midnight(:zone => 'Alaska') + 1.hour
      @override.due_at = fancy_midnight(:zone => 'Alaska')
      @override.all_day.should == true
    end

    it "should not interpret non-11:59pm as all day no prior value" do
      @override.due_at = fancy_midnight(:zone => 'Alaska').in_time_zone('Baghdad')
      @override.all_day.should == false
    end

    it "should not interpret non-11:59pm as all day with same-tz all-day prior value" do
      @override.due_at = fancy_midnight(:zone => 'Alaska')
      @override.due_at = fancy_midnight(:zone => 'Alaska') + 1.hour
      @override.all_day.should == false
    end

    it "should not interpret non-11:59pm as all day with other-tz all-day prior value" do
      @override.due_at = fancy_midnight(:zone => 'Baghdad')
      @override.due_at = fancy_midnight(:zone => 'Alaska') + 1.hour
      @override.all_day.should == false
    end

    it "should not interpret non-11:59pm as all day with non-all-day prior value" do
      @override.due_at = fancy_midnight(:zone => 'Alaska') + 1.hour
      @override.due_at = fancy_midnight(:zone => 'Alaska') + 2.hour
      @override.all_day.should == false
    end

    it "should preserve all-day when only changing time zone" do
      @override.due_at = fancy_midnight(:zone => 'Alaska')
      @override.due_at = fancy_midnight(:zone => 'Alaska').in_time_zone('Baghdad')
      @override.all_day.should == true
    end

    it "should preserve non-all-day when only changing time zone" do
      @override.due_at = fancy_midnight(:zone => 'Alaska').in_time_zone('Baghdad')
      @override.due_at = fancy_midnight(:zone => 'Alaska')
      @override.all_day.should == false
    end

    it "should determine date from due_at's timezone" do
      @override.due_at = Date.today.in_time_zone('Baghdad') + 1.hour # 01:00:00 AST +03:00 today
      @override.all_day_date.should == Date.today

      @override.due_at = @override.due_at.in_time_zone('Alaska') - 2.hours # 12:00:00 AKDT -08:00 previous day
      @override.all_day_date.should == Date.today - 1.day
    end

    it "should preserve all-day date when only changing time zone" do
      @override.due_at = Date.today.in_time_zone('Baghdad') # 00:00:00 AST +03:00 today
      @override.due_at = @override.due_at.in_time_zone('Alaska') # 13:00:00 AKDT -08:00 previous day
      @override.all_day_date.should == Date.today
    end

    it "should preserve non-all-day date when only changing time zone" do
      @override.due_at = Date.today.in_time_zone('Alaska') - 11.hours # 13:00:00 AKDT -08:00 previous day
      @override.due_at = @override.due_at.in_time_zone('Baghdad') # 00:00:00 AST +03:00 today
      @override.all_day_date.should == Date.today - 1.day
    end
  end

  describe "visible_to named scope" do
    before :each do
      @course = course_model
      @assignment = assignment_model(:course => @course)
    end

    context "adhoc overrides" do
      before :each do
        @student = user_model
        @section2 = @course.course_sections.create!
        @course.enroll_student(@student, :section => @section2)

        @override = assignment_override_model(:assignment => @assignment)
        @override_student = @override.assignment_override_students.build
        @override_student.user = @student
        @override_student.save!
      end

      it "should include adhoc overrides for students the user can see" do
        AssignmentOverride.visible_to(@teacher, @course).should == [@override]
      end

      it "should not include adhoc overrides for students the user can't see" do
        @enrollment = @teacher.enrollments.first
        @enrollment.limit_privileges_to_course_section = true
        @enrollment.save!
        AssignmentOverride.visible_to(@teacher, @course).should be_empty
      end
    end

    context "group overrides" do
      before :each do
        @assignment.group_category = @course.group_categories.create!
        @assignment.save!

        @group = @assignment.group_category.groups.create!(:context => @course)
        @override = assignment_override_model(:assignment => @assignment)
        @override.set = @group
        @override.save!
      end

      it "should include group overrides for groups the user can see" do
        AssignmentOverride.visible_to(@teacher, @course).should == [@override]
      end

      it "should not include group overrides for groups the user can't see" do
        @student = user_model
        AssignmentOverride.visible_to(@student, @course).should be_empty

        @group.add_user(@student)
        AssignmentOverride.visible_to(@student, @course).should == [@override]
      end
    end

    context "section overrides" do
      before :each do
        @section = @course.default_section
        @override = assignment_override_model(:assignment => @assignment)
        @override.set = @section
        @override.save!
      end

      it "should include section overrides for section the user can see" do
        AssignmentOverride.visible_to(@teacher, @course).should == [@override]
      end

      it "should not include section overrides for sections the user can't see" do
        @enrollment = @teacher.enrollments.first
        @enrollment.limit_privileges_to_course_section = true
        @enrollment.save!

        @section2 = @course.course_sections.create!
        @override.set = @section2
        @override.save!

        AssignmentOverride.visible_to(@teacher, @course).should be_empty
      end
    end

    it "should work with mixed override types" do
      @student = user_model
      @course.enroll_student(@student)

      @override1 = assignment_override_model(:assignment => @assignment)
      @override_student = @override1.assignment_override_students.build
      @override_student.user = @student
      @override_student.save!

      @override2 = assignment_override_model(:assignment => @assignment)
      @override2.set = @course.default_section
      @override2.save!

      visible_overrides = AssignmentOverride.visible_to(@teacher, @course)
      visible_overrides.size.should == 2
      visible_overrides.should include @override1
      visible_overrides.should include @override2
    end
  end
end
