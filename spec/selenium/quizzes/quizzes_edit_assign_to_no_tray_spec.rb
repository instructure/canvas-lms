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
require_relative "page_objects/quizzes_edit_page"
require_relative "page_objects/quizzes_landing_page"
require_relative "../helpers/items_assign_to_tray"
require_relative "../helpers/context_modules_common"
require_relative "../helpers/admin_settings_common"

describe "quiz edit page assign to" do
  include_context "in-process server selenium tests"
  include QuizzesEditPage
  include QuizzesLandingPage
  include ItemsAssignToTray
  include ContextModulesCommon
  include QuizzesCommon

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

  it "shows the assign to card on the edit page" do
    get "/courses/#{@course.id}/quizzes/#{@classic_quiz.id}/edit"

    expect(manage_assign_to_container).to be_displayed
  end

  it "assigns student and saves assignment" do
    get "/courses/#{@course.id}/quizzes/#{@classic_quiz.id}/edit"

    click_add_assign_to_card
    select_module_item_assignee(1, @student1.name)
    update_due_date(1, "12/31/2022")
    update_due_time(1, "5:00 PM")
    update_available_date(1, "12/27/2022")
    update_available_time(1, "8:00 AM")
    update_until_date(1, "1/7/2023")
    update_until_time(1, "9:00 PM")

    submit_page

    expect(@classic_quiz.assignment_overrides.last.assignment_override_students.count).to eq(1)

    due_at_row = retrieve_quiz_due_date_table_row("1 Student")
    expect(due_at_row).not_to be_nil
    expect(due_at_row.text.split("\n").first).to include("Dec 31, 2022")
    expect(due_at_row.text.split("\n").third).to include("Dec 27, 2022")
    expect(due_at_row.text.split("\n").last).to include("Jan 7, 2023")

    due_at_row = retrieve_quiz_due_date_table_row("Everyone else")
    expect(due_at_row).not_to be_nil
    expect(due_at_row.text.count("-")).to eq(3)
  end

  it "saves and shows override updates when page re-edited" do
    get "/courses/#{@course.id}/quizzes/#{@classic_quiz.id}/edit"

    update_due_date(0, "12/31/2022")
    update_due_time(0, "5:00 PM")
    update_available_date(0, "12/27/2022")
    update_available_time(0, "8:00 AM")
    update_until_date(0, "1/7/2023")
    update_until_time(0, "9:00 PM")

    submit_page

    get "/courses/#{@course.id}/quizzes/#{@classic_quiz.id}/edit"

    expect(assign_to_due_date(0).attribute("value")).to eq("Dec 31, 2022")
    expect(assign_to_due_time(0).attribute("value")).to eq("5:00 PM")
    expect(assign_to_available_from_date(0).attribute("value")).to eq("Dec 27, 2022")
    expect(assign_to_available_from_time(0).attribute("value")).to eq("8:00 AM")
    expect(assign_to_until_date(0).attribute("value")).to eq("Jan 7, 2023")
    expect(assign_to_until_time(0).attribute("value")).to eq("9:00 PM")
  end

  it "does not recover a deleted card when adding an assignee" do
    # Bug fix of LX-1619
    get "/courses/#{@course.id}/quizzes/#{@classic_quiz.id}/edit"

    click_add_assign_to_card
    click_delete_assign_to_card(0)
    select_module_item_assignee(0, @student2.name)

    expect(selected_assignee_options.count).to be(1)
  end

  context "assign to differentiaiton tags" do
    before :once do
      @course.account.enable_feature! :assign_to_differentiation_tags
      @course.account.tap do |a|
        a.settings[:allow_assign_to_differentiation_tags] = { value: true }
        a.save!
      end

      @differentiation_tag_category = @course.group_categories.create!(name: "Differentiation Tag Category", non_collaborative: true)
      @diff_tag1 = @course.groups.create!(name: "Differentiation Tag 1", group_category: @differentiation_tag_category, non_collaborative: true)
      @diff_tag2 = @course.groups.create!(name: "Differentiation Tag 2", group_category: @differentiation_tag_category, non_collaborative: true)
      @student1 = student_in_course(course: @course, active_all: true, name: "Student 1").user
      @diff_tag1.add_user(@student1)
    end

    it "assigns a differentiation tag and saves quiz" do
      get "/courses/#{@course.id}/quizzes/#{@classic_quiz.id}/edit"

      click_add_assign_to_card
      select_module_item_assignee(1, @diff_tag1.name)
      update_due_date(1, "12/31/2022")
      update_due_time(1, "5:00 PM")
      update_available_date(1, "12/27/2022")
      update_available_time(1, "8:00 AM")
      update_until_date(1, "1/7/2023")
      update_until_time(1, "9:00 PM")

      submit_page

      override = @classic_quiz.assignment_overrides.last
      expect(override.set_type).to eq("Group")
      expect(override.title).to eq(@diff_tag1.name)

      due_at_row = retrieve_quiz_due_date_table_row("1 Group")
      expect(due_at_row).not_to be_nil
      expect(due_at_row.text.split("\n").first).to include("Dec 31, 2022")
      expect(due_at_row.text.split("\n").third).to include("Dec 27, 2022")
      expect(due_at_row.text.split("\n").last).to include("Jan 7, 2023")

      due_at_row = retrieve_quiz_due_date_table_row("Everyone else")
      expect(due_at_row).not_to be_nil
      expect(due_at_row.text.count("-")).to eq(3)
    end

    context "existing differentiation tag overrides" do
      before do
        @classic_quiz.assignment_overrides.create!(set_type: "Group", set_id: @diff_tag1.id, title: @diff_tag1.name)
        @classic_quiz.assignment_overrides.create!(set_type: "Group", set_id: @diff_tag2.id, title: @diff_tag2.name)
      end

      it "renders all the override assignees" do
        get "/courses/#{@course.id}/quizzes/#{@classic_quiz.id}/edit"

        # 3 differentiation tags
        # Since the quiz is not only visible to overrides the "Everyone else" row is shown
        expect(selected_assignee_options.count).to eq 3
      end

      it "shows the convert override message when diff tags setting disabled" do
        @course.account.tap do |a|
          a.settings[:allow_assign_to_differentiation_tags] = { value: false }
          a.save!
        end
        get "/courses/#{@course.id}/quizzes/#{@classic_quiz.id}/edit"
        wait_for_ajaximations
        expect(element_exists?(convert_override_alert_selector)).to be_truthy
      end

      it "clicking convert overrides button converts the override and refreshes the cards" do
        @classic_quiz.update!(only_visible_to_overrides: true)
        @course.account.tap do |a|
          a.settings[:allow_assign_to_differentiation_tags] = { value: false }
          a.save!
        end
        get "/courses/#{@course.id}/quizzes/#{@classic_quiz.id}/edit"
        wait_for_ajaximations
        expect(f(assignee_selected_option_selector).text).to include(@diff_tag1.name)
        f(convert_override_button_selector).click
        wait_for_ajaximations
        expect(f(assignee_selected_option_selector).text).to include(@student1.name)
      end

      it "clicking convert overrides button converts overrides and refreshes the cards" do
        student2 = student_in_course(course: @course, active_all: true, name: "Student 2").user
        @diff_tag2.add_user(student2)
        @classic_quiz.update!(only_visible_to_overrides: true)
        @course.account.tap do |a|
          a.settings[:allow_assign_to_differentiation_tags] = { value: false }
          a.save!
        end
        get "/courses/#{@course.id}/quizzes/#{@classic_quiz.id}/edit"
        wait_for_ajaximations
        overrides = ff(assignee_selected_option_selector)
        expect(overrides[0].text).to include(@diff_tag1.name)
        expect(overrides[1].text).to include(@diff_tag2.name)
        f(convert_override_button_selector).click
        wait_for_ajaximations
        converted_overrides = ff(assignee_selected_option_selector)
        expect(converted_overrides[0].text).to include(student2.name)
        expect(converted_overrides[1].text).to include(@student1.name)
      end
    end
  end

  context "sync to sis" do
    include AdminSettingsCommon
    include ItemsAssignToTray

    let(:due_date) { 3.years.from_now }

    before do
      account_model
      @account.set_feature_flag! "post_grades", "on"
      course_with_teacher_logged_in(active_all: true, account: @account)
      turn_on_sis_settings(@account)
      @account.settings[:sis_require_assignment_due_date] = { value: true }
      @account.save!
      @quiz = course_quiz
      @quiz.post_to_sis = "1"
    end

    it "blocks saving empty due dates when enabled", :ignore_js_errors do
      get "/courses/#{@course.id}/quizzes/#{@quiz.id}/edit"

      click_post_to_sis_checkbox

      click_quiz_save_button

      expect_instui_flash_message("Please set a due date or change your selection for the “Sync to SIS” option.")

      expect(assign_to_date_and_time[0].text).to include("Please add a due date")
      update_due_date(0, "12/31/2022")
      update_due_time(0, "5:00 PM")

      expect(assign_to_date_and_time[0].text).not_to include("Please add a due date")
      expect(is_checked(post_to_sis_checkbox_selector)).to be_truthy

      submit_page

      due_at_row = retrieve_quiz_due_date_table_row("Everyone")
      expect(due_at_row.text.split("\n").first).to include("Dec 31, 2022")
    end

    it "does not block empty due dates when disabled" do
      get "/courses/#{@course.id}/quizzes/#{@quiz.id}/edit"

      expect(is_checked(post_to_sis_checkbox_selector)).to be_falsey
      click_quiz_save_button
      expect(driver.current_url).not_to include("edit")

      get "/courses/#{@course.id}/quizzes/#{@quiz.id}/edit"
      expect(is_checked(post_to_sis_checkbox_selector)).to be_falsey
    end

    it "validates due date only after user tries to save" do
      get "/courses/#{@course.id}/quizzes/#{@quiz.id}/edit"

      expect(assign_to_date_and_time[0].text).not_to include("Please add a due date")

      click_post_to_sis_checkbox

      # No Sync to SIS validations ran, message didn't change
      expect(assign_to_date_and_time[0].text).not_to include("Please add a due date")

      expect(is_checked(post_to_sis_checkbox_selector)).to be_truthy
      # Perform Sync to SIS validations
      click_quiz_save_button

      # Show validation messages
      expect(assign_to_date_and_time[0].text).to include("Please add a due date")

      click_post_to_sis_checkbox

      # No Sync to SIS validations ran, message didn't change
      expect(assign_to_date_and_time[0].text).to include("Please add a due date")

      expect(is_checked(post_to_sis_checkbox_selector)).to be_falsey
      # Perform Sync to SIS validations
      click_quiz_save_button
      expect(driver.current_url).not_to include("edit")
    end
  end
end
