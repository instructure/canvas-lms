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
end
