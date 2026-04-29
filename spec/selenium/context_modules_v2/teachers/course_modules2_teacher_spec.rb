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
require_relative "../page_objects/modules2_action_tray"
require_relative "../../helpers/items_assign_to_tray"
require_relative "../../helpers/assignments_common"
require_relative "../shared_examples/course_modules2_shared"

describe "context modules", :ignore_js_errors do
  include_context "in-process server selenium tests"
  include ContextModulesCommon
  include Modules2IndexPage
  include ItemsAssignToTray
  include AssignmentsCommon
  include Modules2ActionTray

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

  it "creates a screenreader alert when all module items are loaded" do
    go_to_modules
    expand_all_modules_button.click if element_exists?(expand_all_modules_button_selector)
    wait_for_ajaximations
    expect(screenreader_alert).to include_text("All module items loaded")
  end

  it "validates that item is indented when it has a non-zero indent" do
    indented_module_item = @module1.add_item(
      type: "assignment",
      id: @assignment3.id,
      indent: 2 # Indent level 2 = 40px
    )
    go_to_modules
    wait_for_ajaximations
    module_header_expand_toggles.first.click
    item_indent = module_item_indent(indented_module_item.id)
    expect(item_indent).to match("padding: 0px 0px 0px 40px;")
  end

  context "mastery paths" do
    before do
      @item = @module1.content_tags[0]
    end

    context "when mastery path is not already set" do
      before do
        allow(ConditionalRelease::Service).to receive_messages(enabled_in_context?: true, rules_for: [])
      end

      it "navigates to mastery paths edit page when Add Mastery Paths is clicked" do
        go_to_modules
        module_header_expand_toggles.first.click
        wait_for_ajaximations

        manage_module_item_button(@item.id).click
        wait_for_ajaximations

        module_item_action_menu_link("Add Mastery Paths").click
        wait_for_ajaximations

        expect(driver.current_url).to include("/courses/#{@course.id}/assignments/#{@item.content_id}/edit")
        expect(driver.current_url).to include("#mastery-paths-editor")
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
      expect(module_page_student_dropdown[:value]).to eq("All Modules")

      teacher_select = ff("label")[0]
      expect(teacher_select.text).to include("Teachers View")

      student_select = ff("label")[1]
      expect(student_select.text).to include("Students View")
    end

    it "updates visible modules when selecting a specific module for teachers" do
      go_to_modules
      module_page_teacher_dropdown.click
      wait_for_ajaximations

      first_module = ff("[role='option']")[1]
      expect(first_module.text).to eq("module1")

      first_module.click
      wait_for_ajaximations
      visible_modules = visible_module_headers[0]
      expect(visible_modules.text).to include("module1")
    end

    it "does not update visible module when selecting a specific module for students" do
      go_to_modules
      module_page_student_dropdown.click
      wait_for_ajaximations

      second_module = ff("[role='option']")[2]
      expect(second_module.text).to eq("module2")

      second_module.click
      wait_for_ajaximations

      visible_modules = visible_module_headers
      expect(visible_modules.length).to eq(3)
      expect(visible_modules.first.text).to include("module1")
      expect(visible_modules.last.text).to include("module3")
    end

    it "displays selected module in students view when acting as student" do
      go_to_modules
      module_page_student_dropdown.click
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
      module_page_teacher_dropdown.click
      wait_for_ajaximations

      first_module = ff("[role='option']")[1]
      first_module.click
      wait_for_ajaximations

      refresh_page
      wait_for_ajaximations

      visible_modules = visible_module_headers[0]
      expect(visible_modules.text).to include("module1")
    end

    it "resets teacher dropdown to 'All Modules' when the selected module is deleted" do
      go_to_modules
      module_page_teacher_dropdown.click
      wait_for_ajaximations

      first_module = ff("[role='option']")[1]
      expect(first_module.text).to eq("module1")

      first_module.click
      wait_for_ajaximations

      module_action_menu(@module1.id).click
      module_action_menu_deletetion(@module1.id).click
      alert = driver.switch_to.alert
      alert.accept
      wait_for_ajaximations

      expect(module_page_teacher_dropdown[:value]).to eq("All Modules")
    end
  end

  context "create modules using tray" do
    before(:once) do
      course_with_teacher(active_all: true)
    end

    before do
      user_session(@teacher)

      go_to_modules
      wait_for_ajaximations
    end

    it "brings up the add module tray when Add Module button clicked" do
      add_module_button.click
      expect(add_module_tray).to be_displayed
      expect(tray_header_label.text).to eq("Add Module")
    end

    it "can cancel creation of module" do
      add_module_button.click
      expect(input_module_name).to be_displayed
      fill_in_module_name("Cancel module creation test")
      cancel_tray_button.click
      expect(@course.context_modules.count).to eq 0
    end

    it "can close creation of module" do
      add_module_button.click
      expect(input_module_name).to be_displayed
      fill_in_module_name("Close module creation tray")
      close_tray_button.click
      expect(@course.context_modules.count).to eq 0
    end

    it "give error in add module tray if module name is not provided" do
      add_module_button.click
      expect(input_module_name).to be_displayed
      submit_add_module_button.click
      expect(add_module_tray.text).to include("Module name can’t be blank")
    end

    it_behaves_like "course_module2 add module tray", :context_modules
    it_behaves_like "course_module2 add module tray", :course_homepage
  end

  context "update assign to settings using tray" do
    before :once do
      @section1 = @course.course_sections.create!(name: "section1")
      @section2 = @course.course_sections.create!(name: "section2")
      @student1 = user_factory(name: "user1", active_all: true, active_state: "active")
      @student2 = user_factory(name: "user2", active_all: true, active_state: "active", section: @section2)
      @course.enroll_user(@student1, "StudentEnrollment", enrollment_state: "active")
      @course.enroll_user(@student2, "StudentEnrollment", enrollment_state: "active")
    end

    before do
      user_session(@teacher)
      go_to_modules
    end

    it "shows Everyone as default selection in Assign-To tray" do
      module_action_menu(@module1.id).click
      module_item_action_menu_link("Assign To...").click
      expect(is_checked(everyone_radio_checked)).to be true
    end

    it "selects the custom radio button for module assign to when clicked" do
      module_action_menu(@module1.id).click
      module_item_action_menu_link("Assign To...").click

      custom_access_radio_click.click
      expect(is_checked(custom_access_radio_checked)).to be true
    end

    it "selects the custom radio button for module assign to and cancels" do
      module_action_menu(@module1.id).click
      module_item_action_menu_link("Assign To...").click

      custom_access_radio_click.click
      expect(module_settings_tray).to be_displayed
      expect(cancel_tray_button).to be_displayed

      cancel_tray_button.click
      expect(settings_tray_exists?).to be_falsey
    end

    it "adds more than one name to the assign to list" do
      module_action_menu(@module1.id).click
      module_item_action_menu_link("Assign To...").click

      custom_access_radio_click.click
      assignee_selection.send_keys("user")
      click_option(assignee_selection, "user1")
      assignee_selection.send_keys("user")
      click_option(assignee_selection, "user2")

      assignee_list = assignee_selection_item.map(&:text)
      expect(assignee_list.sort).to eq(%w[user1 user2])
    end

    it "adds a section to the list of assignees" do
      module_action_menu(@module1.id).click
      module_item_action_menu_link("Assign To...").click
      custom_access_radio_click.click

      assignee_selection.send_keys("section")
      click_option(assignee_selection, "section1")
      expect(assignee_selection_item[0].text).to eq("section1")
      expect(assignee_selection_item.count).to eq(1)
    end

    it "adds a user to assign to and shows the user from View Assign To" do
      module_action_menu(@module1.id).click
      module_item_action_menu_link("Assign To...").click

      custom_access_radio_click.click
      expect(assignee_selection).to be_displayed
      assignee_selection.send_keys("user")
      click_option(assignee_selection, "user1")
      submit_add_module_button.click

      expect(view_assign_to_link_on_module(@module1.id)).to be_displayed
      view_assign_to_link_on_module(@module1.id).click
      expect(assignee_selection).to be_displayed
      expect(assignee_selection_item[0].text).to eq("user1")
      expect(assignee_selection_item.count).to eq(1)
    end

    it_behaves_like "course_module2 module tray assign to", :context_modules
    it_behaves_like "course_module2 module tray assign to", :course_homepage

    it "deletes added assignee by clicking on it" do
      module_action_menu(@module1.id).click
      module_item_action_menu_link("Assign To...").click
      custom_access_radio_click.click

      assignee_selection.send_keys("user")
      click_option(assignee_selection, "user1")

      assignee_selection_item_remove("user1").click
      expect(element_exists?(assignee_selection_item_selector)).to be false
    end

    it "clears the assignee list when clear all is clicked" do
      module_action_menu(@module1.id).click
      module_item_action_menu_link("Assign To...").click
      custom_access_radio_click.click

      assignee_selection.send_keys("user")
      click_option(assignee_selection, "user1")

      clear_all.click
      expect(element_exists?(assignee_selection_item_selector)).to be false
    end

    it "does not show the assign to buttons when the user does not have the manage_course_content_edit permission" do
      @module1.assignment_overrides.create!

      go_to_modules
      module_action_menu(@module1.id).click

      expect(f("body")).to contain_jqcss(module_index_menu_tool_link_selector("Assign To..."))
      expect(f("body")).to contain_jqcss(context_module_view_assign_to_link_selector(@module1.id))

      RoleOverride.create!(context: @course.account, permission: "manage_course_content_edit", role: teacher_role, enabled: false)
      go_to_modules

      module_action_menu(@module1.id).click
      expect(f("body")).not_to contain_jqcss(module_index_menu_tool_link_selector("Assign To..."))
      expect(f("body")).not_to contain_jqcss(context_module_view_assign_to_link_selector(@module1.id))
    end

    it "displays correct error message if assignee list is empty" do
      module_action_menu(@module1.id).click
      module_item_action_menu_link("Assign To...").click
      custom_access_radio_click.click

      assignee_selection.send_keys("user")
      click_option(assignee_selection, "user1")

      clear_all.click
      expect(assign_to_error_message.text).to eq("A student or section must be selected")
    end

    context "differentiation tags" do
      before :once do
        @course.account.tap do |a|
          a.settings[:allow_assign_to_differentiation_tags] = { value: true }
          a.save!
        end

        @differentiation_tag_category = @course.group_categories.create!(name: "Differentiation Tag Category", non_collaborative: true)
        @diff_tag1 = @course.groups.create!(name: "Differentiation Tag 1", group_category: @differentiation_tag_category, non_collaborative: true)
        @diff_tag2 = @course.groups.create!(name: "Differentiation Tag 2", group_category: @differentiation_tag_category, non_collaborative: true)

        @diff_tag1.add_user(@student1)
        @diff_tag2.add_user(@student2)
      end

      it "can add differentiation tags as assignees to module overrides" do
        go_to_modules
        module_action_menu(@module1.id).click
        module_item_action_menu_link("Assign To...").click
        custom_access_radio_click.click

        assignee_selection.send_keys("Differentiation")
        click_option(assignee_selection, "Differentiation Tag 1")
        expect(assignee_selection_item[0].text).to eq("Differentiation Tag 1")
      end

      it "differentiation tags will persist after saving" do
        go_to_modules
        module_action_menu(@module1.id).click
        module_item_action_menu_link("Assign To...").click
        custom_access_radio_click.click

        assignee_selection.send_keys("Differentiation")
        click_option(assignee_selection, "Differentiation Tag 1")

        submit_add_module_button.click

        module_action_menu(@module1.id).click
        module_item_action_menu_link("Assign To...").click
        expect(assignee_selection_item[0].text).to eq("Differentiation Tag 1")
      end

      it "differentiation tags will not show as assignee option if the account setting is disabled" do
        @course.account.tap do |a|
          a.settings[:allow_assign_to_differentiation_tags] = { value: false }
          a.save!
        end

        go_to_modules
        module_action_menu(@module1.id).click
        module_item_action_menu_link("Assign To...").click
        custom_access_radio_click.click

        assignee_selection.click
        options = ff("[data-testid='assignee_selector_option']").map(&:text)
        expect(options).not_to include("Differentiation")
      end

      it "displays correct error message if assignee list is empty" do
        go_to_modules
        module_action_menu(@module1.id).click
        module_item_action_menu_link("Assign To...").click
        custom_access_radio_click.click

        assignee_selection.send_keys("Differentiation")
        click_option(assignee_selection, "Differentiation Tag 1")

        clear_all.click
        expect(assign_to_error_message.text).to eq("A student, section, or tag must be selected")
      end

      context "differentiation tag rollback" do
        it "displays error message and disables saving if differentiaiton tags exist after account setting is turned off" do
          go_to_modules

          module_action_menu(@module1.id).click
          module_item_action_menu_link("Assign To...").click
          custom_access_radio_click.click

          assignee_selection.send_keys("Differentiation")
          click_option(assignee_selection, "Differentiation Tag 1")
          submit_add_module_button.click

          # Turn off differentiaiton tags account setting
          @course.account.tap do |a|
            a.settings[:allow_assign_to_differentiation_tags] = { value: false }
            a.save!
          end

          go_to_modules
          module_action_menu(@module1.id).click
          module_item_action_menu_link("Assign To...").click
          custom_access_radio_click.click

          expect(assign_to_error_message.text).to eq("Differentiation tag overrides must be removed")
          expect(convert_differentiated_tag_button).to be_displayed
        end

        it "removes error message when user manually removes all differentiation tags from assignee selector" do
          go_to_modules

          module_action_menu(@module1.id).click
          module_item_action_menu_link("Assign To...").click
          custom_access_radio_click.click

          assignee_selection.send_keys("Differentiation")
          click_option(assignee_selection, "Differentiation Tag 1")
          submit_add_module_button.click

          # Turn off differentiaiton tags account setting
          @course.account.tap do |a|
            a.settings[:allow_assign_to_differentiation_tags] = { value: false }
            a.save!
          end

          go_to_modules
          module_action_menu(@module1.id).click
          module_item_action_menu_link("Assign To...").click
          custom_access_radio_click.click
          expect(convert_differentiated_tag_button).to be_displayed

          assignee_selection_item_remove("Differentiation Tag 1").click
          expect(element_exists?(convert_differentiated_tag_button_selector)).to be_falsey
          expect(assign_to_error_message.text).to eq("A student or section must be selected")
        end

        it "converts differentiation tags to ADHOC overrides when 'convert tags' button is clicked" do
          go_to_modules
          module_action_menu(@module1.id).click
          module_item_action_menu_link("Assign To...").click
          custom_access_radio_click.click

          assignee_selection.send_keys("Differentiation")
          click_option(assignee_selection, "Differentiation Tag 1")
          assignee_selection.send_keys("Differentiation")
          click_option(assignee_selection, "Differentiation Tag 2")
          submit_add_module_button.click

          # Turn off differentiaiton tags account setting
          @course.account.tap do |a|
            a.settings[:allow_assign_to_differentiation_tags] = { value: false }
            a.save!
          end

          go_to_modules
          module_action_menu(@module1.id).click
          module_item_action_menu_link("Assign To...").click
          custom_access_radio_click.click

          convert_differentiated_tag_button.click
          wait_for_ajaximations

          expect(assignee_selection_item[0].text).to eq("user1")
          expect(assignee_selection_item[1].text).to eq("user2")
        end
      end
    end
  end

  context "adding files after course creation" do
    before :once do
      @course = course_factory(active_all: true)
      @teacher = @course.teachers.first
    end

    before do
      user_session(@teacher)
      @empty_module = @course.context_modules.create!(name: "Multi File Module")
    end

    it "displays the module file drop area when a module has no items" do
      go_to_modules
      wait_for_ajaximations

      module_header_expand_toggles.last.click
      wait_for_ajaximations
      expect(module_file_drop_element_exists?(@empty_module.id)).to be true

      drop_area = module_file_drop_element(@empty_module.id)
      expect(drop_area).to be_displayed
      expect(drop_area.text).to include("Drop files here to upload")
    end

    it "hides the module file drop area after adding a file item" do
      attachment = create_file("a_file.txt")
      @empty_module.add_item(type: "File", id: attachment.id)
      go_to_modules
      wait_for_ajaximations

      module_header_expand_toggles.last.click
      wait_for_ajaximations
      expect(module_file_drop_element_exists?(@empty_module.id)).to be false
    end

    it "renders the added file in the module list" do
      attachment = create_file("a_file.txt")
      @empty_module.add_item(type: "File", id: attachment.id)
      go_to_modules
      wait_for_ajaximations

      module_header_expand_toggles.last.click
      wait_for_ajaximations
      item_titles = module_item_title_links.last.text
      expect(item_titles).to include("a_file.txt")
    end

    it "renders multiple added files in the module list" do
      file1 = create_file("a_file.txt")
      file2 = create_file("b_file.txt")
      @empty_module.add_item(type: "File", id: file1.id)
      @empty_module.add_item(type: "File", id: file2.id)
      go_to_modules
      wait_for_ajaximations

      module_header_expand_toggles.last.click
      wait_for_ajaximations
      item_titles1 = module_item_title_links[0].text
      item_titles2 = module_item_title_links[1].text
      expect(item_titles1).to include("a_file.txt")
      expect(item_titles2).to include("b_file.txt")
    end
  end

  context "add items to module" do
    before :once do
      @course = course_factory(active_all: true)
      @teacher = @course.teachers.first
    end

    before do
      user_session(@teacher)
      @empty_module = @course.context_modules.create!(name: "Multi File Module")
    end

    it "does not appear when user does not have the manage_course_content_add permission" do
      go_to_modules
      wait_for_ajaximations
      expect(element_exists?(add_item_button_selector)).to be true

      RoleOverride.create!(context: @course.account, permission: "manage_course_content_add", role: teacher_role, enabled: false)
      go_to_modules
      expect(element_exists?(add_item_button_selector)).to be false
    end

    context "when adding a quiz" do
      # Quiz LTI is used when creating new quizzes when quizzes_next flag is enabled
      # and Quiz LTI is added to the course
      it "new quiz engine enabled and Quiz LTI added" do
        @course.root_account.settings[:provision] = { "lti" => "lti url" }
        @course.root_account.save!
        @course.root_account.enable_feature! :quizzes_next
        @course.enable_feature! :quizzes_next

        @course.context_external_tools.create!(
          name: "Quizzes.Next",
          consumer_key: "test_key",
          shared_secret: "test_secret",
          tool_id: "Quizzes 2",
          url: "http://example.com/launch"
        )

        @course.root_account.enable_feature! :new_quizzes_by_default
        @course.enable_feature! :new_quizzes_by_default

        go_to_modules
        wait_for_ajaximations

        # Expand the module to see its items
        context_module_expand_toggle(@empty_module.id).click
        wait_for_ajaximations

        add_item_button(@empty_module.id).click
        wait_for_ajaximations

        # Select External Tool from the dropdown
        click_INSTUI_Select_option(new_item_type_select_selector, "Quiz")
        wait_for_ajaximations

        tab_create_item.click

        # Verify that quiz engine selector is NOT shown
        expect(quiz_engine_option_exists?).to be_falsey

        # Fill in the quiz details
        new_item_name = "New Quizz"

        replace_content(create_learning_object_name_input, new_item_name)

        # Click Add Item
        add_item_modal_add_item_button.click
        wait_for_ajaximations

        # A quiz with new Quiz engine is created and found in Module Item list
        expect(new_quiz_icon.count).to eq(1)
      end

      it "new quiz engine enabled but Quiz LTI is not added" do
        @course.root_account.settings[:provision] = { "lti" => "lti url" }
        @course.root_account.save!
        @course.root_account.enable_feature! :quizzes_next
        @course.enable_feature! :quizzes_next

        go_to_modules
        wait_for_ajaximations

        # Expand the module to see its items
        context_module_expand_toggle(@empty_module.id).click
        wait_for_ajaximations

        add_item_button(@empty_module.id).click
        wait_for_ajaximations

        # Select External Tool from the dropdown
        click_INSTUI_Select_option(new_item_type_select_selector, "Quiz")
        wait_for_ajaximations

        tab_create_item.click

        # Fill in the quiz details
        new_item_name = "New Quizz"

        replace_content(create_learning_object_name_input, new_item_name)

        # Click Add Item
        add_item_modal_add_item_button.click
        wait_for_ajaximations

        # A quiz with classic Quiz engine is created and found in Module Item list
        expect(classic_quiz_icon.count).to eq(1)
      end

      it "new quiz engine disabled but Quiz LTI is added" do
        @course.root_account.settings[:provision] = { "lti" => "lti url" }
        @course.root_account.save!
        @course.root_account.disable_feature! :quizzes_next
        @course.disable_feature! :quizzes_next

        @course.context_external_tools.create!(
          name: "Quizzes.Next",
          consumer_key: "test_key",
          shared_secret: "test_secret",
          tool_id: "Quizzes 2",
          url: "http://example.com/launch"
        )

        go_to_modules
        wait_for_ajaximations

        # Expand the module to see its items
        context_module_expand_toggle(@empty_module.id).click
        wait_for_ajaximations

        add_item_button(@empty_module.id).click
        wait_for_ajaximations

        # Select External Tool from the dropdown
        click_INSTUI_Select_option(new_item_type_select_selector, "Quiz")
        wait_for_ajaximations

        tab_create_item.click

        # Fill in the quiz details
        new_item_name = "New Quizz"

        replace_content(create_learning_object_name_input, new_item_name)

        # Click Add Item
        add_item_modal_add_item_button.click
        wait_for_ajaximations

        # A quiz with classic Quiz engine is created and found in Module Item list
        expect(classic_quiz_icon.count).to eq(1)
      end

      it "shows quiz engine selector" do
        @course.root_account.settings[:provision] = { "lti" => "lti url" }
        @course.root_account.save!
        @course.root_account.enable_feature! :quizzes_next
        @course.enable_feature! :quizzes_next
        @course.root_account.disable_feature! :new_quizzes_by_default
        @course.disable_feature! :new_quizzes_by_default

        @course.context_external_tools.create!(
          name: "Quizzes.Next",
          consumer_key: "test_key",
          shared_secret: "test_secret",
          tool_id: "Quizzes 2",
          url: "http://example.com/launch"
        )

        go_to_modules
        wait_for_ajaximations

        # Expand the module to see its items
        context_module_expand_toggle(@empty_module.id).click
        wait_for_ajaximations

        add_item_button(@empty_module.id).click
        wait_for_ajaximations

        # Select Quiz from the dropdown
        click_INSTUI_Select_option(new_item_type_select_selector, "Quiz")
        wait_for_ajaximations

        tab_create_item.click

        # Verify that quiz engine selector is shown
        expect(quiz_engine_option_exists?).to be_truthy
      end
    end
  end

  context "module header" do
    it "includes Complete All Items pill when Complete All requirements are present" do
      @module1.completion_requirements = { @module_item1.id => { type: "must_view" }, @module_item2.id => { type: "must_view" } }
      @module1.save!

      go_to_modules
      expect(completion_requirement.text).to eq("Complete All Items")
    end

    it "includes Complete One Item pill when Complete One requirement is present" do
      @module1.completion_requirements = { @module_item1.id => { type: "must_view" }, @module_item2.id => { type: "must_view" } }
      @module1.requirement_count = 1
      @module1.save!

      go_to_modules
      expect(completion_requirement.text).to eq("Complete One Item")
    end

    it "includes Module Pre-requisite when one is present" do
      @module2.prerequisites = "module_#{@module1.id}"
      @module2.save!

      go_to_modules
      expect(module_prerequisite.text).to eq("Prerequisite: #{@module1.name}")
    end

    it "shows multiple Module Pre-requisites when multiple are present" do
      @module3 = @course.context_modules.create!(name: "module3")
      @module3.prerequisites = "module_#{@module1.id},module_#{@module2.id}"
      @module3.save!

      go_to_modules
      expect(module_prerequisite.text).to eq("Prerequisites: #{@module1.name}, #{@module2.name}")
    end
  end

  it_behaves_like "module unlock dates"
  it_behaves_like "module collapse and expand", :context_modules
  it_behaves_like "module collapse and expand", :course_homepage

  context "module action menu deletion" do
    def trigger_module_deletion(module_id)
      go_to_modules
      wait_for_ajaximations
      module_menu = module_action_menu(module_id)
      module_menu.click

      deletion_option = module_action_menu_deletetion(module_id)
      deletion_option.click

      alert = driver.switch_to.alert
      expect(alert).not_to be_nil
      alert
    end

    it "cancels out of deletion" do
      trigger_module_deletion(@module1.id).dismiss
      expect(element_exists?(module_header_selector(@module1.id))).to be_truthy
    end

    it "deletes a module" do
      trigger_module_deletion(@module1.id).accept
      wait_for_ajaximations
      expect(element_exists?(module_header_selector(@module1.id))).to be_falsey
      @module1.reload
      expect(@module1.deleted_at).not_to be_nil
    end
  end

  context "module action menu copy" do
    before :once do
      course = @course
      @other_course = course_factory(course_name: "test for copy")
      course_with_teacher(course: @other_course, user: @teacher, name: "Sharee", active_all: true)
      @course = course
    end

    def open_module_copy_modal(module_id)
      go_to_modules
      wait_for_ajaximations
      module_menu = module_action_menu(module_id)
      module_menu.click

      copy_option = module_action_menu_copy(module_id)
      copy_option.click
      wait_for_ajaximations
    end

    it "cancels out of copy" do
      open_module_copy_modal(@module1.id)
      close_copy_to_tray_button.click
      wait_for_ajaximations
      expect(element_exists?(close_copy_tray_button_selector)).to be_falsey
    end

    it "copies a module to another course" do
      open_module_copy_modal(@module1.id)

      set_value(copy_to_tray_course_select, "test for copy")
      option_list_id = copy_to_tray_course_select.attribute("aria-controls")
      expect(option_list(option_list_id).count).to eq 1

      option_list_course_option(option_list_id, @other_course.name).click
      copy_button.click
      wait_for_ajaximations

      expect(@other_course.content_migrations.last.migration_settings["copy_options"].keys).to eq(["context_modules"])
    end
  end

  context "view progress button" do
    let(:progressions_status_page_url) { "/courses/#{@course.id}/modules/progressions" }

    it "navigates to the progressions status page when clicked" do
      go_to_modules
      wait_for_ajaximations
      progress_button.click

      expect(driver.current_url).to include(progressions_status_page_url)
    end
  end

  context "module publish menu" do
    it "does not show the publish buttons when the user does not have the manage_course_content_edit permission" do
      go_to_modules
      wait_for_ajaximations
      expect(element_exists?(context_module_published_icon_selector(@module1.id))).to be true
      expect(element_exists?(bulk_publish_button_selector)).to be true

      RoleOverride.create!(context: @course.account, permission: "manage_course_content_edit", role: teacher_role, enabled: false)
      go_to_modules
      expect(element_exists?(context_module_published_icon_selector(@module1.id))).to be false
      expect(element_exists?(bulk_publish_button_selector)).to be false
    end

    context "'Publish module and all items' button" do
      it "publishes the module and all its items" do
        prepare_unpublished_modules(@course.context_modules)

        go_to_modules
        wait_for_ajaximations
        module_publish_menu_for(@module1.id).click

        module_publish_with_all_items.click

        wait_for_ajaximations

        verify_publication_state([@module1], module_published: true, items_published: true)
        expect(modules_published_icon_state?(published: true, modules: [@module1])).to be true
        expand_all_modules
        expect(module_items_published_icon_state?(published: true, modules: [@module1])).to be true
      end
    end

    context "'Publish module only' button" do
      it "publishes the module but not its items" do
        prepare_unpublished_modules(@course.context_modules)

        go_to_modules
        wait_for_ajaximations
        module_publish_menu_for(@module1.id).click

        module_publish.click

        wait_for_ajaximations

        verify_publication_state([@module1], module_published: true, items_published: false)
        expect(modules_published_icon_state?(published: true, modules: [@module1])).to be true
        expand_all_modules
        expect(module_items_published_icon_state?(published: false, modules: [@module1])).to be true
      end
    end

    context "'Unpublish module and all items' button" do
      it "unpublishes the module and all its items" do
        go_to_modules
        wait_for_ajaximations
        module_publish_menu_for(@module1.id).click

        module_unpublish_with_all_items.click

        wait_for_ajaximations

        verify_publication_state([@module1], module_published: false, items_published: false)
        expect(modules_published_icon_state?(published: false, modules: [@module1])).to be true
        expand_all_modules
        expect(module_items_published_icon_state?(published: false, modules: [@module1])).to be true
      end
    end

    context "'Unpublish module only' button" do
      it "unpublishes the module but not its items" do
        go_to_modules
        wait_for_ajaximations
        module_publish_menu_for(@module1.id).click

        module_unpublish.click

        wait_for_ajaximations

        verify_publication_state([@module1], module_published: false, items_published: true)
        expect(modules_published_icon_state?(published: false, modules: [@module1])).to be true
        expand_all_modules
        expect(module_items_published_icon_state?(published: true, modules: [@module1])).to be true
      end
    end
  end

  context "publish all menu" do
    context "'Publish all modules and items' button" do
      it "publishes all modules and items" do
        prepare_unpublished_modules(@course.context_modules)

        go_to_modules
        wait_for_ajaximations
        publish_all_menu.click
        publish_all_modules_and_items.click
        publish_all_continue_button.click

        run_jobs

        verify_publication_state(@course.context_modules, module_published: true, items_published: true)
        wait_until_bulk_publish_action_finished
        expect(modules_published_icon_state?(published: true)).to be true
        expand_all_modules
        expect(module_items_published_icon_state?(published: true)).to be true
      end
    end

    context "'Publish modules only' button" do
      it "publishes all modules but not items" do
        prepare_unpublished_modules(@course.context_modules)

        go_to_modules
        wait_for_ajaximations
        publish_all_menu.click
        publish_modules_only.click
        publish_module_only_continue_button.click

        run_jobs

        verify_publication_state(@course.context_modules, module_published: true, items_published: false)
        wait_until_bulk_publish_action_finished
        expect(modules_published_icon_state?(published: true)).to be true
        expand_all_modules
        expect(module_items_published_icon_state?(published: false)).to be true
      end

      it "displays spinners correctly" do
        prepare_unpublished_modules(@course.context_modules)

        go_to_modules
        wait_for_ajaximations

        # Count how many publish buttons are present
        module_header_publish_buttons_count = module_publish_menu_buttons.length
        expect(module_header_publish_buttons_count).to eq @course.context_modules.count

        publish_all_menu.click
        publish_modules_only.click
        publish_module_only_continue_button.click
        expect(element_exists?(module_publish_menu_spinner_selector)).to be true
        # Spinners appear on each module's publish button
        expect(module_publish_menu_button_spinners.length).to eq module_header_publish_buttons_count

        run_jobs
        wait_until_bulk_publish_action_finished
        wait_for_ajaximations
        # Spinners go away after publishing is finished
        expect(modules_published_icon_state?(published: true)).to be true
      end
    end

    context "'Unpublish all modules and items' button" do
      it "unpublishes all modules and items" do
        go_to_modules
        wait_for_ajaximations
        publish_all_menu.click
        unpublish_all_modules_and_items.click
        unpublish_all_continue_button.click

        run_jobs

        verify_publication_state(@course.context_modules, module_published: false, items_published: false)
        wait_until_bulk_publish_action_finished
        expect(modules_published_icon_state?(published: false)).to be true
        expand_all_modules
        expect(module_items_published_icon_state?(published: false)).to be true
      end
    end

    context "'Unpublish modules only' button" do
      it "unpublishes all modules but not items" do
        go_to_modules
        wait_for_ajaximations
        publish_all_menu.click
        unpublish_modules_only.click
        unpublish_all_continue_button.click

        run_jobs

        verify_publication_state(@course.context_modules, module_published: false, items_published: true)
        wait_until_bulk_publish_action_finished
        expect(modules_published_icon_state?(published: false)).to be true
        expand_all_modules
        expect(module_items_published_icon_state?(published: true)).to be true
      end
    end

    context "module item deletion" do
      it "focuses on the next item when a module item is deleted" do
        go_to_modules
        module_header_expand_toggles.last.click
        wait_for_ajaximations

        first_module_item = @module3.content_tags[0]
        second_module_item = @module3.content_tags[1]

        manage_module_item_button(first_module_item.id).click
        module_item_action_menu_link("Remove").click

        alert = driver.switch_to.alert
        expect(alert).not_to be_nil
        alert.accept

        wait_for_ajaximations
        expect(module_item_title_by_id(second_module_item.id)).to eq(driver.switch_to.active_element)
      end
    end
  end
end
