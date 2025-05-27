# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

require_relative "../../spec_helper"
require_relative "../../models/student_visibility/student_visibility_common"

# need tests for:
# overrides that arent date related
describe AssignmentVisibility::AssignmentVisibilityService do
  describe "differentiated_assignments" do
    include StudentVisibilityCommon

    specs_require_sharding

    def course_with_differentiated_assignments_enabled
      @course = Course.create!
      @user = user_model
      @course.enroll_user(@user)
      @course.save!
    end

    def make_assignment(opts = {})
      @assignment = Assignment.create!({
                                         context: @course,
                                         description: "descript foo",
                                         only_visible_to_overrides: opts[:ovto],
                                         points_possible: rand(1000),
                                         submission_types: "online_text_entry",
                                         title: "yes_due_date",
                                         group_category: opts[:group_category]
                                       })
      @assignment.publish
      @assignment.save!
    end

    def assignment_with_true_only_visible_to_overrides
      make_assignment({ date: nil, ovto: true })
    end

    def assignment_with_false_only_visible_to_overrides
      make_assignment({ date: Time.zone.now, ovto: false })
    end

    def group_assignment_with_true_only_visible_to_overrides(opts = {})
      group_category = opts[:group_category] || @course.group_categories.first
      make_assignment({ date: nil, ovto: true, group_category: })
    end

    def student_in_course_with_adhoc_override(assignment, opts = {})
      @user = opts[:user] || user_model
      StudentEnrollment.create!(user: @user, course: @course)
      ao = AssignmentOverride.new
      ao.assignment = assignment
      ao.title = "ADHOC OVERRIDE"
      ao.workflow_state = "active"
      ao.set_type = "ADHOC"
      ao.unassign_item = opts[:unassign_item] || "false"
      ao.save!
      assignment.reload
      override_student = ao.assignment_override_students.build
      override_student.user = @user
      override_student.save!
      @user
    end

    def enroller_user_in_section(section, opts = {})
      @user = opts[:user] || user_model
      StudentEnrollment.create!(user: @user, course: @course, course_section: section)
    end

    def enroller_user_in_both_sections
      @user = user_model
      StudentEnrollment.create!(user: @user, course: @course, course_section: @section_foo)
      StudentEnrollment.create!(user: @user, course: @course, course_section: @section_bar)
    end

    def enroll_user_in_group(group, opts = {})
      @user = opts[:user] || user_model
      group.add_user(@user, "accepted", true)
    end

    def enroller_user_in_both_groups(opts = {})
      @user = opts[:user] || user_model
      @group_foo.add_user(@user, "accepted", true)
      @group_bar.add_user(@user, "accepted", true)
    end

    def add_multiple_sections
      @default_section = @course.default_section
      @section_foo = @course.course_sections.create!(name: "foo")
      @section_bar = @course.course_sections.create!(name: "bar")
    end

    def add_multiple_groups
      @group_foo = @course.groups.create!(name: "foo group")
      @group_bar = @course.groups.create!(name: "bar group")
    end

    def create_override_for_assignment(assignment)
      ao = AssignmentOverride.new
      ao.assignment = assignment
      ao.title = "Lorem"
      ao.workflow_state = "active"
      yield(ao)
      ao.save!
      assignment.reload
    end

    def give_section_due_date(assignment, section, opts = {})
      create_override_for_assignment(assignment) do |ao|
        ao.set = section
        ao.due_at = 3.weeks.from_now
        ao.unassign_item = opts[:unassign_item] || "false"
      end
    end

    def give_group_due_date(assignment, group)
      assignment.group_category = group.group_category
      create_override_for_assignment(assignment) do |ao|
        ao.set = group
        ao.due_at = 3.weeks.from_now
      end
    end

    def give_course_due_date(assignment)
      create_override_for_assignment(assignment) do |ao|
        ao.set = @course
        ao.due_at = 3.weeks.from_now
      end
    end

    def ensure_user_does_not_see_assignment
      visible_assignment_ids = AssignmentVisibility::AssignmentVisibilityService.assignments_visible_to_students(user_ids: @user.id, course_ids: @course.id).map(&:assignment_id)
      expect(visible_assignment_ids.map(&:to_i).include?(@assignment.id)).to be_falsey
    end

    def ensure_user_sees_assignment
      visible_assignment_ids = AssignmentVisibility::AssignmentVisibilityService.assignments_visible_to_students(user_ids: @user.id, course_ids: @course.id).map(&:assignment_id)
      expect(visible_assignment_ids.map(&:to_i).include?(@assignment.id)).to be_truthy
    end

    context "course_with_differentiated_assignments_enabled" do
      before do
        course_with_differentiated_assignments_enabled
        add_multiple_sections
      end

      context "assignment only visible to overrides" do
        context "ADHOC overrides" do
          before { assignment_with_true_only_visible_to_overrides }

          it "returns a visibility for a student with an ADHOC override" do
            student_in_course_with_adhoc_override(@assignment)
            ensure_user_sees_assignment
          end

          it "does show the assignment if course_ids is not present" do
            student_in_course_with_adhoc_override(@assignment)
            visible_assignment_ids = AssignmentVisibility::AssignmentVisibilityService.assignments_visible_to_students(user_ids: @user.id, assignment_ids: @assignment.id, course_ids: nil).map(&:assignment_id)
            expect(visible_assignment_ids.map(&:to_i).include?(@assignment.id)).to be_truthy
          end

          it "works with course section and return a single visibility" do
            student_in_course_with_adhoc_override(@assignment)
            give_section_due_date(@assignment, @section_foo)
            enroller_user_in_section(@section_foo)
            ensure_user_sees_assignment
            expect(AssignmentVisibility::AssignmentVisibilityService.assignments_visible_to_students(user_ids: @user.id, course_ids: @course.id).count).to eq 1
          end

          it "does not return a visibility for a student without an ADHOC override" do
            @user = user_model
            ensure_user_does_not_see_assignment
          end

          it "does not return a visibility if ADHOC override is deleted" do
            student_in_course_with_adhoc_override(@assignment)
            @assignment.assignment_overrides.each(&:destroy)
            ensure_user_does_not_see_assignment
          end
        end

        context "group overrides" do
          before do
            add_multiple_groups
            group_assignment_with_true_only_visible_to_overrides(group_category: @group_foo.group_category)
            give_group_due_date(@assignment, @group_foo)
          end

          context "user in group with override who then changes groups" do
            before do
              @student = @user
              teacher_in_course(course: @course)
              enroll_user_in_group(@group_foo, { user: @student })
            end

            it "does not keep the assignment visible even if there is a grade" do
              @assignment.grade_student(@student, grade: 10, grader: @teacher)
              @student.group_memberships.each(&:destroy!)
              enroll_user_in_group(@group_bar, { user: @student })
              ensure_user_does_not_see_assignment
            end

            it "does not keep the assignment visible if there is no grade" do
              @assignment.grade_student(@student, grade: nil, grader: @teacher)
              @student.group_memberships.each(&:destroy!)
              enroll_user_in_group(@group_bar, { user: @student })
              ensure_user_does_not_see_assignment
            end

            it "does not keep the assignment visible even if the grade is zero" do
              @assignment.grade_student(@student, grade: 0, grader: @teacher)
              @student.group_memberships.each(&:destroy!)
              enroll_user_in_group(@group_bar, { user: @student })
              ensure_user_does_not_see_assignment
            end
          end

          context "user not in group with override" do
            it "hides the assignment from the user" do
              # user not yet in group
              ensure_user_does_not_see_assignment
            end
          end

          context "user in group with override" do
            before do
              enroll_user_in_group(@group_foo, { user: @user })
            end

            it "updates when enrollments change" do
              ensure_user_sees_assignment
              @user.group_memberships.each(&:destroy!)
              ensure_user_does_not_see_assignment
            end

            it "updates when the override is deleted" do
              ensure_user_sees_assignment
              @assignment.assignment_overrides.each(&:destroy!)
              ensure_user_does_not_see_assignment
            end

            it "does not return duplicate visibilities with multiple visible sections" do
              enroll_user_in_group(@group_bar, { user: @user })
              give_group_due_date(@assignment, @group_bar)
              visible_assignment_ids = AssignmentVisibility::AssignmentVisibilityService.assignments_visible_to_students(user_ids: @user.id, course_ids: @course.id)
              expect(visible_assignment_ids.count).to eq 1
            end
          end

          context "user in groups with and without override" do
            before { enroller_user_in_both_groups(user: @user) }

            it "shows the assignment to the user" do
              ensure_user_sees_assignment
            end

            it "does show the assignment if course_ids is not present" do
              visible_assignment_ids = AssignmentVisibility::AssignmentVisibilityService.assignments_visible_to_students(user_ids: @user.id, assignment_ids: @assignment.id, course_ids: nil).map(&:assignment_id)
              expect(visible_assignment_ids.map(&:to_i).include?(@assignment.id)).to be_truthy
            end
          end

          context "user is non-collaborative group" do
            before do
              @course.account.enable_feature!(:assign_to_differentiation_tags)
              @course.account.settings = { allow_assign_to_differentiation_tags: { value: true } }
              @course.account.save

              @group_category = @course.group_categories.create!(name: "Non-Collaborative Group", non_collaborative: true)
              @group_category.create_groups(2)
              @differentiation_tag_group = @group_category.groups.first

              @student = user_model
              @course.enroll_user(@student)
              @course.save!

              enroll_user_in_group(@differentiation_tag_group, { user: @student })
              assignment_with_true_only_visible_to_overrides
              @assignment.assignment_overrides.create!(set: @differentiation_tag_group)
            end

            it "sees the assignment" do
              visible_assignment_ids = AssignmentVisibility::AssignmentVisibilityService.assignments_visible_to_students(user_ids: @student.id, course_ids: @course.id).map { |x| x.assignment_id.to_i }
              expect(visible_assignment_ids.include?(@assignment.id)).to be_truthy
            end

            it "does not see the assignment if the override is deleted" do
              @assignment.assignment_overrides.each(&:destroy)

              visible_assignment_ids = AssignmentVisibility::AssignmentVisibilityService.assignments_visible_to_students(user_ids: @student.id, course_ids: @course.id).map { |x| x.assignment_id.to_i }
              expect(visible_assignment_ids.include?(@assignment.id)).to be_falsy
            end

            it "does not see the assignment if the feature flag is disabled" do
              @course.account.disable_feature!(:assign_to_differentiation_tags)

              visible_assignment_ids = AssignmentVisibility::AssignmentVisibilityService.assignments_visible_to_students(user_ids: @student.id, course_ids: @course.id).map { |x| x.assignment_id.to_i }
              expect(visible_assignment_ids.include?(@assignment.id)).to be_falsy
            end

            it "does not show the assignment if course_ids is not present" do
              visible_assignment_ids = AssignmentVisibility::AssignmentVisibilityService.assignments_visible_to_students(user_ids: @user.id, assignment_ids: @assignment.id, course_ids: nil).map(&:assignment_id)
              expect(visible_assignment_ids.map(&:to_i).include?(@assignment.id)).to be_falsy
            end
          end
        end

        context "section overrides" do
          before do
            assignment_with_true_only_visible_to_overrides
            give_section_due_date(@assignment, @section_foo)
          end

          context "user in section with override who then changes sections" do
            before do
              teacher_in_course(course: @course)
              enroller_user_in_section(@section_foo)
            end

            it "does not keep the assignment visible even if there is a grade (original enrollment deleted)" do
              @assignment.grade_student(@user, grade: 10, grader: @teacher)
              section_foo_enrollment = @course.enrollments.find_by(user: @user, course_section: @section_foo)
              section_foo_enrollment.scores.each(&:destroy_permanently!)
              section_foo_enrollment.destroy_permanently!
              enroller_user_in_section(@section_bar, { user: @user })
              ensure_user_does_not_see_assignment
            end

            it "does not keep the assignment visible even if there is a grade (original enrollment deactivated)" do
              @assignment.grade_student(@user, grade: 10, grader: @teacher)
              section_foo_enrollment = @course.enrollments.find_by(user: @user, course_section: @section_foo)
              section_foo_enrollment.deactivate
              enroller_user_in_section(@section_bar, { user: @user })
              ensure_user_does_not_see_assignment
            end

            it "does not keep the assignment visible if there is no grade" do
              @assignment.grade_student(@user, grade: nil, grader: @teacher)
              Score.where(enrollment_id: @user.enrollments).find_each(&:destroy_permanently!)
              @user.enrollments.each(&:destroy_permanently!)
              enroller_user_in_section(@section_bar, { user: @user })
              ensure_user_does_not_see_assignment
            end

            it "does not keep the assignment visible even if the grade is zero" do
              @assignment.grade_student(@user, grade: 0, grader: @teacher)
              Score.where(enrollment_id: @user.enrollments).find_each(&:destroy_permanently!)
              @user.enrollments.each(&:destroy_permanently!)
              enroller_user_in_section(@section_bar, { user: @user })
              ensure_user_does_not_see_assignment
            end
          end

          context "user in default section" do
            it "hides the assignment from the user" do
              ensure_user_does_not_see_assignment
            end
          end

          context "user in section with override" do
            before { enroller_user_in_section(@section_foo) }

            it "shows the assignment to the user" do
              ensure_user_sees_assignment
            end

            it "does show the assignment if course_ids is not present" do
              visible_assignment_ids = AssignmentVisibility::AssignmentVisibilityService.assignments_visible_to_students(user_ids: @user.id, assignment_ids: @assignment.id, course_ids: nil).map(&:assignment_id)
              expect(visible_assignment_ids.map(&:to_i).include?(@assignment.id)).to be_truthy
            end

            it "does not show unpublished assignments" do
              @assignment.workflow_state = "unpublished"
              @assignment.save!
              ensure_user_does_not_see_assignment
            end

            it "updates when enrollments are destroyed" do
              ensure_user_sees_assignment
              enrollments = StudentEnrollment.where(user_id: @user.id, course_id: @course.id, course_section_id: @section_foo.id)
              enrollments.destroy_all
              ensure_user_does_not_see_assignment
            end

            it "updates when enrollments are inactive" do
              ensure_user_sees_assignment
              @user.enrollments.where(course_id: @course.id, course_section_id: @section_foo.id).first.deactivate
              ensure_user_does_not_see_assignment
            end

            it "updates when the override is deleted" do
              ensure_user_sees_assignment
              @assignment.assignment_overrides.each(&:destroy!)
              ensure_user_does_not_see_assignment
            end

            it "does not return duplicate visibilities with multiple visible sections" do
              enroller_user_in_section(@section_bar, { user: @user })
              give_section_due_date(@assignment, @section_bar)
              visible_assignment_ids = AssignmentVisibility::AssignmentVisibilityService.assignments_visible_to_students(user_ids: @user.id, course_ids: @course.id)
              expect(visible_assignment_ids.count).to eq 1
            end
          end

          context "user in section with no override" do
            before { enroller_user_in_section(@section_bar) }

            it "hides the assignment from the user" do
              ensure_user_does_not_see_assignment
            end
          end

          context "user in section with override and one without override" do
            before do
              enroller_user_in_both_sections
            end

            it "shows the assignment to the user" do
              ensure_user_sees_assignment
            end
          end
        end

        shared_examples_for "module overrides" do
          it "includes everyone else if there no modules and no overrides" do
            assignment_with_false_only_visible_to_overrides
            ensure_user_sees_assignment
          end

          it "includes everyone else if part of an unpublished module with overrides" do
            assignment_with_false_only_visible_to_overrides

            module1 = @course.context_modules.create!(name: "Module 1", workflow_state: "unpublished")
            @assignment.context_module_tags.create! context_module: module1, context: @course, tag_type: "context_module"

            module2 = @course.context_modules.create!(name: "Module 2")
            module2.assignment_overrides.create!
            @assignment.context_module_tags.create! context_module: module2, context: @course, tag_type: "context_module"

            ensure_user_sees_assignment
          end

          it "does not apply context module overrides that don't apply to user" do
            assignment_with_false_only_visible_to_overrides

            module1 = @course.context_modules.create!(name: "Module 1")
            @assignment.context_module_tags.create! context_module: module1, context: @course, tag_type: "context_module"

            module1.assignment_overrides.create!

            ensure_user_does_not_see_assignment
          end

          it "applies context module adhoc overrides" do
            assignment_with_true_only_visible_to_overrides

            module1 = @course.context_modules.create!(name: "Module 1")
            @assignment.context_module_tags.create! context_module: module1, context: @course, tag_type: "context_module"

            module_override = module1.assignment_overrides.create!
            module_override.assignment_override_students.create!(user: @user)

            ensure_user_sees_assignment
          end

          it "applies context module section overrides" do
            assignment_with_true_only_visible_to_overrides
            enroller_user_in_section(@section_foo)
            module1 = @course.context_modules.create!(name: "Module 1")
            @assignment.context_module_tags.create! context_module: module1, context: @course, tag_type: "context_module"

            module_override = module1.assignment_overrides.create!

            module_override.set_type = "CourseSection"
            module_override.set_id = @section_foo
            module_override.save!

            ensure_user_sees_assignment
          end

          it "does not apply context module section overrides student is not enrolled in" do
            assignment_with_false_only_visible_to_overrides

            module1 = @course.context_modules.create!(name: "Module 1")
            @assignment.context_module_tags.create! context_module: module1, context: @course, tag_type: "context_module"

            module_override = module1.assignment_overrides.create!

            module_override.set_type = "CourseSection"
            module_override.set_id = @section_foo
            module_override.save!

            ensure_user_does_not_see_assignment
          end

          it "applies an assignment's quiz's module overrides" do
            quiz = quiz_model(course: @course)
            quiz.update!(only_visible_to_overrides: true)
            quiz.assignment.update!(only_visible_to_overrides: true)

            module1 = @course.context_modules.create!(name: "Module 1")
            module_override = module1.assignment_overrides.create!
            module_override.assignment_override_students.create!(user: @user)

            quiz.context_module_tags.create! context_module: module1, context: @course, tag_type: "context_module"

            expect(AssignmentVisibility::AssignmentVisibilityService.assignments_visible_to_students(assignment_ids: quiz.assignment, course_ids: @course.id).map(&:user_id)).to include @user.id
          end

          it "applies overrides from unpublished modules" do
            assignment_with_true_only_visible_to_overrides

            module1 = @course.context_modules.create!(name: "Module 1", workflow_state: "unpublished")
            module_override = module1.assignment_overrides.create!
            module_override.assignment_override_students.create!(user: @user)

            @assignment.context_module_tags.create! context_module: module1, context: @course, tag_type: "context_module"

            ensure_user_sees_assignment
          end

          it "does not apply overrides from deleted modules" do
            assignment_with_true_only_visible_to_overrides

            module1 = @course.context_modules.create!(name: "Module 1", workflow_state: "deleted")
            module_override = module1.assignment_overrides.create!
            module_override.assignment_override_students.create!(user: @user)

            @assignment.context_module_tags.create! context_module: module1, context: @course, tag_type: "context_module"

            ensure_user_does_not_see_assignment
          end

          it "does not apply module overrides if the content tag is deleted" do
            assignment_with_true_only_visible_to_overrides

            module1 = @course.context_modules.create!(name: "Module 1")
            module_override = module1.assignment_overrides.create!
            module_override.assignment_override_students.create!(user: @user)

            @assignment.context_module_tags.create! context_module: module1, context: @course, tag_type: "context_module", workflow_state: "deleted"

            ensure_user_does_not_see_assignment
          end
        end

        context "assignments with modules" do
          it_behaves_like "module overrides" do
            before :once do
              Account.site_admin.disable_feature!(:visibility_performance_improvements)
            end
          end
          it_behaves_like "module overrides" do
            before :once do
              Account.site_admin.enable_feature!(:visibility_performance_improvements)
            end
          end
        end

        context "unassign item overrides" do
          before do
            assignment_with_true_only_visible_to_overrides
          end

          it "is not visible with an unassigned adhoc override" do
            student_in_course_with_adhoc_override(@assignment, { unassign_item: "true" })
            ensure_user_does_not_see_assignment
          end

          it "is not visible with an unassigned section override" do
            enroller_user_in_section(@section_foo)
            give_section_due_date(@assignment, @section_foo, { unassign_item: "true" })
            ensure_user_does_not_see_assignment
          end

          it "is not visible with an unassigned adhoc override and assigned section override" do
            enroller_user_in_section(@section_foo)
            give_section_due_date(@assignment, @section_foo)
            student_in_course_with_adhoc_override(@assignment, { unassign_item: "true" })
            ensure_user_does_not_see_assignment
          end

          it "is visible with an unassigned section override and assigned adhoc override" do
            enroller_user_in_section(@section_foo)
            give_section_due_date(@assignment, @section_foo, { unassign_item: "true" })
            student_in_course_with_adhoc_override(@assignment)
            ensure_user_sees_assignment
          end

          it "does not apply context module section override with an unassigned section override" do
            enroller_user_in_section(@section_foo)
            module1 = @course.context_modules.create!(name: "Module 1")
            @assignment.context_module_tags.create! context_module: module1, context: @course, tag_type: "context_module"

            module_override = module1.assignment_overrides.create!

            module_override.set_type = "CourseSection"
            module_override.set_id = @section_foo
            module_override.save!

            give_section_due_date(@assignment, @section_foo, { unassign_item: "true" })

            ensure_user_does_not_see_assignment
          end

          it "does not apply context module adhoc overrides with an unassigned adhoc override" do
            module1 = @course.context_modules.create!(name: "Module 1")
            @assignment.context_module_tags.create! context_module: module1, context: @course, tag_type: "context_module"

            module_override = module1.assignment_overrides.create!
            module_override.assignment_override_students.create!(user: @user)

            student_in_course_with_adhoc_override(@assignment, { unassign_item: "true" })
            ensure_user_does_not_see_assignment
          end
        end

        context "course overrides" do
          before do
            assignment_with_true_only_visible_to_overrides
            give_course_due_date(@assignment)
          end

          it "shows the assignment to users in the course" do
            ensure_user_sees_assignment
          end

          it "does show the assignment if course_ids is not present" do
            visible_assignment_ids = AssignmentVisibility::AssignmentVisibilityService.assignments_visible_to_students(user_ids: @user.id, assignment_ids: @assignment.id, course_ids: nil).map(&:assignment_id)
            expect(visible_assignment_ids.map(&:to_i).include?(@assignment.id)).to be_truthy
          end

          it "does not show unpublished assignments" do
            @assignment.workflow_state = "unpublished"
            @assignment.save!
            ensure_user_does_not_see_assignment
          end

          it "updates when enrollments are destroyed" do
            ensure_user_sees_assignment
            enrollments = StudentEnrollment.where(user_id: @user.id, course_id: @course.id)
            enrollments.destroy_all
            ensure_user_does_not_see_assignment
          end

          it "updates when enrollments are inactive" do
            ensure_user_sees_assignment
            @user.enrollments.where(course_id: @course.id).first.deactivate
            ensure_user_does_not_see_assignment
          end

          it "updates when the override is deleted" do
            ensure_user_sees_assignment
            @assignment.assignment_overrides.each(&:destroy!)
            ensure_user_does_not_see_assignment
          end
        end

        context "assignment with false only_visible_to_overrides" do
          before do
            assignment_with_false_only_visible_to_overrides
            give_section_due_date(@assignment, @section_foo)
          end

          context "user in default section" do
            it "shows the assignment to the user" do
              ensure_user_sees_assignment
            end

            it "does not show deleted assignments" do
              @assignment.destroy
              ensure_user_does_not_see_assignment
            end
          end

          context "user in section with override" do
            before { enroller_user_in_section(@section_foo) }

            it "shows the assignment to the user" do
              ensure_user_sees_assignment
            end
          end

          context "user in section with no override" do
            before { enroller_user_in_section(@section_bar) }

            it "shows the assignment to the user" do
              ensure_user_sees_assignment
            end
          end

          context "user in section with override and one without override" do
            before do
              enroller_user_in_both_sections
            end

            it "shows the assignment to the user" do
              ensure_user_sees_assignment
            end
          end
        end
      end
    end

    context "discussion topics with section or adhoc overrides" do
      before do
        course_with_differentiated_assignments_enabled
        add_multiple_sections
        @student = user_model
        @course.enroll_user(@student, "StudentEnrollment")
        @course.save!
      end

      context "section specific discussion topics" do
        it "shows an assignment if it's created for a section specific discussion where user has posted" do
          # Create a discussion topic
          @discussion_topic = @course.discussion_topics.create!(
            title: "Section specific discussion",
            message: "Discuss this topic"
          )

          # Create an assignment override for the discussion topic (limit to section_foo)
          ao = AssignmentOverride.new
          ao.discussion_topic = @discussion_topic
          ao.set_type = "CourseSection"
          ao.set_id = @section_foo.id
          ao.workflow_state = "active"
          ao.save!

          # Enroll student in section_foo
          enroller_user_in_section(@section_foo, { user: @student })

          # Post in the discussion as the student
          entry = @discussion_topic.discussion_entries.create!(
            message: "I'm participating in this discussion",
            user: @student
          )
          expect(entry.workflow_state).to eq "active"

          # Now convert the discussion to an assignment
          @assignment = @course.assignments.create!(
            title: @discussion_topic.title,
            submission_types: "discussion_topic",
            only_visible_to_overrides: true
          )
          @discussion_topic.assignment = @assignment
          @discussion_topic.save!

          # The assignment should be visible to the student who has posted in the discussion
          visible_assignment_ids = AssignmentVisibility::AssignmentVisibilityService
                                   .assignments_visible_to_students(user_ids: @student.id, course_ids: @course.id)
                                   .map { |x| x.assignment_id.to_i }

          expect(visible_assignment_ids).to include(@assignment.id)
        end

        it "does not show an assignment if the student is not in the visible section" do
          # Create a discussion topic
          @discussion_topic = @course.discussion_topics.create!(
            title: "Section specific discussion",
            message: "Discuss this topic"
          )

          # Create an assignment override for the discussion topic (limit to section_foo)
          ao = AssignmentOverride.new
          ao.discussion_topic = @discussion_topic
          ao.set_type = "CourseSection"
          ao.set_id = @section_foo.id
          ao.workflow_state = "active"
          ao.save!

          # Enroll student in section_bar (NOT in section_foo which has visibility)
          enroller_user_in_section(@section_bar, { user: @student })

          # Now create an assignment for the discussion
          @assignment = @course.assignments.create!(
            title: @discussion_topic.title,
            submission_types: "discussion_topic",
            only_visible_to_overrides: true
          )
          @discussion_topic.assignment = @assignment
          @discussion_topic.save!

          # The assignment should NOT be visible to the student in a different section
          visible_assignment_ids = AssignmentVisibility::AssignmentVisibilityService
                                   .assignments_visible_to_students(user_ids: @student.id, course_ids: @course.id)
                                   .map { |x| x.assignment_id.to_i }

          expect(visible_assignment_ids).not_to include(@assignment.id)
        end
      end

      context "adhoc overridden discussion topics" do
        it "shows an assignment if it's created for a discussion with adhoc overrides for the user" do
          # Create a discussion topic
          @discussion_topic = @course.discussion_topics.create!(
            title: "Discussion with adhoc overrides",
            message: "Discuss this topic"
          )

          # Create assignment override for the discussion topic
          ao = AssignmentOverride.new
          ao.discussion_topic = @discussion_topic
          ao.title = "ADHOC OVERRIDE"
          ao.workflow_state = "active"
          ao.set_type = "ADHOC"
          ao.save!

          # Add the student to the override
          override_student = ao.assignment_override_students.build
          override_student.user = @student
          override_student.save!

          # Post in the discussion as the student
          entry = @discussion_topic.discussion_entries.create!(
            message: "I'm participating in this discussion with adhoc override",
            user: @student
          )
          expect(entry.workflow_state).to eq "active"

          # Now convert the discussion to an assignment
          @assignment = @course.assignments.create!(
            title: @discussion_topic.title,
            submission_types: "discussion_topic",
            only_visible_to_overrides: true
          )
          @discussion_topic.assignment = @assignment
          @discussion_topic.save!

          # The assignment should be visible to the student with adhoc override
          visible_assignment_ids = AssignmentVisibility::AssignmentVisibilityService
                                   .assignments_visible_to_students(user_ids: @student.id, course_ids: @course.id)
                                   .map { |x| x.assignment_id.to_i }

          expect(visible_assignment_ids).to include(@assignment.id)
        end

        it "does not show an assignment if student has no adhoc override for the discussion" do
          # Create a discussion topic
          @discussion_topic = @course.discussion_topics.create!(
            title: "Discussion with adhoc overrides",
            message: "Discuss this topic"
          )

          # Create assignment override for the discussion topic but for a different student
          ao = AssignmentOverride.new
          ao.discussion_topic = @discussion_topic
          ao.title = "ADHOC OVERRIDE"
          ao.workflow_state = "active"
          ao.set_type = "ADHOC"
          ao.save!

          # Add a different student to the override
          other_student = user_model
          @course.enroll_user(other_student, "StudentEnrollment")
          override_student = ao.assignment_override_students.build
          override_student.user = other_student
          override_student.save!

          # Now convert the discussion to an assignment
          @assignment = @course.assignments.create!(
            title: @discussion_topic.title,
            submission_types: "discussion_topic",
            only_visible_to_overrides: true
          )
          @discussion_topic.assignment = @assignment
          @discussion_topic.save!

          # The assignment should NOT be visible to our student without adhoc override
          visible_assignment_ids = AssignmentVisibility::AssignmentVisibilityService
                                   .assignments_visible_to_students(user_ids: @student.id, course_ids: @course.id)
                                   .map { |x| x.assignment_id.to_i }

          expect(visible_assignment_ids).not_to include(@assignment.id)
        end
      end
    end

    context "with caching" do
      specs_require_cache(:redis_cache_store)

      it "does not treat nil and [] as the same cache key" do
        # the visibility query has different results for nil arguments and [] arguments
        # so we must ensure the cache key is different as well
        course_with_differentiated_assignments_enabled
        assignment_with_false_only_visible_to_overrides
        # with passing nil assignment_ids
        visible_assignment_ids = AssignmentVisibility::AssignmentVisibilityService.assignments_visible_to_students(user_ids: @user.id, course_ids: @course.id).map(&:assignment_id)
        expect(visible_assignment_ids.map(&:to_i).include?(@assignment.id)).to be_truthy
        # with passing an empty array to assignment_ids
        visible_assignment_ids = AssignmentVisibility::AssignmentVisibilityService.assignments_visible_to_students(user_ids: @user.id, course_ids: @course.id, assignment_ids: []).map(&:assignment_id)
        expect(visible_assignment_ids.map(&:to_i).include?(@assignment.id)).to be_falsey
      end

      it "produces cached result when queried with same keys" do
        course_with_differentiated_assignments_enabled
        assignment_with_false_only_visible_to_overrides
        visible_assignment_ids_1 = AssignmentVisibility::AssignmentVisibilityService.assignments_visible_to_students(user_ids: @user.id, course_ids: @course.id).map(&:assignment_id)
        make_assignment
        visible_assignment_ids_2 = AssignmentVisibility::AssignmentVisibilityService.assignments_visible_to_students(user_ids: @user.id, course_ids: @course.id).map(&:assignment_id)

        expect(visible_assignment_ids_1).to eq(visible_assignment_ids_2)
      end

      it "produces updated result when cache is invalidated" do
        course_with_differentiated_assignments_enabled
        assignment_with_false_only_visible_to_overrides
        visible_assignment_ids_1 = AssignmentVisibility::AssignmentVisibilityService.assignments_visible_to_students(user_ids: @user.id, course_ids: @course.id).map(&:assignment_id)
        make_assignment
        AssignmentVisibility::AssignmentVisibilityService.invalidate_cache(user_ids: @user.id, course_ids: @course.id)
        visible_assignment_ids_2 = AssignmentVisibility::AssignmentVisibilityService.assignments_visible_to_students(user_ids: @user.id, course_ids: @course.id).map(&:assignment_id)

        expect(visible_assignment_ids_1).not_to eq(visible_assignment_ids_2)
      end
    end

    describe AssignmentVisibility do
      let!(:course) do
        course = Course.create!
        course.enroll_student(first_student)
        course.enroll_student(second_student)
        course
      end

      let(:assignment) do
        assignment = course.assignments.create!({
                                                  only_visible_to_overrides: false,
                                                  points_possible: 5,
                                                  submission_types: "online_text_entry",
                                                  title: "assignment"
                                                })
        assignment.publish
        assignment.save!
        assignment
      end
      let(:first_student) { User.create! }
      let(:second_student) { User.create! }
      let(:fake_student) { User.create! }

      describe ".assignments_with_user_visibilities" do
        let(:assignment_only_visible_to_overrides) do
          assignment = course.assignments.create!({
                                                    only_visible_to_overrides: true,
                                                    points_possible: 5,
                                                    submission_types: "online_text_entry",
                                                    title: "assignment only visible to overrides"
                                                  })
          override = assignment.assignment_overrides.create!(set_type: "ADHOC")
          override.assignment_override_students.create!(user: first_student)
          assignment
        end

        let(:assignments_with_visibilities) do
          AssignmentVisibility::AssignmentVisibilityService
            .assignments_with_user_visibilities(course, [assignment, assignment_only_visible_to_overrides])
        end

        it "returns a hash with assignment ids and their associated user ids " \
           "(or an empty array if the assignment is visible to everyone)" do
          expected_visibilities = {
            assignment.id => [],
            assignment_only_visible_to_overrides.id => [first_student.id]
          }
          expect(assignments_with_visibilities).to eq expected_visibilities
        end

        it "excludes student ids for deleted enrollments" do
          expected_visibilities = {
            assignment.id => [],
            assignment_only_visible_to_overrides.id => []
          }
          course.enrollments.find_by(user_id: first_student).destroy
          expect(assignments_with_visibilities).to eq expected_visibilities
        end

        it "does not call AssignmentVisibleToStudent.users_with_visibility_by_assignment " \
           "if all assignments are visible to everyone" do
          expect(AssignmentVisibility::AssignmentVisibilityService).not_to receive(:users_with_visibility_by_assignment)
          # change this assignment so that it is visible to all students
          assignment_only_visible_to_overrides.only_visible_to_overrides = false
          assignment_only_visible_to_overrides.save!
          assignments_with_visibilities
        end
      end
    end
  end
end
