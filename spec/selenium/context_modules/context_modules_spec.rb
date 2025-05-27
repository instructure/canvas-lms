# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

  context "adds existing items to modules" do
    before(:once) do
      course_factory(active_course: true)
      @course.context_modules.create! name: "Module 1"
      @mod = @course.context_modules.first
    end

    before do
      course_with_teacher_logged_in(course: @course, active_enrollment: true)
    end

    context "when Restrict Quantitative Data is enabled" do
      before do
        # truthy feature flag
        Account.default.enable_feature! :restrict_quantitative_data

        # truthy setting
        Account.default.settings[:restrict_quantitative_data] = { value: true, locked: true }
        Account.default.save!
        @course.restrict_quantitative_data = true
        @course.save!
      end

      it "hides points possible for student", priority: "1" do
        Account.default.reload
        course_with_student_logged_in(course: @course, active_enrollment: true)
        a = @course.assignments.create!(title: "some assignment", points_possible: 10)
        @pub_graded_discussion = @course.discussion_topics.build(assignment: a, title: "Graded Published Discussion")
        @pub_graded_discussion.save!
        @mod.add_item(type: "discussion_topic", id: @pub_graded_discussion.id)
        go_to_modules
        verify_module_title("Graded Published Discussion")
        expect(f("body")).not_to contain_jqcss(".points_possible_display")
      end

      it "does not hide points possible for teacher", priority: "1" do
        Account.default.reload
        a = @course.assignments.create!(title: "some assignment", points_possible: 10)
        @pub_graded_discussion = @course.discussion_topics.build(assignment: a, title: "Graded Published Discussion")
        @pub_graded_discussion.save!
        @mod.add_item(type: "discussion_topic", id: @pub_graded_discussion.id)
        go_to_modules
        verify_module_title("Graded Published Discussion")
        expect(f("span.publish-icon.published.publish-icon-published")).to be_displayed
        expect(f(".points_possible_display")).to include_text "10 pts"
      end
    end

    it "adds an unpublished page to a module", priority: "1" do
      @unpub_page = @course.wiki_pages.create!(title: "Unpublished Page")
      @unpub_page.workflow_state = "unpublished"
      @unpub_page.save!
      @mod.add_item(type: "wiki_page", id: @unpub_page.id)
      go_to_modules
      verify_module_title("Unpublished Page")
      expect(f("span.publish-icon.unpublished.publish-icon-publish > i.icon-unpublish")).to be_displayed
    end

    it "adds a published page to a module", priority: "1" do
      @pub_page = @course.wiki_pages.create!(title: "Published Page")
      @mod.add_item(type: "wiki_page", id: @pub_page.id)
      go_to_modules
      verify_module_title("Published Page")
      expect(f("span.publish-icon.published.publish-icon-published")).to be_displayed
    end

    it "adds an unpublished quiz to a module", priority: "1" do
      @unpub_quiz = Quizzes::Quiz.create!(context: @course, title: "Unpublished Quiz")
      @unpub_quiz.workflow_state = "unpublished"
      @unpub_quiz.save!
      @mod.add_item(type: "quiz", id: @unpub_quiz.id)
      go_to_modules
      verify_module_title("Unpublished Quiz")
      expect(f("span.publish-icon.unpublished.publish-icon-publish > i.icon-unpublish")).to be_displayed
      expect(f(".speed-grader-link-container").attribute("class")).to include("hidden")
    end

    it "adds a published quiz to a module", priority: "1" do
      @pub_quiz = Quizzes::Quiz.create!(context: @course, title: "Published Quiz", workflow_state: "available")
      @mod.add_item(type: "quiz", id: @pub_quiz.id)
      go_to_modules
      verify_module_title("Published Quiz")
      expect(f("span.publish-icon.published.publish-icon-published")).to be_displayed
      expect(f(".speed-grader-link-container")).to be_present
    end

    it "shows due date on a quiz in a module", priority: "2" do
      @pub_quiz = Quizzes::Quiz.create!(context: @course, title: "Published Quiz", due_at: 2.days.from_now)
      @mod.add_item(type: "quiz", id: @pub_quiz.id)
      go_to_modules
      expect(f(".due_date_display").text).to eq date_string(@pub_quiz.due_at, :no_words)
    end

    it "adds an unpublished assignment to a module", priority: "1" do
      @unpub_assignment = Assignment.create!(context: @course, title: "Unpublished Assignment")
      @unpub_assignment.workflow_state = "unpublished"
      @unpub_assignment.save!
      @mod.add_item(type: "assignment", id: @unpub_assignment.id)
      go_to_modules
      verify_module_title("Unpublished Assignment")
      expect(f("span.publish-icon.unpublished.publish-icon-publish > i.icon-unpublish")).to be_displayed
      expect(f(".speed-grader-link-container").attribute("class")).to include("hidden")
    end

    it "adds a published assignment to a module", priority: "1" do
      @pub_assignment = Assignment.create!(context: @course, title: "Published Assignment")
      @mod.add_item(type: "assignment", id: @pub_assignment.id)
      go_to_modules
      verify_module_title("Published Assignment")
      expect(f("span.publish-icon.published.publish-icon-published")).to be_displayed
      expect(f(".speed-grader-link-container")).to be_present
    end

    it "adds an non-graded unpublished discussion to a module", priority: "1" do
      @unpub_ungraded_discussion = @course.discussion_topics.create!(title: "Non-graded Unpublished Discussion")
      @unpub_ungraded_discussion.workflow_state = "unpublished"
      @unpub_ungraded_discussion.save!
      @mod.add_item(type: "discussion_topic", id: @unpub_ungraded_discussion.id)
      go_to_modules
      verify_module_title("Non-graded Unpublished Discussion")
      expect(f("span.publish-icon.unpublished.publish-icon-publish > i.icon-unpublish")).to be_displayed
    end

    it "adds a non-graded published discussion to a module", priority: "1" do
      @pub_ungraded_discussion = @course.discussion_topics.create!(title: "Non-graded Published Discussion")
      @mod.add_item(type: "discussion_topic", id: @pub_ungraded_discussion.id)
      go_to_modules
      verify_module_title("Non-graded Published Discussion")
      expect(f("span.publish-icon.published.publish-icon-published")).to be_displayed
    end

    it "adds an graded unpublished discussion to a module", priority: "1" do
      a = @course.assignments.create!(title: "some assignment", points_possible: 10)
      @unpub_graded_discussion = @course.discussion_topics.build(assignment: a, title: "Graded Unpublished Discussion")
      @unpub_graded_discussion.workflow_state = "unpublished"
      @unpub_graded_discussion.save!
      @mod.add_item(type: "discussion_topic", id: @unpub_graded_discussion.id)
      go_to_modules
      verify_module_title("Graded Unpublished Discussion")
      expect(f("span.publish-icon.unpublished.publish-icon-publish > i.icon-unpublish")).to be_displayed
      expect(f(".points_possible_display")).to include_text "10 pts"
    end

    it "adds a graded published discussion to a module", priority: "1" do
      a = @course.assignments.create!(title: "some assignment", points_possible: 10)
      @pub_graded_discussion = @course.discussion_topics.build(assignment: a, title: "Graded Published Discussion")
      @pub_graded_discussion.save!
      @mod.add_item(type: "discussion_topic", id: @pub_graded_discussion.id)
      go_to_modules
      verify_module_title("Graded Published Discussion")
      expect(f("span.publish-icon.published.publish-icon-published")).to be_displayed
      expect(f(".points_possible_display")).to include_text "10 pts"
    end

    it "adds a graded published discussion with a due date to a module", priority: "1" do
      @due_at = 3.days.from_now
      a = @course.assignments.create!(title: "some assignment", points_possible: 10, due_at: @due_at)
      @pub_graded_discussion_due = @course.discussion_topics.build(assignment: a, title: "Graded Published Discussion with Due Date")
      @pub_graded_discussion_due.save!
      @mod.add_item(type: "discussion_topic", id: @pub_graded_discussion_due.id)
      go_to_modules
      verify_module_title("Graded Published Discussion with Due Date")
      expect(f("span.publish-icon.published.publish-icon-published")).to be_displayed
      expect(f(".due_date_display").text).not_to be_blank
      expect(f(".due_date_display").text).to eq date_string(@due_at, :no_words)
      expect(f(".points_possible_display")).to include_text "10 pts"
    end

    it "shows the due date on an graded discussion in a module", priority: "2" do
      due_at = 3.days.from_now
      @assignment = @course.assignments.create!(name: "assignemnt", due_at:)
      @discussion = @course.discussion_topics.create!(title: "Graded Discussion", assignment: @assignment)
      @mod.add_item(type: "discussion_topic", id: @discussion.id)
      go_to_modules
      expect(f(".due_date_display").text).to eq date_string(due_at, :no_words)
    end

    it "shows the todo date on an ungraded discussion in a module", priority: "1" do
      todo_date = 1.day.from_now
      @pub_ungraded_discussion = @course.discussion_topics.create!(title: "Non-graded Published Discussion", todo_date:)
      @mod.add_item(type: "discussion_topic", id: @pub_ungraded_discussion.id)
      go_to_modules
      verify_module_title("Non-graded Published Discussion")
      expect(f(".due_date_display").text).to eq date_string(todo_date, :no_words)
    end

    it "does not show the todo date on an graded discussion in a module", priority: "2" do
      due_at = 3.days.from_now
      todo_date = 3.days.from_now
      @assignment = @course.assignments.create!(name: "assignemnt", due_at:)
      @discussion = @course.discussion_topics.create!(title: "Graded Discussion", assignment: @assignment, todo_date:)
      @mod.add_item(type: "discussion_topic", id: @discussion.id)
      go_to_modules
      expect(f(".due_date_display").text).to eq date_string(due_at, :no_words)
    end

    it "edits available/until dates on a ungraded discussion in a module", priority: "2" do
      skip "Will be fixed in VICE-5209"
      available_from = 2.days.from_now
      available_until = 4.days.from_now
      @discussion = @course.discussion_topics.create!(title: "Non-graded Published Discussion")
      @mod.add_item(type: "discussion_topic", id: @discussion.id)
      go_to_modules
      fln("Non-graded Published Discussion").click
      f(".edit-btn").click
      replace_content(f('input[type=text][name="delayed_post_at"]'), format_date_for_view(available_from), tab_out: true)
      replace_content(f('input[type=text][name="lock_at"]'), format_date_for_view(available_until), tab_out: true)
      expect_new_page_load { f(".form-actions button[type=submit]").click }
      go_to_modules
      expect(f(".context_module_item")).not_to include_text(available_from.to_s)
    end

    it "publishes assignment on publish module", priority: "2" do
      @unpub_assignment = Assignment.create!(context: @course, title: "some assignment in a module")
      @unpub_assignment.workflow_state = "unpublished"
      @unpub_assignment.save!
      @mod.add_item(type: "assignment", id: @unpub_assignment.id)
      @mod.workflow_state = "unpublished"
      @mod.save!
      go_to_modules
      verify_module_title("some assignment in a module")
      expect(unpublished_module_icon(@mod.id)).to be_present
      expect(f("span.publish-icon.unpublished.publish-icon-publish > i.icon-unpublish")).to be_present
      publish_module_and_items(@mod.id)
      expect(published_module_icon(@mod.id)).to be_present
      expect(f("span.publish-icon.unpublished.publish-icon-published > i.icon-publish")).to be_present
    end

    it "toggles visibility of the move contents link when items are added or removed" do
      go_to_modules
      expect(f(".move-contents-container")[:style]).to include("display: none;")

      @assignment = Assignment.create!(context: @course, title: "some assignment in a module")
      @assignment.save!
      @mod.add_item(type: "assignment", id: @assignment.id)
      @mod.save!
      refresh_page
      expect(f(".move-contents-container")[:style]).not_to include("display: none;")

      @assignment.destroy!
      refresh_page
      expect(f(".move-contents-container")[:style]).to include("display: none;")
    end
  end

  context "edit inline items on module page" do
    before(:once) do
      course_factory(active_course: true)
      @course.context_modules.create! name: "Module 2"
      @mod = @course.context_modules.first
    end

    before do
      course_with_teacher_logged_in(course: @course, active_enrollment: true)
    end

    it "edit text header module item inline", priority: "2" do
      @mod.add_item(title: "EditMe text header", type: "sub_header")
      go_to_modules
      verify_edit_item_form
    end

    it "edit assignment module item inline", priority: "2" do
      @edit_assignment = Assignment.create!(context: @course, title: "EditMe Assignment")
      @mod.add_item(type: "assignment", id: @edit_assignment.id)
      go_to_modules
      verify_edit_item_form
    end

    it "edit quiz module item inline", priority: "2" do
      @edit_quiz = Quizzes::Quiz.create!(context: @course, title: "EditMe Quiz")
      @mod.add_item(type: "quiz", id: @edit_quiz.id)
      go_to_modules
      verify_edit_item_form
    end

    it "edit content page module item inline", priority: "2" do
      @edit_page = @course.wiki_pages.create!(title: "EditMe Page")
      @mod.add_item(type: "wiki_page", id: @edit_page.id)
      go_to_modules
      verify_edit_item_form
    end

    it "edit discussion module item inline", priority: "2" do
      @edit_discussion = @course.discussion_topics.create!(title: "EditMe Discussion")
      @mod.add_item(type: "discussion_topic", id: @edit_discussion.id)
      go_to_modules
      verify_edit_item_form
    end

    it "edit external tool module item inline", priority: "2" do
      @edit_tool = @course.context_external_tools.create! name: "WHAT", consumer_key: "what", shared_secret: "what", url: "http://what.example.org"
      @mod.add_item(title: "EditMe Tool", type: "external_tool", id: @edit_tool.id, url: "http://what.example.org/")
      go_to_modules
      verify_edit_item_form
    end

    it "edit external URL module item inline", priority: "2" do
      go_to_modules
      add_new_external_item("External URL", "www.google.com", "Google")
      verify_edit_item_form
    end

    it "editing external URL module item inline w/ load in new tab should use the right title" do
      go_to_modules

      f(".add_module_item_link").click
      wait_for_ajaximations
      select_module_item("#add_module_item_select", "External URL")
      wait_for_ajaximations
      url_input = fj('input[name="url"]:visible')
      title_input = fj('input[name="title"]:visible')
      replace_content(url_input, "http://www.google.com")
      title = "Goooogle"
      replace_content(title_input, title)
      fj('input[name="new_tab"]:visible').click

      fj(".add_item_button.ui-button").click
      wait_for_ajaximations
      go_to_modules
      f(".context_module_item .al-trigger").click
      wait_for_ajaximations
      f(".edit_item_link").click
      wait_for_ajaximations
      expect(get_value("#content_tag_title")).to eq title
    end
  end

  describe "files" do
    let(:file_name) { "some test file" }

    before(:once) do
      course_factory(active_course: true)
      @course.usage_rights_required = true
      @course.save!
      # adding file to course
      @file = @course.attachments.create!(display_name: file_name, uploaded_data: default_uploaded_data)
      @file.context = @course
      @file.save!

      @file2 = @course.attachments.create!(display_name: "another.txt", uploaded_data: default_uploaded_data)
      @file2.context = @course
      @file2.save!
    end

    before do
      course_with_teacher_logged_in(course: @course, active_enrollment: true)
    end

    describe "module drag and drop" do
      before(:once) do
        @mod = @course.context_modules.create!(name: "files module")
      end

      it "duplicate of an empty module should display a drag and drop area" do
        get "/courses/#{@course.id}/modules"
        wait_for_ajaximations

        f("button.al-trigger").click
        wait_for_ajaximations

        f("a.duplicate_module_link").click
        wait_for_ajaximations

        expect(ff('.module_dnd input[type="file"]')).to have_size(2)
      end

      it "duplicate of a non-empty module should not display a drag and drop area" do
        pub_assignment = Assignment.create!(context: @course, title: "Published Assignment")
        @course.context_modules.first.add_item(type: "assignment", id: pub_assignment.id)

        get "/courses/#{@course.id}/modules"
        wait_for_ajaximations

        f("button.al-trigger").click
        wait_for_ajaximations

        f("a.duplicate_module_link").click
        wait_for_ajaximations

        # non-empty module should not have a DnD area
        expect(find_with_jquery('.module_dnd input[type="file"]')).to be_nil
      end

      it "adds multiple file items to a module" do
        file_names = [file_name, "another.txt"]
        get "/courses/#{@course.id}/modules"
        add_existing_module_file_items("#attachments_select", file_names)
        file_names.each { |item_name| expect(fj(".context_module_item:contains(#{item_name.inspect})")).to be_displayed }
      end

      it "uploads multiple files to add items to a module" do
        get "/courses/#{@course.id}/modules"

        filename, fullpath, _data = get_file("testfile1.txt")

        add_uploaded_file_items("#attachments_select", fullpath)

        expect(f("body")).not_to contain_jqcss('.ui-dialog:contains("Add Item to"):visible')
        expect(fj(".context_module_item:contains(#{filename})")).to be_displayed
      end

      it "does not duplicate items on multiple uploads when replace is chosen" do
        # create the existing module item
        filename, fullpath, _data = get_file("a_file.txt")
        file = @course.attachments.create!(display_name: filename, uploaded_data: fixture_file_upload("a_file.txt", "text/plain"))
        file.context = @course
        file.save!
        @mod.add_item({ id: file.id, type: "attachment" })

        get "/courses/#{@course.id}/modules"
        upload_file_item_with_selection("div#context_module_#{@mod.id} .add_module_item_link", "#attachments_select", fullpath)
        upload_file_item_with_selection("div#context_module_#{@mod.id} .add_module_item_link", "#attachments_select", fullpath)
        upload_file_item_with_selection("div#context_module_#{@mod.id} .add_module_item_link", "#attachments_select", fullpath)

        expect(ffj(".context_module_item:contains(#{filename})").length).to eq(1)
      end

      it "adds an uploaded file if the same content was just deleted" do
        filename, fullpath, _data = get_file("a_file.txt")
        file = @course.attachments.create!(display_name: filename, uploaded_data: fixture_file_upload("a_file.txt", "text/plain"))
        file.context = @course
        file.save!
        @mod.add_item({ id: file.id, type: "attachment" })

        get "/courses/#{@course.id}/modules"
        driver.execute_script("window.confirm = function() {return true}")

        f(".context_module_item .al-trigger").click
        wait_for_ajaximations
        f(".context_module_item .delete_item_link").click
        wait_for_ajaximations
        upload_file_item_with_selection("div#context_module_#{@mod.id} .add_module_item_link", "#attachments_select", fullpath)

        expect(ffj(".context_module_item:contains(#{filename})").length).to eq(1)
      end

      it "replaces an existing module item with a replacement uploaded file" do
        # create the existing module item
        filename, fullpath, _data = get_file("a_file.txt")
        file = @course.attachments.create!(display_name: filename, uploaded_data: fixture_file_upload("a_file.txt", "text/plain"))
        file.context = @course
        file.save!
        @mod.add_item({ id: file.id, type: "attachment" })

        get "/courses/#{@course.id}/modules"
        upload_file_item_with_selection("div#context_module_#{@mod.id} .add_module_item_link", "#attachments_select", fullpath)

        expect(f("body")).not_to contain_jqcss('.ui-dialog:contains("Add Item to"):visible')
        expect(ffj(".context_module_item:contains(#{filename})").length).to eq(1)
      end

      it "closing the rename dialog should not close the module dialog" do
        filename, fullpath, _data = get_file("a_file.txt")
        file = @course.attachments.create!(display_name: filename, uploaded_data: fixture_file_upload("a_file.txt", "text/plain"))
        file.context = @course
        file.save!

        get "/courses/#{@course.id}/modules"

        # Start the upload, but click Close instead
        upload_file_item_with_selection(
          "div#context_module_#{@mod.id} .add_module_item_link",
          "#attachments_select",
          fullpath,
          "Close"
        )

        # ...then click on the add item button again
        scroll_to(f(".add_item_button.ui-button"))
        f(".add_item_button.ui-button").click
        wait_for_ajaximations

        # now replace the file
        fj('button:contains("Replace")').click
        wait_for_ajaximations

        # File should be uploaded and dialog closed
        expect(f("body")).not_to contain_jqcss('.ui-dialog:contains("Add Item to"):visible')
        expect(ffj(".context_module_item:contains(#{filename})").length).to eq(1)
      end

      it "skipping the only file should not close the add item to module dialog" do
        filename, fullpath, _data = get_file("a_file.txt")
        file = @course.attachments.create!(display_name: filename, uploaded_data: fixture_file_upload("a_file.txt", "text/plain"))
        file.context = @course
        file.save!

        get "/courses/#{@course.id}/modules"

        # Start the upload, but click Skip instead
        upload_file_item_with_selection(
          "div#context_module_#{@mod.id} .add_module_item_link",
          "#attachments_select",
          fullpath,
          "Skip"
        )

        # Dialog should be not closed and not uploaded
        expect(f("body")).to contain_jqcss('.ui-dialog:contains("Add Item to"):visible')
        expect(f("body")).not_to contain_jqcss(".context_module_item:contains(#{filename}):visible")
      end

      it "does not ask to rename upload after folder change" do
        filename, fullpath, _data = get_file("a_file.txt")
        file = @course.attachments.create!(display_name: filename, uploaded_data: fixture_file_upload("a_file.txt", "text/plain"))
        file.context = @course
        file.save!

        get "/courses/#{@course.id}/modules"

        # Start the upload, but click Close instead
        folder_select = upload_file_item_with_selection(
          "div#context_module_#{@mod.id} .add_module_item_link",
          "#attachments_select",
          fullpath,
          "Close"
        )

        # Change to a folder not containing the file
        folder_select.options[0].click

        # ...then click on the add item button again
        scroll_to(f(".add_item_button.ui-button"))
        f(".add_item_button.ui-button").click
        wait_for_ajaximations

        # File should be uploaded and dialog closed
        expect(f("body")).not_to contain_jqcss('.ui-dialog:contains("Add Item to"):visible')
        expect(ffj(".context_module_item:contains(#{filename})").length).to eq(1)
      end

      it "creates a module item with a replacement uploaded file if in a different module" do
        # create the existing module item
        filename, fullpath, _data = get_file("a_file.txt")
        file = @course.attachments.create!(display_name: filename, uploaded_data: fixture_file_upload("a_file.txt", "text/plain"))
        file.context = @course
        file.save!
        @mod.add_item({ id: file.id, type: "attachment" })
        # create a new module
        @mod2 = @course.context_modules.create!(name: "another module")

        get "/courses/#{@course.id}/modules"
        upload_file_item_with_selection("div#context_module_#{@mod2.id} .add_module_item_link", "#attachments_select", fullpath)
        expect(ffj(".context_module_item:contains(#{filename})").length).to eq(2)
      end

      it "uploads file via module drag and drop" do
        get "/courses/#{@course.id}/modules"
        wait_for_ajaximations

        # empty module should have a DnD area
        expect(f('.module_dnd input[type="file"]')).to be_displayed
        filename1, fullpath1, _data = get_file("testfile1.txt")

        f('.module_dnd input[type="file"]').send_keys(fullpath1)
        wait_for_ajaximations

        expect(fj(".context_module_item:contains(#{filename1.inspect})")).to be_displayed

        get "/courses/#{@course.id}/modules"
        wait_for_ajaximations

        # non-empty module should not have a DnD area
        expect(find_with_jquery('.module_dnd input[type="file"]')).to be_nil
      end

      it "creating a new module should display a drag and drop area with differentiated modules" do
        get "/courses/#{@course.id}/modules"

        click_new_module_link
        update_module_name("New Module")
        click_add_tray_add_module_button

        expect(ff('.module_dnd input[type="file"]')).to have_size(2)
      end
    end

    it "adds a file item to a module when differentiated modules is enabled", priority: "1" do
      get "/courses/#{@course.id}/modules"
      manually_add_module_item("#attachments_select", "File", file_name)
      expect(f(".context_module_item")).to include_text(file_name)
    end

    it "does not remove the file link in a module when file is overwritten" do
      course_module
      @module.add_item({ id: @file.id, type: "attachment" })
      get "/courses/#{@course.id}/modules"

      expect(f(".context_module_item")).to include_text(file_name)
      file = @course.attachments.create!(display_name: file_name, uploaded_data: default_uploaded_data)
      file.context = @course
      file.save!
      Attachment.last.handle_duplicates(:overwrite)
      refresh_page
      expect(f(".context_module_item")).to include_text(file_name)
    end

    context("files rewrite tooggle") do
      before(:once) do
        Account.site_admin.enable_feature! :files_a11y_rewrite
        Account.site_admin.enable_feature! :files_a11y_rewrite_toggle
      end

      before do
        user_session @teacher
      end

      it "sets usage rights on a file in a module", priority: "1" do
        @teacher.set_preference(:files_ui_version, "v1")
        course_module
        @module.add_item({ id: @file.id, type: "attachment" })
        get "/courses/#{@course.id}/modules"

        f(".icon-publish").click
        wait_for_ajaximations
        set_value f(".UsageRightsSelectBox__select"), "own_copyright"
        set_value f("#copyrightHolder"), "Test User"
        f(".form-horizontal.form-dialog.permissions-dialog-form > div.form-controls > button.btn.btn-primary").click
        wait_for_ajaximations
        get "/courses/#{@course.id}/files/folder/unfiled"
        icon_class = "icon-files-copyright"
        expect(f(".UsageRightsIndicator__openModal i.#{icon_class}")).to be_displayed
      end

      it "sets usage rights on a file in a module with new files UI", priority: "1" do
        @teacher.set_preference(:files_ui_version, "v2")
        course_module
        @module.add_item({ id: @file.id, type: "attachment" })
        get "/courses/#{@course.id}/modules"

        f(".icon-publish").click
        wait_for_ajaximations
        set_value f(".UsageRightsSelectBox__select"), "used_by_permission"
        set_value f("#copyrightHolder"), "Test User"
        f(".form-horizontal.form-dialog.permissions-dialog-form > div.form-controls > button.btn.btn-primary").click
        wait_for_ajaximations
        get "/courses/#{@course.id}/files/folder/unfiled"
        expect(fxpath("//button[.//span[text()='Used by Permission']]")).to be_displayed
      end
    end

    it "edit file module item inline", priority: "2" do
      course_module
      @module.add_item({ id: @file.id, type: "attachment" })

      get "/courses/#{@course.id}/modules"

      verify_edit_item_form
    end
  end

  context "logged out", priority: "2" do
    before(:once) do
      @course = course_factory(active_all: true)
      course_module
      @course.is_public = true
      @course.save!
      @course.reload
    end

    before do
      remove_user_session
    end

    it "loads page with differentiated assignments" do
      assert_page_loads
    end
  end

  context "when a public course is accessed" do
    include_context "public course as a logged out user"

    it "displays modules list", priority: "1" do
      @module = public_course.context_modules.create!(name: "module 1")
      @assignment = public_course.assignments.create!(name: "assignment 1", assignment_group: @assignment_group)
      @module.add_item type: "assignment", id: @assignment.id
      get "/courses/#{public_course.id}/modules"
      validate_selector_displayed(".item-group-container")
    end

    context "when :react_discussions_post ff is ON" do
      before do
        Account.default.enable_feature!(:react_discussions_post)
      end

      context "when visiting a graded discussion in a module" do
        before do
          @module = public_course.context_modules.create!(name: "module 1")
          @assignment = @course.assignments.create!(name: "assignemnt")
          @discussion = @course.discussion_topics.create!(title: "Graded Discussion", assignment: @assignment)
          @module.add_item(type: "discussion_topic", id: @discussion.id)
        end

        it "redirects unauthenticated users to login page" do
          get "/courses/#{public_course.id}/modules"
          f("a[title='Graded Discussion']").click
          expect(f("#pseudonym_session_unique_id")).to be_present
        end

        it "lets users with access see the discussion" do
          student = user_factory(active_all: true, active_state: "active")
          public_course.enroll_user(student, "StudentEnrollment", enrollment_state: "active")
          user_session student
          get "/courses/#{public_course.id}/modules"
          f("a[title='Graded Discussion']").click
          wait_for_ajaximations
          expect(fj("[data-testid='discussion-topic-container']:contains('Graded Discussion')")).to be_present
        end
      end
    end
  end
end
