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

describe "context module items", :ignore_js_errors do
  include_context "in-process server selenium tests"
  include ContextModulesCommon
  include Modules2IndexPage
  include Modules2ActionTray
  include ItemsAssignToTray
  include AssignmentsCommon
  include Modules2ActionTray

  before :once do
    modules2_teacher_setup
  end

  before do
    user_session(@teacher)
  end

  context "module items header actions" do
    it "shows the Everyone due date for an assignment when set" do
      due_at = 1.week.from_now
      @assignment.due_at = due_at
      @assignment.save!

      go_to_modules
      wait_for_ajaximations

      module_header_expand_toggles.first.click

      expect(module_item_due_date(@module_item1.id).text).to include(format_date_for_view(due_at, "%b %-d, %Y"))
    end

    it "shows the points possible for an assignment when set" do
      go_to_modules
      wait_for_ajaximations

      module_header_expand_toggles.first.click
      expect(manage_module_item_container(@module_item1.id).text).not_to include("pts")
      expect(manage_module_item_container(@module_item2.id).text).to include("10 pts")
    end

    it "shows requirements type for assignment module items" do
      due_at = 3.days.from_now
      @disc_assignment = @course.assignments.create!(name: "disc assignment", due_at:)
      @graded_discussion = @course.discussion_topics.create!(title: "Graded Discussion", assignment: @disc_assignment)
      graded_discussion_module_item = @module1.add_item(type: "discussion_topic", id: @graded_discussion.id)
      @module1.completion_requirements = {
        @module_item1.id => { type: "must_submit" },
        graded_discussion_module_item.id => { type: "must_view" }
      }
      @module1.save!
      go_to_modules
      wait_for_ajaximations

      module_header_expand_toggles.first.click

      expect(manage_module_item_container(@module_item1.id).text).to include("To do: Submit assignment")
      expect(manage_module_item_container(graded_discussion_module_item.id).text).to include("To do: View discussion")
    end

    it "unpublishes and republishes a module item" do
      go_to_modules
      wait_for_ajaximations

      module_header_expand_toggles.first.click
      expect(module_item_publish_button(@module_item1.id).text).to include "Published"

      # Unpublish the first module item
      module_item_publish_button(@module_item1.id).click
      wait_for_ajaximations
      expect(module_item_publish_button(@module_item1.id).text).to include "Unpublished"

      # Republish the first module item
      module_item_publish_button(@module_item1.id).click
      wait_for_ajaximations
      expect(module_item_publish_button(@module_item1.id).text).to include "Published"
    end

    it "won't allow unpublish if student has submission" do
      student = student_in_course(course: @course, name: "student", active_all: true).user
      @assignment.submit_homework(student, { submission_type: "online_text_entry", body: "Here it is" })

      go_to_modules
      wait_for_ajaximations

      module_header_expand_toggles.first.click

      expect(module_item_publish_button(@module_item1.id)).to be_disabled
    end

    it "shows a multiple due date link in header when there are more due dates" do
      due_at = 1.week.from_now
      @assignment.due_at = due_at
      @assignment.save!

      student = student_in_course(course: @course, name: "student", active_all: true).user
      override = assignment_override_model(assignment: @assignment)
      override.override_due_at(2.weeks.from_now)
      override.save!
      override_student = override.assignment_override_students.build
      override_student.user = student
      override_student.save!

      go_to_modules
      wait_for_ajaximations

      module_header_expand_toggles.first.click

      expect(module_item_multiple_due_dates(@module_item1.id)).to be_displayed
    end
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
      expect(module_item_by_id_selector(text_header.id)).not_to include("[data-testid='document-icon']")
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

  context "module items action menu" do
    context "edit module item kebab form" do
      before do
        # add a file item
        file = @course.attachments.create!(display_name: "some file", uploaded_data: default_uploaded_data, locked: true)
        @module3.add_item(type: "file", id: file.id)
        # add external tool
        @tool = @course.context_external_tools.create!(name: "new tool",
                                                       consumer_key: "key",
                                                       shared_secret: "secret",
                                                       url: "http://localhost:3000/",
                                                       custom_fields: { "a" => "1", "b" => "2" })
        @external_tool_tag = @module3.add_item({
                                                 type: "context_external_tool",
                                                 title: "Example",
                                                 url: "http://localhost:3000/",
                                                 new_tab: "0"
                                               })
        @external_tool_tag.publish!
        # add external url
        @external_url_tag = @module3.add_item({
                                                type: "external_url",
                                                title: "pls view",
                                                url: "http://localhost:3000/lolcats"
                                              })
        @external_url_tag.publish!
      end

      def validate_edit_item_form(item)
        manage_module_item_button(item.id).click
        module_item_action_menu_link("Edit").click

        expect(edit_item_modal).to be_displayed
        edit_item_modal_submit_button.click
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

          new_tab_value = item.new_tab.nil? ? false : item.new_tab
          expect(edit_item_modal_new_tab_checkbox.selected?).to eq(new_tab_value)
        end

        edit_item_modal_submit_button.click
        wait_for_ajaximations
      end

      def validate_update_module_item_title(item, new_title = "New Title")
        manage_module_item_button(item.id).click
        module_item_action_menu_link("Edit").click
        wait_for_ajaximations

        replace_content(edit_item_modal_title_input, new_title)

        edit_item_modal_submit_button.click
        wait_for_ajaximations
        assignment_title = manage_module_item_container(item.id).find_element(:xpath, ".//*[text()='#{new_title}']")
        expect(assignment_title.text).to eq(new_title)
      end
      it "edit item form is shown" do
        go_to_modules
        module_header_expand_toggles[2].click
        wait_for_ajaximations

        @module3.content_tags.each do |item|
          validate_edit_item_form(item)
        end
      end

      it "title fields has the right value" do
        go_to_modules
        module_header_expand_toggles[2].click
        wait_for_ajaximations

        @module3.content_tags.each do |item|
          validate_text_fields_has_right_value(item)
        end
      end

      it "item is updated" do
        go_to_modules
        module_header_expand_toggles[2].click
        wait_for_ajaximations

        @module3.content_tags.each do |item|
          validate_update_module_item_title(item)
        end
      end
    end

    context "link to speedgrader" do
      it "redirects to speedgrader page" do
        student_in_course(course: @course, name: "student", active_all: true).user

        go_to_modules
        module_header_expand_toggles.first.click
        wait_for_ajaximations

        manage_module_item_button(@module_item1.id).click
        module_item_action_menu_link("SpeedGrader").click

        driver.switch_to.window(driver.window_handles.last)
        expect(driver.current_url).to include(
          "/courses/#{@course.id}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
        )
      end
    end

    context "indent module items" do
      before(:once) do
        @indented_item1 = @module1.add_item(
          type: "assignment",
          id: @assignment3.id,
          indent: 3 # Indent level 3 = 60px
        )

        @indented_item2 = @module2.add_item(
          type: "quiz",
          id: @quiz2.id,
          indent: 1 # Indent level 1 = 20px
        )
      end

      it "can increase indent with edit modal" do
        go_to_modules
        module_header_expand_toggles.first.click
        wait_for_ajaximations

        manage_module_item_button(@module_item1.id).click # First item in the first module
        module_item_action_menu_link("Edit").click
        click_INSTUI_Select_option(add_item_indent_select, "Indent 2 levels")
        edit_item_modal_submit_button.click

        wait_for_ajaximations
        item_indent = module_item_indent(@module_item1.id)
        expect(item_indent).to match("padding: 0px 0px 0px 40px;")
      end

      it "can decrease indent with edit modal" do
        go_to_modules
        module_header_expand_toggles.first.click
        wait_for_ajaximations

        manage_module_item_button(@indented_item1.id).click
        module_item_action_menu_link("Edit").click
        click_INSTUI_Select_option(add_item_indent_select, "Indent 1 level")
        edit_item_modal_submit_button.click

        wait_for_ajaximations
        item_indent = module_item_indent(@indented_item1.id)
        expect(item_indent).to match("padding: 0px 0px 0px 20px;")
      end

      it "can increase indent" do
        go_to_modules
        module_header_expand_toggles[1].click
        wait_for_ajaximations

        manage_module_item_button(@indented_item2.id).click # Last item in second module, already indented 1 level
        module_item_action_menu_link("Increase indent").click

        wait_for_ajaximations
        item_indent = module_item_indent(@indented_item2.id)
        expect(item_indent).to match("padding: 0px 0px 0px 40px;")
      end

      it "can decrease indent" do
        go_to_modules
        module_header_expand_toggles[1].click
        wait_for_ajaximations

        manage_module_item_button(@indented_item2.id).click
        module_item_action_menu_link("Decrease indent").click

        wait_for_ajaximations
        item_indent = module_item_indent(@indented_item2.id)
        expect(item_indent).to match("padding: 0px;")
      end

      it "shows correct indent options depending on item position" do
        go_to_modules
        module_header_expand_toggles.first.click
        wait_for_ajaximations

        manage_module_item_button(@module_item1.id).click
        expect(module_item_action_menu_link_exists?("Decrease indent")).to be_falsey # Can't decrease indent at level 0
        expect(module_item_action_menu_link_exists?("Increase indent")).to be_truthy
        manage_module_item_button(@indented_item1.id).click
        expect(module_item_action_menu_link_exists?("Decrease indent")).to be_truthy
        expect(module_item_action_menu_link_exists?("Increase indent")).to be_truthy
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

      it "send item form is shown for file items" do
        @file = @course.attachments.create!(display_name: "some file", uploaded_data: default_uploaded_data)
        file_item = @module1.add_item(type: "file", id: @file.id)
        go_to_modules
        module_header_expand_toggles.first.click
        wait_for_ajaximations
        manage_module_item_button(file_item.id).click
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
        @file = @course.attachments.create!(display_name: "some file", uploaded_data: default_uploaded_data)
        @file_item = @module3.add_item(type: "file", id: @file.id)
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

        copy_and_expect(@assignment_item, "assignments")
        copy_and_expect(@discussion_item, "discussion_topics")
        copy_and_expect(@page_item, "wiki_pages")
      end

      it "module item files is correctly copied" do
        go_to_modules
        # Use the third module
        module_header_expand_toggles[2].click
        wait_for_ajaximations

        copy_and_expect(@file_item, "attachments")
      end

      it "module item quiz is correctly copied" do
        go_to_modules
        # Use the third module
        module_header_expand_toggles[2].click
        wait_for_ajaximations

        copy_and_expect(@quiz_item, "quizzes")
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

        moved_item = @module3.content_tags.first
        manage_module_item_button(moved_item.id).click
        module_item_action_menu_link("Move to...").click
        expect(move_item_tray_select_modules_listbox).to be_displayed
        move_item_tray_select_modules_listbox.click

        option_list_id = move_item_tray_select_modules_listbox.attribute("aria-controls")
        option_list_course_option(option_list_id, @module1.name).click
        move_tray_place_contents_listbox.click
        place_item_at_option("At the bottom").click
        submit_move_to_button.click
        wait_for_ajaximations

        item_titles_list = module_item_title_links.map(&:text)
        expect(@module1.content_tags.last.title).to include(moved_item.title)
        expect(item_titles_list.count(moved_item.title)).to eq(1)
      end

      it "moves module item within the same module" do
        go_to_modules
        module_header_expand_toggles.first.click
        module_header_expand_toggles.last.click
        wait_for_ajaximations

        moved_item = @module3.content_tags.first
        manage_module_item_button(moved_item.id).click
        module_item_action_menu_link("Move to...").click
        expect(move_item_tray_select_modules_listbox).to be_displayed
        move_item_tray_select_modules_listbox.click

        option_list_id = move_item_tray_select_modules_listbox.attribute("aria-controls")
        option_list_course_option(option_list_id, @module3.name).click
        move_tray_place_contents_listbox.click
        place_item_at_option("At the bottom").click
        submit_move_to_button.click
        wait_for_ajaximations

        item_titles_list = module_item_title_links.map(&:text)
        expect(@module3.content_tags.last.title).to include(moved_item.title)
        expect(item_titles_list.count(moved_item.title)).to eq(1)
      end

      context "with pagination" do
        before :once do
          Setting.set("module_perf_threshold", -1) # force pagination

          @source_module = @course.context_modules.create!(name: "Source Module")
          @target_module = @course.context_modules.create!(name: "Target Module")

          first_source_assignment = @course.assignments.create!(title: "Source Assignment First", position: 0)
          @moved_item = @source_module.add_item(type: "assignment", id: first_source_assignment.id)

          (1..15).each do |i|
            a = @course.assignments.create!(title: "Target Assignment #{i}", position: i)
            @target_module.add_item(type: "assignment", id: a.id)
            b = @course.assignments.create!(title: "Source Assignment #{i}", position: i)
            @source_module.add_item(type: "assignment", id: b.id)
          end

          last_source_assignment = @course.assignments.create!(title: "Source Assignment Last", position: 15)
          @moved_item_last = @source_module.add_item(type: "assignment", id: last_source_assignment.id)
        end

        before do
          user_session(@teacher)
          go_to_modules
          wait_for_ajaximations
          context_module_expand_toggle(@source_module.id).click
          context_module_expand_toggle(@target_module.id).click
          wait_for_ajaximations
        end

        it "moves item to top of target module" do
          open_move_item_tray(@moved_item.id, @target_module.name)
          place_item_at_option("At the top").click
          submit_move_to_button.click
          wait_for_ajaximations
          expect(@target_module.reload.content_tags.first.title).to eq("Source Assignment First")
        end

        it "moves item to bottom of target module" do
          open_move_item_tray(@moved_item.id, @target_module.name)
          place_item_at_option("At the bottom").click
          submit_move_to_button.click
          wait_for_ajaximations
          expect(@target_module.reload.content_tags.last.title).to eq("Source Assignment First")
        end

        it "moves last item to the top of same module" do
          pagination_page_buttons[1].click
          open_move_item_tray(@moved_item_last.id, @source_module.name)
          place_item_at_option("At the top").click
          submit_move_to_button.click
          wait_for_ajaximations
          expect(@source_module.reload.content_tags.first.title).to eq("Source Assignment Last")
        end

        it "moves item to bottom of same module" do
          open_move_item_tray(@moved_item.id, @source_module.name)
          place_item_at_option("At the bottom").click
          submit_move_to_button.click
          wait_for_ajaximations
          expect(@source_module.reload.content_tags.last.title).to eq("Source Assignment First")
        end

        it "moves a module item before another item in a different module" do
          open_move_item_tray(@moved_item.id, @target_module.name)
          place_item_at_option("Before...").click
          move_item_tray_select_page_listbox.click
          page_option(1).click
          move_item_tray_reference_listbox.click
          reference_item = "Target Assignment 1"
          reference_item_option(reference_item).click
          submit_move_to_button.click
          wait_for_ajaximations
          module2_titles = @target_module.content_tags.map(&:title)
          moved_index    = module2_titles.index { |t| t.include?("Source Assignment First") }
          ref_index      = module2_titles.index { |t| t.include?(reference_item) }
          expect(moved_index).to eq(0)
          expect(ref_index).to eq(1)
        end

        it "moves a module item after another item in a different module" do
          open_move_item_tray(@moved_item.id, @target_module.name)
          place_item_at_option("After...").click
          move_item_tray_select_page_listbox.click
          page_option(1).click
          move_item_tray_reference_listbox.click
          reference_item = "Target Assignment 1"
          reference_item_option(reference_item).click
          submit_move_to_button.click
          wait_for_ajaximations
          module2_titles = @target_module.content_tags.map(&:title)
          moved_index    = module2_titles.index { |t| t.include?("Source Assignment First") }
          ref_index      = module2_titles.index { |t| t.include?(reference_item) }
          expect(moved_index).to eq(1)
          expect(ref_index).to eq(0)
        end

        it "moves a module item before another item in the same module" do
          open_move_item_tray(@moved_item.id, @source_module.name)
          place_item_at_option("Before...").click
          move_item_tray_select_page_listbox.click
          page_option(1).click
          move_item_tray_reference_listbox.click
          reference_item = "Source Assignment 2"
          reference_item_option(reference_item).click
          submit_move_to_button.click
          wait_for_ajaximations
          module1_titles = @source_module.content_tags.map(&:title)
          moved_index    = module1_titles.index { |t| t.include?("Source Assignment First") }
          ref_index      = module1_titles.index { |t| t.include?(reference_item) }
          expect(moved_index).to eq(ref_index - 1)
        end

        it "moves a module item after another item in the same module" do
          open_move_item_tray(@moved_item.id, @source_module.name)
          place_item_at_option("After...").click
          move_item_tray_select_page_listbox.click
          page_option(1).click
          move_item_tray_reference_listbox.click
          reference_item = "Source Assignment 2"
          reference_item_option(reference_item).click
          submit_move_to_button.click
          wait_for_ajaximations
          module1_titles = @source_module.content_tags.map(&:title)
          moved_index    = module1_titles.index { |t| t.include?("Source Assignment First") }
          ref_index      = module1_titles.index { |t| t.include?(reference_item) }
          expect(moved_index).to eq(ref_index + 1)
        end
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

    context "remove module item" do
      before :once do
        @test_module = @course.context_modules.create!(name: "module_remove_item")
        @remove_assignment = @course.assignments.create!(title: "Remove me", submission_types: "online_text_entry")
        @remove_item = @test_module.add_item(type: "assignment", id: @remove_assignment.id)
      end

      it "removes last module item displays initial module state" do
        go_to_modules
        wait_for_ajaximations

        context_module_expand_toggle(@test_module.id).click
        wait_for_ajaximations

        manage_module_item_button(@remove_item.id).click
        module_item_action_menu_link("Remove").click
        expect(driver.switch_to.alert).not_to be_nil
        driver.switch_to.alert.accept
        wait_for_ajaximations

        expect(module_file_drop_element_exists?(@test_module.id)).to be true
        expect(f("body")).not_to contain_css(manage_module_item_container_selector(@remove_item.id))
      end

      it "removes a module item" do
        go_to_modules
        wait_for_ajaximations

        context_module_expand_toggle(@test_module.id).click
        wait_for_ajaximations

        removed_item = @test_module.content_tags.last
        expect(removed_item.workflow_state).to eq("active")

        manage_module_item_button(@remove_item.id).click
        module_item_action_menu_link("Remove").click
        expect(driver.switch_to.alert).not_to be_nil
        driver.switch_to.alert.accept
        wait_for_ajaximations

        expect(removed_item.reload.workflow_state).to eq("deleted")
        expect(f("body")).not_to contain_css(manage_module_item_container_selector(@remove_item.id))
      end
    end
  end
end
