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

describe AssignmentOverrideApplicator do
  def create_group_override
    @category = group_category
    @group = @category.groups.create!(context: @course)

    @assignment.group_category = @category
    @assignment.save!

    @override = assignment_override_model(assignment: @assignment)
    @override.set = @group
    @override.save!

    @membership = @group.add_user(@student)
  end

  def create_group_override_for_discussion
    @category = group_category(name: "bar")
    @group = @category.groups.create!(context: @course)

    @assignment = create_assignment(course: @course)
    @assignment.submission_types = "discussion_topic"
    @assignment.saved_by = :discussion_topic
    @discussion_topic = @course.discussion_topics.create(message: "some message")
    @discussion_topic.group_category_id = @category.id
    @discussion_topic.assignment = @assignment
    @discussion_topic.save!
    @assignment.reload

    @override = assignment_override_model(assignment: @assignment)
    @override.set = @group
    @override.save!

    @membership = @group.add_user(@student)
  end

  def create_section_context_module_override(section)
    @module = @course.context_modules.create!(name: "Module 1")
    @assignment.context_module_tags.create! context_module: @module, context: @course, tag_type: "context_module"

    @module_override = @module.assignment_overrides.create!
    @module_override.set_type = "CourseSection"
    @module_override.set_id = section
    @module_override.save!
  end

  def create_context_module_and_override_adhoc
    @module = @course.context_modules.create!(name: "Module 1")
    @assignment.context_module_tags.create! context_module: @module, context: @course, tag_type: "context_module"

    @module_override = @module.assignment_overrides.create!
    @override_student = @module_override.assignment_override_students.build
    @override_student.user = @student
    @override_student.save!
    @module_override
  end

  def create_assignment(*args)
    # need to make sure it doesn't invalidate the cache right away
    Timecop.freeze(5.seconds.ago) do
      assignment_model(*args)
    end
  end

  describe "assignment_overridden_for" do
    before :once do
      student_in_course(active_all: true)
      @assignment = create_assignment(course: @course)
    end

    context "when a student has multiple enrollments in a course" do
      before do
        @now = Time.zone.now
        @assignment.update!(due_at: 10.days.from_now(@now))
        @section2 = @course.course_sections.create!(name: "Summer session")
        @section2_enrollment = @course.enroll_student(
          @student,
          section: @section2,
          allow_multiple_enrollments: true,
          enrollment_state: "active"
        )

        @section2_override = create_section_override_for_assignment(
          @assignment,
          course_section: @section2,
          due_at: 20.days.from_now(@now)
        )
      end

      context "with a concluded enrollment in an assigned section" do
        before { @section2_enrollment.conclude }

        it "uses the 'Everyone' due date over the due date for the override associated with the concluded enrollment" do
          due_at = AssignmentOverrideApplicator.assignment_overridden_for(@assignment, @student).due_at
          expect(due_at).to eq @assignment.due_at
        end

        it "uses the due date for the override associated with the concluded enrollment when the feature flag is disabled" do
          Account.site_admin.disable_feature!(:deprioritize_section_overrides_for_nonactive_enrollments)
          due_at = AssignmentOverrideApplicator.assignment_overridden_for(@assignment, @student).due_at
          expect(due_at).to eq @section2_override.due_at
        end

        it "uses the due date for any override associated with an active enrollment over the override associated with the concluded enrollment" do
          active_enrollment_section_override = create_section_override_for_assignment(
            @assignment,
            course_section: @course.default_section,
            due_at: 5.days.from_now(@now)
          )
          due_at = AssignmentOverrideApplicator.assignment_overridden_for(@assignment, @student).due_at
          expect(due_at).to eq active_enrollment_section_override.due_at
        end

        it "uses the due date for the override associated with the concluded enrollment if it's the only option (no other overrides, and no 'Everyone' date)" do
          expect do
            @assignment.update!(only_visible_to_overrides: true)
          end.to change {
            AssignmentOverrideApplicator.assignment_overridden_for(@assignment, @student).due_at
          }.from(@assignment.due_at).to(@section2_override.due_at)
        end

        it "uses the most lenient due date (giving most time to submit) if there are multiple overrides associated with concluded students" do
          @assignment.update!(only_visible_to_overrides: true)
          @course.enrollments.find_by(user: @student, course_section: @course.default_section).conclude
          default_section_override = create_section_override_for_assignment(
            @assignment,
            course_section: @course.default_section,
            due_at: 5.days.from_now(@now)
          )

          new_due_at = 25.days.from_now(@now)
          expect do
            default_section_override.update!(due_at: new_due_at)
          end.to change {
            AssignmentOverrideApplicator.assignment_overridden_for(@assignment, @student).due_at
          }.from(@section2_override.due_at).to(new_due_at)
        end
      end

      context "with a deactivated enrollment in an assigned section" do
        before { @section2_enrollment.deactivate }

        it "uses the 'Everyone' due date over the due date for the override associated with the deactivated enrollment" do
          due_at = AssignmentOverrideApplicator.assignment_overridden_for(@assignment, @student).due_at
          expect(due_at).to eq @assignment.due_at
        end

        it "uses the due date for the override associated with the deactivated enrollment when the feature flag is disabled" do
          Account.site_admin.disable_feature!(:deprioritize_section_overrides_for_nonactive_enrollments)
          due_at = AssignmentOverrideApplicator.assignment_overridden_for(@assignment, @student).due_at
          expect(due_at).to eq @section2_override.due_at
        end

        it "uses the due date for any override associated with an active enrollment over the override associated with the deactivated enrollment" do
          active_enrollment_section_override = create_section_override_for_assignment(
            @assignment,
            course_section: @course.default_section,
            due_at: 5.days.from_now(@now)
          )
          due_at = AssignmentOverrideApplicator.assignment_overridden_for(@assignment, @student).due_at
          expect(due_at).to eq active_enrollment_section_override.due_at
        end

        it "uses the due date for the override associated with the deactivated enrollment if it's the only option (no other overrides, and no 'Everyone' date)" do
          expect do
            @assignment.update!(only_visible_to_overrides: true)
          end.to change {
            AssignmentOverrideApplicator.assignment_overridden_for(@assignment, @student).due_at
          }.from(@assignment.due_at).to(@section2_override.due_at)
        end

        it "uses the most lenient due date (giving most time to submit) if there are multiple overrides associated with deactivated students" do
          @assignment.update!(only_visible_to_overrides: true)
          @course.enrollments.find_by(user: @student, course_section: @course.default_section).deactivate
          default_section_override = create_section_override_for_assignment(
            @assignment,
            course_section: @course.default_section,
            due_at: 5.days.from_now(@now)
          )

          new_due_at = 25.days.from_now(@now)
          expect do
            default_section_override.update!(due_at: new_due_at)
          end.to change {
            AssignmentOverrideApplicator.assignment_overridden_for(@assignment, @student).due_at
          }.from(@section2_override.due_at).to(new_due_at)
        end
      end

      context "with an active enrollment in an assigned section" do
        it "uses the override's due date over the 'Everyone' due date" do
          @assignment.update!(due_at: 25.days.from_now(@now))
          due_at = AssignmentOverrideApplicator.assignment_overridden_for(@assignment, @student).due_at
          expect(due_at).to eq @section2_override.due_at
        end

        it "uses the most lenient due date (giving most time to submit) if there are multiple applicable overrides" do
          @assignment.update!(only_visible_to_overrides: true)
          default_section_override = create_section_override_for_assignment(
            @assignment,
            course_section: @course.default_section,
            due_at: 5.days.from_now(@now)
          )

          new_due_at = 25.days.from_now(@now)
          expect do
            default_section_override.update!(due_at: new_due_at)
          end.to change {
            AssignmentOverrideApplicator.assignment_overridden_for(@assignment, @student).due_at
          }.from(@section2_override.due_at).to(new_due_at)
        end
      end
    end

    context "with unassign_item" do
      before :once do
        @adhoc_override = assignment_override_model(assignment: @assignment)
        @override_student = @adhoc_override.assignment_override_students.build
        @override_student.user = @student
        @override_student.save!
        @adhoc_override.override_due_at(7.days.from_now)
        @adhoc_override.save!

        @section_override = assignment_override_model(assignment: @assignment, set: @course.default_section)
        @section_override.override_due_at(7.days.from_now)
        @section_override.save!
      end

      it "does not apply overrides if adhoc override is unassigned" do
        Account.site_admin.enable_feature!(:differentiated_modules)
        @adhoc_override.unassign_item = true
        @adhoc_override.save!

        due_at = AssignmentOverrideApplicator.assignment_overridden_for(@assignment, @student).due_at
        expect(due_at).to eq @assignment.due_at
      end

      it "applies unassigned overrides if flag is off" do
        Account.site_admin.disable_feature!(:differentiated_modules)
        @adhoc_override.unassign_item = true
        @adhoc_override.save!

        due_at = AssignmentOverrideApplicator.assignment_overridden_for(@assignment, @student).due_at
        expect(due_at).to eq @adhoc_override.due_at
      end

      it "applies adhoc override even if section override is unassigned" do
        Account.site_admin.enable_feature!(:differentiated_modules)
        @section_override.unassign_item = true
        @section_override.save!

        due_at = AssignmentOverrideApplicator.assignment_overridden_for(@assignment, @student).due_at
        expect(due_at).to eq @adhoc_override.due_at
      end
    end

    it "notes the user id for whom overrides were applied" do
      @adhoc_override = assignment_override_model(assignment: @assignment)
      @override_student = @adhoc_override.assignment_override_students.build
      @override_student.user = @student
      @override_student.save!
      @adhoc_override.override_due_at(7.days.from_now)
      @adhoc_override.save!
      @overridden_assignment = AssignmentOverrideApplicator.assignment_overridden_for(@assignment, @student)
      expect(@overridden_assignment.overridden_for_user.id).to eq @student.id
    end

    it "notes the user id for whom overrides were not found" do
      @overridden_assignment = AssignmentOverrideApplicator.assignment_overridden_for(@assignment, @student)
      expect(@overridden_assignment.overridden_for_user.id).to eq @student.id
    end

    it "applies new overrides if an overridden assignment is overridden for a new user" do
      @student1 = @student
      @overridden_assignment = AssignmentOverrideApplicator.assignment_overridden_for(@assignment, @student1)
      expect(@overridden_assignment.overridden_for_user.id).to eq @student1.id
      student_in_course
      @student2 = @student
      expect(AssignmentOverrideApplicator).to receive(:overrides_for_assignment_and_user).with(@overridden_assignment, @student2).and_return([])
      @reoverridden_assignment = AssignmentOverrideApplicator.assignment_overridden_for(@overridden_assignment, @student2)
    end

    it "does not attempt to apply overrides if an overridden assignment is overridden for the same user" do
      @overridden_assignment = AssignmentOverrideApplicator.assignment_overridden_for(@assignment, @student)
      expect(@overridden_assignment.overridden_for_user.id).to eq @student.id
      expect(AssignmentOverrideApplicator).not_to receive(:overrides_for_assignment_and_user)
      @reoverridden_assignment = AssignmentOverrideApplicator.assignment_overridden_for(@overridden_assignment, @student)
    end

    it "ignores soft deleted Assignment Override Students" do
      now = Time.zone.now.change(usec: 0)
      adhoc_override = assignment_override_model(assignment: @assignment)
      override_student = adhoc_override.assignment_override_students.create!(user: @student)
      adhoc_override.override_due_at(7.days.from_now(now))
      adhoc_override.save!
      override_student.update!(workflow_state: "deleted")

      adhoc_override = assignment_override_model(assignment: @assignment)
      adhoc_override.assignment_override_students.create!(user: @student)
      adhoc_override.override_due_at(2.days.from_now(now))
      adhoc_override.save!

      overriden_assignment = AssignmentOverrideApplicator.assignment_overridden_for(@assignment, @student)
      expect(overriden_assignment.due_at).to eq(adhoc_override.due_at)
    end

    context "give teachers the more lenient of override.due_at or assignment.due_at" do
      before do
        teacher_in_course
        @section = @course.course_sections.create! name: "Overridden Section"
        student_in_section(@section)
        @student = @user
      end

      def override_section(section, due)
        override = assignment_override_model(assignment: @assignment)
        override.set = section
        override.override_due_at(due)
        override.save!
      end

      def setup_overridden_assignments(section_due_at, assignment_due_at)
        override_section(@section, section_due_at)
        @assignment.update_attribute(:due_at, assignment_due_at)

        @students_assignment = AssignmentOverrideApplicator
                               .assignment_overridden_for(@assignment, @student)
        @teachers_assignment = AssignmentOverrideApplicator
                               .assignment_overridden_for(@assignment, @teacher)
      end

      it "assignment.due_at is more lenient" do
        section_due_at = 5.days.ago
        assignment_due_at = nil
        setup_overridden_assignments(section_due_at, assignment_due_at)
        expect(@teachers_assignment.due_at.to_i).to eq assignment_due_at.to_i
        expect(@students_assignment.due_at.to_i).to eq section_due_at.to_i
      end

      it "override.due_at is more lenient" do
        section_due_at = 5.days.from_now
        assignment_due_at = 5.days.ago
        setup_overridden_assignments(section_due_at, assignment_due_at)
        expect(@teachers_assignment.due_at.to_i).to eq section_due_at.to_i
        expect(@students_assignment.due_at.to_i).to eq section_due_at.to_i
      end

      it "ignores assignment.due_at if all sections have overrides" do
        section_due_at = 5.days.from_now
        assignment_due_at = 1.year.from_now

        override_section(@course.default_section, section_due_at)
        setup_overridden_assignments(section_due_at, assignment_due_at)

        expect(@teachers_assignment.due_at.to_i).to eq section_due_at.to_i
        expect(@students_assignment.due_at.to_i).to eq section_due_at.to_i
      end
    end
  end

  describe "overrides_for_assignment_and_user" do
    before do
      student_in_course
      @assignment = create_assignment(course: @course, due_at: 5.days.from_now)
    end

    context "it works" do
      it "is serializable" do
        override = AssignmentOverrideApplicator.assignment_overridden_for(@assignment, @student)
        expect { Marshal.dump(override) }.not_to raise_error
      end

      it "caches by assignment and user" do
        enable_cache do
          AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @student)
          expect(Rails.cache).not_to receive(:write_entry)
          AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @student)
        end
      end

      it "distinguishes cache by assignment" do
        enable_cache do
          AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @student)
          assignment = create_assignment
          expect(Rails.cache).to receive(:write_entry)
          AssignmentOverrideApplicator.overrides_for_assignment_and_user(assignment, @student)
        end
      end

      it "distinguishes cache by assignment version" do
        Timecop.travel Time.now + 1.hour do
          @assignment.due_at = 7.days.from_now
          @assignment.save!
          expect(@assignment.versions.count).to eq 2
          enable_cache do
            AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment.versions.first.model, @student)
            expect(Rails.cache).to receive(:write_entry)
            AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment.versions.current.model, @student)
          end
        end
      end

      it "distinguishes cache by user" do
        enable_cache do
          AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @student)
          user = user_model
          expect(Rails.cache).to receive(:write_entry)
          AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, user)
        end
      end

      it "orders adhoc override before group override" do
        @category = group_category
        @group = @category.groups.create!(context: @course)
        @membership = @group.add_user(@student)
        @assignment.group_category = @category
        @assignment.save!

        @group_override = assignment_override_model(assignment: @assignment)
        @group_override.set = @group
        @group_override.save!

        @adhoc_override = assignment_override_model(assignment: @assignment)
        @override_student = @adhoc_override.assignment_override_students.build
        @override_student.user = @student
        @override_student.save!

        overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @student)
        expect(overrides.size).to eq 2
        expect(overrides.first).to eq @adhoc_override
        expect(overrides.last).to eq @group_override
      end

      it "orders group override before section overrides" do
        @category = group_category
        @group = @category.groups.create!(context: @course)
        @membership = @group.add_user(@student)
        @assignment.group_category = @category
        @assignment.save!

        @section_override = assignment_override_model(assignment: @assignment)
        @section_override.set = @course.default_section
        @section_override.save!

        @group_override = assignment_override_model(assignment: @assignment)
        @group_override.set = @group
        @group_override.save!

        overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @student)
        expect(overrides.size).to eq 2
        expect(overrides.first).to eq @group_override
        expect(overrides.last).to eq @section_override
      end

      it "orders section override before course overrides" do
        Account.site_admin.enable_feature!(:differentiated_modules)
        @section_override = assignment_override_model(assignment: @assignment)
        @section_override.set = @course.default_section
        @section_override.save!

        @course_override = assignment_override_model(assignment: @assignment)
        @course_override.set = @course
        @course_override.save!

        overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @student)
        expect(overrides.size).to eq 2
        expect(overrides.first).to eq @section_override
        expect(overrides.last).to eq @course_override
      end

      it "should order section overrides by position" # see TODO in implementation

      context "sharding" do
        specs_require_sharding

        it "does not break when running for a teacher on a different shard" do
          @shard1.activate do
            @teacher = User.create!
          end
          teacher_in_course(user: @teacher, course: @course, active_all: true)

          @adhoc_override = assignment_override_model(assignment: @assignment)
          @adhoc_override.assignment_override_students.create!(user: @student)

          @shard1.activate do
            ovs = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @teacher)
            expect(ovs).to eq [@adhoc_override]
          end
        end
      end
    end

    context "adhoc overrides" do
      before do
        @override = assignment_override_model(assignment: @assignment)
        @override_student = @override.assignment_override_students.build
        @override_student.user = @student
        @override_student.save!
      end

      describe "for students" do
        it "includes adhoc override for the user" do
          overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @student)
          expect(overrides).to eq [@override]
        end

        it "does not include adhoc overrides that don't include the user" do
          new_student = student_in_course
          overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, new_student.user)
          expect(overrides).to be_empty
        end

        it "finds the overrides for the correct student" do
          result = AssignmentOverrideApplicator.adhoc_override(@assignment, @student)
          expect(result.assignment_override_id).to eq @override.id
        end

        it "returns AssignmentOverrideStudent" do
          result = AssignmentOverrideApplicator.adhoc_override(@assignment, @student)
          expect(result).to be_an_instance_of(AssignmentOverrideStudent)
        end

        it "includes context module overrides" do
          @override.destroy!
          Account.site_admin.enable_feature!(:differentiated_modules)
          create_context_module_and_override_adhoc

          result = AssignmentOverrideApplicator.adhoc_override(@assignment, @student)
          expect(result.assignment_override_id).to eq @module_override.id
        end
      end

      describe "for teachers" do
        before { teacher_in_course(active_all: true) }

        it "works" do
          overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @teacher)
          expect(overrides).to eq [@override]
        end

        it "does not duplicate adhoc overrides" do
          @override_student = @override.assignment_override_students.create(user: student_in_course.user)

          overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @teacher)
          expect(overrides).to eq [@override]
        end

        it "includes context module overrides" do
          Account.site_admin.enable_feature!(:differentiated_modules)
          create_context_module_and_override_adhoc

          overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @teacher)
          expect(overrides).to eq [@override, @module_override]
        end
      end

      describe "for observers" do
        it "works" do
          course_with_observer({ course: @course, active_all: true })
          @course.enroll_user(@observer, "ObserverEnrollment", { associated_user_id: @student.id })
          overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @observer)
          expect(overrides).to eq [@override]
        end

        it "includes context module overrides" do
          @override.destroy!
          Account.site_admin.enable_feature!(:differentiated_modules)
          course_with_observer({ course: @course, active_all: true })
          @course.enroll_user(@observer, "ObserverEnrollment", { associated_user_id: @student.id })
          create_context_module_and_override_adhoc
          overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @observer)
          expect(overrides).to eq [@module_override]
        end
      end

      describe "for admins" do
        it "works" do
          account_admin_user
          overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @admin)
          expect(overrides).to eq [@override]
        end

        it "includes context module overrides" do
          Account.site_admin.enable_feature!(:differentiated_modules)
          account_admin_user
          create_context_module_and_override_adhoc
          overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @admin)
          expect(overrides).to eq [@override, @module_override]
        end
      end

      describe "for other types of learning objects" do
        before do
          teacher_in_course(active_all: true)
          account_admin_user
          course_with_observer({ course: @course, active_all: true })
          @course.enroll_user(@observer, "ObserverEnrollment", { associated_user_id: @student.id })
        end

        it "works for ungraded discussions" do
          discussion = @course.discussion_topics.create!
          discussion_override = discussion.assignment_overrides.create!
          discussion_override_student = discussion_override.assignment_override_students.build
          discussion_override_student.user = @student
          discussion_override_student.save!

          # students
          overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(discussion, @student)
          expect(overrides).to eq [discussion_override]

          # teachers
          overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(discussion, @teacher)
          expect(overrides).to eq [discussion_override]

          # admins
          overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(discussion, @admin)
          expect(overrides).to eq [discussion_override]

          # observers
          overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(discussion, @observer)
          expect(overrides).to eq [discussion_override]
        end

        it "works for wiki pages" do
          wiki_page = @course.wiki_pages.create!(title: "Wiki Page")
          wiki_page_override = wiki_page.assignment_overrides.create!
          wiki_page_override_student = wiki_page_override.assignment_override_students.build
          wiki_page_override_student.user = @student
          wiki_page_override_student.save!

          # students
          overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(wiki_page, @student)
          expect(overrides).to eq [wiki_page_override]

          # teachers
          overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(wiki_page, @teacher)
          expect(overrides).to eq [wiki_page_override]

          # admins
          overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(wiki_page, @admin)
          expect(overrides).to eq [wiki_page_override]

          # observers
          overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(wiki_page, @observer)
          expect(overrides).to eq [wiki_page_override]
        end
      end
    end

    context "group overrides" do
      before do
        create_group_override
      end

      describe "for students" do
        it "returns group overrides" do
          result = AssignmentOverrideApplicator.group_overrides(@assignment, @student)
          expect(result).to eq [@override]
        end

        it "returns groups overrides for graded discussions" do
          create_group_override_for_discussion
          result = AssignmentOverrideApplicator.group_overrides(@assignment, @student)
          expect(result).to eq [@override]
        end

        it "does not include group override for groups other than the user's" do
          @override.set = @category.groups.create!(context: @course)
          @override.save!
          overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @student)
          expect(overrides).to be_empty
        end

        it "does not include group override for deleted groups" do
          @group.destroy
          overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @student)
          expect(overrides).to be_empty
        end

        it "does not include group override for deleted group memberships" do
          @membership.destroy
          overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @student)
          expect(overrides).to be_empty
        end

        it "still returns something when there are old deleted group overrides" do
          @override.destroy!
          overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @student)
          expect(overrides).to be_empty

          override2 = assignment_override_model(assignment: @assignment)
          override2.set = @group
          override2.save!
          overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @student)
          expect(overrides).to eq [override2]
        end

        context "sharding" do
          specs_require_sharding

          it "determines cross-shard user groups correctly" do
            cs_user = @shard1.activate { User.create! }
            student_in_course(course: @course, user: cs_user)
            @group.add_user(cs_user)
            result = AssignmentOverrideApplicator.group_overrides(@assignment, cs_user)
            expect(result).to eq [@override]
          end
        end
      end

      describe "for teachers" do
        it "works" do
          teacher_in_course
          result = AssignmentOverrideApplicator.group_overrides(@assignment, @teacher)
          expect(result).to eq [@override]
        end
      end

      describe "for observers" do
        it "works" do
          course_with_observer({ course: @course, active_all: true })
          @course.enroll_user(@observer, "ObserverEnrollment", { associated_user_id: @student.id })
          overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @observer)
          expect(overrides).to eq [@override]
        end
      end

      describe "for admins" do
        it "works" do
          account_admin_user
          user_session(@admin)
          result = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @admin)
          expect(result).to eq [@override]
        end
      end
    end

    context "section overrides" do
      before do
        @override = assignment_override_model(assignment: @assignment)
        @override.set = @course.default_section
        @override.save!
        @section2 = @course.course_sections.create!(name: "Summer session")
        @override2 = assignment_override_model(assignment: @assignment)
        @override2.set_type = "CourseSection"
        @override2.set_id = @section2.id
        @override2.due_at = 7.days.from_now
        @override2.save!
        @student2 = student_in_section(@section2, { active_all: true })
      end

      describe "for students" do
        it "returns section overrides" do
          result = AssignmentOverrideApplicator.section_overrides(@assignment, @student2)
          expect(result.length).to eq 1
        end

        it "enforces lenient date" do
          adhoc_due_at = 10.days.from_now

          ao = AssignmentOverride.new
          ao.assignment = @assignment
          ao.title = "ADHOC OVERRIDE"
          ao.workflow_state = "active"
          ao.set_type = "ADHOC"
          ao.override_due_at(adhoc_due_at)
          ao.save!
          override_student = ao.assignment_override_students.build
          override_student.user = @student2
          override_student.save!
          @assignment.reload

          students_assignment = AssignmentOverrideApplicator
                                .assignment_overridden_for(@assignment, @student2)
          expect(students_assignment.due_at.to_i).to eq adhoc_due_at.to_i
        end

        it "includes section overrides for sections with an active student enrollment" do
          overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @student2)
          expect(overrides).to eq [@override2]
        end

        it "does not include section overrides for sections with deleted enrollments" do
          @student2.student_enrollments.first.destroy
          overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @student2)
          expect(overrides).to be_empty
        end

        it "includes section overrides for sections with concluded enrollments" do
          @student2.student_enrollments.first.conclude
          overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @student2)
          expect(overrides).to eq [@override2]
        end

        it "includes all relevant section overrides" do
          @course.enroll_student(@student, section: @override2.set, allow_multiple_enrollments: true)
          overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @student)
          expect(overrides.size).to eq 2
          expect(overrides).to include(@override)
          expect(overrides).to include(@override2)
        end

        it "works even if :read_roster is disabled" do
          RoleOverride.create!(context: @course.root_account,
                               permission: "read_roster",
                               role: student_role,
                               enabled: false)
          overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @student2)
          expect(overrides).to eq [@override2]
        end

        it "only uses the latest due_date for student_view_student" do
          due_at = 3.days.from_now
          a = create_assignment(course: @course)
          cs1 = @course.course_sections.create!
          override1 = assignment_override_model(assignment: a)
          override1.set = cs1
          override1.override_due_at(due_at)
          override1.save!

          cs2 = @course.course_sections.create!
          override2 = assignment_override_model(assignment: a)
          override2.set = cs2
          override2.override_due_at(due_at - 1.day)
          override2.save!

          @fake_student = @course.student_view_student
          overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(a, @fake_student)
          expect(overrides).to include(override1, override2)
          expect(AssignmentOverrideApplicator.collapsed_overrides(a, overrides)[:due_at].to_i).to eq due_at.to_i
        end

        it "does not include section overrides for sections without an enrollment" do
          assignment = create_assignment(course: @course, due_at: 5.days.from_now)
          override = assignment_override_model(assignment:)
          override.set = @course.course_sections.create!
          override.save!
          overrides = AssignmentOverrideApplicator.section_overrides(assignment, @student)
          expect(overrides).to be_empty
        end

        it "includes context module overrides" do
          Account.site_admin.enable_feature!(:differentiated_modules)
          create_section_context_module_override(@course.default_section)
          overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @student)
          expect(overrides).to include(@module_override)
        end
      end

      describe "for teachers" do
        it "works" do
          teacher_in_course
          result = AssignmentOverrideApplicator.section_overrides(@assignment, @teacher)
          expect(result).to include(@override, @override2)
        end

        it "includes context module overrides" do
          Account.site_admin.enable_feature!(:differentiated_modules)
          teacher_in_course
          create_section_context_module_override(@course.default_section)
          result = AssignmentOverrideApplicator.section_overrides(@assignment, @teacher)
          expect(result).to include(@module_override)
        end
      end

      describe "for observers" do
        it "works" do
          course_with_observer({ course: @course, active_all: true })
          @course.enroll_user(@observer, "ObserverEnrollment", { associated_user_id: @student2.id })
          overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @observer)
          expect(overrides).to eq [@override2]
        end

        it "includes context module overrides" do
          Account.site_admin.enable_feature!(:differentiated_modules)
          course_with_observer({ course: @course, active_all: true })
          @course.enroll_user(@observer, "ObserverEnrollment", { associated_user_id: @student2.id })

          create_section_context_module_override(@section2)

          overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @observer)
          expect(overrides).to eq [@override2, @module_override]
        end
      end

      describe "for admins" do
        it "works" do
          account_admin_user
          result = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @admin)
          expect(result).to include(@override, @override2)
        end

        it "includes context module overrides" do
          Account.site_admin.enable_feature!(:differentiated_modules)
          account_admin_user
          create_section_context_module_override(@section2)
          result = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @admin)
          expect(result).to include(@module_override)
        end
      end

      describe "for other types of learning objects" do
        before do
          teacher_in_course(active_all: true)
          account_admin_user
          course_with_observer({ course: @course, active_all: true })
          @course.enroll_user(@observer, "ObserverEnrollment", { associated_user_id: @student.id })
        end

        it "works for ungraded discussions" do
          discussion = @course.discussion_topics.create!
          discussion_override = discussion.assignment_overrides.create!
          discussion_override.set = @course.default_section
          discussion_override.save!

          # students
          overrides = AssignmentOverrideApplicator.section_overrides(discussion, @student)
          expect(overrides).to eq [discussion_override]

          # teachers
          overrides = AssignmentOverrideApplicator.section_overrides(discussion, @teacher)
          expect(overrides).to eq [discussion_override]

          # admins
          overrides = AssignmentOverrideApplicator.section_overrides(discussion, @admin)
          expect(overrides).to eq [discussion_override]

          # observers
          overrides = AssignmentOverrideApplicator.section_overrides(discussion, @observer)
          expect(overrides).to eq [discussion_override]
        end

        it "works for wiki pages" do
          wiki_page = @course.wiki_pages.create!(title: "Wiki Page")
          wiki_page_override = wiki_page.assignment_overrides.create!
          wiki_page_override.set = @course.default_section
          wiki_page_override.save!

          # students
          overrides = AssignmentOverrideApplicator.section_overrides(wiki_page, @student)
          expect(overrides).to eq [wiki_page_override]

          # teachers
          overrides = AssignmentOverrideApplicator.section_overrides(wiki_page, @teacher)
          expect(overrides).to eq [wiki_page_override]

          # admins
          overrides = AssignmentOverrideApplicator.section_overrides(wiki_page, @admin)
          expect(overrides).to eq [wiki_page_override]

          # observers
          overrides = AssignmentOverrideApplicator.section_overrides(wiki_page, @observer)
          expect(overrides).to eq [wiki_page_override]
        end
      end
    end

    context "course overrides" do
      before do
        @override = assignment_override_model(assignment: @assignment)
        @override.set = @course
        @override.save!
      end

      describe "for students" do
        it "returns course overrides" do
          Account.site_admin.enable_feature!(:differentiated_modules)
          result = AssignmentOverrideApplicator.course_overrides(@assignment, @student)
          expect(result.length).to eq 1
        end

        it "doesn't include course overrides if flag is off" do
          Account.site_admin.disable_feature!(:differentiated_modules)
          result = AssignmentOverrideApplicator.course_overrides(@assignment, @student)
          expect(result).to be_nil
        end

        it "doesn't include course overrides for student not in course" do
          Account.site_admin.enable_feature!(:differentiated_modules)
          course2 = course_factory
          student2 = student_in_course(course: course2)
          result = AssignmentOverrideApplicator.course_overrides(@assignment, student2.user)
          expect(result).to be_nil
        end
      end

      describe "for teachers" do
        it "works" do
          Account.site_admin.enable_feature!(:differentiated_modules)
          teacher_in_course
          result = AssignmentOverrideApplicator.course_overrides(@assignment, @teacher)
          expect(result).to include(@override)
        end

        it "doesn't include course overrides if flag is off" do
          Account.site_admin.disable_feature!(:differentiated_modules)
          teacher_in_course
          result = AssignmentOverrideApplicator.course_overrides(@assignment, @teacher)
          expect(result).to be_nil
        end
      end

      describe "for observers" do
        it "works" do
          Account.site_admin.enable_feature!(:differentiated_modules)
          course_with_observer({ course: @course, active_all: true })
          @course.enroll_user(@observer, "ObserverEnrollment", { associated_user_id: @student.id })
          overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @observer)
          expect(overrides).to eq [@override]
        end

        it "doesn't include course overrides if flag is off" do
          Account.site_admin.disable_feature!(:differentiated_modules)
          course_with_observer({ course: @course, active_all: true })
          @course.enroll_user(@observer, "ObserverEnrollment", { associated_user_id: @student.id })
          overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @observer)
          expect(overrides).to eq []
        end
      end

      describe "for admins" do
        it "works" do
          Account.site_admin.enable_feature!(:differentiated_modules)
          account_admin_user
          overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @admin)
          expect(overrides).to eq [@override]
        end

        it "doesn't include course overrides if flag is off" do
          Account.site_admin.disable_feature!(:differentiated_modules)
          account_admin_user
          overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @admin)
          expect(overrides).to eq []
        end
      end

      describe "for other types of learning objects" do
        before do
          Account.site_admin.enable_feature!(:differentiated_modules)
          teacher_in_course(active_all: true)
          account_admin_user
          course_with_observer({ course: @course, active_all: true })
          @course.enroll_user(@observer, "ObserverEnrollment", { associated_user_id: @student.id })
        end

        it "works for ungraded discussions" do
          discussion = @course.discussion_topics.create!
          discussion_override = discussion.assignment_overrides.create!
          discussion_override.set = @course
          discussion_override.save!

          # students
          overrides = AssignmentOverrideApplicator.course_overrides(discussion, @student)
          expect(overrides).to eq [discussion_override]

          # teachers
          overrides = AssignmentOverrideApplicator.course_overrides(discussion, @teacher)
          expect(overrides).to eq [discussion_override]

          # admins
          overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(discussion, @admin)
          expect(overrides).to eq [discussion_override]

          # observers
          overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(discussion, @observer)
          expect(overrides).to eq [discussion_override]
        end

        it "works for wiki pages" do
          wiki_page = @course.wiki_pages.create!(title: "Wiki Page")
          wiki_page_override = wiki_page.assignment_overrides.create!
          wiki_page_override.set = @course
          wiki_page_override.save!

          # students
          overrides = AssignmentOverrideApplicator.course_overrides(wiki_page, @student)
          expect(overrides).to eq [wiki_page_override]

          # teachers
          overrides = AssignmentOverrideApplicator.course_overrides(wiki_page, @teacher)
          expect(overrides).to eq [wiki_page_override]

          # admins
          overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(wiki_page, @admin)
          expect(overrides).to eq [wiki_page_override]

          # observers
          overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(wiki_page, @observer)
          expect(overrides).to eq [wiki_page_override]
        end
      end
    end

    context "#observer_overrides" do
      it "returns all dates visible to observer" do
        @override = assignment_override_model(assignment: @assignment)
        @override_student = @override.assignment_override_students.build
        @override_student.user = @student
        @override_student.save!
        course_with_observer({ course: @course, active_all: true })
        @course.enroll_user(@observer, "ObserverEnrollment", { associated_user_id: @student.id })

        @section2 = @course.course_sections.create!(name: "Summer session")
        @override2 = assignment_override_model(assignment: @assignment)
        @override2.set_type = "ADHOC"
        @override2.due_at = 7.days.from_now
        @override2.save!
        @override2_student = @override2.assignment_override_students.build
        @student2 = student_in_section(@section2, { active_all: true })
        @override2_student.user = @student2
        @override2_student.save!
        @course.enroll_user(@observer, "ObserverEnrollment", { allow_multiple_enrollments: true, associated_user_id: @student2.id })
        result = AssignmentOverrideApplicator.observer_overrides(@assignment, @observer)
        expect(result.length).to eq 2
      end
    end

    context "#has_invalid_args?" do
      it "returns true with nil user" do
        result = AssignmentOverrideApplicator.has_invalid_args?(@assignment, nil)
        expect(result).to be_truthy
      end

      it "returns true for assignments with no overrides" do
        result = AssignmentOverrideApplicator.has_invalid_args?(@assignment, @student)
        expect(result).to be_truthy
      end

      it "returns false if user and overrides are valid" do
        @override = assignment_override_model(assignment: @assignment)
        @override_student = @override.assignment_override_students.build
        @override_student.user = @student
        @override_student.save!

        result = AssignmentOverrideApplicator.has_invalid_args?(@assignment, @student)
        expect(result).to be_falsey
      end

      it "returns false if the assignment has context module overrides" do
        Account.site_admin.enable_feature!(:differentiated_modules)
        @module = @course.context_modules.create!(name: "Module 1")
        @assignment.context_module_tags.create! context_module: @module, context: @course, tag_type: "context_module"

        @module_override = @module.assignment_overrides.create!
        result = AssignmentOverrideApplicator.has_invalid_args?(@assignment, @student)
        expect(result).to be_falsey
      end
    end

    context "versioning" do
      it "uses the appropriate version of an override" do
        @override = assignment_override_model(assignment: @assignment)
        @override_student = @override.assignment_override_students.build
        @override_student.user = @student
        @override_student.save!

        original_override_version_number = @override.version_number

        @assignment.due_at = 3.days.from_now
        @assignment.save!

        @override.override_due_at(5.days.from_now)
        @override.save!

        overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @student)
        expect(overrides.first.version_number).to eq @override.version_number

        overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment.versions.first.model, @student)
        expect(overrides.first.version_number).to eq original_override_version_number
      end

      it "uses the most-recent override version for the given assignment version" do
        @override = assignment_override_model(assignment: @assignment)
        @override_student = @override.assignment_override_students.build
        @override_student.user = @student
        @override_student.save!

        first_version = @override.version_number

        @override.override_due_at(7.days.from_now)
        @override.save!

        second_version = @override.version_number
        expect(first_version).not_to eq second_version

        overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @student)
        expect(overrides.first.version_number).to eq second_version
      end

      it "excludes overrides that weren't created until a later assignment version" do
        @assignment.due_at = 3.days.from_now
        @assignment.save!

        @override = assignment_override_model(assignment: @assignment)
        @override_student = @override.assignment_override_students.build
        @override_student.user = @student
        @override_student.save!

        overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment.versions.first.model, @student)
        expect(overrides).to be_empty
      end

      it "excludes overrides that were deleted as of the assignment version" do
        @override = assignment_override_model(assignment: @assignment)
        @override_student = @override.assignment_override_students.build
        @override_student.user = @student
        @override_student.save!

        @override.destroy

        overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @student)
        expect(overrides).to be_empty
      end

      it "includes now-deleted overrides that weren't deleted yet as of the assignment version" do
        @override = assignment_override_model(assignment: @assignment)
        @override.set = @course.default_section
        @override.save!

        @assignment.due_at = 3.days.from_now
        @assignment.save!

        @override.destroy

        overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment.versions.first.model, @student)
        expect(overrides).to eq [@override]
        expect(overrides.first).not_to be_deleted
      end

      it "includes now-deleted overrides that weren't deleted yet as of the assignment version (with manage_courses permission)" do
        account_admin_user

        @override = assignment_override_model(assignment: @assignment)
        @override.set = @course.default_section
        @override.save!

        @assignment.due_at = 3.days.from_now
        @assignment.save!

        @override.destroy

        overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment.versions.first.model, @admin)
        expect(overrides).to eq [@override]
        expect(overrides.first).not_to be_deleted
      end

      context "overrides for an assignment for a quiz, where the overrides were created before the quiz was published" do
        context "without draft states" do
          it "skips versions of the override that have nil for an assignment version" do
            student_in_course
            expected_time = Time.zone.now
            quiz = @course.quizzes.create! title: "VDD Quiz", quiz_type: "assignment"
            section = @course.course_sections.create! name: "title"
            @course.enroll_user(@student,
                                "StudentEnrollment",
                                section:,
                                enrollment_state: "active",
                                allow_multiple_enrollments: true)
            override = quiz.assignment_overrides.build
            override.quiz_id = quiz.id
            override.quiz = quiz
            override.set_type = "CourseSection"
            override.set_id = section.id
            override.title = "Quiz Assignment override"
            override.due_at = expected_time
            override.save!
            quiz.publish!
            override = quiz.reload.assignment.assignment_overrides.first
            expect(override.versions.length).to eq 1
            expect(override.versions[0].model.assignment_version).not_to be_nil
            # Assert that it won't call the "<=" method on nil
            expect do
              AssignmentOverrideApplicator.overrides_for_assignment_and_user(quiz.assignment, @student)
            end.to_not raise_error
          end
        end

        context "with draft states" do
          it "quiz should always have an assignment for overrides" do
            # with draft states quizzes always have an assignment.
            student_in_course
            expected_time = Time.zone.now
            quiz = @course.quizzes.create! title: "VDD Quiz", quiz_type: "assignment"
            section = @course.course_sections.create! name: "title"
            @course.enroll_user(@student,
                                "StudentEnrollment",
                                section:,
                                enrollment_state: "active",
                                allow_multiple_enrollments: true)
            override = quiz.assignment_overrides.build
            override.quiz_id = quiz.id
            override.quiz = quiz
            override.set_type = "CourseSection"
            override.set_id = section.id
            override.title = "Quiz Assignment override"
            override.due_at = expected_time
            override.save!
            quiz.publish!
            override = quiz.reload.assignment.assignment_overrides.first
            expect(override.versions.length).to eq 1
            expect(override.versions[0].model.assignment_version).not_to be_nil
            # Assert that it won't call the "<=" method on nil
            expect do
              AssignmentOverrideApplicator.overrides_for_assignment_and_user(quiz.assignment, @student)
            end.to_not raise_error
          end
        end
      end
    end
  end

  describe "assignment_with_overrides" do
    around do |example|
      Time.use_zone("Alaska", &example)
    end

    before do
      @assignment = create_assignment(
        due_at: 5.days.from_now,
        unlock_at: 4.days.from_now,
        lock_at: 6.days.from_now,
        title: "Some Title"
      )
      @override = assignment_override_model(assignment: @assignment)
      @override.override_due_at(7.days.from_now)
      @overridden = AssignmentOverrideApplicator.assignment_with_overrides(@assignment, [@override])
    end

    it "returns a new assignment object" do
      expect(@overridden.class).to eq @assignment.class
      expect(@overridden.object_id).not_to eq @assignment.object_id
    end

    it "returns a new discussion topic object for discussion topics" do
      discussion = @course.discussion_topics.create!
      discussion_override = discussion.assignment_overrides.create!
      overridden_discussion = AssignmentOverrideApplicator.assignment_with_overrides(discussion, [discussion_override])
      expect(overridden_discussion.class).to eq discussion.class
      expect(overridden_discussion.object_id).not_to eq discussion.object_id
    end

    it "returns a new wiki page object for wiki pages" do
      wiki_page = @course.wiki_pages.create!(title: "Wiki Page")
      wiki_page_override = wiki_page.assignment_overrides.create!
      overridden_wiki_page = AssignmentOverrideApplicator.assignment_with_overrides(wiki_page, [wiki_page_override])
      expect(overridden_wiki_page.class).to eq wiki_page.class
      expect(overridden_wiki_page.object_id).not_to eq wiki_page.object_id
    end

    it "preserves assignment id" do
      expect(@overridden.id).to eq @assignment.id
    end

    it "is new_record? iff the original assignment is" do
      expect(@overridden).not_to be_new_record

      @assignment = Assignment.new
      @overridden = AssignmentOverrideApplicator.assignment_with_overrides(@assignment, [])
      expect(@overridden).to be_new_record
    end

    it "applies overrides to the returned assignment object" do
      expect(@overridden.due_at).to eq @override.due_at
    end

    it "does not change the original assignment object" do
      expect(@assignment.due_at).not_to eq @overridden.due_at
    end

    it "inherits other values from the original assignment object" do
      expect(@overridden.title).to eq @assignment.title
    end

    it "returns a readonly assignment object" do
      expect(@overridden).to be_readonly
      expect { @overridden.save!(validate: false) }.to raise_exception ActiveRecord::ReadOnlyRecord
    end

    it "casts datetimes to the active time zone" do
      expect(@overridden.due_at.time_zone).to eq Time.zone
      expect(@overridden.unlock_at.time_zone).to eq Time.zone
      expect(@overridden.lock_at.time_zone).to eq Time.zone
    end

    it "does not cast dates to zoned datetimes" do
      expect(@overridden.all_day_date.class).to eq Date
    end

    it "copies pre-loaded associations" do
      expect(@overridden.association(:context).loaded?).to eq @assignment.association(:context).loaded?
      expect(@overridden.association(:rubric).loaded?).to eq @assignment.association(:rubric).loaded?
      @overridden.learning_outcome_alignments.loaded? == @assignment.learning_outcome_alignments.loaded?
    end

    it "is locked in between overrides" do
      past_override = assignment_override_model(assignment: @assignment,
                                                unlock_at: 2.months.ago,
                                                lock_at: 1.month.ago)
      future_override = assignment_override_model(assignment: @assignment,
                                                  unlock_at: 2.months.from_now,
                                                  lock_at: 1.month.from_now)
      overridden = AssignmentOverrideApplicator.assignment_with_overrides(@assignment, [past_override, future_override])
      expect(overridden.locked_for?(@student)).to be_truthy
    end

    it "is not locked when in an override" do
      override = assignment_override_model(assignment: @assignment,
                                           unlock_at: 2.months.ago,
                                           lock_at: 2.months.from_now)
      overridden = AssignmentOverrideApplicator.assignment_with_overrides(@assignment, [override])
      expect(overridden.locked_for?(@student)).to be(false)
    end
  end

  describe "collapsed_overrides" do
    it "caches by assignment and overrides" do
      @assignment = create_assignment
      @override = assignment_override_model(assignment: @assignment)
      enable_cache do
        AssignmentOverrideApplicator.collapsed_overrides(@assignment, [@override])
        expect(Rails.cache).not_to receive(:write_entry)
        Timecop.freeze(5.seconds.from_now) do
          AssignmentOverrideApplicator.collapsed_overrides(@assignment, [@override])
        end
      end
    end

    it "distinguishes cache by assignment" do
      @assignment1 = create_assignment
      @assignment2 = create_assignment
      @override = assignment_override_model(assignment: @assignment1)
      enable_cache do
        AssignmentOverrideApplicator.collapsed_overrides(@assignment1, [@override])
        expect(Rails.cache).to receive(:write_entry)
        AssignmentOverrideApplicator.collapsed_overrides(@assignment2, [@override])
      end
    end

    it "distinguishes cache by assignment updated_at" do
      @assignment = create_assignment
      Timecop.travel Time.now + 1.hour do
        @assignment.due_at = 5.days.from_now
        @assignment.save!
        expect(@assignment.versions.count).to eq 2
        @override = assignment_override_model(assignment: @assignment)
        enable_cache do
          expect(@assignment.versions.first.updated_at).not_to eq @assignment.versions.current.model.updated_at
          AssignmentOverrideApplicator.collapsed_overrides(@assignment.versions.first.model, [@override])
          expect(Rails.cache).to receive(:write_entry)
          AssignmentOverrideApplicator.collapsed_overrides(@assignment.versions.current.model, [@override])
        end
      end
    end

    it "distinguishes cache by overrides" do
      @assignment = create_assignment
      @override1 = assignment_override_model(assignment: @assignment)
      @override2 = assignment_override_model(assignment: @assignment)
      enable_cache do
        AssignmentOverrideApplicator.collapsed_overrides(@assignment, [@override1])
        expect(Rails.cache).to receive(:write_entry)
        AssignmentOverrideApplicator.collapsed_overrides(@assignment, [@override2])
      end
    end

    it "has a collapsed value for each recognized field" do
      @assignment = create_assignment
      @override = assignment_override_model(assignment: @assignment)
      overrides = AssignmentOverrideApplicator.collapsed_overrides(@assignment, [@override])
      expect(overrides.class).to eq Hash
      expect(overrides.keys.to_set).to eq %i[due_at all_day all_day_date unlock_at lock_at].to_set
    end

    it "uses raw UTC time for datetime fields" do
      Time.zone = "Alaska"
      @assignment = create_assignment(due_at: 5.days.from_now, unlock_at: 4.days.from_now, lock_at: 7.days.from_now)
      collapsed = AssignmentOverrideApplicator.collapsed_overrides(@assignment, [])
      expect(collapsed[:due_at].class).to eq Time
      expect(collapsed[:due_at]).to eq @assignment.due_at.utc
      expect(collapsed[:unlock_at].class).to eq Time
      expect(collapsed[:unlock_at]).to eq @assignment.unlock_at.utc
      expect(collapsed[:lock_at].class).to eq Time
      expect(collapsed[:lock_at]).to eq @assignment.lock_at.utc
    end

    it "does not use raw UTC time for date fields" do
      Time.zone = "Alaska"
      @assignment = create_assignment(due_at: 5.days.from_now)
      collapsed = AssignmentOverrideApplicator.collapsed_overrides(@assignment, [])
      expect(collapsed[:all_day_date].class).to eq Date
      expect(collapsed[:all_day_date]).to eq @assignment.all_day_date
    end
  end

  describe "overrides_hash" do
    it "is consistent for the same overrides" do
      overrides = Array.new(5) { assignment_override_model }
      hash1 = AssignmentOverrideApplicator.overrides_hash(overrides)
      hash2 = AssignmentOverrideApplicator.overrides_hash(overrides)
      expect(hash1).to eq hash2
    end

    it "is unique for different overrides" do
      overrides1 = Array.new(5) { assignment_override_model }
      overrides2 = Array.new(5) { assignment_override_model }
      hash1 = AssignmentOverrideApplicator.overrides_hash(overrides1)
      hash2 = AssignmentOverrideApplicator.overrides_hash(overrides2)
      expect(hash1).not_to eq hash2
    end

    it "is unique for different versions of the same overrides" do
      overrides = Array.new(5) { assignment_override_model }
      hash1 = AssignmentOverrideApplicator.overrides_hash(overrides)
      overrides.first.override_due_at(5.days.from_now)
      overrides.first.save!
      hash2 = AssignmentOverrideApplicator.overrides_hash(overrides)
      expect(hash1).not_to eq hash2
    end

    it "is unique for different orders of the same overrides" do
      overrides = Array.new(5) { assignment_override_model }
      hash1 = AssignmentOverrideApplicator.overrides_hash(overrides)
      hash2 = AssignmentOverrideApplicator.overrides_hash(overrides.reverse)
      expect(hash1).not_to eq hash2
    end
  end

  def fancy_midnight(opts = {})
    zone = opts[:zone] || Time.zone
    Time.use_zone(zone) do
      time = opts[:time] || Time.zone.now
      time.in_time_zone.midnight + 1.day - 1.minute
    end
  end

  describe "overridden_due_at" do
    before do
      @assignment = create_assignment(due_at: 5.days.from_now)
      @override = assignment_override_model(assignment: @assignment)
    end

    context "adhoc override prioritization" do
      before do
        @adhoc_override = @override
        @section_override = assignment_override_model(assignment: @assignment, set: @course.default_section)
        @adhoc_override.override_due_at(6.days.from_now)
        @section_override.override_due_at(7.days.from_now)
      end

      let(:due_at) do
        AssignmentOverrideApplicator.overridden_due_at(@assignment, [@adhoc_override, @section_override])
      end

      it "always uses the adhoc due_at, if one exists" do
        expect(due_at).to eq @adhoc_override.due_at
      end

      it "uses no override if the override is unassigned" do
        Account.site_admin.enable_feature!(:differentiated_modules)
        @adhoc_override.unassign_item = true
        expect(due_at).to eq @assignment.due_at
      end

      it "uses adhoc override even if section override is unassigned" do
        Account.site_admin.enable_feature!(:differentiated_modules)
        @section_override.unassign_item = true
        expect(due_at).to eq @adhoc_override.due_at
      end
    end

    it "uses overrides that override due_at" do
      @override.override_due_at(7.days.from_now)
      due_at = AssignmentOverrideApplicator.overridden_due_at(@assignment, [@override])
      expect(due_at).to eq @override.due_at
    end

    it "skips overrides that don't override due_at" do
      @override2 = assignment_override_model(assignment: @assignment)
      @override2.override_due_at(7.days.from_now)
      due_at = AssignmentOverrideApplicator.overridden_due_at(@assignment, [@override, @override2])
      expect(due_at).to eq @override2.due_at
    end

    it "considers no due date as most lenient" do
      @override.override_due_at(nil)
      @override2 = assignment_override_model(assignment: @assignment)
      @override2.override_due_at(7.days.from_now)
      due_at = AssignmentOverrideApplicator.overridden_due_at(@assignment, [@override, @override2])
      expect(due_at).to eq @override.due_at
    end

    it "does not consider empty original due date as more lenient than an override due date" do
      @assignment.due_at = nil
      @override.override_due_at(6.days.from_now)
      due_at = AssignmentOverrideApplicator.overridden_due_at(@assignment, [@override])
      expect(due_at).to eq @override.due_at
    end

    it "prefers overrides even when earlier when determining most lenient due date" do
      earlier = 6.days.from_now
      @assignment.due_at = 7.days.from_now
      @override.override_due_at(earlier)
      due_at = AssignmentOverrideApplicator.overridden_due_at(@assignment, [@override])
      expect(due_at).to eq earlier
    end

    it "fallbacks on the assignment's due_at" do
      due_at = AssignmentOverrideApplicator.overridden_due_at(@assignment, [@override])
      expect(due_at).to eq @assignment.due_at
    end

    it "recognizes overrides with overridden-but-nil due_at" do
      @override.override_due_at(nil)
      due_at = AssignmentOverrideApplicator.overridden_due_at(@assignment, [@override])
      expect(due_at).to eq @override.due_at
    end

    it "uses no override with no adhoc override due_at and section override unassigned" do
      Account.site_admin.enable_feature!(:differentiated_modules)
      @section_override = assignment_override_model(assignment: @assignment, set: @course.default_section)
      @section_override.override_due_at(7.days.from_now)
      @section_override.unassign_item = true

      due_at = AssignmentOverrideApplicator.overridden_due_at(@assignment, [@override, @section_override])
      expect(due_at).to eq @assignment.due_at
    end
  end

  # specs for overridden_due_at cover all_day and all_day_date, since they're
  # pulled from the same assignment/override the due_at is

  describe "overridden_unlock_at" do
    before do
      @assignment = create_assignment(due_at: 11.days.from_now, unlock_at: 10.days.from_now)
      @override = assignment_override_model(assignment: @assignment)
    end

    it "uses no override if the override is unassigned" do
      Account.site_admin.enable_feature!(:differentiated_modules)
      @override.override_unlock_at(7.days.from_now)
      @override.unassign_item = true
      unlock_at = AssignmentOverrideApplicator.overridden_unlock_at(@assignment, [@override])
      expect(unlock_at).to eq @assignment.unlock_at
    end

    it "uses adhoc override even if section override is unassigned" do
      Account.site_admin.enable_feature!(:differentiated_modules)
      @adhoc_override = @override
      @adhoc_override.override_unlock_at(7.days.from_now)

      @section_override = assignment_override_model(assignment: @assignment, set: @course.default_section)
      @section_override.override_unlock_at(7.days.from_now)
      @section_override.unassign_item = true

      unlock_at = AssignmentOverrideApplicator.overridden_unlock_at(@assignment, [@adhoc_override, @section_override])
      expect(unlock_at).to eq @adhoc_override.unlock_at
    end

    it "uses overrides that override unlock_at" do
      @override.override_unlock_at(7.days.from_now)
      unlock_at = AssignmentOverrideApplicator.overridden_unlock_at(@assignment, [@override])
      expect(unlock_at).to eq @override.unlock_at
    end

    it "skips overrides that don't override unlock_at" do
      @override2 = assignment_override_model(assignment: @assignment)
      @override2.override_unlock_at(7.days.from_now)
      unlock_at = AssignmentOverrideApplicator.overridden_unlock_at(@assignment, [@override, @override2])
      expect(unlock_at).to eq @override2.unlock_at
    end

    it "prefers most lenient override" do
      @override.override_unlock_at(7.days.from_now)
      @override2 = assignment_override_model(assignment: @assignment)
      @override2.override_unlock_at(6.days.from_now)
      unlock_at = AssignmentOverrideApplicator.overridden_unlock_at(@assignment, [@override, @override2])
      expect(unlock_at).to eq @override2.unlock_at
    end

    it "considers no unlock date as most lenient" do
      @override.override_unlock_at(nil)
      @override2 = assignment_override_model(assignment: @assignment)
      @override2.override_unlock_at(7.days.from_now)
      unlock_at = AssignmentOverrideApplicator.overridden_unlock_at(@assignment, [@override, @override2])
      expect(unlock_at).to eq @override.unlock_at
    end

    it "does not consider empty original unlock date as more lenient than an override unlock date" do
      @assignment.unlock_at = nil
      @override.override_unlock_at(6.days.from_now)
      unlock_at = AssignmentOverrideApplicator.overridden_unlock_at(@assignment, [@override])
      expect(unlock_at).to eq @override.unlock_at
    end

    it "prefers overrides even when later when determining most lenient unlock date" do
      later = 7.days.from_now
      @assignment.unlock_at = 6.days.from_now
      @override.override_unlock_at(later)
      unlock_at = AssignmentOverrideApplicator.overridden_unlock_at(@assignment, [@override])
      expect(unlock_at).to eq later
    end

    it "fallbacks on the assignment's unlock_at" do
      unlock_at = AssignmentOverrideApplicator.overridden_unlock_at(@assignment, [@override])
      expect(unlock_at).to eq @assignment.unlock_at
    end

    it "recognizes overrides with overridden-but-nil unlock_at" do
      @override.override_unlock_at(nil)
      unlock_at = AssignmentOverrideApplicator.overridden_unlock_at(@assignment, [@override])
      expect(unlock_at).to eq @override.unlock_at
    end

    it "includes unlock_at for previous adhoc overrides that have already been locked" do
      @override.override_unlock_at(10.days.ago)
      @override.override_lock_at(5.days.ago)
      unlock_at = AssignmentOverrideApplicator.overridden_unlock_at(@assignment, [@override])
      expect(unlock_at).to eq @override.unlock_at
    end

    it "does not include unlock_at for previous non-adhoc overrides that have already been locked" do
      @override.set_type = "CourseSection"
      @override.override_unlock_at(10.days.ago)
      @override.override_lock_at(5.days.ago)
      unlock_at = AssignmentOverrideApplicator.overridden_unlock_at(@assignment, [@override])
      expect(unlock_at).to eq @assignment.unlock_at
    end

    it "uses discussion overrides that override unlock_at" do
      @discussion = discussion_topic_model
      @override = @discussion.assignment_overrides.create!
      @override.override_unlock_at(7.days.from_now)
      unlock_at = AssignmentOverrideApplicator.overridden_unlock_at(@discussion, [@override])
      expect(unlock_at).to eq @override.unlock_at
    end

    it "uses wiki page overrides that override unlock_at" do
      @wiki_page = discussion_topic_model
      @override = @wiki_page.assignment_overrides.create!
      @override.override_unlock_at(7.days.from_now)
      unlock_at = AssignmentOverrideApplicator.overridden_unlock_at(@wiki_page, [@override])
      expect(unlock_at).to eq @override.unlock_at
    end
  end

  describe "overridden_lock_at" do
    before do
      @assignment = create_assignment(due_at: 1.day.from_now, lock_at: 5.days.from_now)
      @override = assignment_override_model(assignment: @assignment)
    end

    it "uses no override if the override is unassigned" do
      Account.site_admin.enable_feature!(:differentiated_modules)
      @override.override_lock_at(7.days.from_now)
      @override.unassign_item = true
      lock_at = AssignmentOverrideApplicator.overridden_lock_at(@assignment, [@override])
      expect(lock_at).to eq @assignment.lock_at
    end

    it "uses adhoc override even if section override is unassigned" do
      Account.site_admin.enable_feature!(:differentiated_modules)
      @adhoc_override = @override
      @adhoc_override.override_lock_at(7.days.from_now)

      @section_override = assignment_override_model(assignment: @assignment, set: @course.default_section)
      @section_override.override_lock_at(7.days.from_now)
      @section_override.unassign_item = true

      lock_at = AssignmentOverrideApplicator.overridden_lock_at(@assignment, [@adhoc_override, @section_override])
      expect(lock_at).to eq @adhoc_override.lock_at
    end

    it "uses overrides that override lock_at" do
      @override.override_lock_at(7.days.from_now)
      lock_at = AssignmentOverrideApplicator.overridden_lock_at(@assignment, [@override])
      expect(lock_at).to eq @override.lock_at
    end

    it "skips overrides that don't override lock_at" do
      @override2 = assignment_override_model(assignment: @assignment)
      @override2.override_lock_at(7.days.from_now)
      lock_at = AssignmentOverrideApplicator.overridden_lock_at(@assignment, [@override, @override2])
      expect(lock_at).to eq @override2.lock_at
    end

    it "prefers most lenient override" do
      @override.override_lock_at(6.days.from_now)
      @override2 = assignment_override_model(assignment: @assignment)
      @override2.override_lock_at(7.days.from_now)
      lock_at = AssignmentOverrideApplicator.overridden_lock_at(@assignment, [@override, @override2])
      expect(lock_at).to eq @override2.lock_at
    end

    it "considers no lock date as most lenient" do
      @override.override_lock_at(nil)
      @override2 = assignment_override_model(assignment: @assignment)
      @override2.override_lock_at(7.days.from_now)
      lock_at = AssignmentOverrideApplicator.overridden_lock_at(@assignment, [@override, @override2])
      expect(lock_at).to eq @override.lock_at
    end

    it "does not consider empty original lock date as more lenient than an override lock date" do
      @assignment.lock_at = nil
      @override.override_lock_at(6.days.from_now)
      lock_at = AssignmentOverrideApplicator.overridden_lock_at(@assignment, [@override])
      expect(lock_at).to eq @override.lock_at
    end

    it "prefers overrides even when earlier when determining most lenient lock date" do
      earlier = 6.days.from_now
      @assignment.lock_at = 7.days.from_now
      @override.override_lock_at(earlier)
      lock_at = AssignmentOverrideApplicator.overridden_lock_at(@assignment, [@override])
      expect(lock_at).to eq earlier
    end

    it "fallbacks on the assignment's lock_at" do
      lock_at = AssignmentOverrideApplicator.overridden_lock_at(@assignment, [@override])
      expect(lock_at).to eq @assignment.lock_at
    end

    it "recognizes overrides with overridden-but-nil lock_at" do
      @override.override_lock_at(nil)
      lock_at = AssignmentOverrideApplicator.overridden_lock_at(@assignment, [@override])
      expect(lock_at).to eq @override.lock_at
    end

    it "uses discussion overrides that override lock_at" do
      @discussion = discussion_topic_model
      @override = @discussion.assignment_overrides.create!
      @override.override_lock_at(7.days.from_now)
      lock_at = AssignmentOverrideApplicator.overridden_lock_at(@discussion, [@override])
      expect(lock_at).to eq @override.lock_at
    end

    it "uses wiki page overrides that override lock_at" do
      @wiki_page = wiki_page_model
      @override = @wiki_page.assignment_overrides.create!
      @override.override_lock_at(7.days.from_now)
      lock_at = AssignmentOverrideApplicator.overridden_lock_at(@wiki_page, [@override])
      expect(lock_at).to eq @override.lock_at
    end
  end

  describe "Overridable#has_no_overrides" do
    before do
      student_in_course
      @assignment = create_assignment(course: @course,
                                      due_at: 1.week.from_now)
      o = assignment_override_model(assignment: @assignment,
                                    due_at: 1.week.ago)
      o.assignment_override_students.create! user: @student
    end

    it "makes assignment_overridden_for lie!" do
      truly_overridden_assignment = AssignmentOverrideApplicator.assignment_overridden_for(@assignment, @student)

      @assignment.has_no_overrides = true
      fake_overridden_assignment = AssignmentOverrideApplicator.assignment_overridden_for(@assignment, @student)
      expect(fake_overridden_assignment.overridden).to be_truthy
      expect(fake_overridden_assignment.due_at).not_to eq truly_overridden_assignment.due_at
      expect(fake_overridden_assignment.due_at).to eq @assignment.due_at
    end
  end

  describe "without_overrides" do
    before do
      student_in_course
      @assignment = create_assignment(course: @course)
    end

    it "returns an unoverridden copy of an overridden assignment" do
      @overridden_assignment = AssignmentOverrideApplicator.assignment_overridden_for(@assignment, @student)
      expect(@overridden_assignment.overridden_for_user.id).to eq @student.id
      @unoverridden_assignment = @overridden_assignment.without_overrides
      expect(@unoverridden_assignment.overridden_for_user).to be_nil
    end
  end

  it "uses the full stack" do
    student_in_course(active_all: true)
    original_due_at = 3.days.from_now
    @assignment = create_assignment(course: @course)
    @assignment.due_at = original_due_at
    @assignment.save!
    @assignment.reload

    @section_override = assignment_override_model(assignment: @assignment)
    @section_override.set = @course.default_section
    @section_override.override_due_at(5.days.from_now)
    @section_override.save!
    @section_override.reload

    @adhoc_override = assignment_override_model(assignment: @assignment)
    @override_student = @adhoc_override.assignment_override_students.build
    @override_student.user = @student
    @override_student.save!

    @adhoc_override.override_due_at(7.days.from_now)
    @adhoc_override.save!
    @adhoc_override.reload
    @overridden_assignment = AssignmentOverrideApplicator.assignment_overridden_for(@assignment, @student)
    expect(@overridden_assignment.due_at).to eq @adhoc_override.due_at

    @adhoc_override.clear_due_at_override
    @adhoc_override.save!

    @overridden_assignment = AssignmentOverrideApplicator.assignment_overridden_for(@assignment, @student)
    expect(@overridden_assignment.due_at).to eq @section_override.due_at
  end

  it "does not cache incorrect overrides through due_between_with_overrides" do
    course_with_student(active_all: true)
    @assignment = create_assignment(course: @course, submission_types: "online_upload")

    so = assignment_override_model(assignment: @assignment)
    so.set = @course.default_section
    so.override_due_at(30.days.from_now) # set it outside of the default upcoming events range
    so.save!

    other_so = assignment_override_model(assignment: @assignment)
    other_so.set = @course.course_sections.create!
    other_so.override_due_at(5.days.from_now) # set it so it would be included in the upcoming events query
    other_so.save!

    Timecop.freeze(5.seconds.from_now) do
      enable_cache do
        @student.upcoming_events # prime the cache

        @assignment.reload
        expect(@assignment.overridden_for(@student).due_at).to eq so.due_at # should have cached correctly
      end
    end
  end
end
