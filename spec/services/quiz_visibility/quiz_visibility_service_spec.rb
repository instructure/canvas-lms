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

require_relative "../../spec_helper"
require_relative "../../models/student_visibility/student_visibility_common"

describe "differentiated_assignments" do
  include StudentVisibilityCommon

  def course_with_differentiated_assignments_enabled
    @course = Course.create!
    @user = user_model
    @course.enroll_user(@user)
    @course.save!
  end

  def make_quiz(opts = {})
    @quiz = Quizzes::Quiz.create!({
                                    context: @course,
                                    description: "descript foo",
                                    only_visible_to_overrides: opts[:ovto],
                                    points_possible: rand(1000),
                                    title: "I am a quiz"
                                  })
    @quiz.publish
    @quiz.save!
    @quiz.assignment.context = @course
    @quiz.save!
    @assignment = @quiz.assignment
  end

  def quiz_with_true_only_visible_to_overrides
    make_quiz({ date: nil, ovto: true })
  end

  def quiz_with_false_only_visible_to_overrides
    make_quiz({ date: Time.zone.now, ovto: false })
  end

  def student_in_course_with_adhoc_override(quiz, opts = {})
    @user = opts[:user] || user_model
    StudentEnrollment.create!(user: @user, course: @course)
    ao = AssignmentOverride.new
    ao.quiz = quiz
    ao.title = "ADHOC OVERRIDE"
    ao.workflow_state = "active"
    ao.set_type = "ADHOC"
    ao.unassign_item = opts[:unassign_item] || "false"
    ao.save!
    override_student = ao.assignment_override_students.build
    override_student.user = @user
    override_student.save!
    quiz.reload
    @user
  end

  def enroller_user_in_section(section, opts = {})
    @user = opts[:user] || user_model
    StudentEnrollment.create!(user: @user, course: @course, course_section: section)
  end

  def create_diff_tags_category_with_groups(number_of_groups: 1)
    @diff_tag_category = @course.group_categories.create!(name: "Non-Collaborative Group", non_collaborative: true)
    @diff_tag_category.create_groups(number_of_groups)
  end

  def user_in_non_collaborative_group(non_collaborative_group, opts = {})
    @user = opts[:user] || user_model
    StudentEnrollment.create!(user: @user, course: @course)
    non_collaborative_group.add_user(@user)
  end

  def configure_differentiation_tags(setting_enabled: true, feature_flag_enabled: true)
    feature_flag_enabled ? @course.account.enable_feature!(:assign_to_differentiation_tags) : @course.account.disable_feature!(:assign_to_differentiation_tags)
    @course.account.settings[:allow_assign_to_differentiation_tags] = { value: setting_enabled }
    @course.account.save!
  end

  def enroller_user_in_both_sections
    @user = user_model
    StudentEnrollment.create!(user: @user, course: @course, course_section: @section_foo)
    StudentEnrollment.create!(user: @user, course: @course, course_section: @section_bar)
  end

  def add_multiple_sections
    @default_section = @course.default_section
    @section_foo = @course.course_sections.create!(name: "foo")
    @section_bar = @course.course_sections.create!(name: "bar")
  end

  def create_override_for_quiz(quiz)
    ao = AssignmentOverride.new
    ao.quiz = quiz
    ao.title = "Lorem"
    ao.workflow_state = "active"
    yield(ao)
    ao.save!
    quiz.reload
  end

  def give_non_collaborative_group_foo_due_date(quiz, non_collaborative_group, opts = {})
    create_override_for_quiz(quiz) do |ao|
      ao.set = non_collaborative_group
      ao.due_at = 3.weeks.from_now
      ao.unassign_item = opts[:unassign_item] || "false"
    end
  end

  def give_section_foo_due_date(quiz, opts = {})
    create_override_for_quiz(quiz) do |ao|
      ao.set = @section_foo
      ao.due_at = 3.weeks.from_now
      ao.unassign_item = opts[:unassign_item] || "false"
    end
  end

  def give_course_due_date(quiz)
    create_override_for_quiz(quiz) do |ao|
      ao.set = @course
      ao.due_at = 3.weeks.from_now
    end
  end

  def ensure_user_does_not_see_quiz
    visible_quiz_ids = QuizVisibility::QuizVisibilityService.quizzes_visible_to_students(user_ids: @user.id, course_ids: @course.id).map(&:quiz_id)
    expect(visible_quiz_ids.map(&:to_i).include?(@quiz.id)).to be_falsey
    expect(QuizVisibility::QuizVisibilityService.visible_quiz_ids_in_course_by_user(user_ids: [@user.id], course_ids: [@course.id])[@user.id]).not_to include(@quiz.id)
  end

  def ensure_user_sees_quiz
    visible_quiz_ids = QuizVisibility::QuizVisibilityService.quizzes_visible_to_students(user_ids: @user.id, course_ids: @course.id).map(&:quiz_id)
    expect(visible_quiz_ids.map(&:to_i).include?(@quiz.id)).to be_truthy
    expect(QuizVisibility::QuizVisibilityService.visible_quiz_ids_in_course_by_user(user_ids: [@user.id], course_ids: [@course.id])[@user.id]).to include(@quiz.id)
  end

  context "course_with_differentiated_assignments_enabled" do
    before do
      course_with_differentiated_assignments_enabled
      add_multiple_sections
    end

    context "quiz only visible to overrides" do
      before do
        quiz_with_true_only_visible_to_overrides
        give_section_foo_due_date(@quiz)
      end

      context "ADHOC overrides" do
        before { quiz_with_true_only_visible_to_overrides }

        it "returns a visibility for a student with an ADHOC override" do
          student_in_course_with_adhoc_override(@quiz)
          ensure_user_sees_quiz
        end

        it "shows the quiz to the user if course_ids is not present" do
          student_in_course_with_adhoc_override(@quiz)

          visible_quiz_ids = QuizVisibility::QuizVisibilityService.quizzes_visible_to_students(user_ids: @user.id, quiz_ids: @quiz.id, course_ids: nil).map(&:quiz_id)
          expect(visible_quiz_ids.map(&:to_i).include?(@quiz.id)).to be_truthy
        end

        it "does not return a visibility for a student without an ADHOC override" do
          @user = user_model
          ensure_user_does_not_see_quiz
        end

        it "does not return a visibility if ADHOC override is deleted" do
          student_in_course_with_adhoc_override(@quiz)
          @quiz.assignment_overrides.to_a.each(&:destroy)
          ensure_user_does_not_see_quiz
        end
      end

      context "user in section with override who then changes sections" do
        before do
          enroller_user_in_section(@section_foo)
          @student = @user
          teacher_in_course(course: @course)
        end

        it "does not keep the quiz visible even if there is a grade" do
          @quiz.assignment.grade_student(@student, grade: 10, grader: @teacher)
          Score.where(enrollment_id: @student.enrollments).each(&:destroy_permanently!)
          @student.enrollments.each(&:destroy_permanently!)
          enroller_user_in_section(@section_bar, { user: @student })
          ensure_user_does_not_see_quiz
        end

        it "does not keep the quiz visible if there is no score, even if it has a grade" do
          @quiz.assignment.grade_student(@student, grade: 10, grader: @teacher)
          @quiz.assignment.submissions.last.update_attribute("score", nil)
          @quiz.assignment.submissions.last.update_attribute("grade", 10)
          Score.where(enrollment_id: @student.enrollments).each(&:destroy_permanently!)
          @student.enrollments.each(&:destroy_permanently!)
          enroller_user_in_section(@section_bar, { user: @student })
          ensure_user_does_not_see_quiz
        end

        it "does not keep the quiz visible even if the grade is zero" do
          @quiz.assignment.grade_student(@student, grade: 0, grader: @teacher)
          Score.where(enrollment_id: @student.enrollments).each(&:destroy_permanently!)
          @student.enrollments.each(&:destroy_permanently!)
          enroller_user_in_section(@section_bar, { user: @student })
          ensure_user_does_not_see_quiz
        end
      end

      context "user in default section" do
        it "hides the quiz from the user" do
          ensure_user_does_not_see_quiz
        end
      end

      context "user in section with override" do
        before { enroller_user_in_section(@section_foo) }

        it "shows the quiz to the user" do
          ensure_user_sees_quiz
        end

        it "shows the quiz to the user if course_ids is not present" do
          visible_quiz_ids = QuizVisibility::QuizVisibilityService.quizzes_visible_to_students(user_ids: @user.id, quiz_ids: @quiz.id, course_ids: nil).map(&:quiz_id)
          expect(visible_quiz_ids.map(&:to_i).include?(@quiz.id)).to be_truthy
        end

        it "updates when enrollments change" do
          ensure_user_sees_quiz
          enrollments = StudentEnrollment.where(user_id: @user.id, course_id: @course.id, course_section_id: @section_foo.id)
          Score.where(enrollment_id: enrollments).each(&:destroy_permanently!)
          enrollments.each(&:destroy_permanently!)
          ensure_user_does_not_see_quiz
        end

        it "updates when the override is deleted" do
          ensure_user_sees_quiz
          @quiz.assignment_overrides.to_a.each(&:destroy!)
          ensure_user_does_not_see_quiz
        end
      end

      context "user in section with no override" do
        before { enroller_user_in_section(@section_bar) }

        it "hides the quiz from the user" do
          ensure_user_does_not_see_quiz
        end
      end

      context "user in section with override and one without override" do
        before do
          enroller_user_in_both_sections
        end

        it "shows the quiz to the user" do
          ensure_user_sees_quiz
        end
      end
    end

    context "quiz assignment non collaborative group overrides" do
      before do
        quiz_with_true_only_visible_to_overrides
        configure_differentiation_tags
      end

      it "applies non collaborative group overrides" do
        create_diff_tags_category_with_groups
        diff_tag_group_1 = @diff_tag_category.groups[0]
        user_in_non_collaborative_group(diff_tag_group_1)

        @quiz.assignment_overrides.create!(set: diff_tag_group_1)
        ensure_user_sees_quiz
      end

      it "does not apply non collaborative group overrides" do
        create_diff_tags_category_with_groups(number_of_groups: 2)
        diff_tag_group_1 = @diff_tag_category.groups[0]
        user_in_non_collaborative_group(diff_tag_group_1)
        diff_tag_group_no_users = @diff_tag_category.groups[1]

        @quiz.assignment_overrides.create!(set: diff_tag_group_no_users)
        ensure_user_does_not_see_quiz
      end

      it "applies existing non collaborative group overrides when account setting is disabled" do
        create_diff_tags_category_with_groups
        diff_tag_group_1 = @diff_tag_category.groups[0]
        user_in_non_collaborative_group(diff_tag_group_1)

        @quiz.assignment_overrides.create!(set: diff_tag_group_1)
        ensure_user_sees_quiz

        configure_differentiation_tags(setting_enabled: false, feature_flag_enabled: true)
        ensure_user_sees_quiz
      end

      it "does not apply non collaborative group overrides when feature flag is disabled" do
        create_diff_tags_category_with_groups
        diff_tag_group_1 = @diff_tag_category.groups[0]
        user_in_non_collaborative_group(diff_tag_group_1)

        @quiz.assignment_overrides.create!(set: diff_tag_group_1)
        ensure_user_sees_quiz

        configure_differentiation_tags(setting_enabled: false, feature_flag_enabled: false)
        ensure_user_does_not_see_quiz
      end

      it "does not include quiz if course_ids is not present" do
        create_diff_tags_category_with_groups
        diff_tag_group_1 = @diff_tag_category.groups[0]
        user_in_non_collaborative_group(diff_tag_group_1)

        @quiz.assignment_overrides.create!(set: diff_tag_group_1)

        visible_quiz_ids = QuizVisibility::QuizVisibilityService.quizzes_visible_to_students(user_ids: @user.id, quiz_ids: @quiz.id, course_ids: nil).map(&:quiz_id)
        expect(visible_quiz_ids.map(&:to_i).include?(@quiz.id)).to be_falsey
      end

      it "does not apply non collaborative group overrides when override is deleted" do
        create_diff_tags_category_with_groups
        diff_tag_group_1 = @diff_tag_category.groups[0]
        user_in_non_collaborative_group(diff_tag_group_1)

        @quiz.assignment_overrides.create!(set: diff_tag_group_1, workflow_state: "deleted")
        ensure_user_does_not_see_quiz
      end
    end

    shared_examples_for "module overrides" do
      it "includes everyone else if there no modules and no overrides" do
        quiz_with_false_only_visible_to_overrides
        ensure_user_sees_quiz
      end

      it "does not apply context module overrides that don't apply to user" do
        quiz_with_false_only_visible_to_overrides

        module1 = @course.context_modules.create!(name: "Module 1")
        @quiz.context_module_tags.create! context_module: module1, context: @course, tag_type: "context_module"

        module1.assignment_overrides.create!

        ensure_user_does_not_see_quiz
      end

      it "applies context module adhoc overrides" do
        quiz_with_true_only_visible_to_overrides

        module1 = @course.context_modules.create!(name: "Module 1")
        @quiz.context_module_tags.create! context_module: module1, context: @course, tag_type: "context_module"

        module_override = module1.assignment_overrides.create!
        module_override.assignment_override_students.create!(user: @user)

        ensure_user_sees_quiz
      end

      it "applies context module section overrides" do
        quiz_with_true_only_visible_to_overrides
        enroller_user_in_section(@section_foo)
        module1 = @course.context_modules.create!(name: "Module 1")
        @quiz.context_module_tags.create! context_module: module1, context: @course, tag_type: "context_module"

        module_override = module1.assignment_overrides.create!

        module_override.set_type = "CourseSection"
        module_override.set_id = @section_foo
        module_override.save!

        ensure_user_sees_quiz
      end

      it "does not apply context module section overrides student is not enrolled in" do
        quiz_with_false_only_visible_to_overrides

        module1 = @course.context_modules.create!(name: "Module 1")
        @quiz.context_module_tags.create! context_module: module1, context: @course, tag_type: "context_module"

        module_override = module1.assignment_overrides.create!

        module_override.set_type = "CourseSection"
        module_override.set_id = @section_foo
        module_override.save!

        ensure_user_does_not_see_quiz
      end

      context "non collaborative group overrides" do
        before do
          quiz_with_true_only_visible_to_overrides
          configure_differentiation_tags
        end

        it "applies context module non collaborative group overrides" do
          create_diff_tags_category_with_groups
          diff_tag_group_1 = @diff_tag_category.groups[0]
          user_in_non_collaborative_group(diff_tag_group_1)

          module1 = @course.context_modules.create!(name: "Module 1")
          @quiz.context_module_tags.create! context_module: module1, context: @course, tag_type: "context_module"

          module1.assignment_overrides.create!(set_type: "Group", set_id: diff_tag_group_1.id)
          ensure_user_sees_quiz
        end

        it "does not apply context module non collaborative group overrides" do
          create_diff_tags_category_with_groups(number_of_groups: 2)
          diff_tag_group_1 = @diff_tag_category.groups[0]
          user_in_non_collaborative_group(diff_tag_group_1)
          diff_tag_group_no_users = @diff_tag_category.groups[1]

          module1 = @course.context_modules.create!(name: "Module 1")
          @quiz.context_module_tags.create! context_module: module1, context: @course, tag_type: "context_module"

          module1.assignment_overrides.create!(set_type: "Group", set_id: diff_tag_group_no_users.id)
          ensure_user_does_not_see_quiz
        end

        it "applies existing context module non collaborative group overrides when account setting is disabled" do
          create_diff_tags_category_with_groups
          diff_tag_group_1 = @diff_tag_category.groups[0]
          user_in_non_collaborative_group(diff_tag_group_1)

          module1 = @course.context_modules.create!(name: "Module 1")
          @quiz.context_module_tags.create! context_module: module1, context: @course, tag_type: "context_module"

          module1.assignment_overrides.create!(set_type: "Group", set_id: diff_tag_group_1.id)
          ensure_user_sees_quiz

          configure_differentiation_tags(setting_enabled: false, feature_flag_enabled: true)
          ensure_user_sees_quiz
        end

        it "does not apply context module non collaborative group overrides when feature flag is disabled" do
          create_diff_tags_category_with_groups
          diff_tag_group_1 = @diff_tag_category.groups[0]
          user_in_non_collaborative_group(diff_tag_group_1)

          module1 = @course.context_modules.create!(name: "Module 1")
          @quiz.context_module_tags.create! context_module: module1, context: @course, tag_type: "context_module"

          module1.assignment_overrides.create!(set_type: "Group", set_id: diff_tag_group_1.id)
          ensure_user_sees_quiz

          configure_differentiation_tags(setting_enabled: false, feature_flag_enabled: false)
          ensure_user_does_not_see_quiz
        end

        it "does not apply context module non collaborative group overrides when override is deleted" do
          create_diff_tags_category_with_groups
          diff_tag_group_1 = @diff_tag_category.groups[0]
          user_in_non_collaborative_group(diff_tag_group_1)

          module1 = @course.context_modules.create!(name: "Module 1")
          @quiz.context_module_tags.create! context_module: module1, context: @course, tag_type: "context_module"

          module1.assignment_overrides.create!(set_type: "Group", set_id: diff_tag_group_1.id, workflow_state: "deleted")
          ensure_user_does_not_see_quiz
        end
      end
    end

    context "quizzes with modules" do
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
        quiz_with_true_only_visible_to_overrides
      end

      it "is not visible with an unassigned adhoc override" do
        student_in_course_with_adhoc_override(@quiz, { unassign_item: "true" })
        ensure_user_does_not_see_quiz
      end

      it "is not visible with an unassigned section override" do
        enroller_user_in_section(@section_foo)
        give_section_foo_due_date(@quiz, { unassign_item: "true" })
        ensure_user_does_not_see_quiz
      end

      it "is not visible with an unassigned non collaborative group override" do
        configure_differentiation_tags
        create_diff_tags_category_with_groups
        diff_tag_group_1 = @diff_tag_category.groups[0]
        user_in_non_collaborative_group(diff_tag_group_1)

        give_non_collaborative_group_foo_due_date(@quiz, diff_tag_group_1, { unassign_item: "true" })
        ensure_user_does_not_see_quiz
      end

      it "is not visible with an unassigned adhoc override and assigned section override" do
        enroller_user_in_section(@section_foo)
        give_section_foo_due_date(@quiz)
        student_in_course_with_adhoc_override(@quiz, { unassign_item: "true" })
        ensure_user_does_not_see_quiz
      end

      it "is visible with an unassigned section override and assigned adhoc override" do
        enroller_user_in_section(@section_foo)
        give_section_foo_due_date(@quiz, { unassign_item: "true" })
        student_in_course_with_adhoc_override(@quiz)
        ensure_user_sees_quiz
      end

      it "does not apply context module section override with an unassigned section override" do
        enroller_user_in_section(@section_foo)
        module1 = @course.context_modules.create!(name: "Module 1")
        @quiz.context_module_tags.create! context_module: module1, context: @course, tag_type: "context_module"

        module_override = module1.assignment_overrides.create!

        module_override.set_type = "CourseSection"
        module_override.set_id = @section_foo
        module_override.save!

        give_section_foo_due_date(@quiz, { unassign_item: "true" })

        ensure_user_does_not_see_quiz
      end

      it "does not apply context module section override with an unassigned non collaborative group override" do
        configure_differentiation_tags
        create_diff_tags_category_with_groups
        diff_tag_group_1 = @diff_tag_category.groups[0]
        user_in_non_collaborative_group(diff_tag_group_1)

        module1 = @course.context_modules.create!(name: "Module 1")
        @quiz.context_module_tags.create! context_module: module1, context: @course, tag_type: "context_module"

        module1.assignment_overrides.create!(set_type: "Group", set_id: diff_tag_group_1.id)

        give_non_collaborative_group_foo_due_date(@quiz, diff_tag_group_1, { unassign_item: "true" })

        ensure_user_does_not_see_quiz
      end

      it "does not apply context module adhoc overrides with an unassigned adhoc override" do
        module1 = @course.context_modules.create!(name: "Module 1")
        @quiz.context_module_tags.create! context_module: module1, context: @course, tag_type: "context_module"

        module_override = module1.assignment_overrides.create!
        module_override.assignment_override_students.create!(user: @user)

        student_in_course_with_adhoc_override(@quiz, { unassign_item: "true" })
        ensure_user_does_not_see_quiz
      end
    end

    context "course overrides" do
      before do
        quiz_with_true_only_visible_to_overrides
        give_course_due_date(@quiz)
      end

      it "shows the quiz to users in the course" do
        ensure_user_sees_quiz
      end

      it "shows the quiz to the user if course_ids is not present" do
        visible_quiz_ids = QuizVisibility::QuizVisibilityService.quizzes_visible_to_students(user_ids: @user.id, quiz_ids: @quiz.id, course_ids: nil).map(&:quiz_id)
        expect(visible_quiz_ids.map(&:to_i).include?(@quiz.id)).to be_truthy
      end

      it "does not show unpublished quizzes" do
        @quiz.workflow_state = "unpublished"
        @quiz.save!
        ensure_user_does_not_see_quiz
      end

      it "updates when enrollments are destroyed" do
        ensure_user_sees_quiz
        enrollments = StudentEnrollment.where(user_id: @user.id, course_id: @course.id)
        enrollments.destroy_all
        ensure_user_does_not_see_quiz
      end

      it "updates when enrollments are inactive" do
        ensure_user_sees_quiz
        @user.enrollments.where(course_id: @course.id).first.deactivate
        ensure_user_does_not_see_quiz
      end

      it "updates when the override is deleted" do
        ensure_user_sees_quiz
        @quiz.assignment_overrides.each(&:destroy!)
        ensure_user_does_not_see_quiz
      end
    end

    context "quiz with false only_visible_to_overrides" do
      before do
        quiz_with_false_only_visible_to_overrides
        give_section_foo_due_date(@quiz)
      end

      context "user in default section" do
        it "shows the quiz to the user" do
          ensure_user_sees_quiz
        end
      end

      context "user in section with override" do
        before { enroller_user_in_section(@section_foo) }

        it "shows the quiz to the user" do
          ensure_user_sees_quiz
        end
      end

      context "user in section with no override" do
        before { enroller_user_in_section(@section_bar) }

        it "shows the quiz to the user" do
          ensure_user_sees_quiz
        end
      end

      context "user in section with override and one without override" do
        before do
          enroller_user_in_both_sections
        end

        it "shows the quiz to the user" do
          ensure_user_sees_quiz
        end
      end
    end
  end
end
