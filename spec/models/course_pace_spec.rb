# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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
require_relative "../spec_helper"

describe CoursePace do
  before :once do
    course_with_student active_all: true
    @course.update start_at: "2021-06-30", restrict_enrollments_to_course_dates: true, time_zone: "UTC"
    @course.root_account.enable_feature!(:course_paces)
    @course.enable_course_paces = true
    @course.save!
    @module = @course.context_modules.create!
    @assignment = @course.assignments.create!
    @course_section = @course.course_sections.first
    @tag = @assignment.context_module_tags.create! context_module: @module, context: @course, tag_type: "context_module"
    @course_pace = @course.course_paces.create! workflow_state: "active", published_at: Time.zone.now
    @course_pace_module_item = @course_pace.course_pace_module_items.create! module_item: @tag
    @unpublished_assignment = @course.assignments.create! workflow_state: "unpublished"
    @unpublished_tag = @unpublished_assignment.context_module_tags.create! context_module: @module, context: @course, tag_type: "context_module", workflow_state: "unpublished"
    @student_enrollment = @course.student_enrollments.find_by(user_id: @student.id)
  end

  context "associations" do
    it "has functioning course association" do
      expect(@course.course_paces).to match_array([@course_pace])
      expect(@course_pace.course).to eq @course
    end

    it "has functioning course_pace_module_items association" do
      expect(@course_pace.course_pace_module_items.map(&:module_item)).to match_array([@tag, @unpublished_tag])
    end
  end

  context "scopes" do
    before :once do
      @other_section = @course.course_sections.create! name: "other_section"
      @section_plan = @course.course_paces.create! course_section: @other_section
      @student_plan = @course.course_paces.create! user: @student
    end

    it "has a working primary scope" do
      expect(@course.course_paces.primary).to match_array([@course_pace])
    end

    it "has a working for_user scope" do
      expect(@course.course_paces.for_user(@student)).to match_array([@student_plan])
    end

    it "has a working for_section scope" do
      expect(@course.course_paces.for_section(@other_section)).to match_array([@section_plan])
    end

    it "has a working section_paces scope" do
      expect(@course.course_paces.section_paces).to match_array([@section_plan])
    end

    it "has a working student_enrollment_paces scope" do
      expect(@course.course_paces.student_enrollment_paces).to match_array([@student_plan])
    end
  end

  context "course_pace_context" do
    it "requires a course" do
      bad_plan = CoursePace.create
      expect(bad_plan).not_to be_valid

      bad_plan.course = course_factory
      expect(bad_plan).to be_valid
    end

    it "disallows a user and section simultaneously" do
      course_with_student
      bad_plan = @course.course_paces.build(user: @student, course_section: @course.default_section)
      expect(bad_plan).not_to be_valid

      bad_plan.course_section = nil
      expect(bad_plan).to be_valid
    end
  end

  context "constraints" do
    it "has a unique constraint on course for active primary course paces" do
      expect { @course.course_paces.create! workflow_state: "active" }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "has a unique constraint for active section course paces" do
      @course.course_paces.create! course_section: @course.default_section, workflow_state: "active"
      expect do
        @course.course_paces.create! course_section: @course.default_section, workflow_state: "active"
      end.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "has a unique constraint for active student course paces" do
      @course.course_paces.create! user: @student, workflow_state: "active"
      expect do
        @course.course_paces.create! user: @student, workflow_state: "active"
      end.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  context "root_account" do
    it "infers root_account_id from course" do
      expect(@course_pace.root_account).to eq @course.root_account
    end
  end

  describe "#effective_name" do
    before :once do
      @section_plan = @course.course_paces.create! course_section: @course_section
      @student_plan = @course.course_paces.create! user: @student
    end

    it "returns the user's name for a student pace" do
      expect(@student_plan.effective_name).to eq @student.name
    end

    it "returns the section's name for a section pace" do
      expect(@section_plan.effective_name).to eq @course_section.name
    end

    it "returns the course's name for a course pace" do
      expect(@course_pace.effective_name).to eq @course.name
    end
  end

  describe "#type" do
    before :once do
      @section_plan = @course.course_paces.create! course_section: @course_section
      @student_plan = @course.course_paces.create! user: @student
    end

    it "returns 'StudentEnrollment' for a student pace" do
      expect(@student_plan.type).to eq "StudentEnrollment"
    end

    it "returns 'Section' for a section pace" do
      expect(@section_plan.type).to eq "Section"
    end

    it "returns 'Course' for a course pace" do
      expect(@course_pace.type).to eq "Course"
    end
  end

  describe "#duration" do
    it "returns 1 if there are no module items" do
      expect(@course_pace.duration).to eq 1
    end

    context "multiple paced module items exist" do
      before do
        @course.context_module_tags.each do |tag|
          @course_pace.course_pace_module_items.create! module_item: tag, duration: 1
        end
      end

      it "returns the sum of all item durations, taking into account the day of enrollment" do
        expect(@course_pace.duration).to eq 3
      end
    end
  end

  context "duplicate" do
    it "returns an initialized duplicate of the course pace" do
      duplicate_course_pace = @course_pace.duplicate
      expect(duplicate_course_pace.class).to eq(CoursePace)
      expect(duplicate_course_pace.persisted?).to be(false)
      expect(duplicate_course_pace.id).to be_nil
    end

    it "supports passing in options" do
      opts = { user_id: 1 }
      duplicate_course_pace = @course_pace.duplicate(opts)
      expect(duplicate_course_pace.user_id).to eq(opts[:user_id])
      expect(duplicate_course_pace.course_section_id).to eq(opts[:course_section_id])
    end
  end

  context "publish" do
    def fancy_midnight_rounded_to_last_second(date)
      CanvasTime.fancy_midnight(date.to_datetime).to_time.in_time_zone("UTC")
    end

    before :once do
      @course_pace.update! end_date: "2021-09-30"
      @student_enrollment.update(start_at: @course_pace.start_date)
    end

    it "respects the course timezone" do
      @course.update! time_zone: "Abu Dhabi"
      @course_pace.reload.publish
      abu_due_at = @course.reload.assignments.last.assignment_overrides.last.due_at

      @course.update! time_zone: "Brasilia"
      @course_pace.reload.publish
      br_due_at = @course.reload.assignments.last.assignment_overrides.last.due_at

      @course.update! time_zone: "Mountain Time (US & Canada)"
      @course_pace.reload.publish
      mt_due_at = @course.reload.assignments.last.assignment_overrides.last.due_at

      expected_abu_due_at = CanvasTime.fancy_midnight(Date.parse(@course.start_at.to_s).in_time_zone("UTC")) - 4.hours
      expected_br_due_at  = CanvasTime.fancy_midnight(Date.parse(@course.start_at.to_s).in_time_zone("UTC")) + 3.hours

      # DST, otherwise it'd be +7 (-0700)
      expected_mt_due_at  = CanvasTime.fancy_midnight(Date.parse(@course.start_at.to_s).in_time_zone("UTC")) + 6.hours

      expect([abu_due_at, br_due_at, mt_due_at]).to eq([expected_abu_due_at, expected_br_due_at, expected_mt_due_at])
    end

    it "creates an override for students" do
      expect(@assignment.due_at).to be_nil
      expect(@unpublished_assignment.due_at).to be_nil
      expect(@course_pace.publish).to be(true)
      expect(AssignmentOverride.count).to eq(2)
    end

    it "creates assignment overrides for the course pace user" do
      @course_pace.update(user_id: @student)
      expect(AssignmentOverride.count).to eq(0)
      expect(@course_pace.publish).to be(true)
      expect(AssignmentOverride.count).to eq(2)
      @course.assignments.each do |assignment|
        assignment_override = assignment.assignment_overrides.first
        expect(assignment_override.due_at).to eq(fancy_midnight_rounded_to_last_second(@course.start_at.to_s))
        expect(assignment_override.assignment_override_students.first.user_id).to eq(@student.id)
      end
    end

    it "creates assignment overrides based on the enrollment start_at" do
      @student_enrollment.update(start_at: "2021-09-10")
      expect(AssignmentOverride.count).to eq(0)
      expect(@course_pace.publish).to be(true)
      expect(AssignmentOverride.count).to eq(2)
      @course.assignments.each do |assignment|
        assignment_override = assignment.assignment_overrides.first
        expect(assignment_override.due_at).to eq(fancy_midnight_rounded_to_last_second("2021-09-10"))
        expect(assignment_override.assignment_override_students.first.user_id).to eq(@student.id)
      end
    end

    it "creates assignment overrides based on the enrollment created_at when start_at is nil" do
      @student_enrollment.reload.update!(start_at: nil, created_at: "2021-09-17")
      expect(AssignmentOverride.count).to eq(0)
      expect(@course_pace.publish).to be(true)
      expect(AssignmentOverride.count).to eq(2)
      @course.assignments.each do |assignment|
        assignment_override = assignment.assignment_overrides.first
        expect(assignment_override.due_at).to eq(fancy_midnight_rounded_to_last_second("2021-09-17"))
        expect(assignment_override.assignment_override_students.first.user_id).to eq(@student.id)
      end
    end

    it "removes the user from an adhoc assignment override if it includes other students" do
      student2 = user_model
      StudentEnrollment.create!(user: student2, course: @course, start_at: @course_pace.start_date)
      assignment_override = @assignment.assignment_overrides.create(
        title: "ADHOC Test",
        workflow_state: "active",
        set_type: "ADHOC",
        due_at: fancy_midnight_rounded_to_last_second("2021-09-05"),
        due_at_overridden: true
      )
      assignment_override.assignment_override_students << AssignmentOverrideStudent.new(user_id: @student, no_enrollment: false)
      assignment_override.assignment_override_students << AssignmentOverrideStudent.new(user_id: student2, no_enrollment: false)

      @course_pace.update(user_id: @student)
      expect(@assignment.assignment_overrides.count).to eq(1)
      assignment_override = @assignment.assignment_overrides.first
      expect(assignment_override.due_at).to eq(fancy_midnight_rounded_to_last_second("2021-09-05"))
      expect(assignment_override.assignment_override_students.pluck(:user_id)).to eq([@student.id, student2.id])
      expect(@course_pace.publish).to be(true)
      expect(@assignment.assignment_overrides.count).to eq(2)
      expect(assignment_override.due_at).to eq(fancy_midnight_rounded_to_last_second("2021-09-05"))
      expect(assignment_override.assignment_override_students.pluck(:user_id)).to eq([student2.id])
      assignment_override2 = @assignment.assignment_overrides.second
      expect(assignment_override2.due_at).to eq(fancy_midnight_rounded_to_last_second(@course.start_at.to_s))
      expect(assignment_override2.assignment_override_students.pluck(:user_id)).to eq([@student.id])
    end

    it "adds the user to an adhoc assignment override if it already exists for that date" do
      # The due_at times are stored in the databas as UTC times, so we need to convert the timezone to UTC
      assignment_override = @assignment.assignment_overrides.create!(
        title: "ADHOC Test",
        workflow_state: "active",
        set_type: "ADHOC",
        due_at: fancy_midnight_rounded_to_last_second(@course.start_at.to_s),
        due_at_overridden: true
      )
      assignment_override.assignment_override_students << AssignmentOverrideStudent.new(user_id: @student, no_enrollment: false)
      assignment_override2 = @assignment.assignment_overrides.create!(
        title: "ADHOC Test",
        workflow_state: "active",
        set_type: "ADHOC",
        due_at: fancy_midnight_rounded_to_last_second("2021-09-06"),
        due_at_overridden: true
      )
      student2 = user_model
      StudentEnrollment.create!(user: student2, course: @course, start_at: @course_pace.start_date)
      assignment_override2.assignment_override_students << AssignmentOverrideStudent.new(user_id: student2, no_enrollment: false)
      expect(@assignment.assignment_overrides.active.count).to eq(2)
      expect(@course_pace.publish).to be(true)
      expect(@assignment.assignment_overrides.active.count).to eq(1)
      assignment_override = @assignment.assignment_overrides.active.first
      # We need to round to the last whole second to ensure the due_at is the same
      expect(assignment_override.due_at).to eq(fancy_midnight_rounded_to_last_second(@course.start_at.to_s))
      expect(assignment_override.assignment_override_students.pluck(:user_id).sort).to eq([@student.id, student2.id])
    end

    it "creates assignment overrides for the course pace course section" do
      @course_pace.update(course_section: @course_section)
      expect(@assignment.assignment_overrides.count).to eq(0)
      expect(@course_pace.publish).to be(true)
      expect(@assignment.assignment_overrides.count).to eq(1)
      assignment_override = @assignment.assignment_overrides.first
      expect(assignment_override.title).to eq("Course Pacing")
      expect(assignment_override.due_at).to eq(fancy_midnight_rounded_to_last_second(@course.start_at.to_s))
      expect(assignment_override.assignment_override_students.first.user_id).to eq(@student.id)
    end

    it "updates overrides that are already present if the days have changed" do
      @course_pace.publish
      assignment_override = @assignment.assignment_overrides.first
      expect(assignment_override.due_at).to eq(fancy_midnight_rounded_to_last_second(@course.start_at.to_s))
      @course_pace_module_item.update duration: 2
      @course_pace.publish
      assignment_override.reload
      expect(assignment_override.due_at).to eq(fancy_midnight_rounded_to_last_second("2021-07-02"))
    end

    it "updates user overrides that are already present if the days have changed" do
      @course_pace.update(user_id: @student)
      @course_pace.publish
      expect(@assignment.assignment_overrides.active.count).to eq(1)
      @course_pace_module_item.update duration: 2
      @course_pace.publish
      expect(@assignment.assignment_overrides.active.count).to eq(1)
      assignment_override = @assignment.assignment_overrides.active.first
      expect(assignment_override.due_at).to eq(fancy_midnight_rounded_to_last_second("2021-07-02"))
      expect(assignment_override.assignment_override_students.first.user_id).to eq(@student.id)
    end

    it "updates course section overrides that are already present if the days have changed" do
      @course_pace.update(course_section: @course_section)
      @course_pace.publish
      expect(@assignment.assignment_overrides.active.count).to eq(1)
      @course_pace_module_item.update duration: 2
      @course_pace.publish
      expect(@assignment.assignment_overrides.active.count).to eq(1)
      assignment_override = @assignment.assignment_overrides.active.first
      expect(assignment_override.due_at).to eq(fancy_midnight_rounded_to_last_second("2021-07-02"))
      expect(assignment_override.assignment_override_students.first.user_id).to eq(@student.id)
    end

    it "does not change assignment due date when user course pace is published if an assignment override already exists" do
      @course_pace.publish
      assignment_override = @assignment.assignment_overrides.first
      expect(assignment_override.due_at).to eq(fancy_midnight_rounded_to_last_second(@course.start_at.to_s))
      expect(@assignment.assignment_overrides.active.count).to eq(1)

      student_course_pace = @course.course_paces.create!(user: @student, workflow_state: "active")
      student_course_pace.publish
      assignment_override.reload
      expect(assignment_override.due_at).to eq(fancy_midnight_rounded_to_last_second(@course.start_at.to_s))
      expect(@assignment.assignment_overrides.active.count).to eq(1)
    end

    it "sets overrides for graded discussions" do
      topic = graded_discussion_topic(context: @course)
      topic_tag = @module.add_item type: "discussion_topic", id: topic.id
      @course_pace.course_pace_module_items.create! module_item: topic_tag
      expect(topic.assignment.assignment_overrides.count).to eq 0
      expect(@course_pace.publish).to be(true)
      expect(topic.assignment.assignment_overrides.count).to eq 1
    end

    it "does not change overrides for students that have course paces if the course pace is published" do
      expect(@course_pace.publish).to be(true)
      expect(@assignment.assignment_overrides.active.count).to eq(1)
      assignment_override = @assignment.assignment_overrides.active.first
      expect(assignment_override.due_at).to eq(fancy_midnight_rounded_to_last_second(@course.start_at.to_s))
      # Publish student specific course pace and verify dates have changed
      student_course_pace = @course.course_paces.create! user: @student, workflow_state: "active"
      @course.student_enrollments.find_by(user: @student).update(start_at: "2021-09-06")
      student_course_pace.course_pace_module_items.create! module_item: @tag
      expect(student_course_pace.publish).to be(true)
      assignment_override.reload
      expect(assignment_override.due_at).to eq(fancy_midnight_rounded_to_last_second("2021-09-06"))
      # Republish course pace and verify dates have not changed on student specific override
      @course_pace.instance_variable_set(:@student_enrollments, nil)
      expect(@course_pace.publish).to be(true)
      assignment_override.reload
      expect(assignment_override.due_at).to eq(fancy_midnight_rounded_to_last_second("2021-09-06"))
    end

    it "does not change overrides for sections that have course paces if the course pace is published" do
      @student_enrollment.reload.update(start_at: nil, created_at: Time.at(0))
      expect(@course_pace.publish).to be(true)
      expect(@assignment.assignment_overrides.active.count).to eq(1)
      assignment_override = @assignment.assignment_overrides.active.first
      expect(assignment_override.due_at).to eq(fancy_midnight_rounded_to_last_second(@course.start_at.to_s))
      # Publish course section specific course pace and verify dates have changed
      @course_section.update(start_at: Date.parse("2021-09-06").in_time_zone(@course.time_zone), restrict_enrollments_to_section_dates: true)
      section_course_pace = @course.course_paces.create! course_section: @course_section, workflow_state: "active"
      section_course_pace.course_pace_module_items.create! module_item: @tag
      expect(section_course_pace.publish).to be(true)
      assignment_override.reload
      expect(assignment_override.due_at).to eq(fancy_midnight_rounded_to_last_second("2021-09-06"))
      # Republish course pace and verify dates have not changed on student specific override
      @course_pace.instance_variable_set(:@student_enrollments, nil)
      expect(@course_pace.publish).to be(true)
      assignment_override.reload
      expect(assignment_override.due_at).to eq(fancy_midnight_rounded_to_last_second("2021-09-06"))
    end

    it "does not change overrides for students that have course paces if the course section course pace is published" do
      @course_pace.update(course_section: @course_section)
      expect(@course_pace.publish).to be(true)
      expect(@assignment.assignment_overrides.active.count).to eq(1)
      assignment_override = @assignment.assignment_overrides.active.first
      expect(assignment_override.due_at).to eq(fancy_midnight_rounded_to_last_second(@course.start_at.to_s))
      # Publish student specific course pace and verify dates have changed
      @course.student_enrollments.find_by(user: @student).update(start_at: "2021-09-06")
      student_course_pace = @course.course_paces.create! user: @student, workflow_state: "active"
      student_course_pace.course_pace_module_items.create! module_item: @tag
      expect(student_course_pace.publish).to be(true)
      assignment_override.reload
      expect(assignment_override.due_at).to eq(fancy_midnight_rounded_to_last_second("2021-09-06"))
      # Republish course pace and verify dates have not changed on student specific override
      @course_pace.instance_variable_set(:@student_enrollments, nil)
      expect(@course_pace.publish).to be(true)
      assignment_override.reload
      expect(assignment_override.due_at).to eq(fancy_midnight_rounded_to_last_second("2021-09-06"))
    end

    it "logs if the assignment being updated has been completed" do
      @assignment.submit_homework(@student, body: "Test")
      allow(InstStatsd::Statsd).to receive(:increment).and_call_original
      expect(@course_pace.publish).to be(true)
      expect(InstStatsd::Statsd).to have_received(:increment).with("course_pacing.submitted_assignment_date_change")
    end

    it "compresses to hard end dates" do
      @course_pace.course_pace_module_items.update(duration: 900)
      expect(AssignmentOverride.count).to eq(0)
      expect(@course_pace.publish).to be(true)
      expect(AssignmentOverride.count).to eq(2)
      expect(AssignmentOverride.last.due_at).to eq(fancy_midnight_rounded_to_last_second(@course_pace.end_date.to_s))
      expect(@course_pace.course_pace_module_items.reload.pluck(:duration)).to eq([900, 900])
    end
  end

  describe "default plan start_at" do
    orig_zone = Time.zone
    before do
      @course.update start_at: nil
      @course_pace.user_id = nil
      Time.zone = @course.time_zone
    end

    after do
      Time.zone = orig_zone
    end

    it "returns student enrollment date, if working on behalf of a student" do
      student3 = user_model
      enrollment = StudentEnrollment.create!(user: student3, course: @course)
      enrollment.update start_at: "2022-01-29"
      @course_pace.user_id = student3.id
      expect(@course_pace.start_date.to_date).to eq(Date.parse("2022-01-29"))

      result = @course_pace.start_date(with_context: true)
      expect(result[:start_date].to_date).to eq(Date.parse("2022-01-29"))
      expect(result[:start_date_context]).to eq("user")
    end

    it "returns section start if available" do
      other_section = @course.course_sections.create! name: "other_section", start_at: "2022-01-30"
      section_plan = @course.course_paces.create! course_section: other_section
      expect(section_plan.start_date.to_date).to eq(Date.parse("2022-01-30"))

      result = section_plan.start_date(with_context: true)
      expect(result[:start_date].to_date).to eq(Date.parse("2022-01-30"))
      expect(result[:start_date_context]).to eq("section")
    end

    it "returns course start if available" do
      @course.update start_at: "2022-01-28"
      expect(@course_pace.start_date.to_date).to eq(Date.parse("2022-01-28"))

      result = @course_pace.start_date(with_context: true)
      expect(result[:start_date].to_date).to eq(Date.parse("2022-01-28"))
      expect(result[:start_date_context]).to eq("course")
    end

    it "returns course's term start if available" do
      @course.enrollment_term.update start_at: Time.zone.parse("2022-01-27")
      expect(@course_pace.start_date.to_date).to eq(Date.parse("2022-01-27"))

      result = @course_pace.start_date(with_context: true)
      expect(result[:start_date].to_date).to eq(Date.parse("2022-01-27"))
      expect(result[:start_date_context]).to eq("term")
    end

    it "returns today date as a last resort" do
      # there's an extremely tiny window where the date may have changed between
      # when start_date called Time.now and now causing this to fail
      # I don't think it's worth worrying about.
      expect(@course_pace.start_date.to_date).to eq(Time.now.to_date)

      result = @course_pace.start_date(with_context: true)
      expect(result[:start_date].to_date).to eq(Time.now.to_date)
      expect(result[:start_date_context]).to eq("hypothetical")
    end
  end

  describe "default plan effective_end_at" do
    orig_zone = Time.zone
    before do
      @course.update start_at: nil
      @course_pace.user_id = nil
      @student = create_users(1, return_type: :record).first
      @course.enroll_student(@student, enrollment_state: "active")
    end

    after do
      Time.zone = orig_zone
    end

    it "returns hard end date if set" do
      @course_pace.hard_end_dates = true
      @course_pace[:end_date] = "2022-03-17"
      result = @course_pace.effective_end_date(with_context: true)
      expect(result[:end_date].to_date).to eq(Date.parse("2022-03-17"))
      expect(result[:end_date_context]).to eq("hard")
    end

    it "returns section's end date if set and if it is a student plan" do
      new_section = @course.course_sections.create! name: "new_section", end_at: "2022-01-30"
      @course.enroll_student(@student, section: new_section, allow_multiple_enrollments: true, enrollment_state: "active")
      @course.course_paces.create! course_section: new_section
      @course_pace[:user_id] = @student.id
      result = @course_pace.effective_end_date(with_context: true)
      expect(result[:end_date].to_date).to eq(Date.parse("2022-01-30"))
      expect(result[:end_date_context]).to eq("user")
    end

    it "returns the course end date if the section's end date is not set and if it is a student plan" do
      @course.update conclude_at: Time.zone.parse("2022-01-28T13:00:00")
      new_section = @course.course_sections.create! name: "new_section"
      @course.enroll_student(@student, section: new_section, allow_multiple_enrollments: true, enrollment_state: "active")
      @course_pace[:user_id] = @student.id
      result = @course_pace.effective_end_date(with_context: true)
      expect(result[:end_date].to_date).to eq(Date.parse("2022-01-28"))
      expect(result[:end_date_context]).to eq("user")
    end

    it "returns course end if available" do
      @course.update conclude_at: Time.zone.parse("2022-01-28T13:00:00")
      result = @course_pace.effective_end_date(with_context: true)
      expect(result[:end_date].to_date).to eq(Date.parse("2022-01-28"))
      expect(result[:end_date_context]).to eq("course")
    end

    it "returns previous day if course end is midnight" do
      @course.update conclude_at: Time.zone.parse("2022-01-28T00:00:00")
      result = @course_pace.effective_end_date(with_context: true)
      expect(result[:end_date].to_date).to eq(Date.parse("2022-01-27"))
      expect(result[:end_date_context]).to eq("course")
    end

    it "returns course's term end if available" do
      @course.enrollment_term.update end_at: Time.zone.parse("2022-01-27T13:00:00")
      result = @course_pace.effective_end_date(with_context: true)
      expect(result[:end_date].to_date).to eq(Date.parse("2022-01-27"))
      expect(result[:end_date_context]).to eq("term")
    end

    it "returns section end date if applicable" do
      other_section = @course.course_sections.create! name: "other_section", end_at: "2022-01-30"
      section_plan = @course.course_paces.create! course_section: other_section
      result = section_plan.effective_end_date(with_context: true)
      expect(result[:end_date].to_date).to eq(Date.parse("2022-01-30"))
      expect(result[:end_date_context]).to eq("section")
    end

    it "returns an hypothetical context-type for student pace when no fixed date is available" do
      @course_pace[:user_id] = @student.id
      @course.restrict_enrollments_to_course_dates = false
      @course.enrollment_term.update start_at: nil, end_at: nil
      result = @course_pace.effective_end_date(with_context: true)
      expect(result[:end_date_context]).to eq("hypothetical")
      expect(result[:end_date]).to be_nil
    end

    it "returns nil if no fixed date is available" do
      @course.restrict_enrollments_to_course_dates = false
      @course.enrollment_term.update start_at: nil, end_at: nil
      result = @course_pace.effective_end_date(with_context: true)
      expect(result[:end_date]).to be_nil
      expect(result[:end_date_context]).to eq("hypothetical")
    end
  end

  context "course pace creates" do
    before :once do
      course_with_student active_all: true
      @course.root_account.enable_feature!(:course_paces)
      @course.enable_course_paces = true
      @course.save!
      @module = @course.context_modules.create!
      @assignment = @course.assignments.create!
      @tag = @assignment.context_module_tags.create! context_module: @module, context: @course, tag_type: "context_module"
    end

    it "writes the number of course-type course paces to statsd" do
      allow(InstStatsd::Statsd).to receive(:increment).and_call_original
      @course_pace = @course.course_paces.create! workflow_state: "active"
      expect(InstStatsd::Statsd).to have_received(:increment).with("course_pacing.course_paces.count").once
    end

    it "writes the number of section-type course paces to statsd" do
      allow(InstStatsd::Statsd).to receive(:increment).and_call_original
      @new_section = @course.course_sections.create! name: "new_section"
      @section_plan = @course.course_paces.create! course_section: @new_section
      expect(InstStatsd::Statsd).to have_received(:increment).with("course_pacing.section_paces.count").once
    end

    it "writes the number of user-type course paces to statsd" do
      allow(InstStatsd::Statsd).to receive(:increment).and_call_original
      @course.course_paces.create!(user: @student, workflow_state: "active")
      expect(InstStatsd::Statsd).to have_received(:increment).with("course_pacing.user_paces.count").once
    end
  end

  context "course pace deletes" do
    before :once do
      Account.site_admin.enable_feature!(:course_paces_redesign)
      course_with_student active_all: true
      @course.root_account.enable_feature!(:course_paces)
      @course.enable_course_paces = true
      @course.save!
      @module = @course.context_modules.create!
      @assignment = @course.assignments.create!
      @tag = @assignment.context_module_tags.create! context_module: @module, context: @course, tag_type: "context_module"
    end

    it "increments the course pace deletion to statsd" do
      # This destroy does work and we log it here, but in general, the code doesn't allow for the default
      # course pace to be deleted for now.
      allow(InstStatsd::Statsd).to receive(:increment).and_call_original
      course_pace = @course.course_paces.create! workflow_state: "active"
      course_pace.destroy!
      expect(InstStatsd::Statsd).to have_received(:increment).with("course_pacing.deleted_course_pace").once
    end

    it "increments the section-type course pace deletion to statsd" do
      allow(InstStatsd::Statsd).to receive(:increment).and_call_original
      new_section = @course.course_sections.create! name: "new_section"
      section_plan = @course.course_paces.create! course_section: new_section
      section_plan.destroy!
      expect(InstStatsd::Statsd).to have_received(:increment).with("course_pacing.deleted_section_pace").once
    end

    it "increments the student-type course pace deletion to statsd" do
      allow(InstStatsd::Statsd).to receive(:increment).and_call_original
      user_plan = @course.course_paces.create!(user: @student, workflow_state: "active")
      user_plan.destroy!
      expect(InstStatsd::Statsd).to have_received(:increment).with("course_pacing.deleted_user_pace").once
    end
  end

  context "course pace publish logs statsd for various values" do
    before :once do
      course_with_student active_all: true
      @course.root_account.enable_feature!(:course_paces)
      @course.enable_course_paces = true
      @course.save!
      @module = @course.context_modules.create!
      @assignment = @course.assignments.create!
      @tag = @assignment.context_module_tags.create! context_module: @module, context: @course, tag_type: "context_module"
    end

    it "increments on initial publish when exclude_weekends set to true" do
      allow(InstStatsd::Statsd).to receive(:increment)

      @course_pace = @course.course_paces.create!(workflow_state: "active")

      expect(InstStatsd::Statsd).to have_received(:increment).with("course_pacing.weekends_excluded")
    end

    it "does not decrement on initial publish when exclude_weekends set to false" do
      allow(InstStatsd::Statsd).to receive(:decrement)

      @course_pace = @course.course_paces.create!(workflow_state: "active", exclude_weekends: false)

      expect(InstStatsd::Statsd).not_to have_received(:decrement).with("course_pacing.weekends_excluded")
    end

    it "increments on subsequent publish when exclude_weekends initially false then set to true" do
      allow(InstStatsd::Statsd).to receive(:increment)
      allow(InstStatsd::Statsd).to receive(:decrement)

      @course_pace = @course.course_paces.create!(workflow_state: "active", exclude_weekends: false)
      @course_pace.update!(exclude_weekends: true)
      @course_pace.publish

      expect(InstStatsd::Statsd).not_to have_received(:decrement).with("course_pacing.weekends_excluded")
      expect(InstStatsd::Statsd).to have_received(:increment).with("course_pacing.weekends_excluded")
    end

    it "decrements on subsequent publish when exclude_weekends initially true then set to false" do
      allow(InstStatsd::Statsd).to receive(:increment)
      allow(InstStatsd::Statsd).to receive(:decrement)

      @course_pace = @course.course_paces.create!(workflow_state: "active")
      @course_pace.update!(exclude_weekends: false)
      @course_pace.publish

      expect(InstStatsd::Statsd).to have_received(:increment).with("course_pacing.weekends_excluded")
      expect(InstStatsd::Statsd).to have_received(:decrement).with("course_pacing.weekends_excluded")
    end

    it "logs the average module item duration as a count" do
      allow(InstStatsd::Statsd).to receive(:count)

      course_pace = @course.course_paces.create!(workflow_state: "active")
      course_pace_module_item = course_pace.course_pace_module_items.create! module_item: @tag
      course_pace_module_item.update duration: 2
      course_pace.publish

      expect(InstStatsd::Statsd).to have_received(:count).with("course_pacing.average_assignment_duration", 2)
    end

    it "logs updated average module item duration as a count when new assignment added" do
      allow(InstStatsd::Statsd).to receive(:count)

      course_pace = @course.course_paces.create!(workflow_state: "active")
      course_pace_module_item = course_pace.course_pace_module_items.create! module_item: @tag
      course_pace_module_item.update duration: 2
      course_pace.publish

      assignment = @course.assignments.create!
      new_tag = assignment.context_module_tags.create! context_module: @module, context: @course, tag_type: "context_module"

      new_course_pace_module_item = course_pace.course_pace_module_items.create! module_item: new_tag
      new_course_pace_module_item.update duration: 4
      course_pace.publish

      expect(InstStatsd::Statsd).to have_received(:count).with("course_pacing.average_assignment_duration", 3)
    end

    it "doesn't log when no context modules exist" do
      allow(InstStatsd::Statsd).to receive(:count)

      course_pace = @course.course_paces.create!(workflow_state: "active")
      course_pace.publish

      expect(InstStatsd::Statsd).not_to have_received(:count).with("course_pacing.average_assignment_duration", 0)
    end

    it "logs when no context modules item duration is o" do
      allow(InstStatsd::Statsd).to receive(:count)

      course_pace = @course.course_paces.create!(workflow_state: "active")
      course_pace_module_item = course_pace.course_pace_module_items.create! module_item: @tag
      course_pace_module_item.update duration: 0
      course_pace.publish

      expect(InstStatsd::Statsd).to have_received(:count).with("course_pacing.average_assignment_duration", 0)
    end
  end

  context "course pace blackout date counts logging" do
    before do
      Account.site_admin.enable_feature! :account_level_blackout_dates
      course_with_student active_all: true
      @course.root_account.enable_feature!(:course_paces)
      @course.enable_course_paces = true
      @course.save!
      @module = @course.context_modules.create!
      @assignment = @course.assignments.create!
      @tag = @assignment.context_module_tags.create! context_module: @module, context: @course, tag_type: "context_module"
    end

    it "logs the count of course blackout dates when pace is created" do
      allow(InstStatsd::Statsd).to receive(:count)
      CalendarEvent.create!({
                              title: "calendar event blackout event",
                              start_at: Time.zone.now.beginning_of_day,
                              end_at: Time.zone.now.beginning_of_day,
                              context: @course,
                              blackout_date: true
                            })
      @course.course_paces.create!(workflow_state: "active")
      expect(InstStatsd::Statsd).to have_received(:count).with("course_pacing.course_blackout_dates.count", 1)
    end

    it "logs course and account logs separately when course pace is created" do
      allow(InstStatsd::Statsd).to receive(:count)
      CalendarEvent.create!({
                              title: "calendar event blackout event",
                              start_at: Time.zone.now.beginning_of_day,
                              end_at: Time.zone.now.beginning_of_day,
                              context: @course,
                              blackout_date: true
                            })
      CalendarEvent.create!({
                              title: "account event blackout event",
                              start_at: Time.zone.now.beginning_of_day,
                              end_at: Time.zone.now.beginning_of_day,
                              context: Account.find(@course.root_account.id),
                              blackout_date: true
                            })
      @course.course_paces.create!(workflow_state: "active")
      expect(InstStatsd::Statsd).to have_received(:count).with("course_pacing.course_blackout_dates.count", 1).once
      expect(InstStatsd::Statsd).to have_received(:count).with("course_pacing.account_blackout_dates.count", 1).once
    end

    it "logs a zero value if no course blackout dates" do
      allow(InstStatsd::Statsd).to receive(:count)

      @course.course_paces.create!(workflow_state: "active")
      expect(InstStatsd::Statsd).to have_received(:count).with("course_pacing.course_blackout_dates.count", 0)
    end

    it "logs the count of account blackout dates when pace is created" do
      allow(InstStatsd::Statsd).to receive(:count)
      CalendarEvent.create!({
                              title: "calendar event blackout event",
                              start_at: Time.zone.now.beginning_of_day,
                              end_at: Time.zone.now.beginning_of_day,
                              context: Account.find(@course.root_account.id),
                              blackout_date: true
                            })
      @course.course_paces.create!(workflow_state: "active")
      expect(InstStatsd::Statsd).to have_received(:count).with("course_pacing.account_blackout_dates.count", 1)
    end

    it "logs a zero value if no account blackout dates" do
      allow(InstStatsd::Statsd).to receive(:count)

      @course.course_paces.create!(workflow_state: "active")
      expect(InstStatsd::Statsd).to have_received(:count).with("course_pacing.account_blackout_dates.count", 0)
    end

    it "creates a course in a subaccount with its own calendar events and counts all the account calendar events" do
      allow(InstStatsd::Statsd).to receive(:count)
      @subaccount1 = Account.find(@course.root_account.id).sub_accounts.create!
      @subaccount1.enable_feature!(:course_paces)
      @course1 = course_factory(account: @subaccount1, active_all: true)
      @course1.enable_course_paces = true
      @course1.save!
      @module1 = @course1.context_modules.create!
      @assignment1 = @course1.assignments.create!
      @tag = @assignment1.context_module_tags.create! context_module: @module1, context: @course1, tag_type: "context_module"

      CalendarEvent.create!({
                              title: "calendar event blackout event",
                              start_at: Time.zone.now.beginning_of_day,
                              end_at: Time.zone.now.beginning_of_day,
                              context: @course1,
                              blackout_date: true
                            })
      CalendarEvent.create!({
                              title: "account event blackout event",
                              start_at: Time.zone.now.beginning_of_day,
                              end_at: Time.zone.now.beginning_of_day,
                              context: Account.find(@course1.root_account.id),
                              blackout_date: true
                            })
      CalendarEvent.create!({
                              title: "subaccount event blackout event",
                              start_at: Time.zone.now.beginning_of_day,
                              end_at: Time.zone.now.beginning_of_day,
                              context: @subaccount1,
                              blackout_date: true
                            })
      @course1.course_paces.create!(workflow_state: "active")
      expect(InstStatsd::Statsd).to have_received(:count).with("course_pacing.course_blackout_dates.count", 1).once
      expect(InstStatsd::Statsd).to have_received(:count).with("course_pacing.account_blackout_dates.count", 2).once
    end
  end

  describe "log_module_items_count" do
    before do
      rubric = @course.rubrics.create!(title: "rubric")
      @course.context_module_tags.create!(content: rubric, context_module: @module, context: @course, workflow_state: "active")
      allow(InstStatsd::Statsd).to receive(:count)
    end

    it "logs the number of module items to statsd" do
      @course_pace.log_module_items_count
      expect(InstStatsd::Statsd).to have_received(:count).with("course.paced.paced_module_item_count", 1)
      expect(InstStatsd::Statsd).to have_received(:count).with("course.paced.all_module_item_count", 2)
    end

    it "logs during #publish" do
      @course_pace.publish
      expect(InstStatsd::Statsd).to have_received(:count).with("course.paced.paced_module_item_count", 1)
      expect(InstStatsd::Statsd).to have_received(:count).with("course.paced.all_module_item_count", 2)
    end
  end

  describe "student_enrollments" do
    before :once do
      @student1 = @student
      @student2 = student_in_course(course: @course, active_all: true).user
      @section1 = @course.default_section
      @section2 = @course.course_sections.create!
    end

    describe "on a student pace" do
      it "returns the student's pace if they have one" do
        pace = @course.course_paces.create!(user_id: @student1)
        expect(pace.student_enrollments.pluck(:user_id)).to contain_exactly(@student1.id)
      end

      it "does not include deleted enrollments" do
        pace = @course.course_paces.create!(user_id: @student1)
        @student1.enrollments.where(course: @course).first.destroy
        expect(pace.student_enrollments.pluck(:user_id)).to be_empty
      end
    end

    describe "on a section pace" do
      it "returns all the section's students when nobody has an individual pace" do
        section_pace = @course.course_paces.create!(course_section: @section1)
        expect(section_pace.student_enrollments.pluck(:user_id)).to contain_exactly(@student1.id, @student2.id)
      end

      it "doesn't include students who have their own pace" do
        section_pace = @course.course_paces.create!(course_section: @section1)
        @course.course_paces.create!(user_id: @student1)
        expect(section_pace.student_enrollments.pluck(:user_id)).to contain_exactly(@student2.id)
      end

      it "does not include deleted enrollments" do
        section_pace = @course.course_paces.create!(course_section: @section1)
        @student2.enrollments.where(course: @course).first.destroy
        expect(section_pace.student_enrollments.pluck(:user_id)).to contain_exactly(@student1.id)
      end

      it "still includes students with deleted student paces" do
        section_pace = @course.course_paces.create!(course_section: @section1)
        @course.course_paces.create!(user_id: @student1, workflow_state: "deleted")
        expect(section_pace.student_enrollments.pluck(:user_id)).to contain_exactly(@student1.id, @student2.id)
      end
    end

    describe "on the (default) course pace" do
      it "returns all enrollments if there's no section/student paces" do
        expect(@course_pace.student_enrollments.pluck(:user_id)).to contain_exactly(@student1.id, @student2.id)
      end

      it "does not include students who have their own pace" do
        @course.course_paces.create!(user_id: @student1)
        expect(@course_pace.student_enrollments.pluck(:user_id)).to contain_exactly(@student2.id)
      end

      it "does not include students in sections with a section pace" do
        student3 = student_in_course(course: @course, section: @section2, active_all: true).user
        @course.course_paces.create!(course_section: @section1)
        expect(@course_pace.student_enrollments.pluck(:user_id)).to contain_exactly(student3.id)
      end

      it "includes only students with no section or student pace" do
        student_in_course(course: @course, section: @section2, active_all: true).user
        @course.course_paces.create!(course_section: @section2)
        @course.course_paces.create!(user_id: @student1)
        expect(@course_pace.student_enrollments.pluck(:user_id)).to contain_exactly(@student2.id)
      end

      it "does not include deleted enrollments" do
        @student2.enrollments.where(course: @course).first.destroy
        expect(@course_pace.student_enrollments.pluck(:user_id)).to contain_exactly(@student1.id)
      end

      it "still includes students with deleted student or section paces" do
        @course.course_paces.create!(course_section: @section1, workflow_state: "deleted")
        @course.course_paces.create!(user_id: @student1, workflow_state: "deleted")
        expect(@course_pace.student_enrollments.pluck(:user_id)).to contain_exactly(@student1.id, @student2.id)
      end
    end
  end
end
