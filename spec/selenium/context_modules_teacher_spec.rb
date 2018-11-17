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

require File.expand_path(File.dirname(__FILE__) + '/helpers/context_modules_common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/public_courses_context')

describe "context modules" do
  include_context "in-process server selenium tests"
  include ContextModulesCommon

  context "as a teacher", priority: "1" do
    before(:once) do
      course_with_teacher(active_all: true)
      # have to add quiz and assignment to be able to add them to a new module
      @quiz = @course.assignments.create!(:title => 'quiz assignment', :submission_types => 'online_quiz')
      @assignment = @course.assignments.create!(:title => 'assignment 1', :submission_types => 'online_text_entry')
      @assignment2 = @course.assignments.create!(:title => 'assignment 2',
        :submission_types => 'online_text_entry',
        :due_at => 2.days.from_now,
        :points_possible => 10)
      @assignment3 = @course.assignments.create!(:title => 'assignment 3', :submission_types => 'online_text_entry')

      @ag1 = @course.assignment_groups.create!(:name => "Assignment Group 1")
      @ag2 = @course.assignment_groups.create!(:name => "Assignment Group 2")

      @course.reload
    end

    before(:each) do
      user_session(@teacher)
    end

    def module_with_two_items
      modules = create_modules(1, true)
      modules[0].add_item({id: @assignment.id, type: 'assignment'})
      modules[0].add_item({id: @assignment2.id, type: 'assignment'})
      get "/courses/#{@course.id}/modules"
      f(".collapse_module_link[aria-controls='context_module_content_#{modules[0].id}']").click
      wait_for_ajaximations
    end

    it "should show all module items", priority: "1", test_id: 126743 do
      module_with_two_items
      f(".expand_module_link").click
      wait_for_animations
      expect(f('.context_module .content')).to be_displayed
    end

    it "expands/collapses module with 0 items", priority: "2", test_id: 126731 do
      modules = create_modules(1, true)
      get "/courses/#{@course.id}/modules"
      f(".collapse_module_link[aria-controls='context_module_content_#{modules[0].id}']").click
      expect(f('.icon-mini-arrow-down')).to be_displayed
    end

    it "should hide module items", priority: "1", test_id: 280415 do
      module_with_two_items
      wait_for_animations
      expect(f('.context_module .content')).not_to be_displayed
    end

    it "should create a new module using enter key", priority: "2", test_id: 126705 do
      get "/courses/#{@course.id}/modules"
      add_form = new_module_form
      replace_content(add_form.find_element(:id, 'context_module_name'), "module 1")
      3.times do
        driver.action.send_keys(:tab).perform
        wait_for_ajaximations
      end
      driver.action.send_keys(:return).perform
      expect(f('.name')).to be_present
    end

    it "should rearrange child objects in same module", priority: "1", test_id: 126733 do
      modules = create_modules(1, true)
      # attach 1 assignment to module 1 and 2 assignments to module 2 and add completion reqs
      item1 = modules[0].add_item({:id => @assignment.id, :type => 'assignment'})
      item2 = modules[0].add_item({:id => @assignment2.id, :type => 'assignment'})
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

    it "should rearrange child object to new module", priority: "1", test_id: 126734 do
      modules = create_modules(2, true)
      # attach 1 assignment to module 1 and 2 assignments to module 2 and add completion reqs
      item1_mod1 = modules[0].add_item({:id => @assignment.id, :type => 'assignment'})
      item1_mod2 = modules[1].add_item({:id => @assignment2.id, :type => 'assignment'})
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
      expect(f("#content")).not_to contain_css('#context_modules .context_module:last-child .context_module_items .context_module_item')
    end

    it "should only display out-of on an assignment min score restriction when the assignment has a total" do
      ag = @course.assignment_groups.create!
      a1 = ag.assignments.create!(:context => @course)
      a1.points_possible = 10
      a1.save
      a2 = ag.assignments.create!(:context => @course)
      m = @course.context_modules.create!

      make_content_tag = lambda do |assignment|
        ct = ContentTag.new
        ct.content_id = assignment.id
        ct.content_type = 'Assignment'
        ct.context_id = @course.id
        ct.context_type = 'Course'
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

      f('.ig-header-admin  .al-trigger').click
      hover_and_click('#context_modules .edit_module_link')
      wait_for_animations
      expect(f('#add_context_module_form')).to be_displayed
      f('.add_completion_criterion_link').click
      wait_for_animations
      fj(".assignment_picker:visible option[value='#{content_tag_1.id}']").click
      fj('.assignment_requirement_picker:visible option[value="min_score"]').click
      expect(f("body")).to contain_jqcss(".points_possible_parent:visible")

      fj(".assignment_picker:visible option[value='#{content_tag_2.id}']").click
      fj('.assignment_requirement_picker:visible option[value="min_score"]').click
      expect(f("body")).not_to contain_jqcss(".points_possible_parent:visible")
    end

    it "should add and remove completion criteria" do
      get "/courses/#{@course.id}/modules"
      add_existing_module_item('#assignments_select', 'Assignment', @assignment.title)

      @course.reload
      smodule = @course.context_modules.first
      smodule.publish!
      # add completion criterion
      f('.ig-header-admin .al-trigger').click
      f('.edit_module_link').click
      wait_for_ajaximations
      edit_form = f('#add_context_module_form')
      expect(edit_form).to be_displayed
      f('.add_completion_criterion_link', edit_form).click
      wait_for_ajaximations
      check_element_has_focus f("#add_context_module_form .assignment_picker")
      # be_disabled
      expect(f('#add_context_module_form .assignment_requirement_picker option[value=must_contribute]')).to be_disabled
      click_option('#add_context_module_form .assignment_picker', @assignment.title, :text)
      click_option('#add_context_module_form .assignment_requirement_picker', 'must_submit', :value)

      submit_form(edit_form)
      expect(edit_form).not_to be_displayed
      # should show relock warning since we're adding a completion requirement to an active module
      test_relock

      # verify it was added
      smodule.reload
      expect(smodule).not_to be_nil
      expect(smodule.completion_requirements).not_to be_empty
      expect(smodule.completion_requirements[0][:type]).to eq 'must_submit'

      # delete the criterion, then cancel the form
      f('.ig-header-admin .al-trigger').click
      wait_for_ajaximations
      f('.edit_module_link').click
      wait_for_ajaximations
      edit_form = f('#add_context_module_form')
      expect(edit_form).to be_displayed
      f('.completion_entry .delete_criterion_link', edit_form).click
      ff('.cancel_button', dialog_for(edit_form)).last.click

      # now delete the criterion frd
      # (if the previous step did even though it shouldn't have, this will error)
      f('.ig-header-admin .al-trigger').click
      f('.edit_module_link').click
      edit_form = f('#add_context_module_form')
      expect(edit_form).to be_displayed
      f('.completion_entry .delete_criterion_link', edit_form).click
      wait_for_ajaximations
      submit_form(edit_form)
      wait_for_ajax_requests

      # verify it's gone
      @course.reload
      expect(@course.context_modules.first.completion_requirements).to eq []

      # and also make sure the form remembers that it's gone (#8329)
      f('.ig-header-admin .al-trigger').click
      f('.edit_module_link').click
      edit_form = f('#add_context_module_form')
      expect(edit_form).to be_displayed
      expect(f('.completion_entry')).not_to contain_jqcss('.delete_criterion_link:visible')
    end

    it "should delete a module item", priority: "1", test_id: 126739 do
      get "/courses/#{@course.id}/modules"

      add_existing_module_item('#assignments_select', 'Assignment', @assignment.title)
      f('.context_module_item .al-trigger').click()
      f('.delete_item_link').click
      expect(driver.switch_to.alert).not_to be_nil
      driver.switch_to.alert.accept
      expect(f('.context_module_items')).not_to include_text(@assignment.title)
    end

    it "should edit a module item and validate the changes stick", priority: "1", test_id: 126737 do
      get "/courses/#{@course.id}/modules"

      item_edit_text = "Assignment Edit 1"
      module_item = add_existing_module_item('#assignments_select', 'Assignment', @assignment.title)
      tag = ContentTag.last
      edit_module_item(module_item) do |edit_form|
        replace_content(edit_form.find_element(:id, 'content_tag_title'), item_edit_text)
      end
      module_item = f("#context_module_item_#{tag.id}")
      expect(module_item).to include_text(item_edit_text)

      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      expect(f('h1.title').text).to eq item_edit_text

      expect_new_page_load { f('.modules').click }
      expect(f("#context_module_item_#{tag.id} .title").text).to eq item_edit_text
    end

    it "should focus close button on open edit modal" do
      get "/courses/#{@course.id}/modules"

      module_item = add_existing_module_item('#assignments_select', 'Assignment', @assignment.title)
      edit_module_item(module_item) do
        divs = ff('.ui-dialog-titlebar.ui-widget-header.ui-corner-all.ui-helper-clearfix')
        close_button = nil

        divs.each do |div|
          title_span = div.find_element(:css, '.ui-dialog-title')
          if title_span.text == "Edit Item Details"
            close_button = div.find_element(:css, '.ui-dialog-titlebar-close.ui-corner-all')
          end
        end
        check_element_has_focus(close_button)
      end
    end

    it "should rename all instances of an item" do
      get "/courses/#{@course.id}/modules"

      add_existing_module_item('#assignments_select', 'Assignment', @assignment.title)
      item2 = add_existing_module_item('#assignments_select', 'Assignment', @assignment.title)
      edit_module_item(item2) do |edit_form|
        replace_content(edit_form.find_element(:id, 'content_tag_title'), "renamed assignment")
      end
      all_items = ff(".context_module_item.Assignment_#{@assignment.id}")
      expect(all_items.size).to eq 2
      all_items.each { |i| expect(i.find_element(:css, '.title').text).to eq 'renamed assignment' }
      expect(@assignment.reload.title).to eq 'renamed assignment'
      run_jobs
      @assignment.context_module_tags.each { |tag| expect(tag.title).to eq 'renamed assignment' }

      # reload the page and renaming should still work on existing items
      get "/courses/#{@course.id}/modules"
      item3 = add_existing_module_item('#assignments_select', 'Assignment', @assignment.title)
      edit_module_item(item3) do |edit_form|
        replace_content(edit_form.find_element(:id, 'content_tag_title'), "again")
      end
      all_items = ff(".context_module_item.Assignment_#{@assignment.id}")
      expect(all_items.size).to eq 3
      all_items.each { |i| expect(i.find_element(:css, '.title').text).to eq 'again' }
      expect(@assignment.reload.title).to eq 'again'
      run_jobs
      @assignment.context_module_tags.each { |tag| expect(tag.title).to eq 'again' }
    end

    it "should not create a duplicate page if you publish after renaming" do
      mod = @course.context_modules.create! name: 'TestModule'
      page = @course.wiki_pages.create title: 'A Page'
      page.workflow_state = 'unpublished'
      page.save!
      page_count = @course.wiki_pages.count
      tag = mod.add_item({:id => page.id, :type => 'wiki_page'})

      get "/courses/#{@course.id}/modules"

      item = f("#context_module_item_#{tag.id}")
      edit_module_item(item) do |edit_form|
        replace_content(edit_form.find_element(:id, 'content_tag_title'), 'Renamed!')
      end

      item = f("#context_module_item_#{tag.id}")
      item.find_element(:css, '.publish-icon').click
      wait_for_ajax_requests

      expect(@course.wiki_pages.count).to eq page_count
      expect(page.reload).to be_published
    end

    it "publishes a newly created item" do
      @course.context_modules.create!(name: "Content Page")
      get "/courses/#{@course.id}/modules"
      add_new_module_item('#wiki_pages_select', 'Page', '[ New Page ]', 'New Page Title')

      tag = ContentTag.last
      item = f("#context_module_item_#{tag.id}")
      item.find_element(:css, '.publish-icon').click
      wait_for_ajax_requests

      expect(tag.reload).to be_published
    end

    it "should add the 'with-completion-requirements' class to rows that have requirements" do
      mod = @course.context_modules.create! name: 'TestModule'
      tag = mod.add_item({:id => @assignment.id, :type => 'assignment'})

      mod.completion_requirements = {tag.id => {:type => 'must_view'}}
      mod.save

      get "/courses/#{@course.id}/modules"

      ig_rows = ff("#context_module_item_#{tag.id} .with-completion-requirements")
      expect(ig_rows).not_to be_empty
    end

    it "should add a title attribute to the text header" do
      text_header = 'This is a really long module text header that should be truncated to exactly 98 characters plus the ... part so 101 characters really'
      mod = @course.context_modules.create! name: 'TestModule'
      tag1 = mod.add_item(title: text_header, type: 'sub_header')

      get "/courses/#{@course.id}/modules"
      locked_title = ff("#context_module_item_#{tag1.id} .locked_title[title]")

      expect(locked_title[0]).to have_attribute("title", text_header)
    end

    it "should not rename every text header when you rename one" do
      mod = @course.context_modules.create! name: 'TestModule'
      tag1 = mod.add_item(title: 'First text header', type: 'sub_header')
      tag2 = mod.add_item(title: 'Second text header', type: 'sub_header')

      get "/courses/#{@course.id}/modules"
      item2 = f("#context_module_item_#{tag2.id}")
      edit_module_item(item2) do |edit_form|
        replace_content(edit_form.find_element(:id, 'content_tag_title'), 'Renamed!')
      end

      item1 = f("#context_module_item_#{tag1.id}")
      expect(item1).not_to include_text('Renamed!')
    end

    it "should not rename every external tool link when you rename one" do
      tool = @course.context_external_tools.create! name: 'WHAT', consumer_key: 'what', shared_secret: 'what', url: 'http://what.example.org'
      mod = @course.context_modules.create! name: 'TestModule'
      tag1 = mod.add_item(title: 'A', type: 'external_tool', id: tool.id, url: 'http://what.example.org/A')
      tag2 = mod.add_item(title: 'B', type: 'external_tool', id: tool.id, url: 'http://what.example.org/B')

      get "/courses/#{@course.id}/modules"
      item2 = f("#context_module_item_#{tag2.id}")
      edit_module_item(item2) do |edit_form|
        replace_content(edit_form.find_element(:id, 'content_tag_title'), 'Renamed!')
      end

      item1 = f("#context_module_item_#{tag1.id}")
      expect(item1).not_to include_text('Renamed!')
    end

    it "should add a new quiz to a module in a specific assignment group" do
      @course.context_modules.create!(name: "Quiz")
      get "/courses/#{@course.id}/modules"

      add_new_module_item('#quizs_select', 'Quiz', '[ New Quiz ]', "New Quiz") do
        click_option("select[name='quiz[assignment_group_id]']", @ag2.name)
      end
      expect(@ag2.assignments.length).to eq 1
      expect(@ag2.assignments.first.title).to eq "New Quiz"
    end

    it "should add a text header to a module", priority: "1", test_id: 126729  do
      get "/courses/#{@course.id}/modules"
      header_text = 'new header text'
      add_module('Text Header Module')
      f('.ig-header-admin .al-trigger').click
      f('.add_module_item_link').click
      select_module_item('#add_module_item_select', 'Text Header')
      replace_content(f('#sub_header_title'), header_text)
      f('.add_item_button.ui-button').click
      tag = ContentTag.last
      module_item = f("#context_module_item_#{tag.id}")
      expect(module_item).to include_text(header_text)
    end

    it "should always show module contents on empty module", priority: "1", test_id: 126732 do
      get "/courses/#{@course.id}/modules"
      add_module 'Test module'
      ff(".icon-mini-arrow-down")[0].click
      expect(f('.context_module .content')).to be_displayed
      expect(ff(".icon-mini-arrow-down")[0]).to be_displayed
    end

    it "should allow adding an item twice" do
      @course.context_modules.create!(name: "External Tool")
      get "/courses/#{@course.id}/modules"
      tag = add_new_external_item('External Tool', 'www.instructure.com', 'Instructure')
      expect(f("#context_module_item_#{tag.id}")).to have_attribute(:class, "context_external_tool")
      item1 = add_existing_module_item('#assignments_select', 'Assignment', @assignment.title)
      item2 = add_existing_module_item('#assignments_select', 'Assignment', @assignment.title)
      expect(item1).not_to eq item2
      expect(@assignment.reload.context_module_tags.size).to eq 2
    end

    it "should not save an invalid external tool", priority: "1", test_id: 2624908 do
      get "/courses/#{@course.id}/modules"

      add_module 'Test module'
      f('.ig-header-admin .al-trigger').click
      f('.add_module_item_link').click
      select_module_item('#add_module_item_select', 'External Tool')
      f('.add_item_button.ui-button').click
      expect(ff('.alert.alert-error').length).to eq 1
      expect(fj('.alert.alert-error:visible').text).to eq "An external tool can't be saved without a URL."
    end

    it "shows the added pre requisites in the header of a module", priority: "1", test_id: 250297 do
      add_modules_and_set_prerequisites
      get "/courses/#{@course.id}/modules"
      expect(f('.item-group-condensed:nth-of-type(3) .ig-header .prerequisites_message').text).
        to eq "Prerequisites: #{@module1.name}, #{@module2.name}"
    end

    it "shows the added prerequisites when editing a module" do
      add_modules_and_set_prerequisites
      get "/courses/#{@course.id}/modules"
      move_to_click("#context_module_#{@module3.id}")
      f("#context_module_#{@module3.id} .ig-header-admin .al-trigger").click
      f("#context_module_#{@module3.id} .edit_module_link").click
      add_form = f('#add_context_module_form')
      expect(add_form).to be_displayed
      prereq_select = f('.criterion select')
      option = first_selected_option(prereq_select)
      expect(option.text).to eq @module1.name.to_s
    end

    it "does not have a prerequisites section when creating the first module" do
      get "/courses/#{@course.id}/modules"

      form = new_module_form
      expect(f('.prerequisites_entry', form)).not_to be_displayed
      replace_content(form.find_element(:id, 'context_module_name'), "first")
      submit_form(form)
      wait_for_ajaximations

      form = new_module_form
      expect(f('.prerequisites_entry', form)).to be_displayed
    end

    it "does not have a prerequisites section when editing the first module" do
      modules = create_modules(2)
      get "/courses/#{@course.id}/modules"

      mod0 = f("#context_module_#{modules[0].id}")
      f(".ig-header-admin .al-trigger", mod0).click
      f('.edit_module_link', mod0).click
      edit_form = f('#add_context_module_form')
      expect(f('.prerequisites_entry', edit_form)).not_to be_displayed
      submit_form(edit_form)
      mod1 = f("#context_module_#{modules[1].id}")
      f(".ig-header-admin .al-trigger", mod1).click
      f('.edit_module_link', mod1).click
      edit_form = f('#add_context_module_form')
      expect(f('.prerequisites_entry', edit_form)).to be_displayed
    end

    it "retains focus when deleting prerequisites" do
      modules = create_modules(2)
      get "/courses/#{@course.id}/modules"
      mod1 = f("#context_module_#{modules[1].id}")
      f(".ig-header-admin .al-trigger", mod1).click
      f('.edit_module_link', mod1).click; wait_for_ajaximations
      add_button = f(".add_prerequisite_link")
      2.times { add_button.click; wait_for_animations }
      links = ff(".prerequisites_list .criteria_list .delete_criterion_link")
      expect(links.size).to eq 2
      links[1].click
      wait_for_animations
      check_element_has_focus(links[0])
      links[0].click
      wait_for_animations
      check_element_has_focus(add_button)
    end

    it "should save the requirement count chosen in the Edit Module form" do
      get "/courses/#{@course.id}/modules"
      add_existing_module_item('#assignments_select', 'Assignment', @assignment.title)

      @course.reload

      expect(fj('.requirements_message').text).to be_blank

      # add completion criterion
      f('.ig-header-admin .al-trigger').click
      wait_for_ajaximations
      f('.edit_module_link').click
      wait_for_ajaximations
      edit_form = f('#add_context_module_form')
      expect(edit_form).to be_displayed
      f('.add_completion_criterion_link', edit_form).click

      # Select other radio button
      move_to_click('label[for=context_module_requirement_count_1]')

      submit_form(edit_form)

      # Test that pill now says Complete One Item right after change and one reload
      expect(f('.pill li').text).to eq "Complete One Item"
      get "/courses/#{@course.id}/modules"
      expect(f('.pill li').text).to eq "Complete One Item"
    end

    it "should rearrange modules" do
      m1 = @course.context_modules.create!(:name => 'module 1')
      m2 = @course.context_modules.create!(:name => 'module 2')

      get "/courses/#{@course.id}/modules"
      sleep 2 #not sure what we are waiting on but drag and drop will not work, unless we wait

      m1_handle = fj('#context_modules .context_module:first-child .reorder_module_link .icon-drag-handle')
      m2_handle = fj('#context_modules .context_module:last-child .reorder_module_link .icon-drag-handle')
      driver.action.drag_and_drop(m2_handle, m1_handle).perform
      wait_for_ajax_requests

      m1.reload
      expect(m1.position).to eq 2
      m2.reload
      expect(m2.position).to eq 1
    end

    it "should validate locking a module item display functionality" do
      get "/courses/#{@course.id}/modules"
      add_form = new_module_form
      lock_check_click(add_form)
      wait_for_ajaximations
      expect(add_form.find_element(:css, '.unlock_module_at_details')).to be_displayed
      # verify unlock
      lock_check_click(add_form)
      wait_for_ajaximations
      expect(add_form.find_element(:css, '.unlock_module_at_details')).not_to be_displayed
    end

    it "should prompt relock when adding an unlock_at date" do
      lock_until=format_date_for_view(Time.zone.today + 2.days)
      @course.context_modules.create!(name: "name")
      get "/courses/#{@course.id}/modules"
      f(".ig-header-admin .al-trigger").click
      f(".edit_module_link").click
      expect(f('#add_context_module_form')).to be_displayed
      edit_form = f('#add_context_module_form')
      lock_check_click(edit_form)
      wait_for_ajaximations
      unlock_date = edit_form.find_element(:id, 'context_module_unlock_at')
      unlock_date.send_keys(lock_until)
      submit_form(edit_form)
      expect(edit_form).not_to be_displayed
      test_relock
    end

    it "validates module lock date picker format", priority: "2", test_id: 132519 do
      unlock_date = format_time_for_view(Time.zone.today + 2.days)
      @course.context_modules.create!(name: "name", unlock_at: unlock_date)
      get "/courses/#{@course.id}/modules"
      f(".ig-header-admin .al-trigger").click
      f(".edit_module_link").click
      edit_form = f('#add_context_module_form')
      unlock_date_in_dialog = edit_form.find_element(:id, 'context_module_unlock_at')
      expect(format_time_for_view(unlock_date_in_dialog.attribute("value"))).to eq unlock_date
    end

    it "should properly change indent of an item with arrows" do
      get "/courses/#{@course.id}/modules"

      add_existing_module_item('#assignments_select', 'Assignment', @assignment.title)
      tag = ContentTag.last

      f("#context_module_item_#{tag.id} .al-trigger").click
      f('.indent_item_link').click
      expect(f("#context_module_item_#{tag.id}")).to have_class('indent_1')
      tag.reload
      expect(tag.indent).to eq 1
    end

    it "should properly change indent of an item from edit dialog" do
      get "/courses/#{@course.id}/modules"

      add_existing_module_item('#assignments_select', 'Assignment', @assignment.title)
      tag = ContentTag.last

      f("#context_module_item_#{tag.id} .al-trigger").click
      f('.edit_item_link').click
      click_option("#content_tag_indent_select", "Indent 1 Level")
      form = f('#edit_item_form')
      form.submit
      wait_for_ajaximations
      expect(f("#context_module_item_#{tag.id}")).to have_class('indent_1')

      tag.reload
      expect(tag.indent).to eq 1
    end

    context "edit dialog" do
      before :once do
        @mod = create_modules(2, true)
        @mod[0].add_item({id: @assignment.id, type: 'assignment'})
        @mod[0].add_item({id: @assignment2.id, type: 'assignment'})
      end

      before :each do
        get "/courses/#{@course.id}/modules"
      end

      it "shows all items are completed radio button", priority: "1", test_id: 248023 do
        f("#context_module_#{@mod[0].id} .ig-header-admin .al-trigger").click
        hover_and_click("#context_module_#{@mod[0].id} .edit_module_link")
        f('.add-item .add_completion_criterion_link').click
        expect(f('.ic-Radio')).to contain_css("input[type=radio][id = context_module_requirement_count_]")
        expect(f('.ic-Radio .ic-Label').text).to eq('Students must complete all of these requirements')
      end

      it "shows complete one of these items radio button", priority: "1", test_id: 250294 do
        f("#context_module_#{@mod[0].id} .ig-header-admin .al-trigger").click
        hover_and_click("#context_module_#{@mod[0].id} .edit_module_link")
        f('.add-item .add_completion_criterion_link').click
        expect(ff('.ic-Radio')[1]).to contain_css("input[type=radio][id = context_module_requirement_count_1]")
        expect(ff('.ic-Radio .ic-Label')[1].text).to eq('Student must complete one of these requirements')
      end

      it "does not show the radio buttons for module with no items", priority: "1", test_id: 3028275 do
        f("#context_module_#{@mod[1].id} .ig-header-admin .al-trigger").click
        hover_and_click("#context_module_#{@mod[1].id} .edit_module_link")
        expect(f('.ic-Radio .ic-Label').text).not_to include('Students must complete all of these requirements')
        expect(f('.ic-Radio .ic-Label').text).not_to include('Student must complete one of these requirements')
        expect(f('.completion_entry .no_items_message').text).to eq('No items in module')
      end
    end

    context "module item cog focus management", priority: "1" do

      before :once do
        create_modules(1)[0].add_item({id: @assignment.id, type: 'assignment'})
        @tag = ContentTag.last
      end

      before :each do
        get "/courses/#{@course.id}/modules"
        f("#context_module_item_#{@tag.id} .al-trigger").click
      end

      it "should return focus to the cog menu when closing the edit dialog for an item" do
        hover_and_click("#context_module_item_#{@tag.id} .edit_item_link")
        f('.cancel_button.ui-button').click
        check_element_has_focus(fj("#context_module_item_#{@tag.id} .al-trigger"))
      end

      it "should return focus to the module item cog when indenting" do
        hover_and_click("#context_module_item_#{@tag.id} .indent_item_link")
        wait_for_ajaximations
        check_element_has_focus(fj("#context_module_item_#{@tag.id} .al-trigger"))
      end

      it "should return focus to the module item cog when outdenting" do
        hover_and_click("#context_module_item_#{@tag.id} .indent_item_link")
        f("#context_module_item_#{@tag.id} .al-trigger").click
        hover_and_click("#context_module_item_#{@tag.id} .outdent_item_link")
        wait_for_ajaximations
        check_element_has_focus(fj("#context_module_item_#{@tag.id} .al-trigger"))
      end

      it "should return focus to the module item cog when cancelling a delete" do
        hover_and_click("#context_module_item_#{@tag.id} .delete_item_link")
        expect(driver.switch_to.alert).not_to be_nil
        driver.switch_to.alert.dismiss
        wait_for_ajaximations
        check_element_has_focus(fj("#context_module_item_#{@tag.id} .al-trigger"))
      end

      it "should return focus to the previous module item link when deleting a module item." do
        add_existing_module_item('#assignments_select', 'Assignment', @assignment.title)
        @tag2 = ContentTag.last
        hover_and_click("#context_module_item_#{@tag2.id} .delete_item_link")
        expect(driver.switch_to.alert).not_to be_nil
        driver.switch_to.alert.accept
        wait_for_ajaximations
        check_element_has_focus(fj("#context_module_item_#{@tag.id} .item_link"))
      end

      it "should return focus to the parent module's cog when deleting the first module item." do
        first_tag = ContentTag.first
        hover_and_click("#context_module_item_#{first_tag.id} .delete_item_link")
        expect(driver.switch_to.alert).not_to be_nil
        driver.switch_to.alert.accept
        wait_for_ajaximations
        check_element_has_focus(f("#context_module_#{first_tag.context_module_id} .al-trigger"))
      end
    end


    it "should still display due date and points possible after indent change" do
      get "/courses/#{@course.id}/modules"
      module_item = add_existing_module_item('#assignments_select', 'Assignment', @assignment2.title)
      tag = ContentTag.last

      def due_date_assertion
        stale_element = true
        attempt = 5
        until (stale_element == true) && (attempt > 0)
          begin
            wait_for_dom_ready
            expect(module_item.find_element(:css, ".due_date_display").text).not_to be_blank
            stale_element = false
          rescue Selenium::WebDriver::Error::StaleElementReferenceError
            stale_element = true
            attempt -= 1
          end
        end
      end

      def points_possible_assertion(module_item, tag)
        stale_element = true
        attempt = 5
        module_item = f("#context_module_item_#{tag.id}")
        until (stale_element == true) && (attempt > 0)
          begin
            wait_for_dom_ready
            expect(module_item.find_element(:css, ".points_possible_display")).to include_text "10"
            stale_element = false
          rescue Selenium::WebDriver::Error::StaleElementReferenceError
            stale_element = true
            attempt -= 1
          end
        end
      end

      due_date_assertion
      points_possible_assertion(module_item, tag)

      # change indent with arrows
      f("#context_module_item_#{tag.id} .al-trigger").click
      f('.indent_item_link').click

      module_item = f("#context_module_item_#{tag.id}")
      due_date_assertion
      points_possible_assertion(module_item, tag)

      # change indent from edit form
      f("#context_module_item_#{tag.id} .al-trigger").click
      f('.edit_item_link').click

      click_option("#content_tag_indent_select", "Don't Indent")
      form = f('#edit_item_form')
      form.submit

      module_item = f("#context_module_item_#{tag.id}")
      due_date_assertion
      points_possible_assertion(module_item, tag)
    end

    context "Keyboard Accessibility", priority: "1" do
      before :once do
        modules = create_modules(2, true)
        modules[0].add_item({:id => @assignment.id, :type => 'assignment'})
        modules[0].add_item({:id => @assignment2.id, :type => 'assignment'})
        modules[1].add_item({:id => @assignment3.id, :type => 'assignment'})
      end

      before :each do
        skip_if_chrome('skipped - research find html')
        get "/courses/#{@course.id}/modules"

        # focus the first item
        f('html').send_keys("j")
      end

      let(:context_modules) { ff('.context_module .collapse_module_link') }
      let(:context_module_items) { ff('.context_module_item a.title') }

      # Test these shortcuts (access menu by pressing comma key):
      # Up : Previous Module/Item
      # Down : Next Module/Item
      # Space : Move Module/Item
      # k : Previous Module/Item
      # j : Next Module/Item
      # e : Edit Module/Item
      # d : Delete Current Module/Item
      # i : Increase Indent
      # o : Decrease Indent
      # n : New Module
      it "should navigate through modules and module items" do

        # Navigate through modules and module items
        check_element_has_focus(context_modules[0])

        send_keys(:arrow_down)
        check_element_has_focus(context_module_items[0])

        send_keys("j")
        check_element_has_focus(context_module_items[1])

        send_keys("k")
        check_element_has_focus(context_module_items[0])

        send_keys(:arrow_up)
        check_element_has_focus(context_modules[0])
      end

      it "should edit modules" do

        send_keys("e")
        expect(f('#add_context_module_form')).to be_displayed
      end

      it "should create a module" do

        send_keys("n")
        expect(f('#add_context_module_form')).to be_displayed
      end


      it "should indent / outdent" do

        send_keys(:arrow_down)
        check_element_has_focus(context_module_items[0])

        # Test Indent / Outdent
        expect(f('.context_module_item')).to have_class('indent_0')

        send_keys("i")
        wait_for_ajax_requests
        expect(f('.context_module_item')).to have_class('indent_1')

        send_keys("o")
        wait_for_ajax_requests
        expect(f('.context_module_item')).to have_class('indent_0')
      end

      it "should delete" do

        # Test Delete key
        send_keys("d")
        driver.switch_to.alert.accept
        expect(context_module_items).to have_size(2)
      end
    end

    context "multiple overridden due dates", priority: "2" do
      def create_section_override(section, due_at)
        override = assignment_override_model(:assignment => @assignment)
        override.set = section
        override.override_due_at(due_at)
        override.save!
      end

      it "should indicate when course sections have multiple due dates" do
        modules = create_modules(1, true)
        modules[0].add_item({:id => @assignment.id, :type => 'assignment'})

        cs1 = @course.default_section
        cs2 = @course.course_sections.create!

        create_section_override(cs1, 3.days.from_now)
        create_section_override(cs2, 4.days.from_now)

        get "/courses/#{@course.id}/modules"

        expect(f(".due_date_display").text).to eq "Multiple Due Dates"
      end

      it "should not indicate multiple due dates if the sections' dates are the same" do
        skip("needs to ignore base if all visible sections are overridden")
        modules = create_modules(1, true)
        modules[0].add_item({:id => @assignment.id, :type => 'assignment'})

        cs1 = @course.default_section
        cs2 = @course.course_sections.create!

        due_at = 3.days.from_now
        create_section_override(cs1, due_at)
        create_section_override(cs2, due_at)

        get "/courses/#{@course.id}/modules"


        expect(f(".due_date_display").text).not_to be_blank
        expect(f(".due_date_display").text).not_to eq "Multiple Due Dates"
      end

      it "should use assignment due date if there is no section override" do
        modules = create_modules(1, true)
        modules[0].add_item({:id => @assignment.id, :type => 'assignment'})

        cs1 = @course.default_section
        cs2 = @course.course_sections.create!

        due_at = 3.days.from_now
        create_section_override(cs1, due_at)
        @assignment.due_at = due_at
        @assignment.save!

        get "/courses/#{@course.id}/modules"
        expect(f(".due_date_display").text).not_to be_blank
        expect(f(".due_date_display").text).not_to eq "Multiple Due Dates"
      end

      it "should only use the sections the user is restricted to" do
        skip("needs to ignore base if all visible sections are overridden")
        modules = create_modules(1, true)
        modules[0].add_item({:id => @assignment.id, :type => 'assignment'})

        cs1 = @course.default_section
        cs2 = @course.course_sections.create!
        cs3 = @course.course_sections.create!

        user_logged_in
        @course.enroll_user(@user, 'TaEnrollment', :section => cs1, :allow_multiple_enrollments => true, :limit_privileges_to_course_section => true).accept!
        @course.enroll_user(@user, 'TaEnrollment', :section => cs2, :allow_multiple_enrollments => true, :limit_privileges_to_course_section => true).accept!

        due_at = 3.days.from_now
        create_section_override(cs1, due_at)
        create_section_override(cs2, due_at)
        create_section_override(cs3, due_at + 1.day) # This override should not matter

        get "/courses/#{@course.id}/modules"

        expect(f(".due_date_display").text).not_to be_blank
        expect(f(".due_date_display").text).not_to eq "Multiple Due Dates"
      end
    end

    it "should preserve completion criteria after indent change" do
      mod = @course.context_modules.create! name: 'Test Module'
      tag = mod.add_item(type: 'assignment', id: @assignment2.id)
      mod.completion_requirements = {tag.id => {type: 'must_submit'}}
      mod.save!

      get "/courses/#{@course.id}/modules"

      # indent the item
      f("#context_module_item_#{tag.id} .al-trigger").click
      f('.indent_item_link').click

      # make sure the completion criterion was preserved
      module_item = f("#context_module_item_#{tag.id}")
      expect(module_item).to have_class 'must_submit_requirement'
      expect(f('.criterion', module_item)).to have_class 'defined'
      expect(driver.execute_script("return $('#context_module_item_#{tag.id} .criterion_type').text()")).to eq "must_submit"
    end

    it "should show a vdd tooltip summary for assignments with multiple due dates" do
      selector = "li.Assignment_#{@assignment2.id} .due_date_display"
      get "/courses/#{@course.id}/modules"
      add_existing_module_item('#assignments_select', 'Assignment', @assignment2.title)
      expect(f(selector)).not_to include_text "Multiple Due Dates"

      # add a second due date
      new_section = @course.course_sections.create!(:name => 'New Section')
      override = @assignment2.assignment_overrides.build
      override.set = new_section
      override.due_at = Time.zone.now + 1.day
      override.due_at_overridden = true
      override.save!

      get "/courses/#{@course.id}/modules"
      expect(f(selector)).to include_text "Multiple Due Dates"
      driver.mouse.move_to f("#{selector} a")
      wait_for_ajaximations

      tooltip = fj('.vdd_tooltip_content:visible')
      expect(tooltip).to include_text 'New Section'
      expect(tooltip).to include_text 'Everyone else'
    end

    it "should publish a file from the modules page", priority: "1", test_id: 126727 do
      @module = @course.context_modules.create!(:name => "some module")
      @file = @course.attachments.create!(:display_name => "some file", :uploaded_data => default_uploaded_data, :locked => true)
      @tag = @module.add_item({:id => @file.id, :type => 'attachment'})
      expect(@file.reload).not_to be_published
      get "/courses/#{@course.id}/modules"
      f("[data-id='#{@file.id}'] > button.published-status").click
      ff(".permissions-dialog-form input[name='permissions']")[0].click
      f(".permissions-dialog-form [type='submit']").click
      wait_for_ajaximations
      expect(@file.reload).to be_published
    end

    it "should show the file publish button on course home" do
      @course.default_view = 'modules'
      @course.save!

      @module = @course.context_modules.create!(:name => "some module")
      @file = @course.attachments.create!(:display_name => "some file", :uploaded_data => default_uploaded_data)
      @tag = @module.add_item({:id => @file.id, :type => 'attachment'})

      get "/courses/#{@course.id}"
      expect(f(".context_module_item.attachment .icon-publish")).to be_displayed
    end

    it "should render publish buttons in collapsed modules" do
      @module = @course.context_modules.create! name: "collapsed"
      tag = @module.add_item(type: 'assignment', id: @assignment2.id)
      @progression = @module.evaluate_for(@user)
      @progression.collapsed = true
      @progression.save!
      get "/courses/#{@course.id}/modules"
      f('.expand_module_link').click
      expect(f(".context_module_item.assignment .icon-publish")).to be_displayed
    end
  end

  context "as a teacher through course home page (set to modules)", priority: "1" do
    before(:once) do
      course_with_teacher(name: 'teacher', active_all: true)
    end

    context "when adding new module" do
      before(:each) do
        user_session(@teacher)
        get "/courses/#{@course.id}"
      end

      it "should render as course home page", priority: "1", test_id: 126740 do
        create_modules(1)
        @course.default_view = 'modules'
        @course.save!
        get "/courses/#{@course.id}"
        expect(f('.add_module_link').text).not_to be_nil
      end

      it "should add a new module", priority: "1", test_id: 126704 do
        add_module('New Module')
        mod = @course.context_modules.first
        expect(mod.name).to eq 'New Module'
      end

      it "publishes an unpublished module", priority: "1", test_id: 280195 do
        add_module('New Module')
        expect(f('.context_module')).to have_class('unpublished_module')
        expect(@course.context_modules.count).to eq 1
        mod = @course.context_modules.first
        expect(mod.name).to eq 'New Module'
        publish_module
        mod.reload
        expect(mod).to be_published
        expect(f('#context_modules .publish-icon-published')).to be_displayed
      end
    end

    context "when working with existing module" do
      before :once do
        @course.context_modules.create! name: "New Module"
      end

      before :each do
        user_session(@teacher)
        get "/courses/#{@course.id}"
        wait_for_modules_ui
      end

      it "unpublishes a published module", priority: "1", test_id: 280196 do
        mod = @course.context_modules.first
        expect(mod).to be_published
        unpublish_module
        mod.reload
        expect(mod).to be_unpublished
      end

      it "should edit a module", priority: "1", test_id: 126738 do
        edit_text = 'Module Edited'
        f('.ig-header-admin .al-trigger').click
        f('.edit_module_link').click
        expect(f('#add_context_module_form')).to be_displayed
        edit_form = f('#add_context_module_form')
        edit_form.find_element(:id, 'context_module_name').send_keys(edit_text)
        submit_form(edit_form)
        expect(edit_form).not_to be_displayed
        expect(f('.context_module > .header')).to include_text(edit_text)
      end

      it "should delete a module", priority: "1", test_id: 126736 do
        skip_if_safari(:alert)
        f('.ig-header-admin .al-trigger').click
        f('.delete_module_link').click
        expect(driver.switch_to.alert).not_to be_nil
        driver.switch_to.alert.accept
        refresh_page
        expect(f('#no_context_modules_message')).to be_displayed
        expect(f('.context_module > .header')).not_to be_displayed
      end

      it "should add an assignment to a module", priority: "1", test_id: 126723 do
        add_new_module_item('#assignments_select', 'Assignment', '[ New Assignment ]', 'New Assignment Title')
        expect(fln('New Assignment Title')).to be_displayed
      end

      it "should add a assignment item to a module, publish new assignment refresh page and verify", priority: "2", test_id: 441358 do
        # this test basically verifies that the published icon is accurate after a page refresh
        mod = @course.context_modules.first
        assignment = @course.assignments.create!(title: "assignment 1")
        assignment.unpublish!
        tag = mod.add_item({id: assignment.id, type: 'assignment'})
        refresh_page
        item = f("#context_module_item_#{tag.id}")
        expect(f('span.publish-icon.unpublished.publish-icon-publish > i.icon-unpublish')).to be_displayed
        item.find_element(:css, '.publish-icon').click
        wait_for_ajax_requests
        expect(tag.reload).to be_published
        refresh_page
        driver.mouse.move_to f('i.icon-unpublish')
        expect(f('span.publish-icon.published.publish-icon-published')).to be_displayed
        expect(tag).to be_published
      end

      it "should add a quiz to a module", priority: "1", test_id: 126719 do
        mod = @course.context_modules.first
        quiz = @course.quizzes.create!(title: "New Quiz Title")
        mod.add_item({id: quiz.id, type: 'quiz'})
        refresh_page
        verify_persistence('New Quiz Title')
      end

      it "should add a content page item to a module", priority: "1", test_id: 126708 do
        mod = @course.context_modules.first
        page = @course.wiki_pages.create!(title: "New Page Title")
        mod.add_item({id: page.id, type: 'wiki_page'})
        refresh_page
        verify_persistence('New Page Title')
      end

      it "should add a content page item to a module and publish new page", priority: "2", test_id: 441357 do
        mod = @course.context_modules.first
        page = @course.wiki_pages.create!(title: "PAGE 2")
        page.unpublish!
        tag = mod.add_item({id: page.id, type: 'wiki_page'})
        refresh_page
        item = f("#context_module_item_#{tag.id}")
        expect(f('span.publish-icon.unpublished.publish-icon-publish > i.icon-unpublish')).to be_displayed
        item.find_element(:css, '.publish-icon').click
        wait_for_ajax_requests
        expect(tag.reload).to be_published
      end
    end
  end

  context "as a teacher" do
    before(:once) do
      course_factory(active_course: true)
      @teacher = teacher_in_course(course: @course, name: 'teacher', active_all: true).user
      @course.context_modules.create!(name: "New Module")
    end

    before(:each) do
      user_session(@teacher)
    end

    it "should add a discussion item to a module", priority: "1", test_id: 126711 do
      get "/courses/#{@course.id}/modules"
      add_new_module_item('#discussion_topics_select', 'Discussion', '[ New Topic ]', 'New Discussion Title')
      verify_persistence('New Discussion Title')
    end

    it "should add an external url item to a module", priority: "1", test_id: 126707 do
      get "/courses/#{@course.id}/modules"
      add_new_external_item('External URL', 'www.google.com', 'Google')
      expect(fln('Google')).to be_displayed
    end

    it "should require a url for external url items" do
      get "/courses/#{@course.id}/modules"
      f('.ig-header-admin .al-trigger').click
      f('.add_module_item_link').click

      click_option('#add_module_item_select', 'external_url', :value)

      title_input = fj('input[name="title"]:visible')
      replace_content(title_input, 'some title')
      scroll_to(f('.add_item_button.ui-button'))
      f('.add_item_button.ui-button').click

      expect(f('.errorBox:not(#error_box_template)')).to be_displayed

      expect(f("#select_context_content_dialog")).to be_displayed
    end

    it "should add an external tool item to a module from apps", priority: "1", test_id: 126706 do
      get "/courses/#{@course.id}/settings"
      make_full_screen
      f("#tab-tools-link").click
      f(".add_tool_link.lm").click
      f("#configuration_type_selector").click
      f("option[value='url']").click
      ff(".formFields input")[0].send_keys("Khan Academy")
      ff(".formFields input")[1].send_keys("key")
      ff(".formFields input")[2].send_keys("secret")
      ff(".formFields input")[3].send_keys("https://www.eduappcenter.com/configurations/rt6spjamqrgkduhr.xml")
      f("#submitExternalAppBtn").click
      get "/courses/#{@course.id}/modules"
      add_new_external_item('External Tool', 'https://www.edu-apps.org/lti_public_resources/launch?driver=khan_academy&remote_id=y2-uaPiyoxc', 'Counting with small numbers')
      expect(fln('Counting with small numbers')).to be_displayed
      expect(f('span.publish-icon.unpublished.publish-icon-publish > i.icon-unpublish')).to be_displayed
    end

    it "should add an external tool item to a module", priority: "1", test_id: 2624909 do
      get "/courses/#{@course.id}/modules"
      add_new_external_item('External Tool', 'www.instructure.com', 'Instructure')
      expect(fln('Instructure')).to be_displayed
    end
  end
end
