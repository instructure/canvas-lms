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
  before :once do
    student_in_course
  end

  it "should soft-delete" do
    @override = assignment_override_model
    @override.stubs(:assignment_override_students).once.returns stub(:destroy_all)
    @override.expects(:save!).once
    @override.destroy
    AssignmentOverride.find_by_id(@override.id).should_not be_nil
    @override.workflow_state.should == 'deleted'
  end

  it "should default set_type to adhoc" do
    @override = AssignmentOverride.new
    @override.valid? # trigger bookkeeping
    @override.set_type.should == 'ADHOC'
  end

  it "should allow reading set_id and set when set_type is adhoc" do
    @override = AssignmentOverride.new
    @override.set_type = 'ADHOC'
    @override.set_id.should be_nil
    @override.set.should == []
  end

  it "should return the students as the set when set_type is adhoc" do
    @override = assignment_override_model(:course => @course)

    @override_student = @override.assignment_override_students.build
    @override_student.user = @student
    @override_student.save!

    @override.reload
    @override.set.should == [@student]
  end

  it "should remove adhoc associations when an adhoc override is deleted" do
    @override = assignment_override_model(:course => @course)
    @override_student = @override.assignment_override_students.build
    @override_student.user = @student
    @override_student.save!

    @override.destroy
    @override.reload

    @override.set.should == []
  end

  it "should allow reusing students from a deleted adhoc override" do
    @override = assignment_override_model(:course => @course)
    @override_student = @override.assignment_override_students.build
    @override_student.user = @student
    @override_student.save!

    @override.destroy
    @override2 = assignment_override_model(:assignment => @assignment)
    @override_student2 = @override2.assignment_override_students.build
    @override_student2.user = @student

    @override_student2.should be_valid
    @override2.should be_valid

    lambda{ @override_student2.save! }.should_not raise_error
    @override2.reload
    @override2.set.should == [@student]
  end

  describe 'versioning' do
    before :once do
      @override = assignment_override_model
    end

    it "should indicate when it has versions" do
      @override.override_due_at(5.days.from_now)
      @override.save!
      @override.versions.exists?.should be_true
    end

    it "should be versioned" do
      @override.should respond_to :version_number
      old_version = @override.version_number
      @override.override_due_at(5.days.from_now)
      @override.save!
      @override.version_number.should_not == old_version
    end

    it "should keep its assignment version up to date" do
      @override.valid? # trigger bookkeeping
      @override.assignment_version.should == @override.assignment.version_number

      old_version = @override.assignment.version_number
      @override.assignment.due_at = 5.days.from_now
      @override.assignment.save!
      @override.assignment.version_number.should_not == old_version

      @override.valid? # trigger bookkeeping
      @override.assignment_version.should == @override.assignment.version_number
    end
  end

  describe "active scope" do
    before :once do
      @overrides = 5.times.map{ assignment_override_model }
    end

    it "should include active overrides" do
      AssignmentOverride.active.count.should == 5
    end

    it "should exclude deleted overrides" do
      @overrides.map(&:destroy)
      AssignmentOverride.active.count.should == 0
    end
  end

  describe "validations" do
    before :once do
      @override = assignment_override_model
    end

    def invalid_id_for_model(model)
      (model.maximum(:id) || 0) + 1
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
      @category = group_category
      @override.assignment.group_category = @category
      @override.set = @category.groups.create!(context: @override.assignment.context)
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

    # necessary to allow soft deleting overrides that belonged to a cross
    # listed section after it is de-cross-listed
    it "should not reject sections in different course than assignment when deleted" do
      @other_course = course_model
      @override.set = @other_course.default_section
      @override.workflow_state = 'deleted'
      @override.should be_valid
    end

    it "should reject groups in different category than assignment" do
      @assignment.group_category = group_category
      @category = group_category(name: "bar")
      @override.set = @category.groups.create!(context: @assignment.context)
      @override.should_not be_valid
    end

    # necessary to allow soft deleting overrides that were for an assignment's
    # previous group category when the assignment's group category changes
    it "should not reject groups in different category than assignment when deleted" do
      @assignment.group_category = group_category
      @category = group_category(name: "bar")
      @override.set = @category.groups.create!(context: @assignment.context)
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

    it "is valid when the assignment is nil if it has a quiz" do
      @override.assignment = nil
      @override.quiz = quiz_model
      @override.should be_valid
    end
  end

  describe "title" do
    before :once do
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
      @assignment.group_category = group_category
      @group = @assignment.group_category.groups.create!(context: @assignment.context)
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
      before :once do
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

    before do
      @override = AssignmentOverride.new
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
      Timecop.freeze(Time.utc(2013,3,10,0,0)) do
        @override.due_at = Date.today.in_time_zone('Alaska') - 11.hours # 13:00:00 AKDT -08:00 previous day
        @override.due_at = @override.due_at.in_time_zone('Baghdad') # 00:00:00 AST +03:00 today
        @override.all_day_date.should == Date.today - 1.day
      end
    end

    it "sets the date to 11:59 PM of the same day when the date is 12:00 am" do
      @override.due_at = Date.today.in_time_zone('Alaska').midnight
      @override.due_at.should == Date.today.in_time_zone('Alaska').end_of_day
    end

    it "sets the date to the date given when date is not 12:00 AM" do
      expected_time = Date.today.in_time_zone('Alaska') - 11.hours
      @override.unlock_at = expected_time
      @override.unlock_at.should == expected_time
    end
  end

  describe "#lock_at=" do
    before do
      @override = AssignmentOverride.new
    end

    it "sets the date to 11:59 PM of the same day when the date is 12:00 AM" do
      @override.lock_at = Date.today.in_time_zone('Alaska').midnight
      @override.lock_at.should == Date.today.in_time_zone('Alaska').end_of_day
    end

    it "sets the date to the date given when date is not 12:00 AM" do
      expected_time = Date.today.in_time_zone('Alaska') - 11.hours
      @override.lock_at = expected_time
      @override.lock_at.should == expected_time
      @override.lock_at = nil
      @override.lock_at.should be_nil
    end

  end

  describe "default_values" do
    let(:override) { AssignmentOverride.new }
    let(:quiz) { Quizzes::Quiz.new }
    let(:assignment) { Assignment.new }

    context "when the override belongs to a quiz" do
      before do
        override.quiz = quiz
      end

      context "that has an assignment" do
        it "uses the quiz's assignment" do
          override.quiz.assignment = assignment
          override.send(:default_values)
          override.assignment.should == assignment
        end
      end

      context "that has no assignment" do
        it "has a nil assignment" do
          override.send(:default_values)
          override.assignment.should be_nil
        end
      end
    end

    context "when the override belongs to an assignment" do
      before do
        override.assignment = assignment
      end

      context "that has a quiz" do
        it "uses the assignment's quiz" do
          override.assignment.quiz = quiz
          override.send(:default_values)
          override.quiz.should == quiz
        end
      end

      context "that has no quiz" do
        it "has a nil quiz" do
          override.send(:default_values)
          override.quiz.should be_nil
        end
      end
    end
  end

  describe "updating cached due dates" do
    before :once do
      @override = assignment_override_model
      @override.override_due_at(3.days.from_now)
      @override.save
    end

    it "triggers when applicable override is created" do
      DueDateCacher.expects(:recompute).with(@assignment)
      new_override = @assignment.assignment_overrides.build
      new_override.title = 'New Override'
      new_override.override_due_at(3.days.from_now)
      new_override.save!
    end

    it "triggers when overridden due_at changes" do
      DueDateCacher.expects(:recompute).with(@assignment)
      @override.override_due_at(5.days.from_now)
      @override.save
    end

    it "triggers when overridden due_at changes to nil" do
      DueDateCacher.expects(:recompute).with(@assignment)
      @override.override_due_at(nil)
      @override.save
    end

    it "triggers when due_at_overridden changes" do
      DueDateCacher.expects(:recompute).with(@assignment)
      @override.clear_due_at_override
      @override.save
    end

    it "triggers when applicable override deleted" do
      DueDateCacher.expects(:recompute).with(@assignment)
      @override.destroy
    end

    it "triggers when applicable override undeleted" do
      @override.destroy

      DueDateCacher.expects(:recompute).with(@assignment)
      @override.workflow_state = 'active'
      @override.save
    end

    it "does not trigger when non-applicable override is created" do
      DueDateCacher.expects(:recompute).never
      @assignment.assignment_overrides.create
    end

    it "does not trigger when non-applicable override deleted" do
      @override.clear_due_at_override
      @override.save

      DueDateCacher.expects(:recompute).never
      @override.destroy
    end

    it "does not trigger when non-applicable override undeleted" do
      @override.clear_due_at_override
      @override.destroy

      DueDateCacher.expects(:recompute).never
      @override.workflow_state = 'active'
      @override.save
    end

    it "does not trigger when nothing changed" do
      DueDateCacher.expects(:recompute).never
      @override.save
    end
  end

  describe "as_hash" do
    let(:due_at) { Time.utc(2013,1,10,12,30) }
    let(:unlock_at) { Time.utc(2013,1,9,12,30) }
    let(:lock_at) { Time.utc(2013,1,11,12,30) }
    let(:id) { 1 }
    let(:title) { "My Wonderful VDD" }
    let(:override) do
      override = AssignmentOverride.new
      override.title = title
      override.due_at = due_at
      override.all_day = due_at
      override.all_day_date = due_at.to_date
      override.lock_at = lock_at
      override.unlock_at = unlock_at
      override.id = id
      override
    end

    let(:hash) { override.as_hash }

    it "includes the title" do
      hash[:title].should == title
    end

    it "includes the due_at" do
      hash[:due_at].should == due_at
    end

    it "includes the all_day" do
      hash[:all_day].should == override.all_day
    end

    it "includes the all_day_date" do
      hash[:all_day_date].should == override.all_day_date
    end

    it "includes the unlock_at" do
      hash[:unlock_at].should == unlock_at
    end

    it "includes the lock_at" do
      hash[:lock_at].should == lock_at
    end

    it "includes the id" do
      hash[:id].should == id
    end
  end
end
