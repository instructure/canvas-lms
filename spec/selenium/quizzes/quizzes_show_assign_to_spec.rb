# frozen_string_literal: true

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
require_relative "../common"
require_relative "../helpers/quizzes_common"
require_relative "../../spec_helper"
require_relative "page_objects/quizzes_landing_page"
require_relative "../helpers/items_assign_to_tray"
require_relative "../helpers/context_modules_common"

describe "quiz show page assign to" do
  include_context "in-process server selenium tests"
  include QuizzesLandingPage
  include ItemsAssignToTray
  include ContextModulesCommon

  before :once do
    course_with_teacher(active_all: true)
    @quiz_assignment = @course.assignments.create
    @quiz_assignment.quiz = @course.quizzes.create(title: "test quiz")
    @classic_quiz = @course.quizzes.last

    @student1 = student_in_course(course: @course, active_all: true, name: "Student 1").user
    @student2 = student_in_course(course: @course, active_all: true, name: "Student 2").user
  end

  before do
    user_session(@teacher)
  end

  it "brings up the assign to tray when selecting the assign to option" do
    get "/courses/#{@course.id}/quizzes/#{@classic_quiz.id}"

    click_quiz_assign_to_button

    wait_for_assign_to_tray_spinner
    keep_trying_until { expect(item_tray_exists?).to be_truthy }

    expect(tray_header.text).to eq("test quiz")
    expect(icon_type_exists?("Quiz")).to be true
  end

  it "closes the assign to tray on dismiss" do
    get "/courses/#{@course.id}/quizzes/#{@classic_quiz.id}"

    click_quiz_assign_to_button

    wait_for_assign_to_tray_spinner
    keep_trying_until { expect(item_tray_exists?).to be_truthy }

    expect(tray_header.text).to eq("test quiz")
    expect(icon_type_exists?("Quiz")).to be true

    click_cancel_button
    keep_trying_until { expect(element_exists?(module_item_edit_tray_selector)).to be_falsey }
  end

  it "assigns student and saves override", :ignore_js_errors do
    get "/courses/#{@course.id}/quizzes/#{@classic_quiz.id}"

    click_quiz_assign_to_button
    wait_for_assign_to_tray_spinner
    keep_trying_until { expect(item_tray_exists?).to be_truthy }

    click_add_assign_to_card
    select_module_item_assignee(1, @student1.name)
    update_due_date(1, "12/31/2022")
    update_due_time(1, "5:00 PM")
    update_available_date(1, "12/27/2022")
    update_available_time(1, "8:00 AM")
    update_until_date(1, "1/7/2023")
    update_until_time(1, "9:00 PM")
    click_save_button

    keep_trying_until { expect(element_exists?(module_item_edit_tray_selector)).to be_falsey }
    expect(@classic_quiz.assignment_overrides.last.assignment_override_students.count).to eq(1)
    # TODO: check that the dates are saved with date under the title of the item
  end

  it "shows existing enrollments when accessing assign to tray" do
    @classic_quiz.assignment_overrides.create!(set_type: "ADHOC")
    @classic_quiz.assignment_overrides.first.assignment_override_students.create!(user: @student1)

    get "/courses/#{@course.id}/quizzes/#{@classic_quiz.id}"

    click_quiz_assign_to_button
    wait_for_assign_to_tray_spinner
    keep_trying_until { expect(item_tray_exists?).to be_truthy }

    expect(module_item_assign_to_card[0]).to be_displayed
    expect(module_item_assign_to_card[1]).to be_displayed

    expect(assign_to_in_tray("Remove Everyone else")[0]).to be_displayed
    expect(assign_to_in_tray("Remove #{@student1.name}")[0]).to be_displayed
  end

  it "saves and shows override updates when tray reaccessed", :ignore_js_errors do
    get "/courses/#{@course.id}/quizzes/#{@classic_quiz.id}"

    click_quiz_assign_to_button
    wait_for_assign_to_tray_spinner

    keep_trying_until { expect(item_tray_exists?).to be_truthy }

    update_due_date(0, "12/31/2022")
    update_due_time(0, "5:00 PM")
    update_available_date(0, "12/27/2022")
    update_available_time(0, "8:00 AM")
    update_until_date(0, "1/7/2023")
    update_until_time(0, "9:00 PM")

    click_save_button
    keep_trying_until { expect(element_exists?(module_item_edit_tray_selector)).to be_falsey }

    click_quiz_assign_to_button
    wait_for_assign_to_tray_spinner

    keep_trying_until { expect(item_tray_exists?).to be_truthy }

    expect(assign_to_due_date(0).attribute("value")).to eq("Dec 31, 2022")
    expect(assign_to_due_time(0).attribute("value")).to eq("5:00 PM")
    expect(assign_to_available_from_date(0).attribute("value")).to eq("Dec 27, 2022")
    expect(assign_to_available_from_time(0).attribute("value")).to eq("8:00 AM")
    expect(assign_to_until_date(0).attribute("value")).to eq("Jan 7, 2023")
    expect(assign_to_until_time(0).attribute("value")).to eq("9:00 PM")
  end

  it "focus close button on open" do
    get "/courses/#{@course.id}/quizzes/#{@classic_quiz.id}"

    click_quiz_assign_to_button

    wait_for_assign_to_tray_spinner
    keep_trying_until { expect(item_tray_exists?).to be_truthy }

    check_element_has_focus close_button
  end

  it "does not show the button when the user does not have the manage_assignments_edit permission" do
    get "/courses/#{@course.id}/quizzes/#{@classic_quiz.id}"
    expect(element_exists?(quiz_assign_to_button_selector)).to be_truthy

    RoleOverride.create!(context: @course.account, permission: "manage_assignments_edit", role: teacher_role, enabled: false)
    get "/courses/#{@course.id}/quizzes/#{@classic_quiz.id}"
    expect(element_exists?(quiz_assign_to_button_selector)).to be_falsey
  end

  it "does show mastery paths in the assign to list for quizzes" do
    @course.conditional_release = true
    @course.save!

    get "/courses/#{@course.id}/quizzes/#{@classic_quiz.id}"

    click_quiz_assign_to_button

    wait_for_assign_to_tray_spinner
    keep_trying_until { expect(item_tray_exists?).to be_truthy }

    option_elements = INSTUI_Select_options(module_item_assignee[0])
    option_names = option_elements.map(&:text)
    expect(option_names).to include("Mastery Paths")
  end

  context "overrides table" do
    let(:due_at) { Time.zone.parse("2024-04-15") }
    let(:unlock_at) { Time.zone.parse("2024-04-10") }
    let(:lock_at) { Time.zone.parse("2024-04-20") }

    before do
      @course_section1 = @course.course_sections.create!(name: "Section Alpha")
      @course_section2 = @course.course_sections.create!(name: "Section Beta")

      @category = @course.group_categories.create!(name: "Course Group")

      @group1 = @category.groups.create!(name: "Course Group A", context: @course)
      @group2 = @category.groups.create!(name: "Course Group B", context: @course)
    end

    def create_test_overrides(object, types: %w[student section group], params: {})
      if types.include? "student"
        student_overrides = object.assignment_overrides.create!(
          set_type: "ADHOC",
          title: "2 students",
          **params
        )
        student_overrides.assignment_override_students.create!(user: @student1)
        student_overrides.assignment_override_students.create!(user: @student2)
      end

      if types.include? "section"
        object.assignment_overrides.create!(set_type: "CourseSection", set_id: @course_section1.id, **params)
        object.assignment_overrides.create!(set_type: "CourseSection", set_id: @course_section2.id, **params)
      end

      if types.include? "group"
        object.assignment_overrides.create!(set_type: "Group", set_id: @group1.id, **params)
        object.assignment_overrides.create!(set_type: "Group", set_id: @group2.id, **params)
      end
    end

    def validate_all_overrides(expected)
      expect(retrieve_overrides_count).to eq(expected.count)
      retrieve_all_overrides_formatted.each_with_index do |override, index|
        expect(override[:due_at]).to eq(expected[index][:due_at])
        expect(override[:due_for]).to eq(expected[index][:due_for])
        expect(override[:unlock_at]).to eq(expected[index][:unlock_at])
        expect(override[:lock_at]).to eq(expected[index][:lock_at])
      end
    end

    it "shows dates for Everyone when visible_to_everyone is true" do
      @classic_quiz.update!(
        due_at:,
        unlock_at:,
        lock_at:,
        only_visible_to_overrides: false
      )

      get "/courses/#{@course.id}/quizzes/#{@classic_quiz.id}"

      expect(@classic_quiz.visible_to_everyone).to be_truthy
      validate_all_overrides([
                               { due_at: "Apr 15, 2024 at 12am", due_for: "Everyone", unlock_at: "Apr 10, 2024 at 12am", lock_at: "Apr 20, 2024 at 12am" }
                             ])
    end

    it "shows dates for Everyone else when visible_to_everyone is true" do
      @classic_quiz.update!(
        due_at:,
        unlock_at:,
        lock_at:,
        only_visible_to_overrides: false
      )
      @quiz_assignment.update!(
        group_category: @category
      )

      params = {
        due_at:,
        due_at_overridden: true,
        unlock_at:,
        unlock_at_overridden: true,
        lock_at:,
        lock_at_overridden: true,
      }

      create_test_overrides(@quiz_assignment, types: ["student"], params: params.merge!({ due_at: due_at + 1.day }))
      create_test_overrides(@quiz_assignment, types: ["section"], params: params.merge!({ due_at: due_at + 2.days }))
      create_test_overrides(@quiz_assignment, types: ["group"], params: params.merge!({ due_at: due_at + 3.days }))

      get "/courses/#{@course.id}/quizzes/#{@classic_quiz.id}"

      expect(@classic_quiz.visible_to_everyone).to be_truthy

      validate_all_overrides([
                               { due_at: "Apr 15, 2024 at 12am", due_for: "Everyone else", unlock_at: "Apr 10, 2024 at 12am", lock_at: "Apr 20, 2024 at 12am" },
                               { due_at: "Apr 16, 2024", due_for: "2 Students", unlock_at: "Apr 10, 2024 at 12am", lock_at: "Apr 20, 2024 at 11:59pm" },
                               { due_at: "Apr 17, 2024", due_for: "2 Sections", unlock_at: "Apr 10, 2024 at 12am", lock_at: "Apr 20, 2024 at 11:59pm" },
                               { due_at: "Apr 18, 2024", due_for: "2 Groups", unlock_at: "Apr 10, 2024 at 12am", lock_at: "Apr 20, 2024 at 11:59pm" }
                             ])
    end

    it "does not any dates when without visible_to_everyone is false" do
      @classic_quiz.update!(
        due_at:,
        unlock_at:,
        lock_at:,
        only_visible_to_overrides: true
      )

      get "/courses/#{@course.id}/quizzes/#{@classic_quiz.id}"

      expect(@classic_quiz.visible_to_everyone).to be_falsey
      validate_all_overrides([])
    end

    it "does not show dates for Everyone else when visible_to_everyone is false" do
      @classic_quiz.update!(
        due_at:,
        unlock_at:,
        lock_at:,
        only_visible_to_overrides: true
      )
      @quiz_assignment.update!(
        group_category: @category
      )

      params = {
        due_at:,
        due_at_overridden: true,
        unlock_at:,
        unlock_at_overridden: true,
        lock_at:,
        lock_at_overridden: true,
      }

      create_test_overrides(@quiz_assignment, types: ["student"], params:)
      create_test_overrides(@quiz_assignment, types: ["section"], params: params.merge!({ due_at: due_at + 1.day }))
      create_test_overrides(@quiz_assignment, types: ["group"], params: params.merge!({ due_at: due_at + 2.days }))

      get "/courses/#{@course.id}/quizzes/#{@classic_quiz.id}"

      expect(@classic_quiz.visible_to_everyone).to be_falsey
      validate_all_overrides([
                               { due_at: "Apr 15, 2024", due_for: "2 Students", unlock_at: "Apr 10, 2024 at 12am", lock_at: "Apr 20, 2024 at 11:59pm" },
                               { due_at: "Apr 16, 2024", due_for: "2 Sections", unlock_at: "Apr 10, 2024 at 12am", lock_at: "Apr 20, 2024 at 11:59pm" },
                               { due_at: "Apr 17, 2024", due_for: "2 Groups", unlock_at: "Apr 10, 2024 at 12am", lock_at: "Apr 20, 2024 at 11:59pm" }
                             ])
    end

    it "shows dates for Everyone when there is course override" do
      @quiz_assignment.assignment_overrides.create!(set_type: "Course", set_id: @course.id, due_at:, unlock_at:, lock_at:)

      get "/courses/#{@course.id}/quizzes/#{@classic_quiz.id}"

      expect(@quiz_assignment.visible_to_everyone).to be_truthy
      validate_all_overrides([
                               { due_at: "Apr 15, 2024", due_for: "Everyone", unlock_at: "Apr 10, 2024 at 12am", lock_at: "Apr 20, 2024 at 11:59pm" }
                             ])
    end

    it "shows dates for default section" do
      @classic_quiz.update!(
        due_at:,
        unlock_at:,
        lock_at:,
        only_visible_to_overrides: true
      )

      @quiz_assignment.assignment_overrides.create!(
        set_type: "CourseSection",
        set_id: @course.default_section.id,
        due_at:,
        due_at_overridden: true,
        unlock_at:,
        unlock_at_overridden: true,
        lock_at:,
        lock_at_overridden: true
      )

      get "/courses/#{@course.id}/quizzes/#{@classic_quiz.id}"

      expect(@classic_quiz.visible_to_everyone).to be_falsey
      validate_all_overrides([
                               { due_at: "Apr 15, 2024", due_for: "1 Section", unlock_at: "Apr 10, 2024 at 12am", lock_at: "Apr 20, 2024 at 11:59pm" }
                             ])
    end

    it "does not show dates for overrides when unassign_item is true" do
      @classic_quiz.update!(
        due_at:,
        unlock_at:,
        lock_at:,
        only_visible_to_overrides: false
      )
      @quiz_assignment.update!(
        group_category: @category
      )

      create_test_overrides(@quiz_assignment, params: {
                              due_at:,
                              due_at_overridden: true,
                              unlock_at:,
                              unlock_at_overridden: true,
                              lock_at:,
                              lock_at_overridden: true,
                              unassign_item: true
                            })

      get "/courses/#{@course.id}/quizzes/#{@classic_quiz.id}"

      expect(@classic_quiz.visible_to_everyone).to be_truthy
      validate_all_overrides([
                               { due_at: "Apr 15, 2024 at 12am", due_for: "Everyone", unlock_at: "Apr 10, 2024 at 12am", lock_at: "Apr 20, 2024 at 12am" }
                             ])
    end

    it "does not show dates for overrides when workflow_state is deleted" do
      @classic_quiz.update!(
        due_at:,
        unlock_at:,
        lock_at:,
        only_visible_to_overrides: false
      )
      @quiz_assignment.update!(
        group_category: @category
      )

      create_test_overrides(@quiz_assignment, params: {
                              due_at:,
                              due_at_overridden: true,
                              unlock_at:,
                              unlock_at_overridden: true,
                              lock_at:,
                              lock_at_overridden: true,
                              workflow_state: "deleted"
                            })

      get "/courses/#{@course.id}/quizzes/#{@classic_quiz.id}"

      expect(@classic_quiz.visible_to_everyone).to be_truthy
      validate_all_overrides([
                               { due_at: "Apr 15, 2024 at 12am", due_for: "Everyone", unlock_at: "Apr 10, 2024 at 12am", lock_at: "Apr 20, 2024 at 12am" }
                             ])
    end

    context "with module overrides" do
      before do
        @module = @course.context_modules.create!(name: "Module 1")
        @module.add_item(type: "quiz", id: @classic_quiz.id)
      end

      it "shows only dates for inherited overrides" do
        @classic_quiz.update!(
          due_at:,
          unlock_at:,
          lock_at:,
          only_visible_to_overrides: true
        )

        create_test_overrides(@module)

        get "/courses/#{@course.id}/quizzes/#{@classic_quiz.id}"

        validate_all_overrides([
                                 { due_at: "-", due_for: "2 Sections, 2 Groups, 2 Students", unlock_at: "-", lock_at: "-" }
                               ])
      end

      it "shows only dates for assignment overrides due precedence" do
        @classic_quiz.update!(
          due_at:,
          unlock_at:,
          lock_at:,
          only_visible_to_overrides: false
        )
        @quiz_assignment.update!(
          group_category: @category
        )

        create_test_overrides(@module)
        create_test_overrides(@quiz_assignment, params: {
                                due_at:,
                                due_at_overridden: true,
                                unlock_at:,
                                unlock_at_overridden: true,
                                lock_at:,
                                lock_at_overridden: true
                              })

        get "/courses/#{@course.id}/quizzes/#{@classic_quiz.id}"

        # Doesn't show 'Everyone' when there are module overrides even if only_visible_to_overrides is false
        validate_all_overrides([
                                 { due_at: "Apr 15, 2024", due_for: "2 Sections, 2 Groups, 2 Students", unlock_at: "Apr 10, 2024 at 12am", lock_at: "Apr 20, 2024 at 11:59pm" }
                               ])
      end

      it "shows dates for inherited overrides and assignment overrides" do
        @classic_quiz.update!(
          due_at:,
          unlock_at:,
          lock_at:,
          only_visible_to_overrides: false
        )
        @quiz_assignment.update!(
          group_category: @category
        )

        student_overrides = @module.assignment_overrides.create!(
          set_type: "ADHOC",
          title: "2 students"
        )
        student_overrides.assignment_override_students.create!(user: @student1)
        student_overrides.assignment_override_students.create!(user: @student2)
        @module.assignment_overrides.create!(set_type: "CourseSection", set_id: @course_section1.id)
        @module.assignment_overrides.create!(set_type: "CourseSection", set_id: @course_section2.id)
        override_params = {
          due_at:,
          due_at_overridden: true,
          unlock_at:,
          unlock_at_overridden: true,
          lock_at:,
          lock_at_overridden: true
        }
        student_overrides = @quiz_assignment.assignment_overrides.create!(
          set_type: "ADHOC",
          title: "2 students",
          **override_params
        )
        student_overrides.assignment_override_students.create!(user: @student1)
        student_overrides.assignment_override_students.create!(user: @student2)
        @quiz_assignment.assignment_overrides.create!(set_type: "Group", set_id: @group1.id, **override_params)
        @quiz_assignment.assignment_overrides.create!(set_type: "Group", set_id: @group2.id, **override_params)

        get "/courses/#{@course.id}/quizzes/#{@classic_quiz.id}"

        # Doesn't show 'Everyone' when there are module overrides even if only_visible_to_overrides is false
        validate_all_overrides([
                                 { due_at: "Apr 15, 2024", due_for: "2 Groups, 2 Students", unlock_at: "Apr 10, 2024 at 12am", lock_at: "Apr 20, 2024 at 11:59pm" },
                                 { due_at: "-", due_for: "2 Sections", unlock_at: "-", lock_at: "-" }
                               ])
      end
    end
  end
end
