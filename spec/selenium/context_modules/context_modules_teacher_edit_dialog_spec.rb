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

require_relative "../helpers/context_modules_common"
require_relative "../helpers/public_courses_context"

describe "context modules" do
  include_context "in-process server selenium tests"
  include ContextModulesCommon

  context "as a teacher", priority: "1" do
    before(:once) do
      course_with_teacher(active_all: true)
      # have to add quiz and assignment to be able to add them to a new module
      @quiz = @course.assignments.create!(title: "quiz assignment", submission_types: "online_quiz")
      @assignment = @course.assignments.create!(title: "assignment 1", submission_types: "online_text_entry")
      @assignment2 = @course.assignments.create!(title: "assignment 2",
                                                 submission_types: "online_text_entry",
                                                 due_at: 2.days.from_now,
                                                 points_possible: 10)
      @assignment3 = @course.assignments.create!(title: "assignment 3", submission_types: "online_text_entry")

      @ag1 = @course.assignment_groups.create!(name: "Assignment Group 1")
      @ag2 = @course.assignment_groups.create!(name: "Assignment Group 2")
      @course.reload
    end

    before do
      user_session(@teacher)
    end

    it "shows the added prerequisites when editing a module" do
      add_modules_and_set_prerequisites
      get "/courses/#{@course.id}/modules"
      move_to_click("#context_module_#{@module3.id}")
      f("#context_module_#{@module3.id} .ig-header-admin .al-trigger").click
      f("#context_module_#{@module3.id} .edit_module_link").click
      add_form = f("#add_context_module_form")
      expect(add_form).to be_displayed
      prereq_select = f(".criterion select")
      option = first_selected_option(prereq_select)
      expect(option.text).to eq @module1.name.to_s
      expect(ff(".prerequisites_list .criteria_list .delete_criterion_link").map { |link| link.attribute("aria-label") })
        .to eq(["Delete prerequisite First module", "Delete prerequisite Second module"])
    end

    it "updates the name of edited prerequisite modules" do
      add_modules_and_set_prerequisites
      get "/courses/#{@course.id}/modules"
      get "/courses/#{@course.id}/modules"
      move_to_click("#context_module_#{@module1.id}")
      f("#context_module_#{@module1.id} .ig-header-admin .al-trigger").click
      f("#context_module_#{@module1.id} .edit_module_link").click
      add_form = f("#add_context_module_form")
      expect(add_form).to be_displayed
      replace_content(f("#context_module_name"), "FRIST!!")
      f("#add_context_module_form .submit_button").click
      wait_for_ajaximations
      expect(f("#context_module_#{@module3.id} .prerequisites_message").text).to include "FRIST!!, Second module"
    end

    it "does not have a prerequisites section when editing the first module" do
      modules = create_modules(2)
      get "/courses/#{@course.id}/modules"

      mod0 = f("#context_module_#{modules[0].id}")
      f(".ig-header-admin .al-trigger", mod0).click
      f(".edit_module_link", mod0).click
      edit_form = f("#add_context_module_form")
      expect(f(".prerequisites_entry", edit_form)).not_to be_displayed
      submit_form(edit_form)
      mod1 = f("#context_module_#{modules[1].id}")
      f(".ig-header-admin .al-trigger", mod1).click
      f(".edit_module_link", mod1).click
      edit_form = f("#add_context_module_form")
      expect(f(".prerequisites_entry", edit_form)).to be_displayed
    end

    it "saves the requirement count chosen in the Edit Module form" do
      add_existing_module_item("AssignmentModule", @assignment)

      get "/courses/#{@course.id}/modules"

      @course.reload

      expect(fj(".requirements_message").text).to be_blank

      # add completion criterion
      f(".ig-header-admin .al-trigger").click
      wait_for_ajaximations
      f(".edit_module_link").click
      wait_for_ajaximations
      edit_form = f("#add_context_module_form")
      expect(edit_form).to be_displayed
      f(".add_completion_criterion_link", edit_form).click

      # Select other radio button
      move_to_click("label[for=context_module_requirement_count_1]")

      submit_form(edit_form)

      # Test that pill now says Complete One Item right after change and one reload
      expect(f(".pill li").text).to eq "Complete One Item"
      get "/courses/#{@course.id}/modules"
      expect(f(".pill li").text).to eq "Complete One Item"
    end

    it "prompts relock when adding an unlock_at date" do
      lock_until = format_date_for_view(Time.zone.today + 2.days)
      @course.context_modules.create!(name: "name")
      get "/courses/#{@course.id}/modules"
      f(".ig-header-admin .al-trigger").click
      f(".edit_module_link").click
      expect(f("#add_context_module_form")).to be_displayed
      edit_form = f("#add_context_module_form")
      lock_check_click
      wait_for_ajaximations
      unlock_date = edit_form.find_element(:id, "context_module_unlock_at")
      unlock_date.send_keys(lock_until)
      submit_form(edit_form)
      expect(edit_form).not_to be_displayed
      test_relock
    end

    it "validates module lock date picker format", priority: "2" do
      unlock_date = format_time_for_view(Time.zone.today + 2.days)
      @course.context_modules.create!(name: "name", unlock_at: unlock_date)
      get "/courses/#{@course.id}/modules"
      f(".ig-header-admin .al-trigger").click
      f(".edit_module_link").click
      edit_form = f("#add_context_module_form")
      unlock_date_in_dialog = edit_form.find_element(:id, "context_module_unlock_at")
      expect(format_time_for_view(unlock_date_in_dialog.attribute("value"))).to eq unlock_date
    end

    it "only displays out-of on an assignment min score restriction when the assignment has a total" do
      ag = @course.assignment_groups.create!
      a1 = ag.assignments.create!(context: @course)
      a1.points_possible = 10
      a1.save
      a2 = ag.assignments.create!(context: @course)
      m = @course.context_modules.create!

      make_content_tag = lambda do |assignment|
        ct = ContentTag.new
        ct.content_id = assignment.id
        ct.content_type = "Assignment"
        ct.context_id = @course.id
        ct.context_type = "Course"
        ct.title = "Assignment #{assignment.id}"
        ct.tag_type = "context_module"
        ct.context_module_id = m.id
        ct.context_code = "course_#{@course.id}"
        ct.save!
        ct
      end
      content_tag_1 = make_content_tag.call a1
      content_tag_2 = make_content_tag.call a2

      get "/courses/#{@course.id}/modules"

      f(".ig-header-admin  .al-trigger").click
      hover_and_click("#context_modules .edit_module_link")
      wait_for_animations
      expect(f("#add_context_module_form")).to be_displayed
      f(".add_completion_criterion_link").click
      wait_for_animations
      fj(".assignment_picker:visible option[value='#{content_tag_1.id}']").click
      fj('.assignment_requirement_picker:visible option[value="min_score"]').click
      expect(f("body")).to contain_jqcss(".points_possible_parent:visible")

      fj(".assignment_picker:visible option[value='#{content_tag_2.id}']").click
      fj('.assignment_requirement_picker:visible option[value="min_score"]').click
      expect(f("body")).not_to contain_jqcss(".points_possible_parent:visible")
    end

    it "adds and remove completion criteria" do
      add_existing_module_item("AssignmentModule", @assignment)
      get "/courses/#{@course.id}/modules"

      @course.reload
      smodule = @course.context_modules.first
      # add completion criterion
      f(".ig-header-admin .al-trigger").click
      f(".edit_module_link").click
      wait_for_ajaximations
      edit_form = f("#add_context_module_form")
      expect(edit_form).to be_displayed
      f(".add_completion_criterion_link", edit_form).click
      wait_for_ajaximations
      check_element_has_focus f("#add_context_module_form .assignment_picker")
      # be_disabled
      expect(f("#add_context_module_form .assignment_requirement_picker option[value=must_contribute]")).to be_disabled
      click_option("#add_context_module_form .assignment_picker", @assignment.title, :text)
      click_option("#add_context_module_form .assignment_requirement_picker", "must_submit", :value)
      expect(f(".criteria_list .delete_criterion_link").attribute("aria-label")).to eq "Delete requirement assignment 1 (submit the assignment)"
      submit_form(edit_form)
      expect(edit_form).not_to be_displayed
      # should show relock warning since we're adding a completion requirement to an active module
      test_relock

      # verify it was added
      smodule.reload
      expect(smodule).not_to be_nil
      expect(smodule.completion_requirements).not_to be_empty
      expect(smodule.completion_requirements[0][:type]).to eq "must_submit"

      # delete the criterion, then cancel the form
      f(".ig-header-admin .al-trigger").click
      wait_for_ajaximations
      f(".edit_module_link").click
      wait_for_ajaximations
      edit_form = f("#add_context_module_form")
      expect(edit_form).to be_displayed
      f(".completion_entry .delete_criterion_link", edit_form).click
      ff(".cancel_button", dialog_for(edit_form)).last.click

      # now delete the criterion frd
      # (if the previous step did even though it shouldn't have, this will error)
      f(".ig-header-admin .al-trigger").click
      f(".edit_module_link").click
      edit_form = f("#add_context_module_form")
      expect(edit_form).to be_displayed
      f(".completion_entry .delete_criterion_link", edit_form).click
      wait_for_ajaximations
      submit_form(edit_form)
      wait_for_ajax_requests

      # verify it's gone
      @course.reload
      expect(@course.context_modules.first.completion_requirements).to eq []

      # and also make sure the form remembers that it's gone (#8329)
      f(".ig-header-admin .al-trigger").click
      f(".edit_module_link").click
      edit_form = f("#add_context_module_form")
      expect(edit_form).to be_displayed
      expect(f(".completion_entry")).not_to contain_jqcss(".delete_criterion_link:visible")
    end

    context "edit dialog" do
      before :once do
        @mod = create_modules(2, true)
        @mod[0].add_item({ id: @assignment.id, type: "assignment" })
        @mod[0].add_item({ id: @assignment2.id, type: "assignment" })
      end

      before do
        get "/courses/#{@course.id}/modules"
      end

      it "shows all items are completed radio button", priority: "1" do
        f("#context_module_#{@mod[0].id} .ig-header-admin .al-trigger").click
        hover_and_click("#context_module_#{@mod[0].id} .edit_module_link")
        f(".add-item .add_completion_criterion_link").click
        expect(f(".ic-Radio")).to contain_css("input[type=radio][id = context_module_requirement_count_]")
        expect(f(".ic-Radio .ic-Label").text).to eq("Students must complete all of these requirements")
      end

      it "shows complete one of these items radio button", priority: "1" do
        f("#context_module_#{@mod[0].id} .ig-header-admin .al-trigger").click
        hover_and_click("#context_module_#{@mod[0].id} .edit_module_link")
        f(".add-item .add_completion_criterion_link").click
        expect(ff(".ic-Radio")[1]).to contain_css("input[type=radio][id = context_module_requirement_count_1]")
        expect(ff(".ic-Radio .ic-Label")[1].text).to eq("Students must complete one of these requirements")
      end

      it "does not show the radio buttons for module with no items", priority: "1" do
        f("#context_module_#{@mod[1].id} .ig-header-admin .al-trigger").click
        hover_and_click("#context_module_#{@mod[1].id} .edit_module_link")
        expect(f(".ic-Radio .ic-Label").text).not_to include("Students must complete all of these requirements")
        expect(f(".ic-Radio .ic-Label").text).not_to include("Students must complete one of these requirements")
        expect(f(".completion_entry .no_items_message").text).to eq("No items in module")
      end
    end

    it "still displays due date and points possible after indent change" do
      add_existing_module_item("AssignmentModule", @assignment2)
      tag = ContentTag.last

      get "/courses/#{@course.id}/modules"

      def due_date_assertion(tag)
        wait_for_dom_ready
        module_item = f("#context_module_item_#{tag.id}")
        expect(module_item.find_element(:css, ".due_date_display").text).not_to be_blank
      end

      def points_possible_assertion(tag)
        wait_for_dom_ready
        module_item = f("#context_module_item_#{tag.id}")
        expect(module_item.find_element(:css, ".points_possible_display")).to include_text "10"
      end

      due_date_assertion(tag)
      points_possible_assertion(tag)

      # change indent with arrows
      f("#context_module_item_#{tag.id} .al-trigger").click
      f(".indent_item_link").click

      due_date_assertion(tag)
      points_possible_assertion(tag)

      # change indent from edit form
      f("#context_module_item_#{tag.id} .al-trigger").click
      f(".edit_item_link").click

      click_option("#content_tag_indent_select", "Don't Indent")
      form = f("#edit_item_form")
      form.submit

      due_date_assertion(tag)
      points_possible_assertion(tag)
    end

    it "groups quizzes and new quizzes together in dropdown" do
      module_setup
      @course.context_external_tools.create!(
        tool_id: ContextExternalTool::QUIZ_LTI,
        name: "New Quizzes",
        consumer_key: "1",
        shared_secret: "1",
        domain: "quizzes.example.com"
      )
      new_quiz_assignment = @course.assignments.create!(title: "new quizzes assignment")
      new_quiz_assignment.quiz_lti!
      new_quiz_assignment.save!
      @module.add_item(type: "assignment", id: new_quiz_assignment.id)

      get "/courses/#{@course.id}/modules"
      f(".ig-header-admin .al-trigger").click
      wait_for_ajaximations
      f(".edit_module_link").click
      wait_for_ajaximations
      f(".add_completion_criterion_link").click
      fj(".assignment_picker:visible").click
      quizzes_group = fj(".assignment_picker:visible optgroup[label='Quizzes']")
      expect(quizzes_group).to include_text("quiz assignment")
      expect(quizzes_group).to include_text("new quizzes assignment")
    end
  end
end
