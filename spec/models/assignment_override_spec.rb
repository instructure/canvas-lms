# frozen_string_literal: true

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

describe AssignmentOverride do
  before :once do
    @active_student = student_in_course(active_all: true).user
  end

  it "soft-deletes" do
    @override = assignment_override_model(course: @course)
    @override_student = @override.assignment_override_students.build
    @override_student.user = @student
    @override_student.save!

    @override.destroy
    @override_student.reload
    expect(AssignmentOverride.where(id: @override).first).not_to be_nil
    expect(@override).to be_deleted
    expect(AssignmentOverrideStudent.where(id: @override_student).first).not_to be_nil
    expect(@override_student).to be_deleted
  end

  it "allows deletes to invalid objects" do
    override = assignment_override_model(course: @course)
    # make it invalid
    AssignmentOverride.where(id: override).update_all(set_type: "potato")
    expect(override.reload).not_to be_valid
    override.destroy
    expect { override.destroy }.not_to raise_error
  end

  it "defaults set_type to adhoc" do
    @override = AssignmentOverride.new
    @override.valid? # trigger bookkeeping
    expect(@override.set_type).to eq "ADHOC"
  end

  it "allows reading set_id and set when set_type is adhoc" do
    @override = AssignmentOverride.new
    @override.set_type = "ADHOC"
    expect(@override.set_id).to be_nil
    expect(@override.set).to eq []
  end

  it "returns the students as the set when set_type is adhoc" do
    @override = assignment_override_model(course: @course)

    @override_student = @override.assignment_override_students.build
    @override_student.user = @student
    @override_student.save!

    @override.reload
    expect(@override.set).to eq [@student]
  end

  it "allows reading set_id when set_type is noop" do
    @override = AssignmentOverride.new
    @override.set_type = "Noop"
    expect(@override.set_id).to be_nil
    expect(@override.set).to be_nil
  end

  it "doesn't crash when calling polymorphic getters on an adhoc override" do
    @override = assignment_override_model
    expect(@override.course).to be_nil
    expect(@override.course_section).to be_nil
    expect(@override.group).to be_nil
  end

  it "removes adhoc associations when an adhoc override is deleted" do
    @override = assignment_override_model(course: @course)
    @override_student = @override.assignment_override_students.build
    @override_student.user = @student
    @override_student.save!

    @override.destroy
    @override.reload

    expect(@override.set).to eq []
  end

  it "allows reusing students from a deleted adhoc override" do
    @override = assignment_override_model(course: @course)
    @override_student = @override.assignment_override_students.build
    @override_student.user = @student
    @override_student.save!

    @override.destroy
    expect(@override_student.reload).to be_deleted

    @override2 = assignment_override_model(assignment: @assignment)
    @override_student2 = @override2.assignment_override_students.build
    @override_student2.user = @student

    expect(@override_student2).to be_valid
    expect(@override2).to be_valid

    expect { @override_student2.save! }.not_to raise_error
    @override2.reload
    expect(@override2.set).to eq [@student]
  end

  describe "#for_nonactive_enrollment?" do
    before(:once) do
      @override = assignment_override_model(course: @course, set: @course.default_section)
    end

    it "returns false by default" do
      expect(@override).not_to be_for_nonactive_enrollment
    end

    context "when nonactive enrollment state has been preloaded" do
      it "returns true for section overrides associated with deactivated enrollments" do
        @course.enrollments.find_by(user: @student).deactivate
        AssignmentOverride.preload_for_nonactive_enrollment([@override], @course, @student)
        expect(@override).to be_for_nonactive_enrollment
      end

      it "returns true for section overrides associated with concluded enrollments" do
        @course.enrollments.find_by(user: @student).conclude
        AssignmentOverride.preload_for_nonactive_enrollment([@override], @course, @student)
        expect(@override).to be_for_nonactive_enrollment
      end

      it "returns false for section overrides associated with active enrollments" do
        AssignmentOverride.preload_for_nonactive_enrollment([@override], @course, @student)
        expect(@override).not_to be_for_nonactive_enrollment
      end

      it "returns false for individual overrides" do
        @override.update!(set_type: "ADHOC", set: nil)
        @override.assignment_override_students.create(user: @student)
        AssignmentOverride.preload_for_nonactive_enrollment([@override], @course, @student)
        expect(@override).not_to be_for_nonactive_enrollment
      end

      it "returns false for group overrides" do
        category = group_category
        @override.assignment.update!(group_category: category)
        group = category.groups.create!(context: @override.assignment.context)
        @override.update!(set: group)
        AssignmentOverride.preload_for_nonactive_enrollment([@override], @course, @student)
        expect(@override).not_to be_for_nonactive_enrollment
      end
    end
  end

  describe "#notify_change?" do
    before :once do
      course_factory(active_all: true)
      student_in_course(course: @course, active_all: true)
    end

    it "does not notify of change for deleted assignment override due to enrollment removal" do
      due_date_timestamp = DateTime.now.iso8601
      assignment = assignment_model(course: @course)
      override = assignment.assignment_overrides.create!(
        due_at: due_date_timestamp,
        due_at_overridden: true
      )
      override.assignment_override_students.create!(user: @student)
      assignment.update(due_at: nil, only_visible_to_overrides: true, created_at: Time.now - 4.hours)
      expect(override.notify_change?).to be true
      @student.destroy
      expect(override.reload.notify_change?).to be false
    end

    it "does not notify of change for course that has concluded" do
      due_date_timestamp = DateTime.now.iso8601
      assignment = assignment_model(course: @course)
      override = assignment.assignment_overrides.create!(
        due_at: due_date_timestamp,
        due_at_overridden: true
      )
      override.assignment_override_students.create!(user: @student)
      assignment.update(due_at: nil, only_visible_to_overrides: true, created_at: Time.now - 4.hours)
      expect(override.notify_change?).to be true

      expect do
        @course.soft_conclude!
        @course.save!
      end.to change {
        override.reload.notify_change?
      }.from(true).to(false)
    end
  end

  describe "#adhoc?" do
    let(:override) { AssignmentOverride.new }

    it "returns true if the override is an ad hoc override" do
      override.set_type = "ADHOC"
      expect(override).to be_adhoc
    end

    it "returns false if the override is not an ad hoc override" do
      aggregate_failures do
        override.set_type = "CourseSection"
        expect(override).not_to be_adhoc
        override.set_type = "Group"
        expect(override).not_to be_adhoc
        override.set_type = "Noop"
        expect(override).not_to be_adhoc
      end
    end
  end

  context "#mastery_paths?" do
    let(:override) do
      described_class.new({
                            set_type: AssignmentOverride::SET_TYPE_NOOP,
                            set_id: AssignmentOverride::NOOP_MASTERY_PATHS
                          })
    end

    it "returns true when it is a mastery_paths override" do
      expect(override.mastery_paths?).to be true
    end

    it "returns false when it is not a mastery_paths noop" do
      override.set_id = 999
      expect(override.mastery_paths?).to be false
    end

    it "returns false when it is not a noop override" do
      override.set_type = "EvilType"
      expect(override.mastery_paths?).to be false
    end
  end

  describe "versioning" do
    before :once do
      @override = assignment_override_model
    end

    it "indicates when it has versions" do
      @override.override_due_at(5.days.from_now)
      @override.save!
      expect(@override.versions.exists?).to be_truthy
    end

    it "is versioned" do
      expect(@override).to respond_to :version_number
      old_version = @override.version_number
      @override.override_due_at(5.days.from_now)
      @override.save!
      expect(@override.version_number).not_to eq old_version
    end

    it "keeps its assignment version up to date" do
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
      @overrides = Array.new(5) { assignment_override_model }
    end

    it "includes active overrides" do
      expect(AssignmentOverride.active.count).to eq 5
    end

    it "excludes deleted overrides" do
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

    it "propagates student errors" do
      student = student_in_course(course: @override.assignment.context, name: "Johnny Manziel").user
      @override.assignment_override_students.create(user: student, workflow_state: "active")
      @override.assignment_override_students.build(user: student, workflow_state: "active")
      expect(@override).not_to be_valid
      expect(@override.errors[:assignment_override_students].first.type).to eq :taken
    end

    it "rejects non-nil set_id with an adhoc set" do
      @override.set_id = 1
      expect(@override).not_to be_valid
    end

    it "rejects an empty assignment" do
      @override.assignment = nil
      expect(@override).not_to be_valid
    end

    it "rejects an invalid assignment" do
      @override.assignment = nil
      @override.assignment_id = invalid_id_for_model(Assignment)
      expect(@override).not_to be_valid
    end

    it "accepts section sets" do
      @override.set = @course.course_sections.create!
      expect(@override).to be_valid
    end

    it "accepts group sets" do
      @category = group_category
      @override.assignment.group_category = @category
      @override.set = @category.groups.create!(context: @override.assignment.context)
      expect(@override).to be_valid
    end

    it "accepts course sets" do
      @override.set = @course
      expect(@override).to be_valid
      expect(@override.set_id).to eq @course.id
    end

    it "rejects course sets with an incorrect set_id" do
      @override.set = @course
      @override.set_id = 123
      expect(@override).not_to be_valid
    end

    it "rejects course set if unassign_item is true" do
      @override.set = @course
      @override.unassign_item = true
      expect(@override).not_to be_valid
    end

    it "accepts unassign_item is true if not everyone set_type" do
      @override.set = @course.course_sections.create!
      @override.unassign_item = true
      expect(@override).to be_valid
    end

    it "accepts noop with arbitrary set_id" do
      @override.set_type = "Noop"
      @override.set_id = 9000
      expect(@override).to be_valid
      expect(@override.set_id).to eq 9000
    end

    it "rejects an empty set_id with a non-adhoc set_type" do
      @override.set = nil
      @override.set_type = "CourseSection"
      @override.set_id = nil
      expect(@override).not_to be_valid
    end

    it "rejects an invalid set_id with a non-adhoc set_type" do
      @override.set = nil
      @override.set_type = "CourseSection"
      @override.set_id = invalid_id_for_model(CourseSection)
      expect(@override).not_to be_valid
    end

    it "rejects sections in different course than assignment" do
      @other_course = course_model
      @override.set = @other_course.default_section
      expect(@override).not_to be_valid
    end

    # necessary to allow soft deleting overrides that belonged to a cross
    # listed section after it is de-cross-listed
    it "does not reject sections in different course than assignment when deleted" do
      @other_course = course_model
      @override.set = @other_course.default_section
      @override.workflow_state = "deleted"
      expect(@override).to be_valid
    end

    it "rejects groups in different category than assignment" do
      @assignment.group_category = group_category
      @category = group_category(name: "bar")
      @override.set = @category.groups.create!(context: @assignment.context)
      expect(@override).not_to be_valid
    end

    # necessary to allow soft deleting overrides that were for an assignment's
    # previous group category when the assignment's group category changes
    it "does not reject groups in different category than assignment when deleted" do
      @assignment.group_category = group_category
      @category = group_category(name: "bar")
      @override.set = @category.groups.create!(context: @assignment.context)
      @override.workflow_state = "deleted"
      expect(@override).to be_valid
    end

    it "rejects duplicate sets" do
      @override.set = @course.default_section
      @override.save!

      @override = AssignmentOverride.new
      @override.assignment = @assignment
      @override.set = @course.default_section
      expect(@override).not_to be_valid
    end

    it "allows duplicates of sets where only one is active" do
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

    it "does not allow setting due dates with pages, discussions, or files" do
      @override.due_at = 5.days.from_now
      @override.assignment = assignment_model
      expect(@override).to be_valid
      @override.assignment = nil
      @override.wiki_page = wiki_page_model
      expect(@override).not_to be_valid
      @override.wiki_page = nil
      @override.discussion_topic = discussion_topic_model
      expect(@override).not_to be_valid
      @override.discussion_topic = nil
      @override.attachment = attachment_model
      expect(@override).not_to be_valid
    end

    it "allows setting both an assignment and a quiz" do
      @override.assignment = assignment_model
      @override.quiz = quiz_model
      expect(@override).to be_valid
    end

    it "does not allow setting both an assignment and a wiki page" do
      @override.assignment = assignment_model
      @override.wiki_page = wiki_page_model
      expect(@override).not_to be_valid
    end
  end

  describe "title" do
    before :once do
      @override = assignment_override_model
    end

    it "forces title to the name of the section" do
      @section = @course.default_section
      @section.name = "Section Test Value"
      @override.set = @section
      @override.title = "Other Value"
      @override.valid? # trigger bookkeeping
      expect(@override.title).to eq @section.name
    end

    it "defaults title to the name of the group" do
      @assignment.group_category = group_category
      @group = @assignment.group_category.groups.create!(context: @assignment.context)
      @group.name = "Group Test Value"
      @override.set = @group
      @override.title = "Other Value"
      @override.valid? # trigger bookkeeping
      expect(@override.title).to eq @group.name
    end

    it "is not changed for adhoc sets if there are no students" do
      @override.title = "Other Value"
      @override.valid? # trigger bookkeeping
      expect(@override.title).to eq "Other Value"
    end

    it "is not changed for noop" do
      @override.set_type = "Noop"
      @override.title = "Literally Anything"
      @override.valid? # trigger bookkeeping
      expect(@override.title).to eq "Literally Anything"
    end

    it "sets ADHOC's title to reflect students (with few)" do
      @override.title = nil
      @override.set_type = "ADHOC"
      override_student = @override.assignment_override_students.build
      override_student.user = student_in_course(course: @override.assignment.context, name: "Edgar Jones").user
      override_student.save!
      @override.valid? # trigger bookkeeping
      expect(@override.title).to eq "1 student"
    end

    it "sets ADHOC's name to reflect students (with many)" do
      @override.title = nil
      @override.set_type = "ADHOC"
      ["A Student", "B Student", "C Student", "D Student"].each do |student_name|
        override_student = @override.assignment_override_students.build
        override_student.user = student_in_course(course: @override.assignment.context, name: student_name).user
        override_student.save!
      end
      @override.valid? # trigger bookkeeping
      expect(@override.title).to eq "4 students"
    end
  end

  describe "#title_from_students" do
    before do
      @assignment_override = AssignmentOverride.new
      allow(AssignmentOverride).to receive(:title_from_student_count)
    end

    it "returns 'No Students' when passed in nil" do
      expect(@assignment_override.title_from_students(nil)).to eql("No Students")
    end

    it "returns 'No Students' when pass in an empty array" do
      expect(@assignment_override.title_from_students([])).to eql("No Students")
    end

    it "calls AssignmentOverride.title_from_student_count when called with a non-empty array" do
      expect(AssignmentOverride).to receive(:title_from_student_count)

      @assignment_override.title_from_students(["A Student"])
    end
  end

  describe ".title_from_student_count" do
    it "returns '1 student' when passed in 1" do
      expect(AssignmentOverride.title_from_student_count(1)).to eql("1 student")
    end

    it "returns '42 students' when passed in 42" do
      expect(AssignmentOverride.title_from_student_count(42)).to eql("42 students")
    end
  end

  def self.describe_override(field, value1, value2)
    describe "#{field} overrides" do
      before :once do
        @assignment = assignment_model(field.to_sym => value1)
        @override = assignment_override_model(assignment: @assignment)
      end

      it "sets the override when a override_#{field} is called" do
        @override.send(:"override_#{field}", value2)
        expect(@override.send(:"#{field}_overridden")).to be true
        expect(@override.send(field)).to eq value2
      end

      it "clears the override when clear_#{field}_override is called" do
        @override.send(:"override_#{field}", value2)
        @override.send(:"clear_#{field}_override")
        expect(@override.send(:"#{field}_overridden")).to be false
        expect(@override.send(field)).to be_nil
      end
    end
  end

  describe_override("due_at", 5.minutes.from_now, 7.minutes.from_now)
  describe_override("unlock_at", 1.minute.ago, 2.minutes.ago)
  describe_override("lock_at", 10.minutes.from_now, 12.minutes.from_now)

  describe "#due_at=" do
    def fancy_midnight(opts = {})
      zone = opts[:zone] || Time.zone
      Time.use_zone(zone) do
        time = opts[:time] || Time.zone.now
        time.in_time_zone.midnight + 1.day - 1.minute
      end
    end

    before do
      @override = AssignmentOverride.new
    end

    it "interprets 11:59pm as all day with no prior value" do
      @override.due_at = fancy_midnight(zone: "Alaska")
      expect(@override.all_day).to be true
    end

    it "interprets 11:59pm as all day with same-tz all-day prior value" do
      @override.due_at = fancy_midnight(zone: "Alaska") + 1.day
      @override.due_at = fancy_midnight(zone: "Alaska")
      expect(@override.all_day).to be true
    end

    it "interprets 11:59pm as all day with other-tz all-day prior value" do
      @override.due_at = fancy_midnight(zone: "Baghdad")
      @override.due_at = fancy_midnight(zone: "Alaska")
      expect(@override.all_day).to be true
    end

    it "interprets 11:59pm as all day with non-all-day prior value" do
      @override.due_at = fancy_midnight(zone: "Alaska") + 1.hour
      @override.due_at = fancy_midnight(zone: "Alaska")
      expect(@override.all_day).to be true
    end

    it "does not interpret non-11:59pm as all day no prior value" do
      @override.due_at = fancy_midnight(zone: "Alaska").in_time_zone("Baghdad")
      expect(@override.all_day).to be false
    end

    it "does not interpret non-11:59pm as all day with same-tz all-day prior value" do
      @override.due_at = fancy_midnight(zone: "Alaska")
      @override.due_at = fancy_midnight(zone: "Alaska") + 1.hour
      expect(@override.all_day).to be false
    end

    it "does not interpret non-11:59pm as all day with other-tz all-day prior value" do
      @override.due_at = fancy_midnight(zone: "Baghdad")
      @override.due_at = fancy_midnight(zone: "Alaska") + 1.hour
      expect(@override.all_day).to be false
    end

    it "does not interpret non-11:59pm as all day with non-all-day prior value" do
      @override.due_at = fancy_midnight(zone: "Alaska") + 1.hour
      @override.due_at = fancy_midnight(zone: "Alaska") + 2.hours
      expect(@override.all_day).to be false
    end

    it "preserves all-day when only changing time zone" do
      @override.due_at = fancy_midnight(zone: "Alaska")
      @override.due_at = fancy_midnight(zone: "Alaska").in_time_zone("Baghdad")
      expect(@override.all_day).to be true
    end

    it "preserves non-all-day when only changing time zone" do
      @override.due_at = fancy_midnight(zone: "Alaska").in_time_zone("Baghdad")
      @override.due_at = fancy_midnight(zone: "Alaska")
      expect(@override.all_day).to be false
    end

    it "determines date from due_at's timezone" do
      @override.due_at = Date.today.in_time_zone("Baghdad") + 1.hour # 01:00:00 AST +03:00 today
      expect(@override.all_day_date).to eq Date.today

      @override.due_at = @override.due_at.in_time_zone("Alaska") - 2.hours # 12:00:00 AKDT -08:00 previous day
      expect(@override.all_day_date).to eq Date.today - 1.day
    end

    it "preserves all-day date when only changing time zone" do
      @override.due_at = Date.today.in_time_zone("Baghdad") # 00:00:00 AST +03:00 today
      @override.due_at = @override.due_at.in_time_zone("Alaska") # 13:00:00 AKDT -08:00 previous day
      expect(@override.all_day_date).to eq Date.today
    end

    it "preserves non-all-day date when only changing time zone" do
      Timecop.freeze(Time.utc(2013, 3, 10, 0, 0)) do
        @override.due_at = Date.today.in_time_zone("Alaska") - 11.hours # 13:00:00 AKDT -08:00 previous day
        @override.due_at = @override.due_at.in_time_zone("Baghdad") # 00:00:00 AST +03:00 today
        expect(@override.all_day_date).to eq Date.today - 1.day
      end
    end

    it "sets the date to 11:59 PM of the same day when the date is 12:00 am" do
      @override.due_at = Date.today.in_time_zone("Alaska").midnight
      expect(@override.due_at).to eq Date.today.in_time_zone("Alaska").end_of_day
    end

    it "sets the date to the date given when date is not 12:00 AM" do
      expected_time = Date.today.in_time_zone("Alaska") - 11.hours
      @override.unlock_at = expected_time
      expect(@override.unlock_at).to eq expected_time
    end
  end

  describe "#lock_at=" do
    before do
      @override = AssignmentOverride.new
    end

    it "sets the date to 11:59 PM of the same day when the date is 12:00 AM" do
      @override.lock_at = Date.today.in_time_zone("Alaska").midnight
      expect(@override.lock_at).to eq Date.today.in_time_zone("Alaska").end_of_day
    end

    it "sets the date to the date given when date is not 12:00 AM" do
      expected_time = Date.today.in_time_zone("Alaska") - 11.hours
      @override.lock_at = expected_time
      expect(@override.lock_at).to eq expected_time
      @override.lock_at = nil
      expect(@override.lock_at).to be_nil
    end
  end

  describe "#availability_expired?" do
    subject { override.availability_expired? }

    let(:override) { assignment_override_model }

    context "without an overridden lock_at" do
      before do
        override.lock_at_overridden = false
      end

      it { is_expected.to be(false) }
    end

    context "with an overridden lock_at" do
      before do
        override.lock_at_overridden = true
      end

      context "never locks" do
        before do
          override.lock_at = nil
        end

        it { is_expected.to be(false) }
      end

      context "not yet locked" do
        before do
          override.lock_at = 10.minutes.from_now
        end

        it { is_expected.to be(false) }
      end

      context "already locked" do
        before do
          override.lock_at = 10.minutes.ago
        end

        it "returns false if the override is ad hoc" do
          override.set_type = "ADHOC"
          expect(subject).to be(false)
        end

        it "returns true if the override is not ad hoc" do
          override.set_type = "CourseSection"
          expect(subject).to be(true)
        end
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

  describe "#update_grading_period_grades with no grading periods" do
    it "does not update grades when due_at changes" do
      assignment_model
      expect_any_instance_of(Course).not_to receive(:recompute_student_scores)
      override = AssignmentOverride.new
      override.assignment = @assignment
      override.due_at = 6.months.ago
      override.save!
    end
  end

  describe "#update_grading_period_grades" do
    before :once do
      @override = AssignmentOverride.new(set_type: "ADHOC", due_at_overridden: true)
      student_in_course
      @assignment = assignment_model(course: @course)
      @grading_period_group = @course.root_account.grading_period_groups.create!(title: "Example Group")
      @grading_period_group.enrollment_terms << @course.enrollment_term
      @grading_period_group.grading_periods.create!(
        title: "GP1",
        start_date: 9.months.ago,
        end_date: 5.months.ago
      )
      @grading_period_group.grading_periods.create!(
        title: "GP2",
        start_date: 4.months.ago,
        end_date: 2.months.from_now
      )
      @course.enrollment_term.save!
      @assignment.reload
      @override.assignment = @assignment
      @override.save!
      @override.assignment_override_students.create(user: @student)
    end

    it "does not update grades if there are no students on this override" do
      @override.assignment_override_students.clear
      expect_any_instance_of(Course).not_to receive(:recompute_student_scores)
      @override.due_at = 6.months.ago
      @override.save!
    end

    it "updates grades when due_at changes to a grading period" do
      expect_any_instance_of(Course).to receive(:recompute_student_scores).twice
      @override.due_at = 6.months.ago
      @override.save!
    end

    it "updates grades twice when due_at changes to another grading period" do
      @override.due_at = 1.month.ago
      @override.save!
      expect_any_instance_of(Course).to receive(:recompute_student_scores).twice
      @override.due_at = 6.months.ago
      @override.save!
    end

    it "does not update grades if grading period did not change" do
      @override.due_at = 1.month.ago
      @override.save!
      expect_any_instance_of(Course).not_to receive(:recompute_student_scores)
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
      expect(SubmissionLifecycleManager).to receive(:recompute).with(@assignment)
      new_override = @assignment.assignment_overrides.build
      new_override.title = "New Override"
      new_override.override_due_at(3.days.from_now)
      new_override.save!
    end

    it "triggers when overridden due_at changes" do
      expect(SubmissionLifecycleManager).to receive(:recompute).with(@assignment)
      @override.override_due_at(5.days.from_now)
      @override.save
    end

    it "triggers when overridden due_at changes to nil" do
      expect(SubmissionLifecycleManager).to receive(:recompute).with(@assignment)
      @override.override_due_at(nil)
      @override.save
    end

    it "triggers when due_at_overridden changes" do
      expect(SubmissionLifecycleManager).to receive(:recompute).with(@assignment)
      @override.clear_due_at_override
      @override.save
    end

    it "triggers when applicable override deleted" do
      expect(SubmissionLifecycleManager).to receive(:recompute).with(@assignment)
      @override.destroy
    end

    it "triggers when applicable override undeleted" do
      @override.destroy

      expect(SubmissionLifecycleManager).to receive(:recompute).with(@assignment)
      @override.workflow_state = "active"
      @override.save
    end

    it "triggers when override without a due_date is created" do
      expect(SubmissionLifecycleManager).to receive(:recompute)
      @assignment.assignment_overrides.create
    end

    it "triggers when override without a due_date deleted" do
      @override.clear_due_at_override
      @override.save

      expect(SubmissionLifecycleManager).to receive(:recompute)
      @override.destroy
    end

    it "triggers when override without a due_date undeleted" do
      @override.clear_due_at_override
      @override.destroy

      expect(SubmissionLifecycleManager).to receive(:recompute)
      @override.workflow_state = "active"
      @override.save
    end

    it "does not trigger when nothing changed" do
      expect(SubmissionLifecycleManager).not_to receive(:recompute)
      @override.save
    end
  end

  describe "as_hash" do
    let(:due_at) { Time.utc(2013, 1, 10, 12, 30) }
    let(:unlock_at) { Time.utc(2013, 1, 9, 12, 30) }
    let(:lock_at) { Time.utc(2013, 1, 11, 12, 30) }
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
      allow(@override).to receive(:set_type).and_return "NOT_ADHOC"
      expect(@override).not_to receive(:destroy)

      @override.destroy_if_empty_set
    end

    it "does nothing if the set is not empty" do
      allow(@override).to receive_messages(set_type: "ADHOC", set: [1, 2, 3])
      expect(@override).not_to receive(:destroy)

      @override.destroy_if_empty_set
    end

    it "destroys itself if the set is empty" do
      allow(@override).to receive_messages(set_type: "ADHOC", set: [])
      expect(@override).to receive(:destroy).once

      @override.destroy_if_empty_set
    end
  end

  describe "applies_to_students" do
    before do
      student_in_course
    end

    it "returns empty set for noop" do
      @override = assignment_override_model(course: @course)
      @override.set_type = "Noop"

      expect(@override.applies_to_students).to eq []
    end

    it "returns the right students for ADHOC" do
      @override = assignment_override_model(course: @course)
      @override.set_type = "ADHOC"

      expect(@override.applies_to_students).to eq []

      @override_student = @override.assignment_override_students.build
      @override_student.user = @student
      @override_student.save!

      expect(@override.set).to eq @override.applies_to_students
    end

    it "returns the right students for a section" do
      @override = assignment_override_model(course: @course)
      @override.set = @course.default_section
      @override.save!

      expect(@override.applies_to_students).to include(@active_student)
      expect(@override.applies_to_students).not_to include(@student)

      @course.enroll_student(@student, enrollment_state: "active", section: @override.set)

      expect(@override.applies_to_students).to include(@active_student, @student)
    end

    it "returns the right students for course sets" do
      @override = assignment_override_model(course: @course)
      @override.set = @course
      @override.save!

      expect(@override.applies_to_students).to include(@active_student)
      expect(@override.applies_to_students).to eq @course.participating_students
    end
  end

  describe "assignment_edits" do
    before do
      @override = assignment_override_model
    end

    it "returns false if no students who are active in course for ADHOC" do
      allow(@override).to receive_messages(set_type: "ADHOC", set: [])

      expect(@override.set_not_empty?).to be false
    end

    it "returns true if no students who are active in course and CourseSection or Group" do
      allow(@override).to receive(:set_type).and_return "CourseSection"
      allow(@override).to receive(:set).and_return []

      expect(@override.set_not_empty?).to be true

      allow(@override).to receive(:set_type).and_return "Group"

      expect(@override.set_not_empty?).to be true
    end

    it "returns true if has students who are active in course for ADHOC" do
      student = student_in_course(course: @override.assignment.context)
      @override.set_type = "ADHOC"
      @override_student = @override.assignment_override_students.build
      @override_student.user = student.user
      @override_student.save!

      expect(@override.set_not_empty?).to be true
    end
  end

  describe ".visible_students_only" do
    specs_require_sharding

    it "references tables correctly for an out of shard query" do
      # the critical thing is visible_students_only is called the default shard,
      # but the query executes on a different shard, but it should still be
      # well-formed (especially with qualified names)
      expect { AssignmentOverride.visible_students_only([1, 2]).shard(@shard1).to_a }.not_to raise_error
    end

    it "does not duplicate adhoc overrides containing multiple students" do
      @override = assignment_override_model
      students = Array.new(2) { @override.assignment_override_students.create(user: student_in_course.user) }

      expect(AssignmentOverride.visible_students_only(students.map(&:user_id)).count).to eq 1
    end
  end

  describe ".visible_enrollments_for basic cases" do
    subject(:visible_enrollments) do
      AssignmentOverride.visible_enrollments_for(@overrides, @student)
    end

    before do
      @override = assignment_override_model
      @overrides = [@override]
    end

    it "returns empty if provided an empty collection" do
      @overrides = []
      expect(visible_enrollments).to be_empty
    end

    it "returns empty if not provided a user" do
      @student = nil
      expect(visible_enrollments).to be_empty
    end
  end

  describe ".visible_enrollments_for" do
    subject(:visible_enrollments) do
      AssignmentOverride.visible_enrollments_for([override], @student)
    end

    before do
      @options = {}
    end

    let(:override) do
      assignment_override_model(@options)
    end

    context "when associated with an assignment" do
      before do
        assignment_model
        @options = {
          assignment: @assignment
        }
      end

      it "delegates to the course" do
        expect_any_instantiation_of(@assignment.context).to receive(:enrollments_visible_to).with(@student)
        subject
      end
    end

    context "when associated with a quiz" do
      before do
        quiz_model
        @options = {
          quiz: @quiz
        }
      end

      it "delegates to UserSearch" do
        expect_any_instantiation_of(@quiz.context).to receive(:enrollments_visible_to).with(@student)
        subject
      end
    end
  end

  describe "update_due_date_smart_alerts" do
    it "creates a ScheduledSmartAlert on save with due date" do
      override = assignment_override_model(course: @course)
      expect(ScheduledSmartAlert).to receive(:upsert)

      override.update!(due_at: 1.day.from_now, due_at_overridden: true)
    end

    it "deletes the ScheduledSmartAlert if the due date is removed" do
      override = assignment_override_model(course: @course)
      override.update!(due_at: 1.day.from_now, due_at_overridden: true)
      expect(ScheduledSmartAlert.all).to include(an_object_having_attributes(context_type: "AssignmentOverride", context_id: override.id))
      override.update!(due_at: nil)
      expect(ScheduledSmartAlert.all).to_not include(an_object_having_attributes(context_type: "AssignmentOverride", context_id: override.id))
    end

    it "deletes the ScheduledSmartAlert if the due date is changed to the past" do
      override = assignment_override_model(course: @course)
      override.update!(due_at: 1.day.from_now, due_at_overridden: true)
      expect(ScheduledSmartAlert.all).to include(an_object_having_attributes(context_type: "AssignmentOverride", context_id: override.id))
      override.update!(due_at: 1.day.ago)
      expect(ScheduledSmartAlert.all).to_not include(an_object_having_attributes(context_type: "AssignmentOverride", context_id: override.id))
    end

    it "deletes associated ScheduledSmartAlerts when the override is deleted" do
      override = assignment_override_model(course: @course)
      override.update!(due_at: 1.day.from_now, due_at_overridden: true)
      expect(ScheduledSmartAlert.all).to include(an_object_having_attributes(context_type: "AssignmentOverride", context_id: override.id))
      override.destroy
      expect(ScheduledSmartAlert.all).to_not include(an_object_having_attributes(context_type: "AssignmentOverride", context_id: override.id))
    end
  end

  describe "create" do
    it "sets the root_account_id using assignment" do
      override = assignment_override_model(course: @course)
      expect(override.root_account_id).to eq @assignment.root_account_id
    end
  end

  describe "discussion checkpoints" do
    it "allows creating a group override for a checkpoint" do
      @course.root_account.enable_feature!(:discussion_checkpoints)
      category = group_category
      group = category.groups.create!(context: @course)
      topic = DiscussionTopic.create_graded_topic!(course: @course, title: "graded_topic")
      topic.update!(group_category: category)
      topic.create_checkpoints(reply_to_topic_points: 4, reply_to_entry_points: 2)
      checkpoint = topic.reply_to_topic_checkpoint
      override = assignment_override_model(assignment: checkpoint, course: @course, set: group)
      expect(checkpoint.assignment_overrides).to include override
    end
  end
end
