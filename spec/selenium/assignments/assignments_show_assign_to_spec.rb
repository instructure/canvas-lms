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
require_relative "../../spec_helper"
require_relative "page_objects/assignments_index_page"
require_relative "page_objects/assignment_page"
require_relative "../helpers/items_assign_to_tray"
require_relative "../helpers/context_modules_common"

describe "assignments show page assign to" do
  include_context "in-process server selenium tests"
  include AssignmentsIndexPage
  include ItemsAssignToTray
  include ContextModulesCommon

  before :once do
    course_with_teacher(active_all: true)
    @assignment1 = @course.assignments.create(name: "test assignment", points_possible: 25)

    @student1 = student_in_course(course: @course, active_all: true, name: "Student 1").user
    @student2 = student_in_course(course: @course, active_all: true, name: "Student 2").user
  end

  before do
    user_session(@teacher)
  end

  it "brings up the assign to tray when selecting the assign to option" do
    get "/courses/#{@course.id}/assignments/#{@assignment1.id}"

    AssignmentPage.click_assign_to_button

    wait_for_assign_to_tray_spinner
    keep_trying_until { expect(item_tray_exists?).to be_truthy }

    expect(tray_header.text).to eq("test assignment")
    expect(icon_type_exists?("Assignment")).to be true
    expect(item_type_text.text).to include("25 pts")
  end

  it "closes the assign to tray on dismiss" do
    get "/courses/#{@course.id}/assignments/#{@assignment1.id}"

    AssignmentPage.click_assign_to_button

    wait_for_assign_to_tray_spinner
    keep_trying_until { expect(item_tray_exists?).to be_truthy }

    expect(tray_header.text).to eq("test assignment")
    expect(icon_type_exists?("Assignment")).to be true
    expect(item_type_text.text).to include("25 pts")

    click_cancel_button
    keep_trying_until { expect(element_exists?(module_item_edit_tray_selector)).to be_falsey }
  end

  it "assigns student and saves assignment", :ignore_js_errors do
    get "/courses/#{@course.id}/assignments/#{@assignment1.id}"

    AssignmentPage.click_assign_to_button
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
    expect(@assignment1.assignment_overrides.last.assignment_override_students.count).to eq(1)
    # TODO: check that the dates are saved with date under the title of the item
  end

  it "does not show concluded student enrollments" do
    test_student = student_in_course(course: @course, active_all: true, name: "Test Student").user
    Enrollment.where(user_id: test_student.id, course_id: @course.id).first.conclude

    get "/courses/#{@course.id}/assignments/#{@assignment1.id}"

    AssignmentPage.click_assign_to_button

    f("[data-testid='assignee_selector']").click
    expect(find_all('[group="Students"]').map(&:text)).not_to include "Test Student"
  end

  it "shows existing enrollments when accessing assign to tray" do
    @assignment1.assignment_overrides.create!(set_type: "ADHOC")
    @assignment1.assignment_overrides.first.assignment_override_students.create!(user: @student1)

    get "/courses/#{@course.id}/assignments/#{@assignment1.id}"

    AssignmentPage.click_assign_to_button
    wait_for_assign_to_tray_spinner
    keep_trying_until { expect(item_tray_exists?).to be_truthy }

    expect(module_item_assign_to_card[0]).to be_displayed
    expect(module_item_assign_to_card[1]).to be_displayed

    expect(assign_to_in_tray("Remove Everyone else")[0]).to be_displayed
    expect(assign_to_in_tray("Remove #{@student1.name}")[0]).to be_displayed
  end

  it "does not show cards for ADHOC override with no students" do
    @assignment1.assignment_overrides.create!(set_type: "ADHOC")

    get "/courses/#{@course.id}/assignments/#{@assignment1.id}"

    AssignmentPage.click_assign_to_button
    wait_for_assign_to_tray_spinner
    keep_trying_until { expect(item_tray_exists?).to be_truthy }
    # only renders the everyone card
    expect(module_item_assign_to_card.length).to be(1)
  end

  it "saves and shows override updates when tray reaccessed", :ignore_js_errors do
    get "/courses/#{@course.id}/assignments/#{@assignment1.id}"

    AssignmentPage.click_assign_to_button
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

    AssignmentPage.click_assign_to_button
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
    get "/courses/#{@course.id}/assignments/#{@assignment1.id}"

    AssignmentPage.click_assign_to_button
    wait_for_assign_to_tray_spinner
    keep_trying_until { expect(item_tray_exists?).to be_truthy }

    check_element_has_focus close_button
  end

  it "does not show the button when the user does not have the manage_assignments_edit permission" do
    get "/courses/#{@course.id}/assignments/#{@assignment1.id}"
    expect(element_exists?(AssignmentPage.assign_to_button_selector)).to be_truthy

    RoleOverride.create!(context: @course.account, permission: "manage_assignments_edit", role: teacher_role, enabled: false)
    get "/courses/#{@course.id}/assignments/#{@assignment1.id}"
    expect(element_exists?(AssignmentPage.assign_to_button_selector)).to be_falsey
  end

  it "does show mastery paths in the assign to list for assignments" do
    @course.conditional_release = true
    @course.save!

    get "/courses/#{@course.id}/assignments/#{@assignment1.id}"

    AssignmentPage.click_assign_to_button
    wait_for_assign_to_tray_spinner
    keep_trying_until { expect(item_tray_exists?).to be_truthy }

    option_elements = INSTUI_Select_options(module_item_assignee[0])
    option_names = option_elements.map(&:text)
    expect(option_names).to include("Mastery Paths")
  end

  it "shows all the overrides if there are more than a page size for the assignment", custom_timeout: 30 do
    @page_size = 5
    stub_const("Api::MAX_PER_PAGE", @page_size)
    create_users_in_course(@course, 20, return_type: :record, name_prefix: "Student")
    Assignment.suspend_due_date_caching do
      @course.students.each do |student|
        ao = @assignment1.assignment_overrides.create!
        ao.assignment_override_students.create!(user: student)
      end
    end
    get "/courses/#{@course.id}/assignments/#{@assignment1.id}"
    AssignmentPage.click_assign_to_button
    wait_for_assign_to_tray_spinner
    keep_trying_until { expect(item_tray_exists?).to be_truthy }
    # there were 2 existing users in the course, plus the Everyone Else card, so we expect 23 cards
    expect(module_item_assign_to_card.length).to eq(23)
  end

  context "overrides table" do
    let(:due_at) { Time.zone.parse("2024-04-15") }
    let(:unlock_at) { Time.zone.parse("2024-04-10") }
    let(:lock_at) { Time.zone.parse("2024-04-20") }

    before do
      @assignment = @course.assignments.create(name: "test assignment", points_possible: 25)

      @student1 = student_in_course(course: @course, active_all: true, name: "Student 1").user
      @student2 = student_in_course(course: @course, active_all: true, name: "Student 2").user
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
      expect(AssignmentPage.retrieve_overrides_count).to eq(expected.count)
      AssignmentPage.retrieve_all_overrides_formatted.each_with_index do |override, index|
        expect(override[:due_at]).to eq(expected[index][:due_at])
        expect(override[:due_for]).to eq(expected[index][:due_for])
        expect(override[:unlock_at]).to eq(expected[index][:unlock_at])
        expect(override[:lock_at]).to eq(expected[index][:lock_at])
      end
    end

    it "shows dates for Everyone when visible_to_everyone is true" do
      @assignment.update!(
        due_at:,
        unlock_at:,
        lock_at:,
        only_visible_to_overrides: false
      )

      get "/courses/#{@course.id}/assignments/#{@assignment.id}"

      expect(@assignment.visible_to_everyone).to be_truthy
      validate_all_overrides([
                               { due_at: "Apr 15, 2024 at 12am", due_for: "Everyone", unlock_at: "Apr 10, 2024 at 12am", lock_at: "Apr 20, 2024 at 12am" }
                             ])
    end

    it "shows dates for Everyone else when visible_to_everyone is true" do
      @assignment.update!(
        group_category: @category,
        due_at:,
        unlock_at:,
        lock_at:,
        only_visible_to_overrides: false
      )

      params = {
        due_at:,
        due_at_overridden: true,
        unlock_at:,
        unlock_at_overridden: true,
        lock_at:,
        lock_at_overridden: true,
      }

      create_test_overrides(@assignment, types: ["student"], params: params.merge!({ due_at: due_at + 1.day }))
      create_test_overrides(@assignment, types: ["section"], params: params.merge!({ due_at: due_at + 2.days }))
      create_test_overrides(@assignment, types: ["group"], params: params.merge!({ due_at: due_at + 3.days }))

      get "/courses/#{@course.id}/assignments/#{@assignment.id}"

      expect(@assignment.visible_to_everyone).to be_truthy

      validate_all_overrides([
                               { due_at: "Apr 15, 2024 at 12am", due_for: "Everyone else", unlock_at: "Apr 10, 2024 at 12am", lock_at: "Apr 20, 2024 at 12am" },
                               { due_at: "Apr 16, 2024", due_for: "2 Students", unlock_at: "Apr 10, 2024 at 12am", lock_at: "Apr 20, 2024 at 11:59pm" },
                               { due_at: "Apr 17, 2024", due_for: "2 Sections", unlock_at: "Apr 10, 2024 at 12am", lock_at: "Apr 20, 2024 at 11:59pm" },
                               { due_at: "Apr 18, 2024", due_for: "2 Groups", unlock_at: "Apr 10, 2024 at 12am", lock_at: "Apr 20, 2024 at 11:59pm" }
                             ])
    end

    it "does not any dates when without visible_to_everyone is false" do
      @assignment.update!(
        due_at:,
        unlock_at:,
        lock_at:,
        only_visible_to_overrides: true
      )

      get "/courses/#{@course.id}/assignments/#{@assignment.id}"

      expect(@assignment.visible_to_everyone).to be_falsey
      validate_all_overrides([])
    end

    it "does not show dates for Everyone else when visible_to_everyone is false" do
      @assignment.update!(
        group_category: @category,
        due_at:,
        unlock_at:,
        lock_at:,
        only_visible_to_overrides: true
      )

      params = {
        due_at:,
        due_at_overridden: true,
        unlock_at:,
        unlock_at_overridden: true,
        lock_at:,
        lock_at_overridden: true,
      }

      create_test_overrides(@assignment, types: ["student"], params:)
      create_test_overrides(@assignment, types: ["section"], params: params.merge!({ due_at: due_at + 1.day }))
      create_test_overrides(@assignment, types: ["group"], params: params.merge!({ due_at: due_at + 2.days }))

      get "/courses/#{@course.id}/assignments/#{@assignment.id}"

      expect(@assignment.visible_to_everyone).to be_falsey
      validate_all_overrides([
                               { due_at: "Apr 15, 2024", due_for: "2 Students", unlock_at: "Apr 10, 2024 at 12am", lock_at: "Apr 20, 2024 at 11:59pm" },
                               { due_at: "Apr 16, 2024", due_for: "2 Sections", unlock_at: "Apr 10, 2024 at 12am", lock_at: "Apr 20, 2024 at 11:59pm" },
                               { due_at: "Apr 17, 2024", due_for: "2 Groups", unlock_at: "Apr 10, 2024 at 12am", lock_at: "Apr 20, 2024 at 11:59pm" }
                             ])
    end

    it "shows dates for Everyone when there is course override" do
      @assignment.assignment_overrides.create!(set_type: "Course", set_id: @course.id, due_at:, unlock_at:, lock_at:)

      get "/courses/#{@course.id}/assignments/#{@assignment.id}"

      expect(@assignment.visible_to_everyone).to be_truthy
      validate_all_overrides([
                               { due_at: "Apr 15, 2024", due_for: "Everyone", unlock_at: "Apr 10, 2024 at 12am", lock_at: "Apr 20, 2024 at 11:59pm" }
                             ])
    end

    it "shows dates for default section" do
      @assignment.update!(
        due_at:,
        unlock_at:,
        lock_at:,
        only_visible_to_overrides: true
      )

      @assignment.assignment_overrides.create!(
        set_type: "CourseSection",
        set_id: @course.default_section.id,
        due_at:,
        due_at_overridden: true,
        unlock_at:,
        unlock_at_overridden: true,
        lock_at:,
        lock_at_overridden: true
      )

      get "/courses/#{@course.id}/assignments/#{@assignment.id}"

      expect(@assignment.visible_to_everyone).to be_falsey
      validate_all_overrides([
                               { due_at: "Apr 15, 2024", due_for: "1 Section", unlock_at: "Apr 10, 2024 at 12am", lock_at: "Apr 20, 2024 at 11:59pm" }
                             ])
    end

    it "does not show dates for overrides when unassign_item is true" do
      @assignment.update!(
        group_category: @category,
        due_at:,
        unlock_at:,
        lock_at:,
        only_visible_to_overrides: false
      )

      create_test_overrides(@assignment, params: {
                              due_at:,
                              due_at_overridden: true,
                              unlock_at:,
                              unlock_at_overridden: true,
                              lock_at:,
                              lock_at_overridden: true,
                              unassign_item: true
                            })

      get "/courses/#{@course.id}/assignments/#{@assignment.id}"

      expect(@assignment.visible_to_everyone).to be_truthy
      validate_all_overrides([
                               { due_at: "Apr 15, 2024 at 12am", due_for: "Everyone", unlock_at: "Apr 10, 2024 at 12am", lock_at: "Apr 20, 2024 at 12am" }
                             ])
    end

    it "does not show dates for overrides when workflow_state is deleted" do
      @assignment.update!(
        group_category: @category,
        due_at:,
        unlock_at:,
        lock_at:,
        only_visible_to_overrides: false
      )

      create_test_overrides(@assignment, params: {
                              due_at:,
                              due_at_overridden: true,
                              unlock_at:,
                              unlock_at_overridden: true,
                              lock_at:,
                              lock_at_overridden: true,
                              workflow_state: "deleted"
                            })

      get "/courses/#{@course.id}/assignments/#{@assignment.id}"

      expect(@assignment.visible_to_everyone).to be_truthy
      validate_all_overrides([
                               { due_at: "Apr 15, 2024 at 12am", due_for: "Everyone", unlock_at: "Apr 10, 2024 at 12am", lock_at: "Apr 20, 2024 at 12am" }
                             ])
    end

    context "with module overrides" do
      before do
        @module = @course.context_modules.create!(name: "Module 1")
        @module.add_item(type: "assignment", id: @assignment.id)
      end

      it "shows only dates for inherited overrides" do
        @assignment.update!(
          group_category: @category,
          due_at:,
          unlock_at:,
          lock_at:,
          only_visible_to_overrides: true
        )

        create_test_overrides(@module)

        get "/courses/#{@course.id}/assignments/#{@assignment.id}"

        validate_all_overrides([
                                 { due_at: "-", due_for: "2 Sections, 2 Groups, 2 Students", unlock_at: "-", lock_at: "-" }
                               ])
      end

      it "shows only dates for assignment overrides due precedence" do
        @assignment.update!(
          group_category: @category,
          due_at:,
          unlock_at:,
          lock_at:,
          only_visible_to_overrides: false
        )

        create_test_overrides(@module)
        create_test_overrides(@assignment, params: {
                                due_at:,
                                due_at_overridden: true,
                                unlock_at:,
                                unlock_at_overridden: true,
                                lock_at:,
                                lock_at_overridden: true
                              })

        get "/courses/#{@course.id}/assignments/#{@assignment.id}"

        # Doesn't show 'Everyone' when there are module overrides even if only_visible_to_overrides is false
        validate_all_overrides([
                                 { due_at: "Apr 15, 2024", due_for: "2 Sections, 2 Groups, 2 Students", unlock_at: "Apr 10, 2024 at 12am", lock_at: "Apr 20, 2024 at 11:59pm" }
                               ])
      end

      it "shows dates for inherited overrides and assignment overrides" do
        @assignment.update!(
          group_category: @category,
          due_at:,
          unlock_at:,
          lock_at:,
          only_visible_to_overrides: false
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
        student_overrides = @assignment.assignment_overrides.create!(
          set_type: "ADHOC",
          title: "2 students",
          **override_params
        )
        student_overrides.assignment_override_students.create!(user: @student1)
        student_overrides.assignment_override_students.create!(user: @student2)
        @assignment.assignment_overrides.create!(set_type: "Group", set_id: @group1.id, **override_params)
        @assignment.assignment_overrides.create!(set_type: "Group", set_id: @group2.id, **override_params)

        get "/courses/#{@course.id}/assignments/#{@assignment.id}"

        # Doesn't show 'Everyone' when there are module overrides even if only_visible_to_overrides is false
        validate_all_overrides([
                                 { due_at: "Apr 15, 2024", due_for: "2 Groups, 2 Students", unlock_at: "Apr 10, 2024 at 12am", lock_at: "Apr 20, 2024 at 11:59pm" },
                                 { due_at: "-", due_for: "2 Sections", unlock_at: "-", lock_at: "-" }
                               ])
      end
    end
  end

  context "teacher/observer permissions" do
    before :once do
      @teacher = teacher_in_course(active_all: true).user
      @course.enroll_user(@teacher, "ObserverEnrollment", { allow_multiple_enrollments: true, associated_user_id: @student1 })
      @course.enroll_user(@teacher, "ObserverEnrollment", { allow_multiple_enrollments: true, associated_user_id: @student2 })
    end

    before do
      @assignment1.due_at = 1.week.from_now
      @assignment1.save!
      @assignment1.assignment_overrides.create!(set_type: "ADHOC")
      @assignment1.assignment_overrides.first.assignment_override_students.create!(user: @student)
      user_session(@teacher)
    end

    it "shows assignment page for teachers when they are also observers in the course" do
      get "/courses/#{@course.id}/assignments/#{@assignment1.id}"
      expect(element_exists?(AssignmentPage.assign_to_button_selector)).to be_truthy
    end

    it "shows all overrides for teachers when they are also observers in the course" do
      @assignment1.update!(only_visible_to_overrides: true)
      @student3 = student_in_course(course: @course, active_all: true, name: "Student 3").user
      @assignment1.assignment_overrides.create!(set_type: "ADHOC", due_at: Time.zone.parse("2024-04-12"))
      @assignment1.assignment_overrides.last.assignment_override_students.create!(user: @student3)

      get "/courses/#{@course.id}/assignments/#{@assignment1.id}"

      expect(AssignmentPage.retrieve_overrides_count).to eq(2)
      overrides = AssignmentPage.retrieve_all_overrides_formatted
      expect(overrides[0][:due_at]).to eq("Apr 12, 2024")
      expect(overrides[0][:due_for]).to eq("1 Student")
      expect(overrides[1][:due_at]).to eq("-")
      expect(overrides[1][:due_for]).to eq("1 Student")
    end
  end

  context "with course paces and mastery paths on" do
    before(:once) do
      @course.root_account.enable_feature!(:course_pace_pacing_with_mastery_paths)
      @course.update(
        enable_course_paces: true,
        conditional_release: true
      )
    end

    it "sets an assignment override for mastery paths when mastery path toggle is turned on" do
      get "/courses/#{@course.id}/assignments/#{@assignment1.id}"

      AssignmentPage.click_assign_to_button

      wait_for_assign_to_tray_spinner
      keep_trying_until { expect(item_tray_exists?).to be_truthy }

      AssignmentPage.mastery_path_toggle.click
      click_save_button
      keep_trying_until { expect(element_exists?(module_item_edit_tray_selector)).to be_falsey }

      expect(@assignment1.assignment_overrides.active.find_by(set_id: AssignmentOverride::NOOP_MASTERY_PATHS, set_type: AssignmentOverride::SET_TYPE_NOOP)).to be_present
    end

    it "removes assignment override for mastery paths when mastery path toggle is turned off" do
      @assignment1.assignment_overrides.create(set_id: AssignmentOverride::NOOP_MASTERY_PATHS, set_type: AssignmentOverride::SET_TYPE_NOOP)

      get "/courses/#{@course.id}/assignments/#{@assignment1.id}"

      AssignmentPage.click_assign_to_button

      wait_for_assign_to_tray_spinner
      keep_trying_until { expect(item_tray_exists?).to be_truthy }

      AssignmentPage.mastery_path_toggle.click
      click_save_button
      keep_trying_until { expect(element_exists?(module_item_edit_tray_selector)).to be_falsey }

      expect(@assignment1.assignment_overrides.active.find_by(set_id: AssignmentOverride::NOOP_MASTERY_PATHS, set_type: AssignmentOverride::SET_TYPE_NOOP)).not_to be_present
    end
  end
end
