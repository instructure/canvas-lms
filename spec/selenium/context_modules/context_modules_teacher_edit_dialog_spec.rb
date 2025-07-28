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
require_relative "page_objects/modules_index_page"
require_relative "page_objects/modules_settings_tray"

describe "context modules" do
  include_context "in-process server selenium tests"
  include ContextModulesCommon
  include ModulesIndexPage
  include ModulesSettingsTray

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

    context "with differentiated modules" do
      it "shows the added prerequisites when editing a module with enabled differentiated modules" do
        add_modules_and_set_prerequisites
        go_to_modules
        move_to_click("#context_module_#{@module3.id}")
        manage_module_button(@module3).click
        module_index_menu_tool_link("Edit").click

        expect(prerequisites_dropdown.map { |item| item.attribute("value") })
          .to eq(["First module", "Second module"])
      end

      it "updates the name of edited prerequisite modules with enabled differentiated modules" do
        add_modules_and_set_prerequisites
        go_to_modules
        scroll_to_module(@module1.name)
        manage_module_button(@module1).click
        module_index_menu_tool_link("Edit").click
        update_module_name("FIRST!!")
        click_settings_tray_update_module_button
        expect(f("#context_module_#{@module3.id} .prerequisites_message").text).to include "FIRST!!, Second module"
      end

      it "prompts relock when adding an unlock_at date with differentiated modules" do
        lock_until = format_date_for_view(Time.zone.today + 2.days)
        module1 = @course.context_modules.create!(name: "name")
        go_to_modules
        manage_module_button(module1).click
        module_index_menu_tool_link("Edit").click
        click_lock_until_checkbox
        update_lock_until_date(lock_until)
        click_settings_tray_update_module_button
        expect(element_exists?("#relock_modules_dialog")).to be_truthy
        ignore_relock
      end

      it "only displays out-of on an assignment min score restriction when the assignment has a total with differentiated modules enabled" do
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

        go_to_modules

        manage_module_button(m).click
        module_index_menu_tool_link("Edit").click

        click_add_requirement_button

        select_requirement_item_option(0, content_tag_1.title)
        select_requirement_type_option(0, "Score at least")
        expect(element_exists?(number_input_selector(0))).to be_truthy

        select_requirement_item_option(0, content_tag_2.title)
        select_requirement_type_option(0, "Score at least")
        expect(element_exists?(number_input_selector(0))).to be_falsey
      end

      it "adds and remove completion criteria with differentiated modules" do
        add_existing_module_item("AssignmentModule", @assignment)
        go_to_modules

        @course.reload
        smodule = @course.context_modules.first

        # add completion criterion
        manage_module_button(smodule).click
        module_index_menu_tool_link("Edit").click

        click_add_requirement_button

        select_requirement_item_option(0, @assignment.title)
        select_requirement_type_option(0, "Submit the assignment")
        click_settings_tray_update_module_button
        expect(settings_tray_exists?).to be_falsey

        # there will be a form for relock eventually
        ignore_relock

        # verify it was added
        smodule.reload
        expect(smodule).not_to be_nil
        expect(smodule.completion_requirements).not_to be_empty
        expect(smodule.completion_requirements[0][:type]).to eq "must_submit"

        # delete the criterion, then cancel the form
        manage_module_button(smodule).click
        module_index_menu_tool_link("Edit").click

        click_remove_requirement_button(0)
        click_settings_tray_cancel_button

        # now delete the criterion frd
        # (if the previous step did even though it shouldn't have, this will error)
        manage_module_button(smodule).click
        module_index_menu_tool_link("Edit").click

        click_remove_requirement_button(0)
        click_settings_tray_update_module_button

        # verify it's gone
        smodule.reload
        expect(smodule.reload.completion_requirements).to eq []

        # and also make sure the form remembers that it's gone
        manage_module_button(smodule).click
        module_index_menu_tool_link("Edit").click
        expect(element_exists?(remove_requirement_button_selector, true)).to be_falsey
      end

      context "course_pace_time_selection is enabled" do
        before do
          @course.root_account.enable_feature!(:modules_requirements_allow_percentage)
          @course.root_account.reload
        end

        it "select percentage type and validate number input", :ignore_js_errors do
          add_existing_module_item("AssignmentModule", @assignment)
          go_to_modules

          @course.reload
          smodule = @course.context_modules.first

          manage_module_button(smodule).click
          module_index_menu_tool_link("Edit").click

          click_add_requirement_button

          select_requirement_item_option(0, @assignment.title)
          select_requirement_type_option(0, "Score at least")
          select_score_type_option(0, "Percentage")

          expect(element_exists?(number_input_selector(0))).to be_truthy
        end
      end
    end
  end
end
