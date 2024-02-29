# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

require_relative "../spec_helper"
require_relative "student_visibility/student_visibility_common"

# need tests for:
# overrides that arent date related

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
    make_assignment({ date: Time.now, ovto: false })
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
    visible_assignment_ids = AssignmentStudentVisibility.where(user_id: @user.id, course_id: @course.id).pluck(:assignment_id)
    expect(visible_assignment_ids.map(&:to_i).include?(@assignment.id)).to be_falsey
    expect(AssignmentStudentVisibility.visible_assignment_ids_in_course_by_user(user_id: [@user.id], course_id: [@course.id])[@user.id]).not_to include(@assignment.id)
  end

  def ensure_user_sees_assignment
    visible_assignment_ids = AssignmentStudentVisibility.where(user_id: @user.id, course_id: @course.id).pluck(:assignment_id)
    expect(visible_assignment_ids.map(&:to_i).include?(@assignment.id)).to be_truthy
    expect(AssignmentStudentVisibility.visible_assignment_ids_in_course_by_user(user_id: [@user.id], course_id: [@course.id])[@user.id]).to include(@assignment.id)
    expect(AssignmentStudentVisibility.visible_assignment_ids_in_course_by_user(user_id: [@user.id], course_id: [@course.id], use_global_id: true)[Shard.global_id_for(@user.id)]).to include(@assignment.id)
  end

  context "table" do
    before do
      course_with_differentiated_assignments_enabled
      add_multiple_sections
      assignment_with_true_only_visible_to_overrides
      give_section_due_date(@assignment, @section_foo)
      enroller_user_in_section(@section_foo)
    end

    let(:visibility_object) { AssignmentStudentVisibility.first }

    it_behaves_like "student visibility models"
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

        it "works with course section and return a single visibility" do
          student_in_course_with_adhoc_override(@assignment)
          give_section_due_date(@assignment, @section_foo)
          enroller_user_in_section(@section_foo)
          ensure_user_sees_assignment
          expect(AssignmentStudentVisibility.where(user_id: @user.id, course_id: @course.id).count).to eq 1
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
            visible_assignment_ids = AssignmentStudentVisibility.where(user_id: @user.id, course_id: @course.id)
            expect(visible_assignment_ids.count).to eq 1
          end
        end

        context "user in groups with and without override" do
          before { enroller_user_in_both_groups(user: @user) }

          it "shows the assignment to the user" do
            ensure_user_sees_assignment
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
            Score.where(enrollment_id: @user.enrollments).each(&:destroy_permanently!)
            @user.enrollments.each(&:destroy_permanently!)
            enroller_user_in_section(@section_bar, { user: @user })
            ensure_user_does_not_see_assignment
          end

          it "does not keep the assignment visible even if the grade is zero" do
            @assignment.grade_student(@user, grade: 0, grader: @teacher)
            Score.where(enrollment_id: @user.enrollments).each(&:destroy_permanently!)
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
            visible_assignment_ids = AssignmentStudentVisibility.where(user_id: @user.id, course_id: @course.id)
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

      context "module overrides" do
        before do
          Account.site_admin.enable_feature!(:differentiated_modules)
          Setting.set("differentiated_modules_setting", Account.site_admin.feature_enabled?(:differentiated_modules) ? "true" : "false")
          AssignmentStudentVisibility.reset_table_name
        end

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

        it "does not apply context module adhoc overrides with flag off" do
          Account.site_admin.disable_feature!(:differentiated_modules)
          Setting.set("differentiated_modules_setting", Account.site_admin.feature_enabled?(:differentiated_modules) ? "true" : "false")
          AssignmentStudentVisibility.reset_table_name

          assignment_with_true_only_visible_to_overrides

          module1 = @course.context_modules.create!(name: "Module 1")
          @assignment.context_module_tags.create! context_module: module1, context: @course, tag_type: "context_module"

          module_override = module1.assignment_overrides.create!
          module_override.assignment_override_students.create!(user: @user)

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

          expect(AssignmentStudentVisibility.where(assignment_id: quiz.assignment).pluck(:user_id)).to include @user.id
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

      context "unassign item overrides" do
        before do
          Account.site_admin.enable_feature!(:differentiated_modules)
          Setting.set("differentiated_modules_setting", Account.site_admin.feature_enabled?(:differentiated_modules) ? "true" : "false")
          AssignmentStudentVisibility.reset_table_name
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

        it "does not unassign if the flag is off" do
          Account.site_admin.disable_feature!(:differentiated_modules)
          Setting.set("differentiated_modules_setting", Account.site_admin.feature_enabled?(:differentiated_modules) ? "true" : "false")
          AssignmentStudentVisibility.reset_table_name
          student_in_course_with_adhoc_override(@assignment, { unassign: "true" })
          ensure_user_sees_assignment
        end
      end

      context "course overrides" do
        before do
          Account.site_admin.enable_feature!(:differentiated_modules)
          Setting.set("differentiated_modules_setting", Account.site_admin.feature_enabled?(:differentiated_modules) ? "true" : "false")
          AssignmentStudentVisibility.reset_table_name
          assignment_with_true_only_visible_to_overrides
          give_course_due_date(@assignment)
        end

        it "shows the assignment to users in the course" do
          ensure_user_sees_assignment
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

        it "does not show the assignment to users in the course with flag off" do
          Account.site_admin.disable_feature!(:differentiated_modules)
          Setting.set("differentiated_modules_setting", Account.site_admin.feature_enabled?(:differentiated_modules) ? "true" : "false")
          AssignmentStudentVisibility.reset_table_name
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

  describe AssignmentStudentVisibility do
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

    describe ".assignments_visible_to_all_students" do
      let(:assignments_visible_to_all_students) do
        AssignmentStudentVisibility.assignments_visible_to_all_students([assignment])
      end

      it "returns a hash with an empty visibility array for each assignment" do
        expect(assignments_visible_to_all_students).to eq({ assignment.id => [] })
      end
    end

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
        AssignmentStudentVisibility
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

      it "does not call AssignmentStudentVisibility.users_with_visibility_by_assignment " \
         "if all assignments are visible to everyone" do
        expect(AssignmentStudentVisibility).not_to receive(:users_with_visibility_by_assignment)
        # change this assignment so that it is visible to all students
        assignment_only_visible_to_overrides.only_visible_to_overrides = false
        assignment_only_visible_to_overrides.save!
        assignments_with_visibilities
      end
    end
  end
end
