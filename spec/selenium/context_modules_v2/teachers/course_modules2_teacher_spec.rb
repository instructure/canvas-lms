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
require_relative "../../helpers/assignments_common"
require_relative "../shared_examples/course_modules2_shared"

describe "context modules", :ignore_js_errors do
  include_context "in-process server selenium tests"
  include ContextModulesCommon
  include Modules2IndexPage
  include ItemsAssignToTray
  include AssignmentsCommon

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

  context "module items action menu" do
    before do
      # Create a module with at least one item of each type
      module_setup
      # Create a module item of file type
      file = @course.attachments.create!(display_name: "some file", uploaded_data: default_uploaded_data, locked: true)
      @module.add_item(type: "file", id: file.id)
    end

    def validate_edit_item_form(item)
      manage_module_item_button(item.id).click
      module_item_action_menu_link("Edit").click

      expect(edit_item_modal).to be_displayed
      edit_item_modal.find_element(:css, "button[type='button']").click
      wait_for_ajaximations
    end

    def validate_text_fields_has_right_value(item)
      manage_module_item_button(item.id).click
      module_item_action_menu_link("Edit").click
      wait_for_ajaximations
      item_title = item.title
      title = edit_item_modal_title_input_value
      expect(title).to eq(item_title)

      # URL field is only present for ExternalTool, ExternalUrl, and ContextExternalTool items
      if %w[External ExternalUrl ExternalTool ContextExternalTool].include?(item.content_type)
        url_value = edit_item_modal_url_value
        expect(url_value).to eq(item.url)

        new_tab = edit_item_modal.find_element(:css, "input[data-testid='edit-modal-new-tab']")
        new_tab_value = item.new_tab.nil? ? false : item.new_tab
        expect(new_tab.selected?).to eq(new_tab_value)
      end

      edit_item_modal.find_element(:css, "button[type='button']").click
      wait_for_ajaximations
    end

    def validate_update_module_item_title(item, new_title = "New Title")
      manage_module_item_button(item.id).click
      module_item_action_menu_link("Edit").click
      wait_for_ajaximations

      title = edit_item_modal.find_element(:css, "input[data-testid='edit-modal-title']")
      replace_content(title, new_title)

      edit_item_modal.find_element(:css, "button[type='submit']").click
      wait_for_ajaximations
      assignment_title = manage_module_item_container(item.id).find_element(:xpath, ".//*[text()='#{new_title}']")
      expect(assignment_title.text).to eq(new_title)
    end

    context "edit module item kebab form" do
      it "edit item form is shown" do
        go_to_modules
        module_header_expand_toggles.last.click
        wait_for_ajaximations

        @module.content_tags.each do |item|
          validate_edit_item_form(item)
        end
      end

      it "title fields has the right value" do
        go_to_modules
        module_header_expand_toggles.last.click
        wait_for_ajaximations

        @module.content_tags.each do |item|
          validate_text_fields_has_right_value(item)
        end
      end

      it "item is updated" do
        go_to_modules
        module_header_expand_toggles.last.click
        wait_for_ajaximations

        @module.content_tags.each do |item|
          validate_update_module_item_title(item)
        end
      end
    end

    context "send to kebab form" do
      before do
        student_in_course
        @first_user = @course.students.first
        # First item of the module item list is the one used for testing
        @item = @module1.content_tags[0]
      end

      it "send item form is shown" do
        go_to_modules
        module_header_expand_toggles.first.click
        wait_for_ajaximations
        manage_module_item_button(@item.id).click
        module_item_action_menu_link("Send To...").click

        expect(send_to_modal).to be_displayed
      end

      it "module item is correctly sent" do
        go_to_modules
        module_header_expand_toggles.first.click
        wait_for_ajaximations
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
        @quiz_item = @module3.content_tags[0]
        @assignment_item = @module3.content_tags[1]
        @discussion_item = @module3.content_tags[2]
        @page_item = @module3.content_tags[3]
      end

      def copy_and_expect(item, expected_key)
        manage_module_item_button(item.id).click
        module_item_action_menu_link("Copy To...").click

        set_value(copy_to_tray_course_select, "course")
        option_list_id = copy_to_tray_course_select.attribute("aria-controls")
        expect(option_list(option_list_id).count).to eq 1

        option_list_course_option(option_list_id, @other_course.name).click
        copy_button.click
        wait_for_ajaximations

        expect(@other_course.content_migrations.last.migration_settings["copy_options"].keys).to eq([expected_key])

        close_copy_to_tray_button.click
        wait_for_ajaximations
      end

      it "module item is correctly copied" do
        go_to_modules
        # Use the third module
        module_header_expand_toggles[2].click
        wait_for_ajaximations

        copy_and_expect(@quiz_item, "quizzes")
        copy_and_expect(@assignment_item, "assignments")
        copy_and_expect(@discussion_item, "discussion_topics")
        copy_and_expect(@page_item, "wiki_pages")
      end
    end

    context "move module item kebab form" do
      it "shows move item tray and close it" do
        go_to_modules
        module_header_expand_toggles.first.click
        wait_for_ajaximations

        manage_module_item_button(@module1.content_tags.first.id).click
        module_item_action_menu_link("Move to...").click
        expect(f("body")).to contain_css(move_item_tray_selector)
        expect(cancel_tray_button).to be_displayed
        cancel_tray_button.click
        expect(f("body")).not_to contain_css(move_item_tray_selector)

        manage_module_item_button(@module1.content_tags.first.id).click
        module_item_action_menu_link("Move to...").click
        expect(f("body")).to contain_css(move_item_tray_selector)
        expect(close_tray_button).to be_displayed
        close_tray_button.click
        expect(f("body")).not_to contain_css(move_item_tray_selector)
      end

      it "moves module item to another module" do
        go_to_modules
        module_header_expand_toggles.first.click
        module_header_expand_toggles.last.click
        wait_for_ajaximations

        moved_item = @module.content_tags.first
        manage_module_item_button(moved_item.id).click
        module_item_action_menu_link("Move to...").click
        expect(move_item_tray_select_modules_listbox).to be_displayed
        move_item_tray_select_modules_listbox.click

        option_list_id = move_item_tray_select_modules_listbox.attribute("aria-controls")
        option_list_course_option(option_list_id, @module1.name).click
        move_item_tray_place_contents_listbox.click
        place_item_at_bottom_option.click
        submit_move_to_button.click
        wait_for_ajaximations

        item_titles_list = module_item_title_links.map(&:text)
        expect(@module1.content_tags.last.title).to include(moved_item.title)
        expect(item_titles_list.count(moved_item.title)).to eq(1)
      end
    end

    context "duplicate module item" do
      before :once do
        @dup_assignment = @course.assignments.create!(title: "Dup me", submission_types: "online_text_entry")
        @dup_item = @module1.add_item(type: "assignment", id: @dup_assignment.id)
      end

      it "duplicates the module item (UI shows new row and DB count increases)" do
        go_to_modules
        wait_for_ajaximations

        context_module_expand_toggle(@module1.id).click
        wait_for_ajaximations

        ui_count_before = module_item_title_links.length
        manage_module_item_button(@dup_item.id).click
        module_item_action_menu_link("Duplicate").click
        wait_for_ajaximations

        expect(module_item_title_links.length).to eq(ui_count_before + 1)
        expect(module_item_title_links.last.text).to eq("Dup me Copy")
      end
    end
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
      visible_modules = ff("div[class*='context_module'] h2")[0]
      expect(visible_modules.text).to include("module1")
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
      expect(visible_modules.length).to eq(3)
      expect(visible_modules.first.text).to include("module1")
      expect(visible_modules.last.text).to include("module3")
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
      visible_modules = ff("div[class*='context_module'] h2")[0]
      expect(visible_modules.text).to include("module1")
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

    context "when adding an external tool" do
      before do
        @external_tool = @course.context_external_tools.create!(
          context_id: @course.id,
          context_type: "Course",
          url: "https://example.com",
          shared_secret: "fake",
          consumer_key: "fake",
          name: "Test External Tool",
          description: "An external tool for testing",
          settings: { "platform" => "canvas.instructure.com" },
          workflow_state: "active"
        )
      end

      it "allows adding an external tool to the module" do
        go_to_modules
        wait_for_ajaximations

        # Expand the module to see its items
        context_module_expand_toggle(@empty_module.id).click
        wait_for_ajaximations

        add_item_button(@empty_module.id).click
        wait_for_ajaximations

        # Select External Tool from the dropdown
        click_INSTUI_Select_option(new_item_type_select_selector, "External Tool")
        wait_for_ajaximations

        # Select external tool from the dropdown
        click_INSTUI_Select_option(add_existing_item_select_selector, @external_tool.name)
        wait_for_ajaximations

        new_item_name = "External Tool Page Name"

        replace_content(external_tool_page_name_input, new_item_name)

        # Click Add Item
        add_item_modal_add_item_button.click

        expect(module_item_title_links.last.text).to include(new_item_name)
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

  context "module locking" do
    include_examples "module unlock dates"
  end

  context "module expanding and collapsing" do
    it_behaves_like "module collapse and expand", :context_modules
    it_behaves_like "module collapse and expand", :course_homepage
  end

  context "module item types" do
    before(:once) do
      course_module
    end

    it "displays the correct icon for assignment" do
      new_assignment = @course.assignments.create!(title: "Week3 homework", submission_types: "online_text_entry")
      module_item = @module.add_item(type: "assignment", id: new_assignment.id)
      go_to_modules
      wait_for_ajaximations
      module_header_expand_toggles.last.click
      assignment_icon = module_item_assignment_icon(module_item.id)
      expect(assignment_icon).to be_displayed
    end

    it "displays the correct icon for classic Quiz" do
      classic_quiz = @course.quizzes.create!(title: "Week3 Quiz", quiz_type: "survey")
      module_item = @module.add_item(type: "quiz", id: classic_quiz.id)
      go_to_modules
      wait_for_ajaximations
      module_header_expand_toggles.last.click
      quiz_icon = module_item_quiz_icon(module_item.id)
      expect(quiz_icon).to be_displayed
    end

    it "displays the correct icon for wiki page" do
      wiki_page = @course.wiki_pages.create!(title: "week3 Page", body: "hi")
      module_item = @module.add_item(type: "wiki_page", id: wiki_page.id)
      go_to_modules
      wait_for_ajaximations
      module_header_expand_toggles.last.click
      page_icon = module_item_page_icon(module_item.id)
      expect(page_icon).to be_displayed
    end

    it "displays the correct icon for discussion" do
      discussion = @course.discussion_topics.create!(title: "Week3 Discussion", message: "hi")
      module_item = @module.add_item(type: "discussion_topic", id: discussion.id)
      go_to_modules
      wait_for_ajaximations
      module_header_expand_toggles.last.click
      discussion_icon = module_item_discussion_icon(module_item.id)
      expect(discussion_icon).to be_displayed
    end

    it "displays the correct icon for text header" do
      text_header = @module.add_item(type: "context_module_sub_header", title: "Created header")
      go_to_modules
      wait_for_ajaximations
      module_header_expand_toggles.last.click
      text_header_icon = module_item_text_header_icon(text_header.id)
      expect(text_header_icon).to be_displayed
    end

    it "displays the correct icon for external URL" do
      external_url = @module.add_item(type: "external_url", url: "http://example.com", title: "External URL")
      go_to_modules
      wait_for_ajaximations
      module_header_expand_toggles.last.click
      external_url_icon = module_item_url_icon(external_url.id)
      expect(external_url_icon).to be_displayed
    end

    it "displays the correct icon for external tool" do
      @course.context_external_tools.create!(name: "lti tool",
                                             consumer_key: "key",
                                             shared_secret: "secret",
                                             url: "http://example.com")
      external_tool = @module.add_item({
                                         type: "context_external_tool",
                                         title: "new external tool",
                                         url: "http://example.com"
                                       })
      go_to_modules
      wait_for_ajaximations
      module_header_expand_toggles.last.click
      external_tool_icon = module_item_url_icon(external_tool.id)
      expect(external_tool_icon).to be_displayed
    end

    it "displays the correct icon for file upload" do
      file = @course.attachments.create!(display_name: "file uploaded", uploaded_data: default_uploaded_data, locked: true)
      uploaded_file = @module.add_item(type: "attachment", id: file.id)
      go_to_modules
      wait_for_ajaximations
      module_header_expand_toggles.last.click
      uploaded_file_icon = module_item_attachment_icon(uploaded_file.id)
      expect(uploaded_file_icon).to be_displayed
    end
  end

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
    context "'Publish module and all items' button" do
      it "publishes the module and all its items" do
        prepare_unpublished_modules(@course.context_modules)

        go_to_modules
        wait_for_ajaximations
        module_publish_menu(@module1.id).click

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
        module_publish_menu(@module1.id).click

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
        module_publish_menu(@module1.id).click

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
        module_publish_menu(@module1.id).click

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
  end
end
