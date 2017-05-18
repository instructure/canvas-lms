#
# Copyright (C) 2012 - present Instructure, Inc.
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

describe AssignmentOverride do
  before :once do
    student_in_course
  end

  it "should soft-delete" do
    @override = assignment_override_model(:course => @course)
    @override_student = @override.assignment_override_students.build
    @override_student.user = @student
    @override_student.save!

    @override.destroy
    expect(AssignmentOverride.where(id: @override).first).not_to be_nil
    expect(@override.workflow_state).to eq 'deleted'
    expect(AssignmentOverrideStudent.where(:id => @override_student).first).to be_nil
  end

  it "should default set_type to adhoc" do
    @override = AssignmentOverride.new
    @override.valid? # trigger bookkeeping
    expect(@override.set_type).to eq 'ADHOC'
  end

  it "should allow reading set_id and set when set_type is adhoc" do
    @override = AssignmentOverride.new
    @override.set_type = 'ADHOC'
    expect(@override.set_id).to be_nil
    expect(@override.set).to eq []
  end

  it "should return the students as the set when set_type is adhoc" do
    @override = assignment_override_model(:course => @course)

    @override_student = @override.assignment_override_students.build
    @override_student.user = @student
    @override_student.save!

    @override.reload
    expect(@override.set).to eq [@student]
  end

  it "should allow reading set_id when set_type is noop" do
    @override = AssignmentOverride.new
    @override.set_type = 'Noop'
    expect(@override.set_id).to be_nil
    expect(@override.set).to eq nil
  end

  it "should remove adhoc associations when an adhoc override is deleted" do
    @override = assignment_override_model(:course => @course)
    @override_student = @override.assignment_override_students.build
    @override_student.user = @student
    @override_student.save!

    @override.destroy
    @override.reload

    expect(@override.set).to eq []
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

    expect(@override_student2).to be_valid
    expect(@override2).to be_valid

    expect{ @override_student2.save! }.not_to raise_error
    @override2.reload
    expect(@override2.set).to eq [@student]
  end

  context '#mastery_paths?' do
    let(:override) do
      described_class.new({
        set_type: AssignmentOverride::SET_TYPE_NOOP,
        set_id: AssignmentOverride::NOOP_MASTERY_PATHS
      })
    end

    it "returns true when it is a mastery_paths override" do
      expect(override.mastery_paths?).to eq true
    end

    it "returns false when it is not a mastery_paths noop" do
      override.set_id = 999
      expect(override.mastery_paths?).to eq false
    end

    it "returns false when it is not a noop override" do
      override.set_type = 'EvilType'
      expect(override.mastery_paths?).to eq false
    end
  end

  describe 'versioning' do
    before :once do
      @override = assignment_override_model
    end

    it "should indicate when it has versions" do
      @override.override_due_at(5.days.from_now)
      @override.save!
      expect(@override.versions.exists?).to be_truthy
    end

    it "should be versioned" do
      expect(@override).to respond_to :version_number
      old_version = @override.version_number
      @override.override_due_at(5.days.from_now)
      @override.save!
      expect(@override.version_number).not_to eq old_version
    end

    it "should keep its assignment version up to date" do
      @override.valid? # trigger bookkeeping
      expect(@override.assignment_version).to eq @override.assignment.version_number

      old_version = @override.assignment.version_number
      @override.assignment.due_at = 5.days.from_now
      @override.assignment.save!
      expect(@override.assignment.version_number).not_to eq old_version

      @override.valid? # trigger bookkeeping
      expect(@override.assignment_version).to eq @override.assignment.version_number
    end
  end

  describe "active scope" do
    before :once do
      @overrides = 5.times.map{ assignment_override_model }
    end

    it "should include active overrides" do
      expect(AssignmentOverride.active.count).to eq 5
    end

    it "should exclude deleted overrides" do
      @overrides.map(&:destroy)
      expect(AssignmentOverride.active.count).to eq 0
    end
  end

  describe "validations" do
    before :once do
      @override = assignment_override_model
    end

    def invalid_id_for_model(model)
      (model.maximum(:id) || 0) + 1
    end

    it "should propagate student errors" do
      student = student_in_course(course: @override.assignment.context, name: 'Johnny Manziel').user
      @override.assignment_override_students.create(user: student)
      @override.assignment_override_students.build(user: student)
      expect(@override).not_to be_valid
      expect(@override.errors[:assignment_override_students].first.type).to eq :taken
    end

    it "should reject non-nil set_id with an adhoc set" do
      @override.set_id = 1
      expect(@override).not_to be_valid
    end

    it "should reject an empty assignment" do
      @override.assignment = nil
      expect(@override).not_to be_valid
    end

    it "should reject an invalid assignment" do
      @override.assignment = nil
      @override.assignment_id = invalid_id_for_model(Assignment)
      expect(@override).not_to be_valid
    end

    it "should accept section sets" do
      @override.set = @course.course_sections.create!
      expect(@override).to be_valid
    end

    it "should accept group sets" do
      @category = group_category
      @override.assignment.group_category = @category
      @override.set = @category.groups.create!(context: @override.assignment.context)
      expect(@override).to be_valid
    end

    it "should accept noop with arbitrary set_id" do
      @override.set_type = 'Noop'
      @override.set_id = 9000
      expect(@override).to be_valid
      expect(@override.set_id).to eq 9000
    end

    it "should reject an empty set_id with a non-adhoc set_type" do
      @override.set = nil
      @override.set_type = 'CourseSection'
      @override.set_id = nil
      expect(@override).not_to be_valid
    end

    it "should reject an invalid set_id with a non-adhoc set_type" do
      @override.set = nil
      @override.set_type = 'CourseSection'
      @override.set_id = invalid_id_for_model(CourseSection)
      expect(@override).not_to be_valid
    end

    it "should reject sections in different course than assignment" do
      @other_course = course_model
      @override.set = @other_course.default_section
      expect(@override).not_to be_valid
    end

    # necessary to allow soft deleting overrides that belonged to a cross
    # listed section after it is de-cross-listed
    it "should not reject sections in different course than assignment when deleted" do
      @other_course = course_model
      @override.set = @other_course.default_section
      @override.workflow_state = 'deleted'
      expect(@override).to be_valid
    end

    it "should reject groups in different category than assignment" do
      @assignment.group_category = group_category
      @category = group_category(name: "bar")
      @override.set = @category.groups.create!(context: @assignment.context)
      expect(@override).not_to be_valid
    end

    # necessary to allow soft deleting overrides that were for an assignment's
    # previous group category when the assignment's group category changes
    it "should not reject groups in different category than assignment when deleted" do
      @assignment.group_category = group_category
      @category = group_category(name: "bar")
      @override.set = @category.groups.create!(context: @assignment.context)
      @override.workflow_state = 'deleted'
      expect(@override).to be_valid
    end

    it "should reject unrecognized sets" do
      @override.set = @override.assignment.context
      expect(@override).not_to be_valid
    end

    it "should reject duplicate sets" do
      @override.set = @course.default_section
      @override.save!

      @override = AssignmentOverride.new
      @override.assignment = @assignment
      @override.set = @course.default_section
      expect(@override).not_to be_valid
    end

    it "should allow duplicates of sets where only one is active" do
      @override.set = @course.default_section
      @override.save!
      @override.destroy

      @override = AssignmentOverride.new
      @override.assignment = @assignment
      @override.set = @course.default_section
      expect(@override).to be_valid
      @override.destroy

      @override = AssignmentOverride.new
      @override.assignment = @assignment
      @override.set = @course.default_section
      expect(@override).to be_valid
    end

    it "is valid when the assignment is nil if it has a quiz" do
      @override.assignment = nil
      @override.quiz = quiz_model
      expect(@override).to be_valid
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
      expect(@override.title).to eq @section.name
    end

    it "should default title to the name of the group" do
      @assignment.group_category = group_category
      @group = @assignment.group_category.groups.create!(context: @assignment.context)
      @group.name = 'Group Test Value'
      @override.set = @group
      @override.title = 'Other Value'
      @override.valid? # trigger bookkeeping
      expect(@override.title).to eq @group.name
    end

    it "should not be changed for adhoc sets if there are no students" do
      @override.title = 'Other Value'
      @override.valid? # trigger bookkeeping
      expect(@override.title).to eq 'Other Value'
    end

    it "should not be changed for noop" do
      @override.set_type = 'Noop'
      @override.title = 'Literally Anything'
      @override.valid? # trigger bookkeeping
      expect(@override.title).to eq 'Literally Anything'
    end

    it "should set ADHOC's title to reflect students (with few)" do
      @override.title = nil
      @override.set_type = "ADHOC"
      override_student = @override.assignment_override_students.build
      override_student.user = student_in_course(course: @override.assignment.context, name: 'Edgar Jones').user
      override_student.save!
      @override.valid? # trigger bookkeeping
      expect(@override.title).to eq '1 student'
    end

    it "should set ADHOC's name to reflect students (with many)" do
      @override.title = nil
      @override.set_type = "ADHOC"
      ["A Student","B Student","C Student","D Student"].each do |student_name|
        override_student = @override.assignment_override_students.build
        override_student.user = student_in_course(course: @override.assignment.context, name: student_name).user
        override_student.save!
      end
      @override.valid? # trigger bookkeeping
      expect(@override.title).to eq '4 students'
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
        expect(@override.send("#{field}_overridden")).to eq true
        expect(@override.send(field)).to eq value2
      end

      it "should clear the override when clear_#{field}_override is called" do
        @override.send("override_#{field}", value2)
        @override.send("clear_#{field}_override")
        expect(@override.send("#{field}_overridden")).to eq false
        expect(@override.send(field)).to be_nil
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
      expect(@override.all_day).to eq true
    end

    it "should interpret 11:59pm as all day with same-tz all-day prior value" do
      @override.due_at = fancy_midnight(:zone => 'Alaska') + 1.day
      @override.due_at = fancy_midnight(:zone => 'Alaska')
      expect(@override.all_day).to eq true
    end

    it "should interpret 11:59pm as all day with other-tz all-day prior value" do
      @override.due_at = fancy_midnight(:zone => 'Baghdad')
      @override.due_at = fancy_midnight(:zone => 'Alaska')
      expect(@override.all_day).to eq true
    end

    it "should interpret 11:59pm as all day with non-all-day prior value" do
      @override.due_at = fancy_midnight(:zone => 'Alaska') + 1.hour
      @override.due_at = fancy_midnight(:zone => 'Alaska')
      expect(@override.all_day).to eq true
    end

    it "should not interpret non-11:59pm as all day no prior value" do
      @override.due_at = fancy_midnight(:zone => 'Alaska').in_time_zone('Baghdad')
      expect(@override.all_day).to eq false
    end

    it "should not interpret non-11:59pm as all day with same-tz all-day prior value" do
      @override.due_at = fancy_midnight(:zone => 'Alaska')
      @override.due_at = fancy_midnight(:zone => 'Alaska') + 1.hour
      expect(@override.all_day).to eq false
    end

    it "should not interpret non-11:59pm as all day with other-tz all-day prior value" do
      @override.due_at = fancy_midnight(:zone => 'Baghdad')
      @override.due_at = fancy_midnight(:zone => 'Alaska') + 1.hour
      expect(@override.all_day).to eq false
    end

    it "should not interpret non-11:59pm as all day with non-all-day prior value" do
      @override.due_at = fancy_midnight(:zone => 'Alaska') + 1.hour
      @override.due_at = fancy_midnight(:zone => 'Alaska') + 2.hour
      expect(@override.all_day).to eq false
    end

    it "should preserve all-day when only changing time zone" do
      @override.due_at = fancy_midnight(:zone => 'Alaska')
      @override.due_at = fancy_midnight(:zone => 'Alaska').in_time_zone('Baghdad')
      expect(@override.all_day).to eq true
    end

    it "should preserve non-all-day when only changing time zone" do
      @override.due_at = fancy_midnight(:zone => 'Alaska').in_time_zone('Baghdad')
      @override.due_at = fancy_midnight(:zone => 'Alaska')
      expect(@override.all_day).to eq false
    end

    it "should determine date from due_at's timezone" do
      @override.due_at = Date.today.in_time_zone('Baghdad') + 1.hour # 01:00:00 AST +03:00 today
      expect(@override.all_day_date).to eq Date.today

      @override.due_at = @override.due_at.in_time_zone('Alaska') - 2.hours # 12:00:00 AKDT -08:00 previous day
      expect(@override.all_day_date).to eq Date.today - 1.day
    end

    it "should preserve all-day date when only changing time zone" do
      @override.due_at = Date.today.in_time_zone('Baghdad') # 00:00:00 AST +03:00 today
      @override.due_at = @override.due_at.in_time_zone('Alaska') # 13:00:00 AKDT -08:00 previous day
      expect(@override.all_day_date).to eq Date.today
    end

    it "should preserve non-all-day date when only changing time zone" do
      Timecop.freeze(Time.utc(2013,3,10,0,0)) do
        @override.due_at = Date.today.in_time_zone('Alaska') - 11.hours # 13:00:00 AKDT -08:00 previous day
        @override.due_at = @override.due_at.in_time_zone('Baghdad') # 00:00:00 AST +03:00 today
        expect(@override.all_day_date).to eq Date.today - 1.day
      end
    end

    it "sets the date to 11:59 PM of the same day when the date is 12:00 am" do
      @override.due_at = Date.today.in_time_zone('Alaska').midnight
      expect(@override.due_at).to eq Date.today.in_time_zone('Alaska').end_of_day
    end

    it "sets the date to the date given when date is not 12:00 AM" do
      expected_time = Date.today.in_time_zone('Alaska') - 11.hours
      @override.unlock_at = expected_time
      expect(@override.unlock_at).to eq expected_time
    end
  end

  describe "#lock_at=" do
    before do
      @override = AssignmentOverride.new
    end

    it "sets the date to 11:59 PM of the same day when the date is 12:00 AM" do
      @override.lock_at = Date.today.in_time_zone('Alaska').midnight
      expect(@override.lock_at).to eq Date.today.in_time_zone('Alaska').end_of_day
    end

    it "sets the date to the date given when date is not 12:00 AM" do
      expected_time = Date.today.in_time_zone('Alaska') - 11.hours
      @override.lock_at = expected_time
      expect(@override.lock_at).to eq expected_time
      @override.lock_at = nil
      expect(@override.lock_at).to be_nil
    end

  end

  describe '#availability_expired?' do
    let(:override) { assignment_override_model }
    subject { override.availability_expired? }

    context 'without an overridden lock_at' do
      before do
        override.lock_at_overridden = false
      end

      it { is_expected.to be(false) }
    end

    context 'with an overridden lock_at' do
      before do
        override.lock_at_overridden = true
      end

      context 'never locks' do
        before do
          override.lock_at = nil
        end

        it { is_expected.to be(false) }
      end

      context 'not yet locked' do
        before do
          override.lock_at = 10.minutes.from_now
        end

        it { is_expected.to be(false) }
      end

      context 'already locked' do
        before do
          override.lock_at = 10.minutes.ago
        end

        it { is_expected.to be(true) }
      end
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
          expect(override.assignment).to eq assignment
        end
      end

      context "that has no assignment" do
        it "has a nil assignment" do
          override.send(:default_values)
          expect(override.assignment).to be_nil
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
          expect(override.quiz).to eq quiz
        end
      end

      context "that has no quiz" do
        it "has a nil quiz" do
          override.send(:default_values)
          expect(override.quiz).to be_nil
        end
      end
    end
  end

  describe '#update_grading_period_grades with no grading periods' do
    it 'should not update grades when due_at changes' do
      assignment_model
      Course.any_instance.expects(:recompute_student_scores).never
      override = AssignmentOverride.new
      override.assignment = @assignment
      override.due_at = 6.months.ago
      override.save!
    end
  end

  describe '#update_grading_period_grades' do
    before :once do
      @override = AssignmentOverride.new(set_type: 'ADHOC', due_at_overridden: true)
      student_in_course
      @assignment = assignment_model(course: @course)
      @grading_period_group = @course.root_account.grading_period_groups.create!(title: "Example Group")
      @grading_period_group.enrollment_terms << @course.enrollment_term
      @grading_period_group.grading_periods.create!(
        title: 'GP1',
        start_date: 9.months.ago,
        end_date: 5.months.ago
      )
      @grading_period_group.grading_periods.create!(
        title: 'GP2',
        start_date: 4.months.ago,
        end_date: 2.months.from_now
      )
      @course.enrollment_term.save!
      @assignment.reload
      @override.assignment = @assignment
      @override.save!
      @override.assignment_override_students.create(user: @student)
    end

    it 'should not update grades if there are no students on this override' do
      @override.assignment_override_students.clear
      Course.any_instance.expects(:recompute_student_scores).never
      @override.due_at = 6.months.ago
      @override.save!
    end

    it 'should update grades when due_at changes to a grading period' do
      Course.any_instance.expects(:recompute_student_scores).twice
      @override.due_at = 6.months.ago
      @override.save!
    end

    it 'should update grades twice when due_at changes to another grading period' do
      @override.due_at = 1.month.ago
      @override.save!
      Course.any_instance.expects(:recompute_student_scores).twice
      @override.due_at = 6.months.ago
      @override.save!
    end

    it 'should not update grades if grading period did not change' do
      @override.due_at = 1.month.ago
      @override.save!
      Course.any_instance.expects(:recompute_student_scores).never
      @override.due_at = 2.months.ago
      @override.save!
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
      override.all_day = !!due_at
      override.all_day_date = due_at.to_date
      override.lock_at = lock_at
      override.unlock_at = unlock_at
      override.id = id
      override
    end

    let(:hash) { override.as_hash }

    it "includes the title" do
      expect(hash[:title]).to eq title
    end

    it "includes the due_at" do
      expect(hash[:due_at]).to eq due_at
    end

    it "includes the all_day" do
      expect(hash[:all_day]).to eq override.all_day
    end

    it "includes the all_day_date" do
      expect(hash[:all_day_date]).to eq override.all_day_date
    end

    it "includes the unlock_at" do
      expect(hash[:unlock_at]).to eq unlock_at
    end

    it "includes the lock_at" do
      expect(hash[:lock_at]).to eq lock_at
    end

    it "includes the id" do
      expect(hash[:id]).to eq id
    end
  end

  describe "destroy_if_empty_set" do
    before do
      @override = assignment_override_model
    end

    it "does nothing if it is not ADHOC" do
      @override.stubs(:set_type).returns "NOT_ADHOC"
      @override.expects(:destroy).never

      @override.destroy_if_empty_set
    end

    it "does nothing if the set is not empty" do
      @override.stubs(:set_type).returns "ADHOC"
      @override.stubs(:set).returns [1,2,3]
      @override.expects(:destroy).never

      @override.destroy_if_empty_set
    end

    it "destroys itself if the set is empty" do
      @override.stubs(:set_type).returns 'ADHOC'
      @override.stubs(:set).returns []
      @override.expects(:destroy).once

      @override.destroy_if_empty_set
    end
  end

  describe "applies_to_students" do
    before do
      student_in_course
    end

    it "returns empty set for noop" do
      @override = assignment_override_model(:course => @course)
      @override.set_type = 'Noop'

      expect(@override.applies_to_students).to eq []
    end

    it "returns the right students for ADHOC" do
      @override = assignment_override_model(:course => @course)
      @override.set_type = 'ADHOC'

      expect(@override.applies_to_students).to eq []

      @override_student = @override.assignment_override_students.build
      @override_student.user = @student
      @override_student.save!

      expect(@override.set).to eq @override.applies_to_students
    end

    it "returns the right students for a section" do
      @override = assignment_override_model(:course => @course)
      @override.set = @course.default_section
      @override.save!

      expect(@override.applies_to_students).to eq []

      @course.enroll_student(@student,:enrollment_state => 'active', :section => @override.set)

      expect(@override.applies_to_students).to eq [@student]
    end
  end

  describe "assignment_edits" do
    before do
      @override = assignment_override_model
    end

    it "returns false if no students who are active in course for ADHOC" do
      @override.stubs(:set_type).returns "ADHOC"
      @override.stubs(:set).returns []

      expect(@override.set_not_empty?).to eq false
    end

    it "returns true if no students who are active in course and CourseSection or Group" do
      @override.stubs(:set_type).returns "CourseSection"
      @override.stubs(:set).returns []

      expect(@override.set_not_empty?).to eq true

      @override.stubs(:set_type).returns "Group"

      expect(@override.set_not_empty?).to eq true
    end

    it "returns true if has students who are active in course for ADHOC" do
      student = student_in_course(course: @override.assignment.context)
      @override.set_type = "ADHOC"
      @override_student = @override.assignment_override_students.build
      @override_student.user = student.user
      @override_student.save!

      expect(@override.set_not_empty?).to eq true
    end
  end

  describe '.visible_students_only' do
    specs_require_sharding

    it "references tables correctly for an out of shard query" do
      # the critical thing is visible_students_only is called the default shard,
      # but the query executes on a different shard, but it should still be
      # well-formed (especially with qualified names)
      AssignmentOverride.visible_students_only([1, 2]).shard(@shard1).to_a
    end

    it "should not duplicate adhoc overrides containing multiple students" do
      @override = assignment_override_model
      students = Array.new(2) { @override.assignment_override_students.create(user: student_in_course.user) }

      expect(AssignmentOverride.visible_students_only(students.map(&:user_id)).count).to eq 1
    end
  end

  describe '.visible_enrollments_for' do
    before do
      @override = assignment_override_model
      @overrides = [@override]
    end
    subject(:visible_enrollments) do
      AssignmentOverride.visible_enrollments_for(@overrides, @student)
    end

    it 'returns empty if provided an empty collection' do
      @overrides = []
      expect(visible_enrollments).to be_empty
    end

    it 'returns empty if not provided a user' do
      @student = nil
      expect(visible_enrollments).to be_empty
    end
  end

  describe '.visible_enrollments_for' do
    before do
      @options = {}
    end
    let(:override) do
      assignment_override_model(@options)
    end
    subject(:visible_enrollments) do
      AssignmentOverride.visible_enrollments_for([override], @student)
    end

    context 'when associated with an assignment' do
      before do
        assignment_model
        @options = {
          assignment: @assignment
        }
      end

      it 'delegates to the course' do
        @assignment.context.any_instantiation.expects(:enrollments_visible_to).with(@student)
        subject
      end
    end

    context 'when associated with a quiz' do
      before do
        quiz_model
        @options = {
          quiz: @quiz
        }
      end

      it 'delegates to UserSearch' do
        @quiz.context.any_instantiation.expects(:enrollments_visible_to).with(@student)
        subject
      end
    end
  end
end
