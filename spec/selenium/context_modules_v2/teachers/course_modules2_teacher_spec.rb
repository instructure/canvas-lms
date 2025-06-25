# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

require_relative "../../helpers/context_modules_common"
require_relative "../page_objects/modules2_index_page"
require_relative "../../helpers/items_assign_to_tray"

describe "context modules", :ignore_js_errors do
  include_context "in-process server selenium tests"
  include ContextModulesCommon
  include Modules2IndexPage
  include ItemsAssignToTray

  before :once do
    modules2_teacher_setup
  end

  before do
    user_session(@teacher)
  end

  it "shows the modules index page" do
    go_to_modules
    expect(teacher_modules_container).to be_displayed
  end

  context "modules action menu" do
    before do
      @item = @module1.content_tags[0]
    end

    context "edit assignment kebab form" do
      it "edit item form is shown" do
        go_to_modules
        manage_module_item_button(@item.id).click
        module_item_action_menu_link("Edit").click

        expect(edit_item_modal).to be_displayed
      end

      it "title field has the right value" do
        go_to_modules
        manage_module_item_button(@item.id).click
        module_item_action_menu_link("Edit").click

        item_title = @module1.content_tags[0].title
        title = edit_item_modal.find_element(:css, "input[type=text]")

        expect(title.attribute("value")).to eq(item_title)
      end

      it "item is updated" do
        go_to_modules
        manage_module_item_button(@item.id).click
        module_item_action_menu_link("Edit").click

        title = edit_item_modal.find_element(:css, "input[type=text]")
        replace_content(title, "New Title")

        edit_item_modal.find_element(:css, "button[type='submit']").click
        assignment_title = manage_module_item_container(@item.id).find_element(:css, "[data-testid='module-item-title-link']")
        wait_for_animations

        expect(assignment_title.text).to eq("New Title")
      end

      context "send to kebab form" do
        before do
          student_in_course
          @first_user = @course.students.first
        end

        it "shows the send to kebab form" do
          go_to_modules
          module_action_menu(@module1.id).click
          module_item_action_menu_link("Send To...").click

          expect(send_to_modal).to be_displayed
        end

        it "module is correctly sent" do
          go_to_modules
          module_action_menu(@module1.id).click
          module_item_action_menu_link("Send To...").click

          set_value(send_to_modal_input, "User")
          option_list_id = send_to_modal_input.attribute("aria-controls")

          expect(ff("##{option_list_id} [role='option']").count).to eq 1

          fj("##{option_list_id} [role='option']:contains(#{@first_user.first_name})").click
          selected_element = send_to_form_selected_elements.first

          expect(selected_element.text).to eq("User")

          fj("button:contains('Send')").click

          wait_for_ajaximations
          expect(f("body")).not_to contain_css(send_to_modal_modal_selector)
        end
      end
    end

    context "send to kebab form" do
      before do
        student_in_course
        @first_user = @course.students.first
      end

      it "edit item form is shown" do
        go_to_modules
        manage_module_item_button(@item.id).click
        module_item_action_menu_link("Send To...").click

        expect(send_to_modal).to be_displayed
      end

      it "module item is correctly sent" do
        go_to_modules
        manage_module_item_button(@item.id).click
        module_item_action_menu_link("Send To...").click

        set_value(send_to_modal_input, "User")
        option_list_id = send_to_modal_input.attribute("aria-controls")

        expect(ff("##{option_list_id} [role='option']").count).to eq 1

        fj("##{option_list_id} [role='option']:contains(#{@first_user.first_name})").click
        selected_element = send_to_form_selected_elements.first

        expect(selected_element.text).to eq("User")

        fj("button:contains('Send')").click

        wait_for_ajaximations
        expect(f("body")).not_to contain_css(send_to_modal_modal_selector)
      end
    end

    context "copy to kebab form" do
      before do
        course = @course
        @other_course = course_factory(course_name: "Other Course Eh")
        course_with_teacher(course: @other_course, user: @teacher, name: "Sharee", active_all: true)
        @course = course
      end

      it "module item is correctly copied" do
        go_to_modules
        manage_module_item_button(@item.id).click
        module_item_action_menu_link("Copy To...").click

        set_value(copy_to_tray_course_select, "course")
        option_list_id = copy_to_tray_course_select.attribute("aria-controls")

        expect(option_list(option_list_id).count).to eq 1

        option_list_course_option(option_list_id, @other_course.name).click
        copy_button.click

        wait_for_ajaximations
        expect(@other_course.content_migrations.last.migration_settings["copy_options"].keys).to eq(["assignments"])
      end
    end
  end

  context "course home page" do
    before do
      @course.default_view = "modules"
      @course.save

      @course.root_account.enable_feature!(:modules_page_rewrite)
    end

    it "shows the new modules" do
      visit_course(@course)
      wait_for_ajaximations

      expect(f('[data-testid="modules-rewrite-container"]')).to be_displayed
    end
  end

  context "module select dropdown for teacher and student views" do
    before do
      user_session(@teacher)
      @course.root_account.enable_feature!(:modules_teacher_module_selection)
      @course.root_account.enable_feature!(:modules_student_module_selection)
    end

    it "shows teacher and student dropdown with All Modules default" do
      go_to_modules
      student_dropdown_input = f("input[role='combobox'][title='All Modules']")
      expect(student_dropdown_input[:value]).to eq("All Modules")

      teacher_select = ff("label")[0]
      expect(teacher_select.text).to include("Teachers View")

      student_select = ff("label")[1]
      expect(student_select.text).to include("Students View")
    end

    it "updates visible modules when selecting a specific module for teachers" do
      go_to_modules

      teacher_dropdown_input = ff("input[role='combobox'][title='All Modules']")[0]
      teacher_dropdown_input.click

      wait_for_ajaximations

      first_module = ff("[role='option']")[1]
      expect(first_module.text).to eq("module1")

      first_module.click
      wait_for_ajaximations

      visible_modules = ff("div[class*='context_module'] h2")
      expect(visible_modules.length).to eq(1)
      expect(visible_modules.first.text).to include("module1")
    end

    it "does not update visible module when selecting a specific module for students" do
      go_to_modules

      student_dropdown_input = ff("input[role='combobox'][title='All Modules']")[1]
      student_dropdown_input.click

      wait_for_ajaximations

      second_module = ff("[role='option']")[2]
      expect(second_module.text).to eq("module2")

      second_module.click
      wait_for_ajaximations

      visible_modules = ff("div[class*='context_module'] h2")
      expect(visible_modules.length).to eq(2)
      expect(visible_modules.first.text).to include("module1")
    end

    it "displays selected module in students view when acting as student" do
      go_to_modules
      student_dropdown_input = ff("input[role='combobox'][title='All Modules']")[1]
      student_dropdown_input.click

      wait_for_ajaximations

      second_module = ff("[role='option']")[2]
      expect(second_module.text).to eq("module2")

      second_module.click
      wait_for_ajaximations

      student_view_toggle = f("a#easy_student_view")
      student_view_toggle.click

      visible_modules = f("span[class*='ig-header-title'] span")
      expect(visible_modules.text).to include("module2")
    end

    it "persists selected module filter after reload" do
      go_to_modules

      teacher_dropdown_input = f("input[role='combobox'][title='All Modules']")
      teacher_dropdown_input.click

      wait_for_ajaximations

      first_module = ff("[role='option']")[1]
      first_module.click
      wait_for_ajaximations

      refresh_page
      wait_for_ajaximations

      # Ensure the same module is still selected and shown
      visible_modules = ff("div[class*='context_module'] h2")
      expect(visible_modules.length).to eq(1)
      expect(visible_modules.first.text).to include("module1")
    end
  end
end
