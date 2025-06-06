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
require_relative "../../helpers/public_courses_context"
require_relative "../page_objects/modules_index_page"
require_relative "../page_objects/modules_settings_tray"
require_relative "../../helpers/items_assign_to_tray"

shared_examples_for "context modules for teachers" do
  include ContextModulesCommon
  include ModulesIndexPage
  include ModulesSettingsTray
  include ItemsAssignToTray

  it "shows all module items", priority: "1" do
    module_with_two_items

    expect(f(".context_module .content")).to be_displayed
  end

  it "does not render modules page rewrite" do
    user_session(@teacher)
    get "/courses/#{@course.id}/modules"
    expect(driver.execute_script("return document.querySelector('[data-testid=\"modules-rewrite-container\"]')")).to be_nil # rubocop:disable Specs/NoExecuteScript
  end

  it "expands/collapses module with 0 items", priority: "2" do
    modules = create_modules(1, true)
    get "/courses/#{@course.id}/modules"
    expect(module_content(modules[0].id)).to be_displayed
    f(".collapse_module_link[aria-controls='context_module_content_#{modules[0].id}']").click
    expect(module_content(modules[0].id)).not_to be_displayed
  end

  it "collapses module items", priority: "1" do
    mod = module_with_two_items
    collapse_module_link(mod.id).click
    wait_for_ajaximations
    expect(f(".context_module .content")).not_to be_displayed
  end

  it "rearranges child objects in same module", priority: "1" do
    modules = create_modules(1, true)
    # attach 1 assignment to module 1 and 2 assignments to module 2 and add completion reqs
    item1 = modules[0].add_item({ id: @assignment.id, type: "assignment" })
    item2 = modules[0].add_item({ id: @assignment2.id, type: "assignment" })
    get "/courses/#{@course.id}/modules"
    # setting gui drag icons to pass to driver.action.drag_and_drop
    selector1 = "#context_module_item_#{item1.id} .move_item_link"
    selector2 = "#context_module_item_#{item2.id} .move_item_link"
    list_prior_drag = ff("a.title").map(&:text)
    # performs the change position
    js_drag_and_drop(selector2, selector1)
    list_post_drag = ff("a.title").map(&:text)
    expect(list_prior_drag[0]).to eq list_post_drag[1]
    expect(list_prior_drag[1]).to eq list_post_drag[0]
  end

  it "rearranges child object to new module", priority: "1" do
    modules = create_modules(2, true)
    uncollapse_modules(modules, @user)
    # attach 1 assignment to module 1 and 2 assignments to module 2 and add completion reqs
    item1_mod1 = modules[0].add_item({ id: @assignment.id, type: "assignment" })
    item1_mod2 = modules[1].add_item({ id: @assignment2.id, type: "assignment" })
    get "/courses/#{@course.id}/modules"
    # setting gui drag icons to pass to driver.action.drag_and_drop
    selector1 = "#context_module_item_#{item1_mod1.id} .move_item_link"
    selector2 = "#context_module_item_#{item1_mod2.id} .move_item_link"
    # performs the change position
    js_drag_and_drop(selector2, selector1)
    list_post_drag = ff("a.title").map(&:text)
    # validates the module 1 assignments are in the expected places and that module 2 context_module_items isn't present
    expect(list_post_drag[0]).to eq "assignment 2"
    expect(list_post_drag[1]).to eq "assignment 1"
    expect(f("#content")).not_to contain_css("#context_modules .context_module:last-child .context_module_items .context_module_item")
  end

  it "deletes a module item", priority: "1" do
    add_existing_module_item("AssignmentModule", @assignment)
    get "/courses/#{@course.id}/modules"
    f(".context_module_item .al-trigger").click
    f(".delete_item_link").click
    expect(driver.switch_to.alert).not_to be_nil
    driver.switch_to.alert.accept
    expect(f(".context_module_items")).not_to include_text(@assignment.title)
  end

  it "edits a module item and validate the changes stick", priority: "1" do
    add_existing_module_item("AssignmentModule", @assignment)
    get "/courses/#{@course.id}/modules"

    tag = ContentTag.last
    module_item = fj("#context_module_item_#{tag.id}:contains(#{@assignment.title})")
    item_edit_text = "Assignment Edit 1"
    edit_module_item(module_item) do |edit_form|
      replace_content(edit_form.find_element(:id, "content_tag_title"), item_edit_text)
    end
    module_item = f("#context_module_item_#{tag.id}")
    expect(module_item).to include_text(item_edit_text)

    get "/courses/#{@course.id}/assignments/#{@assignment.id}"
    expect(f("h1.title").text).to eq item_edit_text

    expect_new_page_load { f(".modules").click }
    expect(f("#context_module_item_#{tag.id} .title").text).to eq item_edit_text
  end

  it "renames all instances of an item" do
    2.times do
      add_existing_module_item("AssignmentModule", @assignment)
    end
    uncollapse_all_modules(@course, @user)

    get "/courses/#{@course.id}/modules"

    tag = ContentTag.last
    item2 = fj("#context_module_item_#{tag.id}:contains(#{@assignment.title})")

    edit_module_item(item2) do |edit_form|
      replace_content(edit_form.find_element(:id, "content_tag_title"), "renamed assignment")
    end
    all_items = ff(".context_module_item.Assignment_#{@assignment.id}")
    expect(all_items.size).to eq 2
    all_items.each { |i| expect(i.find_element(:css, ".title").text).to eq "renamed assignment" }
    expect(@assignment.reload.title).to eq "renamed assignment"
    run_jobs
    @assignment.context_module_tags.each { |cmtag| expect(cmtag.title).to eq "renamed assignment" }

    # reload the page and renaming should still work on existing items
    mod = add_existing_module_item("AssignmentModule", @assignment)
    uncollapse_modules([mod], @user)

    get "/courses/#{@course.id}/modules"
    tag = ContentTag.last
    item3 = fj("#context_module_item_#{tag.id}:contains(#{@assignment.title})")

    edit_module_item(item3) do |edit_form|
      replace_content(edit_form.find_element(:id, "content_tag_title"), "again")
    end
    all_items = ff(".context_module_item.Assignment_#{@assignment.id}")
    expect(all_items.size).to eq 3
    all_items.each { |i| expect(i.find_element(:css, ".title").text).to eq "again" }
    expect(@assignment.reload.title).to eq "again"
    run_jobs
    @assignment.context_module_tags.each { |cmtag| expect(cmtag.title).to eq "again" }
  end

  it "publishes a newly created item", :xbrowser do
    new_module = @course.context_modules.create!(name: "Content Page")
    wiki_page = @course.wiki_pages.create!(title: "New Page Title", body: "Here is the body", workflow_state: "unpublished")
    new_module.add_item({ id: wiki_page.id, type: "wiki_page" })
    get "/courses/#{@course.id}/modules"

    tag = ContentTag.last
    item = f("#context_module_item_#{tag.id}")
    item.find_element(:css, ".publish-icon").click
    wait_for_ajax_requests

    expect(tag.reload).to be_published
  end

  it "adds the 'with-completion-requirements' class to rows that have requirements" do
    mod = @course.context_modules.create! name: "TestModule"
    tag = mod.add_item({ id: @assignment.id, type: "assignment" })

    mod.completion_requirements = { tag.id => { type: "must_view" } }
    mod.save

    get "/courses/#{@course.id}/modules"

    ig_rows = ff("#context_module_item_#{tag.id} .with-completion-requirements")
    expect(ig_rows).not_to be_empty
  end

  it "adds a new classic quiz to a module in a specific assignment group" do
    @course.context_modules.create!(name: "Quiz")
    get "/courses/#{@course.id}/modules"

    add_new_module_item_and_yield("#quizs_select", "Quiz", "[ Create Quiz ]", "New Quiz") do
      click_option("select[name='quiz[assignment_group_id]']", @ag2.name)
    end
    expect(@ag2.assignments.length).to eq 1
    expect(@ag2.assignments.first.title).to eq "New Quiz"
  end

  it "adds a text header to a module", priority: "1" do
    @course.context_modules.create!(name: "Text Header Module")
    get "/courses/#{@course.id}/modules"
    header_text = "new header text"
    f(".ig-header-admin .al-trigger").click
    f(".add_module_item_link").click
    select_module_item("#add_module_item_select", "Text Header")
    replace_content(f("#sub_header_title"), header_text)
    f(".add_item_button.ui-button").click
    tag = ContentTag.last
    module_item = f("#context_module_item_#{tag.id}")
    expect(module_item).to include_text(header_text)
  end

  it "allows adding an item twice" do
    item1 = add_existing_module_item("AssignmentModule", @assignment)
    item2 = add_existing_module_item("AssignmentModule", @assignment)
    uncollapse_all_modules(@course, @user)

    get "/courses/#{@course.id}/modules"

    all_items = ff(".context_module_item.Assignment_#{@assignment.id}")
    expect(item1).not_to eq item2
    expect(@assignment.reload.context_module_tags.size).to eq 2
    expect(all_items.size).to eq 2
  end

  it "allows adding an external tool item" do
    @course.context_modules.create!(name: "External Tool")
    get "/courses/#{@course.id}/modules"
    tag = add_new_external_item("External Tool", "www.instructure.com", "Instructure")
    expect(f("#context_module_item_#{tag.id}")).to have_attribute(:class, "context_external_tool")
  end

  it "does not save an invalid external tool", priority: "1" do
    @course.context_modules.create!(name: "Test Module")

    get "/courses/#{@course.id}/modules"

    f(".ig-header-admin .al-trigger").click
    f(".add_module_item_link").click
    select_module_item("#add_module_item_select", "External Tool")
    f(".add_item_button.ui-button").click
    expect(ff(".alert.alert-error").length).to eq 1
    expect(fj(".alert.alert-error:visible").text).to eq "An external tool can't be saved without a URL."
  end

  it "shows the added pre requisites in the header of a module", priority: "1" do
    add_modules_and_set_prerequisites
    get "/courses/#{@course.id}/modules"
    expect(f(".item-group-condensed:nth-of-type(3) .ig-header .prerequisites_message").text)
      .to eq "Prerequisites: #{@module1.name}, #{@module2.name}"
  end

  it "rearranges modules" do
    m1 = @course.context_modules.create!(name: "module 1")
    m2 = @course.context_modules.create!(name: "module 2")
    uncollapse_all_modules(@course, @user)

    get "/courses/#{@course.id}/modules"
    sleep 2 # not sure what we are waiting on but drag and drop will not work, unless we wait
    wait_for_ajax_requests

    m1_handle = fj("#context_modules .context_module:first-child .reorder_module_link .icon-drag-handle")
    m2_handle = fj("#context_modules .context_module:last-child .content")
    driver.action.drag_and_drop(m1_handle, m2_handle).perform
    wait_for_ajax_requests

    m1.reload
    expect(m1.position).to eq 2
    m2.reload
    expect(m2.position).to eq 1
  end

  it "validates locking a module item display functionality with differentiated modules" do
    m1 = @course.context_modules.create!(name: "module 1")

    go_to_modules
    manage_module_button(m1).click
    module_index_menu_tool_link("Edit").click

    click_lock_until_checkbox
    expect(element_exists?(lock_until_input_selector)).to be_truthy

    # verify unlock
    click_lock_until_checkbox
    wait_for_ajaximations
    expect(element_exists?(lock_until_input_selector)).to be_falsey
  end

  it "properly changes indent of an item with arrows" do
    add_existing_module_item("AssignmentModule", @assignment)
    tag = ContentTag.last

    get "/courses/#{@course.id}/modules"

    f("#context_module_item_#{tag.id} .al-trigger").click
    f(".indent_item_link").click
    expect(f("#context_module_item_#{tag.id}")).to have_class("indent_1")
    tag.reload
    expect(tag.indent).to eq 1
  end

  it "properly changes indent of an item from edit dialog" do
    add_existing_module_item("AssignmentModule", @assignment)
    tag = ContentTag.last
    get "/courses/#{@course.id}/modules"

    f("#context_module_item_#{tag.id} .al-trigger").click
    f(".edit_item_link").click
    click_option("#content_tag_indent_select", "Indent 1 Level")
    form = f("#edit_item_form")
    form.submit
    wait_for_ajaximations
    expect(f("#context_module_item_#{tag.id}")).to have_class("indent_1")

    tag.reload
    expect(tag.indent).to eq 1
  end

  describe "expand|collapse all" do
    before do
      @modules = create_modules(2, true)
      @modules[0].add_item({ id: @assignment.id, type: "assignment" })
      @modules[1].add_item({ id: @assignment2.id, type: "assignment" })
    end

    it "collapses all modules" do
      go_to_modules
      wait_for_dom_ready
      expect(all_expanded_modules.size).to be > 0
      expand_collapse_all_button.click
      wait_for_ajaximations
      expect(all_collapsed_modules).to have_size(2)
      expect(f("#context_modules")).not_to contain_css(all_expanded_modules_selector)
    end

    it "expands all modules" do
      progression = @modules[0].find_or_create_progression(@teacher)
      progression.collapse!
      progression = @modules[1].find_or_create_progression(@teacher)
      progression.collapse!

      go_to_modules
      wait_for_dom_ready
      expect(all_collapsed_modules).to have_size(2)
      expect(f("#context_modules")).not_to contain_css(all_expanded_modules_selector)
      expand_collapse_all_button.click
      wait_for_ajaximations
      expect(all_expanded_modules).to have_size(2)
      expect(f("#context_modules")).not_to contain_css(all_collapsed_modules_selector)
      expect(ff(module_items_selector(@modules[0].id)).size).to be > 0
      expect(ff(module_items_selector(@modules[1].id)).size).to be > 0
    end
  end

  context "multiple overridden due dates", priority: "2" do
    def create_section_override(section, due_at)
      override = assignment_override_model(assignment: @assignment)
      override.set = section
      override.override_due_at(due_at)
      override.save!
    end

    it "indicates when course sections have multiple due dates" do
      modules = create_modules(1, true)
      modules[0].add_item({ id: @assignment.id, type: "assignment" })

      cs1 = @course.default_section
      cs2 = @course.course_sections.create!

      create_section_override(cs1, 3.days.from_now)
      create_section_override(cs2, 4.days.from_now)

      get "/courses/#{@course.id}/modules"

      expect(f(".due_date_display").text).to eq "Multiple Due Dates"
    end

    it "does not indicate multiple due dates if the sections' dates are the same" do
      skip("needs to ignore base if all visible sections are overridden")
      modules = create_modules(1, true)
      modules[0].add_item({ id: @assignment.id, type: "assignment" })

      cs1 = @course.default_section
      cs2 = @course.course_sections.create!

      due_at = 3.days.from_now
      create_section_override(cs1, due_at)
      create_section_override(cs2, due_at)

      get "/courses/#{@course.id}/modules"

      expect(f(".due_date_display").text).not_to be_blank
      expect(f(".due_date_display").text).not_to eq "Multiple Due Dates"
    end

    it "uses assignment due date if there is no section override" do
      modules = create_modules(1, true)
      modules[0].add_item({ id: @assignment.id, type: "assignment" })

      cs1 = @course.default_section
      @course.course_sections.create!

      due_at = 3.days.from_now
      create_section_override(cs1, due_at)
      @assignment.due_at = due_at
      @assignment.save!

      get "/courses/#{@course.id}/modules"
      expect(f(".due_date_display").text).not_to be_blank
      expect(f(".due_date_display").text).not_to eq "Multiple Due Dates"
    end

    it "only uses the sections the user is restricted to" do
      skip("needs to ignore base if all visible sections are overridden")
      modules = create_modules(1, true)
      modules[0].add_item({ id: @assignment.id, type: "assignment" })

      cs1 = @course.default_section
      cs2 = @course.course_sections.create!
      cs3 = @course.course_sections.create!

      user_logged_in
      @course.enroll_user(@user, "TaEnrollment", section: cs1, allow_multiple_enrollments: true, limit_privileges_to_course_section: true).accept!
      @course.enroll_user(@user, "TaEnrollment", section: cs2, allow_multiple_enrollments: true, limit_privileges_to_course_section: true).accept!

      due_at = 3.days.from_now
      create_section_override(cs1, due_at)
      create_section_override(cs2, due_at)
      create_section_override(cs3, due_at + 1.day) # This override should not matter

      get "/courses/#{@course.id}/modules"

      expect(f(".due_date_display").text).not_to be_blank
      expect(f(".due_date_display").text).not_to eq "Multiple Due Dates"
    end

    context "in a paced course" do
      before do
        @course.enable_course_paces = true
        @course.save!
      end

      after do
        @course.enable_course_paces = false
      end

      it "does not show due dates" do
        modules = create_modules(1, true)
        modules[0].add_item({ id: @assignment.id, type: "assignment", title: "An Assignment" })

        @assignment.due_at = 3.days.from_now
        @assignment.save!

        get "/courses/#{@course.id}/modules"

        wait_for_ajaximations

        expect(fj(".context_module:contains('An Assignment')")).to be_displayed
        expect(f(".context_module")).not_to contain_css(".due_date_display")
      end
    end
  end

  it "shows a vdd tooltip summary for assignments with multiple due dates" do
    selector = "li.Assignment_#{@assignment2.id} .due_date_display"
    add_existing_module_item("AssignmentModule", @assignment2)
    get "/courses/#{@course.id}/modules"

    expect(f(selector)).not_to include_text "Multiple Due Dates"

    # add a second due date
    new_section = @course.course_sections.create!(name: "New Section")
    override = @assignment2.assignment_overrides.build
    override.set = new_section
    override.due_at = 1.day.from_now
    override.due_at_overridden = true
    override.save!

    get "/courses/#{@course.id}/modules"
    expect(f(selector)).to include_text "Multiple Due Dates"
    driver.action.move_to(f("#{selector} a")).perform
    wait_for_ajaximations

    tooltip = fj(".vdd_tooltip_content:visible")
    expect(tooltip).to include_text "1 Section"
    expect(tooltip).to include_text "Everyone else"
  end

  # ignoring "Warning: unmountComponentAtNode is deprecated" console message
  it "publishes a file from the modules page", :ignore_js_errors, priority: "1" do
    @module = @course.context_modules.create!(name: "some module")
    @file = @course.attachments.create!(display_name: "some file", uploaded_data: default_uploaded_data, locked: true)
    @tag = @module.add_item({ id: @file.id, type: "attachment" })
    expect(@file.reload).not_to be_published
    get "/courses/#{@course.id}/modules"
    f("[data-id='#{@file.id}'] > button.published-status").click
    ff(".permissions-dialog-form input[name='permissions']")[0].click
    f(".permissions-dialog-form [type='submit']").click
    wait_for_ajaximations
    refresh_page
    expect(f("[aria-label='some file is Published - Click to modify']")).to be_displayed
  end

  it "shows the file publish button on course home" do
    @course.default_view = "modules"
    @course.save!

    @module = @course.context_modules.create!(name: "some module")
    @file = @course.attachments.create!(display_name: "some file", uploaded_data: default_uploaded_data)
    @tag = @module.add_item({ id: @file.id, type: "attachment" })

    get "/courses/#{@course.id}"
    expect(f(".context_module_item.attachment .icon-publish")).to be_displayed
  end

  it "renders publish buttons in collapsed modules" do
    @module = @course.context_modules.create! name: "collapsed"
    @module.add_item(type: "assignment", id: @assignment2.id)
    @progression = @module.evaluate_for(@user)
    @progression.collapsed = true
    @progression.save!
    get "/courses/#{@course.id}/modules"
    f(".expand_module_link").click
    expect(f(".context_module_item.assignment .icon-publish")).to be_displayed
  end

  it "adds a discussion item to a module", priority: "1" do
    @course.context_modules.create!(name: "New Module")
    get "/courses/#{@course.id}/modules"
    add_new_module_item_and_yield("#discussion_topics_select", "Discussion", "[ Create Topic ]", "New Discussion Title")
    verify_persistence("New Discussion Title")
  end

  it "adds an external url item to a module", priority: "1" do
    @course.context_modules.create!(name: "New Module")
    get "/courses/#{@course.id}/modules"
    add_new_external_item("External URL", "www.google.com", "Google")
    expect(fln("Google")).to be_displayed
  end

  it "requires a url for external url items" do
    @course.context_modules.create!(name: "New Module")
    get "/courses/#{@course.id}/modules"
    f(".ig-header-admin .al-trigger").click
    f(".add_module_item_link").click

    click_option("#add_module_item_select", "external_url", :value)

    title_input = fj('input[name="title"]:visible')
    replace_content(title_input, "some title")
    scroll_to(f(".add_item_button.ui-button"))
    f(".add_item_button.ui-button").click

    expect(f(".errorBox:not(#error_box_template)")).to be_displayed

    expect(f("#select_context_content_dialog")).to be_displayed
  end

  it "adds an external tool item to a module", priority: "1" do
    @course.context_modules.create!(name: "New Module")
    get "/courses/#{@course.id}/modules"
    add_new_external_item("External Tool", "www.instructure.com", "Instructure")
    expect(fln("Instructure")).to be_displayed
    expect(f("span.publish-icon.unpublished.publish-icon-publish > i.icon-unpublish")).to be_displayed
  end

  it "does not render links for subheader type items", priority: "1" do
    mod = @course.context_modules.create! name: "Test Module"
    tag = mod.add_item(title: "Example text header", type: "sub_header")
    get "/courses/#{@course.id}/modules"
    expect(f("#context_module_item_#{tag.id}")).not_to contain_css(".item_link")
  end

  it "renders links for wiki page type items", priority: "1" do
    mod = @course.context_modules.create! name: "Test Module"
    page = @course.wiki_pages.create title: "A Page"
    page.workflow_state = "unpublished"
    page.save!
    tag = mod.add_item({ id: page.id, type: "wiki_page" })
    get "/courses/#{@course.id}/modules"
    expect(f("#context_module_item_#{tag.id}")).to contain_css(".item_link")
  end

  it "duplicates a module" do
    module1 = @course.context_modules.create(name: "My Module")
    get "/courses/#{@course.id}/modules"

    expect(all_modules.length).to eq 1
    manage_module_button(module1).click
    duplicate_module_button(module1).click
    wait_for_ajaximations
    expect(all_modules.length).to eq 2
    expect(f("#flash_screenreader_holder")).not_to include_text("Error")
    # test that the duplicated module's buttons are functional
    module2 = @course.context_modules.reload.last
    add_module_item_button(module2).click
    expect(f("body")).to contain_jqcss('.ui-dialog:contains("Add Item to"):visible')
  end

  context "load in a new tab checkbox" do
    before :once do
      @course.context_modules.create!(name: "New Module")
    end

    it "is checked by default if module_links_default_new_tab is true for user" do
      @teacher.set_preference(:module_links_default_new_tab, true)
      get "/courses/#{@course.id}/modules"
      f(".add_module_item_link").click
      select_module_item("#add_module_item_select", "External URL")
      expect(is_checked(f("#external_url_create_new_tab"))).to be_truthy
      select_module_item("#add_module_item_select", "External Tool")
      expect(is_checked(f("#external_tool_create_new_tab"))).to be_truthy
    end

    it "is unchecked by default if module_links_default_new_tab is false for user" do
      @teacher.set_preference(:module_links_default_new_tab, false)
      get "/courses/#{@course.id}/modules"
      f(".add_module_item_link").click
      select_module_item("#add_module_item_select", "External URL")
      expect(is_checked(f("#external_url_create_new_tab"))).to be_falsey
      select_module_item("#add_module_item_select", "External Tool")
      expect(is_checked(f("#external_tool_create_new_tab"))).to be_falsey
    end

    it "is checked by default in new course after previously checking box" do
      @teacher.set_preference(:module_links_default_new_tab, false)
      get "/courses/#{@course.id}/modules"
      f(".add_module_item_link").click
      select_module_item("#add_module_item_select", "External URL")
      f("#content_tag_create_url").send_keys("http://example.com")
      f("#content_tag_create_title").send_keys("Example URL")
      f("#external_url_create_new_tab").click
      f(".add_item_button.ui-button").click
      expect(@teacher.reload.get_preference(:module_links_default_new_tab)).to be_truthy

      course_with_teacher(active_all: true, user: @teacher)
      @course.context_modules.create!(name: "New Module")
      get "/courses/#{@course.id}/modules"
      f(".add_module_item_link").click
      select_module_item("#add_module_item_select", "External URL")
      expect(is_checked(f("#external_url_create_new_tab"))).to be_truthy
      select_module_item("#add_module_item_select", "External Tool")
      expect(is_checked(f("#external_tool_create_new_tab"))).to be_truthy
    end
  end

  context "with quizzes_next flag enabled" do
    before :once do
      @course.enable_feature! :quizzes_next
      @course.context_external_tools.create!(
        name: "Quizzes.Next",
        consumer_key: "test_key",
        shared_secret: "test_secret",
        tool_id: "Quizzes 2",
        url: "http://example.com/launch"
      )
      @course.root_account.settings[:provision] = { "lti" => "lti url" }
      @course.root_account.save!
      @course.context_modules.create!(name: "Course Quizzes")
    end

    it "lets user select classic quiz or new quiz when new_quizzes_by_default is disabled" do
      @course.disable_feature! :new_quizzes_by_default
      get "/courses/#{@course.id}/modules"

      add_new_module_item_and_yield("#quizs_select", "Quiz", "[ Create Quiz ]", "A Classic Quiz") do
        expect(f("#quizs_select")).to contain_css("input[name=quiz_engine_selection]")
        expect(f("#quizs_select .new")).to include_text("New Quizzes")
        expect(f("#quizs_select .new")).to include_text("Classic Quizzes")
        f("label[for=classic_quizzes_radio]").click
      end
      expect(ContentTag.last.content.is_a?(Quizzes::Quiz)).to be_truthy
    end

    it "creates a new quiz by default when new_quizzes_by_default is enabled" do
      @course.enable_feature! :new_quizzes_by_default
      get "/courses/#{@course.id}/modules"

      add_new_module_item_and_yield("#quizs_select", "Quiz", "[ Create Quiz ]", "A New Quiz") do
        expect(f("#quizs_select")).not_to contain_css("input[name=quiz_engine_selection]")
        expect(f("#quizs_select .new")).not_to include_text("New Quizzes")
        expect(f("#quizs_select .new")).not_to include_text("Classic Quizzes")
      end
      expect(ContentTag.last.content.is_a?(Assignment)).to be_truthy
    end

    it "creates a new quiz by default when both new_quizzes_by_default and require_migration is enabled" do
      @course.enable_feature! :new_quizzes_by_default
      @course.root_account.enable_feature! :require_migration_to_new_quizzes
      get "/courses/#{@course.id}/modules"

      add_new_module_item_and_yield("#quizs_select", "Quiz", "[ Create Quiz ]", "A New Quiz") do
        expect(f("#quizs_select")).not_to contain_css("input[name=quiz_engine_selection]")
        expect(f("#quizs_select .new")).not_to include_text("New Quizzes")
        expect(f("#quizs_select .new")).not_to include_text("Classic Quizzes")
      end
      expect(ContentTag.last.content.is_a?(Assignment)).to be_truthy
    end
  end

  context "with discussion_checkpoints enabled" do
    before :once do
      @course.root_account.enable_feature! :discussion_checkpoints
      @modules = create_modules(1, true)

      @topic = DiscussionTopic.create_graded_topic!(course: @course, title: "checkpointed topic")
    end

    it "shows checkpoint data in module item info section" do
      @modules[0].add_item({ id: @topic.id, type: "discussion_topic" })
      c1 = Checkpoints::DiscussionCheckpointCreatorService.call(
        discussion_topic: @topic,
        checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
        dates: [{ type: "everyone", due_at: 5.years.ago }],
        points_possible: 5
      )
      c2 = Checkpoints::DiscussionCheckpointCreatorService.call(
        discussion_topic: @topic,
        checkpoint_label: CheckpointLabels::REPLY_TO_ENTRY,
        dates: [{ type: "everyone", due_at: 5.years.ago }],
        points_possible: 5,
        replies_required: 2
      )
      get "/courses/#{@course.id}/modules"
      expect(f("span.item_name").text).to include @topic.title
      details = f("div.ig-details").text
      expect(details).to eq "Reply to Topic: #{date_string(c1.due_at)}\nRequired Replies (#{@topic.reply_to_entry_required_count}): #{date_string(c2.due_at)}\n#{@topic.assignment.points_possible.to_i} pts"
    end

    it "does not show due dates when the enable_course_paces is set to true" do
      @modules[0].add_item({ id: @topic.id, type: "discussion_topic" })
      @course.enable_course_paces = true
      @course.save!

      Checkpoints::DiscussionCheckpointCreatorService.call(
        discussion_topic: @topic,
        checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
        dates: [{ type: "everyone", due_at: 5.years.ago }],
        points_possible: 5
      )
      Checkpoints::DiscussionCheckpointCreatorService.call(
        discussion_topic: @topic,
        checkpoint_label: CheckpointLabels::REPLY_TO_ENTRY,
        dates: [{ type: "everyone", due_at: 5.years.ago }],
        points_possible: 5,
        replies_required: 2
      )

      get "/courses/#{@course.id}/modules"
      expect(f("span.item_name").text).to include @topic.title
      details = f("div.ig-details").text
      expect(details).to eq "Reply to Topic\nRequired Replies (2)\n10 pts"
    end

    it "shows multiple due dates as a hoverable link within each checkpoint" do
      @modules[0].add_item({ id: @topic.id, type: "discussion_topic" })
      student_in_course(active_all: true)
      sec1 = add_section("sec1")
      sec2 = add_section("sec2")

      c1due_at = 5.years.ago
      c1o1due_at = c1due_at + 1.day
      c1o2due_at = c1due_at + 2.days

      Checkpoints::DiscussionCheckpointCreatorService.call(
        discussion_topic: @topic,
        checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
        dates: [
          {
            type: "everyone", due_at: c1due_at
          },
          {
            type: "override", set_type: "CourseSection", due_at: c1o1due_at, set_id: sec1.id
          },
          {
            type: "override", set_type: "CourseSection", due_at: c1o2due_at, set_id: sec2.id
          }
        ],
        points_possible: 5
      )

      c2due_at = 4.years.ago
      c2o1due_at = c2due_at + 1.day
      c2o2due_at = c2due_at + 2.days

      Checkpoints::DiscussionCheckpointCreatorService.call(
        discussion_topic: @topic,
        checkpoint_label: CheckpointLabels::REPLY_TO_ENTRY,
        dates: [
          {
            type: "everyone", due_at: c2due_at
          },
          {
            type: "override", set_type: "CourseSection", due_at: c2o1due_at, set_id: sec1.id
          },
          {
            type: "override", set_type: "CourseSection", due_at: c2o2due_at, set_id: sec2.id
          }
        ],
        points_possible: 5,
        replies_required: 2
      )

      get "/courses/#{@course.id}/modules"

      hover(f(".reply_to_topic_display a"))
      rtt_tooltip_els = ff("[class*='vdd_tooltip_']")
      expect(rtt_tooltip_els.first.text).to include "Multiple Due Dates"
      expect(rtt_tooltip_els.last.text).to eq "Everyone else\n#{datetime_string(c1due_at)}\n#{sec1.name}\n#{datetime_string(c1o1due_at)}\n#{sec2.name}\n#{datetime_string(c1o2due_at)}"

      hover(f(".reply_to_entry_display a"))
      rte_tooltip_els = ff("[class*='vdd_tooltip_']")
      expect(rte_tooltip_els.first.text).to include "Multiple Due Dates"
      expect(rte_tooltip_els.last.text).to eq "Everyone else\n#{datetime_string(c2due_at)}\n#{sec1.name}\n#{datetime_string(c2o1due_at)}\n#{sec2.name}\n#{datetime_string(c2o2due_at)}"

      stub_const("Api::V1::Assignment::ALL_DATES_LIMIT", 1)
      get "/courses/#{@course.id}/modules"

      expect(f("body")).not_to contain_jqcss(".reply_to_topic_display a")
      expect(f(".ig-details").text).to eq "Reply to Topic: Multiple Due Dates\nRequired Replies (2): Multiple Due Dates\n10 pts"
    end

    it "shows due dates when newly added" do
      c1 = Checkpoints::DiscussionCheckpointCreatorService.call(
        discussion_topic: @topic,
        checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
        dates: [{ type: "everyone", due_at: 5.years.ago }],
        points_possible: 5
      )
      c2 = Checkpoints::DiscussionCheckpointCreatorService.call(
        discussion_topic: @topic,
        checkpoint_label: CheckpointLabels::REPLY_TO_ENTRY,
        dates: [{ type: "everyone", due_at: 5.years.ago }],
        points_possible: 5,
        replies_required: 2
      )

      get "/courses/#{@course.id}/modules"
      add_new_module_item_and_yield("#discussion_topics_select", "Discussion", @topic.title)
      details = f("div.ig-details").text
      expect(details).to include "Reply to Topic: #{date_string(c1.due_at)}\nRequired Replies (#{@topic.reply_to_entry_required_count}): #{date_string(c2.due_at)}"
    end

    it "can duplicate modules with checkpointed discussions" do
      @modules[0].add_item({ id: @topic.id, type: "discussion_topic" })

      c1 = Checkpoints::DiscussionCheckpointCreatorService.call(
        discussion_topic: @topic,
        checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
        dates: [{ type: "everyone", due_at: 5.years.ago }],
        points_possible: 5
      )
      c2 = Checkpoints::DiscussionCheckpointCreatorService.call(
        discussion_topic: @topic,
        checkpoint_label: CheckpointLabels::REPLY_TO_ENTRY,
        dates: [{ type: "everyone", due_at: 5.years.ago }],
        points_possible: 5,
        replies_required: 2
      )

      get "/courses/#{@course.id}/modules"
      f("button[aria-label='Manage #{@modules[0].name}']").click
      fj("li:contains('Duplicate')").click
      wait_for_ajaximations
      duplicate_module = ContextModule.last
      expect(duplicate_module.name).to eq "#{@modules[0].name} Copy"
      duplicate_discussion = duplicate_module.content_tags.first.content
      expect(duplicate_discussion).not_to eq @topic
      expect(duplicate_discussion.reply_to_topic_checkpoint).not_to eq c1
      expect(duplicate_discussion.reply_to_entry_checkpoint).not_to eq c2

      # check that due dates are still equal to the original checkpoints' due dates
      details = f("div.ig-details").text
      expect(details).to eq "Reply to Topic: #{date_string(c1.due_at)}\nRequired Replies (#{@topic.reply_to_entry_required_count}): #{date_string(c2.due_at)}\n10 pts"
    end

    it "Shows the correct dates inputs in the assign to tray", :ignore_js_errors do
      @modules[0].add_item({ id: @topic.id, type: "discussion_topic" })
      Checkpoints::DiscussionCheckpointCreatorService.call(
        discussion_topic: @topic,
        checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
        dates: [{ type: "everyone", due_at: 5.years.ago }],
        points_possible: 5
      )
      Checkpoints::DiscussionCheckpointCreatorService.call(
        discussion_topic: @topic,
        checkpoint_label: CheckpointLabels::REPLY_TO_ENTRY,
        dates: [{ type: "everyone", due_at: 5.years.ago }],
        points_possible: 5,
        replies_required: 2
      )
      get "/courses/#{@course.id}/modules"
      checkpointed_item = @modules[0].content_tags.first
      manage_module_item_button(checkpointed_item).click
      click_manage_module_item_assign_to(checkpointed_item)
      wait_for_assign_to_tray_spinner
      expect(module_item_assign_to_card.first).not_to contain_css(due_date_input_selector)
      expect(module_item_assign_to_card.first).to contain_css(reply_to_topic_due_date_input_selector)
      expect(module_item_assign_to_card.first).to contain_css(required_replies_due_date_input_selector)
    end
  end
end
