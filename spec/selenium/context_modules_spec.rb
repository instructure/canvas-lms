require File.expand_path(File.dirname(__FILE__) + '/helpers/context_modules_common')

describe "context_modules" do
  include_examples "in-process server selenium tests"
  context "as a teacher" do
    before (:each) do
      course_with_teacher_logged_in
      set_course_draft_state

      #have to add quiz and assignment to be able to add them to a new module
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

    def create_modules(number_to_create, published=false)
      modules = []

      number_to_create.times do |i|
        m = @course.context_modules.create!(:name => "module #{i}")
        m.unpublish! unless published
        modules << m
      end
      modules
    end

    def publish_module
      fj('#context_modules .publish-icon-publish').click
      wait_for_ajaximations
    end

    def unpublish_module
      fj('#context_modules .publish-icon-published').click
      wait_for_ajaximations
    end

    it "should render as course home page" do
      create_modules(1)
      @course.default_view = 'modules'
      @course.save!
      get "/courses/#{@course.id}"

      wait_for_ajaximations
      expect(f('.add_module_link').text).not_to be_nil
    end

    it "should show progressions link in modules home page" do
      create_modules(1)
      @course.default_view = 'modules'
      @course.save!

      get "/courses/#{@course.id}"
      wait_for_ajaximations

      expect(f('.module_progressions_link')).to be_displayed
    end

    it "should not show progressions link in modules home page for large rosters (MOOCs)" do
      create_modules(1)
      @course.default_view = 'modules'
      @course.large_roster = true
      @course.save!

      get "/courses/#{@course.id}"
      wait_for_ajaximations

      expect(f('.module_progressions_link')).to be_nil
    end

    it "publishes an unpublished module" do
      get "/courses/#{@course.id}/modules"

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

    it "unpublishes a published module" do
      get "/courses/#{@course.id}/modules"

      add_module('New Module')
      mod = @course.context_modules.first
      publish_module
      mod.reload
      expect(mod).to be_published
      unpublish_module
      mod.reload
      expect(mod).to be_unpublished
    end

    it "should rearrange child objects in same module" do
      modules = create_modules(1, true)
      #attach 1 assignment to module 1 and 2 assignments to module 2 and add completion reqs
      item1 = modules[0].add_item({:id => @assignment.id, :type => 'assignment'})
      item2 = modules[0].add_item({:id => @assignment2.id, :type => 'assignment'})
      get "/courses/#{@course.id}/modules"
      #setting gui drag icons to pass to driver.action.drag_and_drop
      selector1 = "#context_module_item_#{item1.id} .move_item_link"
      selector2 = "#context_module_item_#{item2.id} .move_item_link"
      list_prior_drag = ff("a.title").map(&:text)
      #performs the change position
      js_drag_and_drop(selector2, selector1)
      wait_for_ajaximations
      list_post_drag = ff("a.title").map(&:text)
      keep_trying_until do
        expect(list_prior_drag[0]).to eq list_post_drag[1]
        expect(list_prior_drag[1]).to eq list_post_drag[0]
      end
    end

    it "should rearrange child object to new module" do
      modules = create_modules(2, true)
      #attach 1 assignment to module 1 and 2 assignments to module 2 and add completion reqs
      item1_mod1 = modules[0].add_item({:id => @assignment.id, :type => 'assignment'})
      item1_mod2 = modules[1].add_item({:id => @assignment2.id, :type => 'assignment'})
      get "/courses/#{@course.id}/modules"
      #setting gui drag icons to pass to driver.action.drag_and_drop
      selector1 = "#context_module_item_#{item1_mod1.id} .move_item_link"
      selector2 = "#context_module_item_#{item1_mod2.id} .move_item_link"
      #performs the change position
      js_drag_and_drop(selector2, selector1)
      wait_for_ajaximations
      list_post_drag = ff("a.title").map(&:text)
      #validates the module 1 assignments are in the expected places and that module 2 context_module_items isn't present
      keep_trying_until do
        expect(list_post_drag[0]).to eq "assignment 2"
        expect(list_post_drag[1]).to eq "assignment 1"
        expect(fj('#context_modules .context_module:last-child .context_module_items .context_module_item')).to be_nil
      end
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

      keep_trying_until do
        f('.ig-header-admin  .al-trigger').click
        hover_and_click('#context_modules .edit_module_link')
        wait_for_ajax_requests
        expect(f('#add_context_module_form')).to be_displayed
      end
      assignment_picker = keep_trying_until do
        f('.add_completion_criterion_link').click
        fj('.assignment_picker:visible')
      end

      assignment_picker.find_element(:css, "option[value='#{content_tag_1.id}']").click
      requirement_picker = fj('.assignment_requirement_picker:visible')
      requirement_picker.find_element(:css, 'option[value="min_score"]').click
      expect(driver.execute_script('return $(".points_possible_parent:visible").length')).to be > 0

      assignment_picker.find_element(:css, "option[value='#{content_tag_2.id}']").click
      requirement_picker.find_element(:css, 'option[value="min_score"]').click
      expect(driver.execute_script('return $(".points_possible_parent:visible").length')).to eq 0
    end

    it "should delete a module" do
      get "/courses/#{@course.id}/modules"

      add_module('Delete Module')
      driver.execute_script("$('.context_module').addClass('context_module_hover')")
      f('.ig-header-admin .al-trigger').click
      wait_for_ajaximations
      f('.delete_module_link').click
      expect(driver.switch_to.alert).not_to be_nil
      driver.switch_to.alert.accept
      wait_for_ajaximations
      refresh_page
      expect(f('#no_context_modules_message')).to be_displayed
    end

    it "should edit a module" do
      get "/courses/#{@course.id}/modules"

      edit_text = 'Module Edited'
      add_module('Edit Module')
      f('.ig-header-admin .al-trigger').click
      f('.edit_module_link').click
      expect(f('.ui-dialog')).to be_displayed
      edit_form = f('#add_context_module_form')
      edit_form.find_element(:id, 'context_module_name').send_keys(edit_text)
      submit_form(edit_form)
      expect(edit_form).not_to be_displayed
      wait_for_ajaximations
      expect(f('.context_module > .header')).to include_text(edit_text)
    end

    it "should add and remove completion criteria" do
      get "/courses/#{@course.id}/modules"
      add_existing_module_item('#assignments_select', 'Assignment', @assignment.title)
      # add completion criterion
      f('.ig-header-admin .al-trigger').click
      wait_for_ajaximations
      f('.edit_module_link').click
      wait_for_ajaximations
      expect(f('.ui-dialog')).to be_displayed
      edit_form = f('#add_context_module_form')
      f('.add_completion_criterion_link', edit_form).click
      wait_for_ajaximations
      click_option('#add_context_module_form .assignment_picker', @assignment.title, :text)
      click_option('#add_context_module_form .assignment_requirement_picker', 'must_submit', :value)
      submit_form(edit_form)
      expect(edit_form).not_to be_displayed
      wait_for_ajax_requests

      # verify it was added
      @course.reload
      smodule = @course.context_modules.first
      expect(smodule).not_to be_nil
      expect(smodule.completion_requirements).not_to be_empty
      expect(smodule.completion_requirements[0][:type]).to eq 'must_submit'

      # delete the criterion, then cancel the form
      f('.ig-header-admin .al-trigger').click
      wait_for_ajaximations
      f('.edit_module_link').click
      wait_for_ajaximations
      expect(f('.ui-dialog')).to be_displayed
      edit_form = f('#add_context_module_form')
      f('.completion_entry .delete_criterion_link', edit_form).click
      wait_for_ajaximations
      ff('.cancel_button', dialog_for(edit_form)).last.click
      wait_for_ajaximations

      # now delete the criterion frd
      # (if the previous step did even though it shouldn't have, this will error)
      f('.ig-header-admin .al-trigger').click
      wait_for_ajaximations
      f('.edit_module_link').click
      wait_for_ajaximations
      expect(f('.ui-dialog')).to be_displayed
      edit_form = f('#add_context_module_form')
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
      expect(f('.ui-dialog')).to be_displayed
      edit_form = f('#add_context_module_form')
      expect(ff('.completion_entry .delete_criterion_link', edit_form)).to be_empty
    end

    it "should delete a module item" do
      get "/courses/#{@course.id}/modules"

      add_existing_module_item('#assignments_select', 'Assignment', @assignment.title)
      f('.context_module_item .al-trigger').click()
      wait_for_ajaximations
      f('.delete_item_link').click
      expect(driver.switch_to.alert).not_to be_nil
      driver.switch_to.alert.accept
      wait_for_ajaximations
      keep_trying_until do
        expect(f('.context_module_items')).not_to include_text(@assignment.title)
        true
      end
    end

    it "should edit a module item and validate the changes stick" do
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

    it "should add an assignment to a module" do
      get "/courses/#{@course.id}/modules"

      add_existing_module_item('#assignments_select', 'Assignment', @assignment.title)
    end

    it "should allow adding an item twice" do
      get "/courses/#{@course.id}/modules"

      item1 = add_existing_module_item('#assignments_select', 'Assignment', @assignment.title)
      item2 = add_existing_module_item('#assignments_select', 'Assignment', @assignment.title)
      expect(item1).not_to eq item2
      expect(@assignment.reload.context_module_tags.size).to eq 2
    end

    it "should rename all instances of an item" do
      get "/courses/#{@course.id}/modules"

      item1 = add_existing_module_item('#assignments_select', 'Assignment', @assignment.title)
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
      wait_for_ajaximations
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

    it "should add the 'with-completion-requirements' class to rows that have requirements" do
      set_course_draft_state
      mod = @course.context_modules.create! name: 'TestModule'
      tag = mod.add_item({:id => @assignment.id, :type => 'assignment'})

      mod.completion_requirements = {tag.id => {:type => 'must_view'}}
      mod.save

      get "/courses/#{@course.id}/modules"

      ig_rows = ff("#context_module_item_#{tag.id} .with-completion-requirements")
      expect(ig_rows).not_to be_empty
    end

    it "should add a title attribute to the text header" do
      set_course_draft_state
      text_header = 'This is a really long module text header that should be truncated to exactly 98 characters plus the ... part so 101 characters really'
      mod = @course.context_modules.create! name: 'TestModule'
      tag1 = mod.add_item(title: text_header, type: 'sub_header')

      get "/courses/#{@course.id}/modules"
      locked_title = ff("#context_module_item_#{tag1.id} .locked_title[title]")

      expect(locked_title[0].attribute(:title)).to eq text_header
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

    it "should add a quiz to a module" do
      get "/courses/#{@course.id}/modules"

      add_existing_module_item('#quizs_select', 'Quiz', @quiz.title)
    end

    it "should add a new quiz to a module in a specific assignment group" do
      get "/courses/#{@course.id}/modules"

      add_new_module_item('#quizs_select', 'Quiz', '[ New Quiz ]', "New Quiz") do
        click_option("select[name='quiz[assignment_group_id]']", @ag2.name)
      end
      expect(@ag2.assignments.length).to eq 1
      expect(@ag2.assignments.first.title).to eq "New Quiz"
    end

    it "should add a content page item to a module" do
      get "/courses/#{@course.id}/modules"

      add_new_module_item('#wiki_pages_select', 'Content Page', '[ New Page ]', 'New Page Title')
    end

    it "should add a discussion item to a module" do
      get "/courses/#{@course.id}/modules"

      add_new_module_item('#discussion_topics_select', 'Discussion', '[ New Topic ]', 'New Discussion Title')
    end

    it "should add a text header to a module" do
      get "/courses/#{@course.id}/modules"

      header_text = 'new header text'
      add_module('Text Header Module')
      f('.ig-header-admin .al-trigger').click
      f('.add_module_item_link').click
      select_module_item('#add_module_item_select', 'Text Header')
      keep_trying_until do
        replace_content(f('#sub_header_title'), header_text)
        true
      end
      fj('.add_item_button:visible').click
      wait_for_ajaximations
      tag = ContentTag.last
      module_item = f("#context_module_item_#{tag.id}")
      expect(module_item).to include_text(header_text)
    end

    it "should add an external url item to a module" do
      get "/courses/#{@course.id}/modules"

      add_new_external_item('External URL', 'www.google.com', 'Google')
    end

    it "should add an external tool item to a module" do
      get "/courses/#{@course.id}/modules"

      add_new_external_item('External Tool', 'www.instructure.com', 'Instructure')
    end

    it "should not save an invalid external tool" do
      get "/courses/#{@course.id}/modules"

      add_module 'Test module'
      f('.ig-header-admin .al-trigger').click
      wait_for_ajaximations
      f('.add_module_item_link').click
      wait_for_ajaximations
      keep_trying_until do
        select_module_item('#add_module_item_select', 'External Tool')
        fj('.add_item_button:visible').click
        expect(ff('.alert.alert-error').length).to eq 1
      end
      expect(fj('.alert.alert-error:visible').text).to eq "An external tool can't be saved without a URL."
    end

    it "should hide module contents" do
      get "/courses/#{@course.id}/modules"

      add_existing_module_item('#assignments_select', 'Assignment', @assignment.title)
      f('.collapse_module_link').click
      wait_for_ajaximations
      expect(f('.context_module .content')).not_to be_displayed
    end

    it "should add 2 modules with the first one as a prerequisite" do
      get "/courses/#{@course.id}/modules"

      first_module_name = 'First Module'
      second_module_name = 'Second Module'
      add_module(first_module_name)
      #adding second module - can't use add_module method because a prerequisite needs to be added to this module
      add_form = new_module_form
      replace_content(add_form.find_element(:id, 'context_module_name'), second_module_name)
      f('.ui-dialog .add_prerequisite_link').click
      wait_for_ajaximations
      #have to do it this way because the select has no css attributes on it
      click_option('.criterion select', "the module, #{first_module_name}")
      submit_form(add_form)
      wait_for_ajaximations
      db_module = ContextModule.last
      context_module = f("#context_module_#{db_module.id}")
      driver.action.move_to(context_module).perform
      f("#context_module_#{db_module.id} .ig-header-admin .al-trigger").click
      f("#context_module_#{db_module.id} .edit_module_link").click
      expect(f('.ui-dialog')).to be_displayed
      wait_for_ajaximations
      prereq_select = fj('.criterion select')
      option = first_selected_option(prereq_select)
      expect(option.text).to eq 'the module, ' + first_module_name
    end

    it "should rearrange modules" do
      m1 = @course.context_modules.create!(:name => 'module 1')
      m2 = @course.context_modules.create!(:name => 'module 2')

      get "/courses/#{@course.id}/modules"
      sleep 2 #not sure what we are waiting on but drag and drop will not work, unless we wait

      m1_a = fj('#context_modules .context_module:first-child .reorder_module_link a')
      m2_a = fj('#context_modules .context_module:last-child .reorder_module_link a')
      driver.action.drag_and_drop(m2_a, m1_a).perform
      wait_for_ajax_requests

      m1.reload
      expect(m1.position).to eq 2
      m2.reload
      expect(m2.position).to eq 1
    end

    it "should validate locking a module item display functionality" do
      get "/courses/#{@course.id}/modules"

      add_form = new_module_form
      lock_check = add_form.find_element(:id, 'unlock_module_at')
      lock_check.click
      wait_for_ajaximations
      expect(add_form.find_element(:css, 'tr.unlock_module_at_details')).to be_displayed
      lock_check.click
      wait_for_ajaximations
      expect(add_form.find_element(:css, 'tr.unlock_module_at_details')).not_to be_displayed
    end

    it "should properly change indent of an item with arrows" do
      get "/courses/#{@course.id}/modules"

      add_existing_module_item('#assignments_select', 'Assignment', @assignment.title)
      tag = ContentTag.last

      driver.execute_script("$('#context_module_item_#{tag.id} .indent_item_link').hover().click()")
      wait_for_ajaximations
      expect(f("#context_module_item_#{tag.id}")).to have_class('indent_1')

      tag.reload
      expect(tag.indent).to eq 1
    end

    it "should properly change indent of an item from edit dialog" do
      get "/courses/#{@course.id}/modules"

      add_existing_module_item('#assignments_select', 'Assignment', @assignment.title)
      tag = ContentTag.last

      driver.execute_script("$('#context_module_item_#{tag.id} .edit_item_link').hover().click()")
      click_option("#content_tag_indent_select", "Indent 1 Level")
      submit_form("#edit_item_form")
      wait_for_ajaximations
      expect(f("#context_module_item_#{tag.id}")).to have_class('indent_1')

      tag.reload
      expect(tag.indent).to eq 1
    end

    it "should still display due date and points possible after indent change" do
      get "/courses/#{@course.id}/modules"

      module_item = add_existing_module_item('#assignments_select', 'Assignment', @assignment2.title)
      tag = ContentTag.last

      expect(module_item.find_element(:css, ".due_date_display").text).not_to be_blank
      expect(module_item.find_element(:css, ".points_possible_display")).to include_text "10"

      # change indent with arrows
      driver.execute_script("$('#context_module_item_#{tag.id} .indent_item_link').hover().click()")
      wait_for_ajaximations

      module_item = f("#context_module_item_#{tag.id}")
      expect(module_item.find_element(:css, ".due_date_display").text).not_to be_blank
      expect(module_item.find_element(:css, ".points_possible_display")).to include_text "10"

      # change indent from edit form
      driver.execute_script("$('#context_module_item_#{tag.id} .edit_item_link').hover().click()")
      click_option("#content_tag_indent_select", "Don't Indent")
      submit_form("#edit_item_form")
      wait_for_ajaximations

      module_item = f("#context_module_item_#{tag.id}")
      expect(module_item.find_element(:css, ".due_date_display").text).not_to be_blank
      expect(module_item.find_element(:css, ".points_possible_display")).to include_text "10"
    end

    context "multiple overridden due dates" do
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
        wait_for_ajaximations

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
        wait_for_ajaximations

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
        wait_for_ajaximations

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
        wait_for_ajaximations

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
      driver.execute_script("$('#context_module_item_#{tag.id} .indent_item_link').hover().click()")
      wait_for_ajaximations

      # make sure the completion criterion was preserved
      module_item = f("#context_module_item_#{tag.id}")
      expect(module_item.attribute('class').split).to include 'must_submit_requirement'
      expect(f('.criterion', module_item).attribute('class').split).to include 'defined'
      expect(driver.execute_script("return $('#context_module_item_#{tag.id} .criterion_type').text()")).to eq "must_submit"
    end

    it "should show a vdd tooltip summary for assignments with multiple due dates" do
      selector = "li.Assignment_#{@assignment2.id} .due_date_display"
      get "/courses/#{@course.id}/modules"
      add_existing_module_item('#assignments_select', 'Assignment', @assignment2.title)
      wait_for_ajaximations
      expect(f(selector)).not_to include_text "Multiple Due Dates"

      # add a second due date
      new_section = @course.course_sections.create!(:name => 'New Section')
      override = @assignment2.assignment_overrides.build
      override.set = new_section
      override.due_at = Time.zone.now + 1.day
      override.due_at_overridden = true
      override.save!

      get "/courses/#{@course.id}/modules"
      wait_for_ajaximations
      expect(f(selector)).to include_text "Multiple Due Dates"
      driver.mouse.move_to f("#{selector} a")
      wait_for_ajaximations

      tooltip = fj('.vdd_tooltip_content:visible')
      expect(tooltip).to include_text 'New Section'
      expect(tooltip).to include_text 'Everyone else'
    end
  end

  context "as an observer" do
    before (:each) do
      @course = course(:active_all => true)
      @student = user(:active_all => true, :active_state => 'active')
      @observer = user(:active_all => true, :active_state => 'active')

      @student_enrollment = @course.enroll_user(@student, 'StudentEnrollment', :enrollment_state => 'active')

      @assignment = @course.assignments.create!(:title => 'assignment 1', :name => 'assignment 1')
      @due_at = 1.year.from_now
      override_for_student(@student, @due_at)

      course_module
      @module.add_item({:id => @assignment.id, :type => 'assignment'})

      user_session(@observer)
    end

    def override_for_student(student, due_at)
      override = assignment_override_model(:assignment => @assignment)
      override.override_due_at(due_at)
      override.save!
      override_student = override.assignment_override_students.build
      override_student.user = student
      override_student.save!
    end

    it "when not associated, and in one section, it should show the section's due date" do
      section2 = @course.course_sections.create!
      override = assignment_override_model(:assignment => @assignment)
      override.set = section2
      override.override_due_at(@due_at)
      override.save!

      @observer_enrollment = @course.enroll_user(@observer, 'ObserverEnrollment', :enrollment_state => 'active', :section => section2)
      get "/courses/#{@course.id}/modules"

      wait_for_ajaximations
      expect(f(".due_date_display").text).not_to be_blank
      expect(f(".due_date_display").text).to eq @due_at.strftime('%b %-d, %Y')
    end

    it "when not associated, and in multiple sections, it should show the latest due date" do
      override = assignment_override_model(:assignment => @assignment)
      override.set = @course.default_section
      override.override_due_at(@due_at)
      override.save!

      section2 = @course.course_sections.create!
      override = assignment_override_model(:assignment => @assignment)
      override.set = section2
      override.override_due_at(@due_at - 1.day)
      override.save!

      @observer_enrollment = @course.enroll_user(@observer, 'ObserverEnrollment', :enrollment_state => 'active')
      @observer_enrollment = @course.enroll_user(@observer, 'ObserverEnrollment', :enrollment_state => 'active', :allow_multiple_enrollments => true, :section => section2)
      get "/courses/#{@course.id}/modules"

      wait_for_ajaximations
      expect(f(".due_date_display").text).not_to be_blank
      expect(f(".due_date_display").text).to eq @due_at.strftime('%b %-d, %Y')
    end

    it "when associated with a student, it should show the student's overridden due date" do
      @observer_enrollment = @course.enroll_user(@observer, 'ObserverEnrollment', :enrollment_state => 'active', :associated_user_id => @student.id)
      get "/courses/#{@course.id}/modules"

      wait_for_ajaximations
      expect(f(".due_date_display").text).not_to be_blank
      expect(f(".due_date_display").text).not_to eq "Multiple Due Dates"
    end

    it "should indicate multiple due dates for multiple observed students" do
      section2 = @course.course_sections.create!
      override = assignment_override_model(:assignment => @assignment)
      override.set = section2
      override.override_due_at(@due_at + 1.day)
      override.save!

      student2 = user(:active_all => true, :active_state => 'active', :section => section2)
      @course.enroll_user(student2, 'StudentEnrollment', :enrollment_state => 'active')
      @course.enroll_user(@observer, 'ObserverEnrollment', :enrollment_state => 'active', :associated_user_id => @student.id)
      @course.enroll_user(@observer, 'ObserverEnrollment', :enrollment_state => 'active', :allow_multiple_enrollments => true, :associated_user_id => student2.id)

      get "/courses/#{@course.id}/modules"

      wait_for_ajaximations
      expect(f(".due_date_display").text).to eq "Multiple Due Dates"
    end
  end

  describe "files" do
    FILE_NAME = 'some test file'

    before (:each) do
      course_with_teacher_logged_in
      set_course_draft_state
      #adding file to course
      @file = @course.attachments.create!(:display_name => FILE_NAME, :uploaded_data => default_uploaded_data)
      @file.context = @course
      @file.save!
    end

    it "should add a file item to a module" do
      get "/courses/#{@course.id}/modules"

      add_existing_module_item('#attachments_select', 'File', FILE_NAME)
    end

    it "should not remove the file link in a module when file is overwritten" do
      course_module
      @module.add_item({:id => @file.id, :type => 'attachment'})
      get "/courses/#{@course.id}/modules"

      expect(f('.context_module_item')).to include_text(FILE_NAME)
      file = @course.attachments.create!(:display_name => FILE_NAME, :uploaded_data => default_uploaded_data)
      file.context = @course
      file.save!
      Attachment.last.handle_duplicates(:overwrite)
      refresh_page
      expect(f('.context_module_item')).to include_text(FILE_NAME)
    end
  end

  context "progressions" do
    before :each do
      course_with_teacher_logged_in(:draft_state => true)

      @module1 = @course.context_modules.create!(:name => "module1")
      @assignment = @course.assignments.create!(:name => "pls submit", :submission_types => ["online_text_entry"], :points_possible => 42)
      @assignment.publish
      @assignment_tag = @module1.add_item(:id => @assignment.id, :type => 'assignment')
      @external_url_tag = @module1.add_item(:type => 'external_url', :url => 'http://example.com/lolcats',
                                            :title => 'pls view', :indent => 1)
      @external_url_tag.publish
      @module1.completion_requirements = {
          @assignment_tag.id => {:type => 'must_submit'},
          @external_url_tag.id => {:type => 'must_view'}}
      @module1.save!

      @christmas = Time.zone.local(Time.now.year + 1, 12, 25, 7, 0)
      @module2 = @course.context_modules.create!(:name => "do not open until christmas",
                                                 :unlock_at => @christmas,
                                                 :require_sequential_progress => true)
      @module2.prerequisites = "module_#{@module1.id}"
      @module2.save!

      @module3 = @course.context_modules.create(:name => "module3")
      @module3.workflow_state = 'unpublished'
      @module3.save!

      @students = []
      4.times do |i|
        student = User.create!(:name => "hello student #{i}")
        @course.enroll_student(student).accept!
        @students << student
      end

      # complete for student 0
      @assignment.submit_homework(@students[0], :body => "done!")
      @external_url_tag.context_module_action(@students[0], :read)
      # in progress for student 1-2
      @assignment.submit_homework(@students[1], :body => "done!")
      @external_url_tag.context_module_action(@students[2], :read)
      # unlocked for student 3
    end

    it "should show student progressions to teachers" do
      get "/courses/#{@course.id}/modules/progressions"
      wait_for_ajaximations

      expect(f("#progression_student_#{@students[0].id}_module_#{@module1.id} .status").text).to include("Complete")
      expect(f("#progression_student_#{@students[0].id}_module_#{@module2.id} .status").text).to include("Locked")
      expect(f("#progression_student_#{@students[0].id}_module_#{@module3.id}")).to be_nil

      f("#progression_student_#{@students[1].id}").click
      wait_for_ajaximations
      expect(f("#progression_student_#{@students[1].id}_module_#{@module1.id} .status").text).to include("In Progress")
      expect(f("#progression_student_#{@students[1].id}_module_#{@module1.id} .items").text).not_to include(@assignment_tag.title)
      expect(f("#progression_student_#{@students[1].id}_module_#{@module1.id} .items").text).to include(@external_url_tag.title)
      expect(f("#progression_student_#{@students[1].id}_module_#{@module2.id} .status").text).to include("Locked")

      f("#progression_student_#{@students[2].id}").click
      wait_for_ajaximations
      expect(f("#progression_student_#{@students[2].id}_module_#{@module1.id} .status").text).to include("In Progress")
      expect(f("#progression_student_#{@students[2].id}_module_#{@module1.id} .items").text).to include(@assignment_tag.title)
      expect(f("#progression_student_#{@students[2].id}_module_#{@module1.id} .items").text).not_to include(@external_url_tag.title)
      expect(f("#progression_student_#{@students[2].id}_module_#{@module2.id} .status").text).to include("Locked")

      f("#progression_student_#{@students[3].id}").click
      wait_for_ajaximations
      expect(f("#progression_student_#{@students[3].id}_module_#{@module1.id} .status").text).to include("Unlocked")
      expect(f("#progression_student_#{@students[3].id}_module_#{@module2.id} .status").text).to include("Locked")
    end

    it "should show progression to individual students" do
      user_session(@students[1])
      get "/courses/#{@course.id}/modules/progressions"

      wait_for_ajaximations
      expect(f("#progression_students")).not_to be_displayed
      expect(f("#progression_student_#{@students[1].id}_module_#{@module1.id} .status").text).to include("In Progress")
      expect(f("#progression_student_#{@students[1].id}_module_#{@module1.id} .items").text).not_to include(@assignment_tag.title)
      expect(f("#progression_student_#{@students[1].id}_module_#{@module1.id} .items").text).to include(@external_url_tag.title)
      expect(f("#progression_student_#{@students[1].id}_module_#{@module2.id} .status").text).to include("Locked")
    end

    it "should show multiple student progressions to observers" do
      @observer = user
      @course.enroll_user(@observer, 'ObserverEnrollment', {:allow_multiple_enrollments => true,
                                                            :associated_user_id => @students[0].id})
      @course.enroll_user(@observer, 'ObserverEnrollment', {:allow_multiple_enrollments => true,
                                                            :associated_user_id => @students[2].id})

      user_session(@observer)

      get "/courses/#{@course.id}/modules/progressions"
      wait_for_ajaximations

      expect(f("#progression_student_#{@students[1].id}")).to be_nil
      expect(f("#progression_student_#{@students[3].id}")).to be_nil

      wait_for_ajaximations
      expect(f("#progression_student_#{@students[0].id}_module_#{@module1.id} .status").text).to include("Complete")
      expect(f("#progression_student_#{@students[0].id}_module_#{@module2.id} .status").text).to include("Locked")
      expect(f("#progression_student_#{@students[0].id}_module_#{@module3.id}")).to be_nil

      f("#progression_student_#{@students[2].id}").click
      wait_for_ajaximations
      expect(f("#progression_student_#{@students[2].id}_module_#{@module1.id} .status").text).to include("In Progress")
      expect(f("#progression_student_#{@students[2].id}_module_#{@module1.id} .items").text).to include(@assignment_tag.title)
      expect(f("#progression_student_#{@students[2].id}_module_#{@module1.id} .items").text).not_to include(@external_url_tag.title)
      expect(f("#progression_student_#{@students[2].id}_module_#{@module2.id} .status").text).to include("Locked")
    end
  end

  context "menu tools" do
    before do
      course_with_teacher_logged_in(:draft_state => true)
      Account.default.enable_feature!(:lor_for_account)

      @tool = Account.default.context_external_tools.new(:name => "a", :domain => "google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @tool.assignment_menu = {:url => "http://www.example.com", :text => "Export Assignment"}
      @tool.module_menu = {:url => "http://www.example.com", :text => "Export Module"}
      @tool.quiz_menu = {:url => "http://www.example.com", :text => "Export Quiz"}
      @tool.wiki_page_menu = {:url => "http://www.example.com", :text => "Export Wiki Page"}
      @tool.save!

      @module1 = @course.context_modules.create!(:name => "module1")
      @assignment = @course.assignments.create!(:name => "pls submit", :submission_types => ["online_text_entry"], :points_possible => 20)
      @assignment_tag = @module1.add_item(:id => @assignment.id, :type => 'assignment')
      @quiz = @course.quizzes.create!(:title => "score 10")
      @quiz.publish!
      @quiz_tag = @module1.add_item(:id => @quiz.id, :type => 'quiz')
      @wiki_page = @course.wiki.front_page
      @wiki_page.workflow_state = 'active'; @wiki_page.save!
      @wiki_page_tag = @module1.add_item(:id => @wiki_page.id, :type => 'wiki_page')
      @subheader_tag = @module1.add_item(:type => 'context_module_sub_header', :title => 'subheader')
    end

    it "should show tool launch links in the gear for modules" do
      get "/courses/#{@course.id}/modules"
      wait_for_ajaximations

      gear = f("#context_module_#{@module1.id} .header .al-trigger")
      gear.click
      link = f("#context_module_#{@module1.id} .header li a.menu_tool_link")
      expect(link).to be_displayed
      expect(link.text).to match_ignoring_whitespace(@tool.label_for(:module_menu))
      expect(link['href']).to eq course_external_tool_url(@course, @tool, launch_type: 'module_menu', :modules => [@module1.id])
    end

    it "should show tool launch links in the gear for modules on course home if set to modules" do
      @course.default_view = 'modules'
      @course.save!
      get "/courses/#{@course.id}"
      wait_for_ajaximations

      gear = f("#context_module_#{@module1.id} .header .al-trigger")
      gear.click
      link = f("#context_module_#{@module1.id} .header li a.menu_tool_link")
      expect(link).to be_displayed
      expect(link.text).to match_ignoring_whitespace(@tool.label_for(:module_menu))
      expect(link['href']).to eq course_external_tool_url(@course, @tool, launch_type: 'module_menu', :modules => [@module1.id])
    end

    it "should not render tool links unless the lor flag is enabled" do
      Account.default.disable_feature!(:lor_for_account)
      get "/courses/#{@course.id}/modules"
      gear = f("#context_module_#{@module1.id} .header .al-trigger")
      gear.click
      link = f("#context_module_#{@module1.id} .header li a.menu_tool_link")
      expect(link).to be_nil
    end

    it "should show tool launch links in the gear for exportable module items" do
      get "/courses/#{@course.id}/modules"
      wait_for_ajaximations

      type_to_tag = {
          :assignment_menu => @assignment_tag,
          :quiz_menu => @quiz_tag,
          :wiki_page_menu => @wiki_page_tag
      }
      type_to_tag.each do |type, tag|
        gear = f("#context_module_item_#{tag.id} .al-trigger")
        gear.click

        type_to_tag.keys.each do |other_type|
          next if other_type == type
          expect(f("#context_module_item_#{tag.id} li.#{other_type} a.menu_tool_link")).to be_nil
        end

        link = f("#context_module_item_#{tag.id} li.#{type} a.menu_tool_link")
        expect(link).to be_displayed
        expect(link.text).to match_ignoring_whitespace(@tool.label_for(type))
        expect(link['href']).to eq course_external_tool_url(@course, @tool, launch_type: type, :module_items => [tag.id])
      end

      gear = f("#context_module_item_#{@subheader_tag.id} .al-trigger")
      gear.click
      link = f("#context_module_item_#{@subheader_tag.id} a.menu_tool_link")
      expect(link).to be_nil
    end

    it "should add links to newly created modules" do
      get "/courses/#{@course.id}/modules"
      wait_for_ajaximations

      f(".add_module_link").click
      wait_for_ajaximations
      form = f('#add_context_module_form')
      replace_content(form.find_element(:id, 'context_module_name'), 'new module')
      submit_form(form)
      wait_for_ajaximations

      new_module = ContextModule.last
      expect(new_module.name).to eq 'new module'

      gear = f("#context_module_#{new_module.id} .header .al-trigger")
      gear.click
      link = f("#context_module_#{new_module.id} .header li a.menu_tool_link")
      expect(link).to be_displayed
      expect(link.text).to match_ignoring_whitespace(@tool.label_for(:module_menu))
      expect(link['href']).to eq course_external_tool_url(@course, @tool, launch_type: 'module_menu', :modules => [new_module.id])
    end

    it "should add links to newly created module items" do
      get "/courses/#{@course.id}/modules"
      wait_for_ajaximations

      f("#context_module_#{@module1.id} .add_module_item_link").click
      wait_for_ajaximations

      click_option('#add_module_item_select', 'wiki_page', :value)
      click_option('#wiki_pages_select .module_item_select', 'new', :value)
      replace_content(f('#wiki_pages_select .item_title'), 'new page')
      fj('.add_item_button:visible').click
      wait_for_ajaximations

      new_page = WikiPage.last
      expect(new_page.title).to eq 'new page'

      new_tag = ContentTag.last
      expect(new_tag.content).to eq new_page

      gear = f("#context_module_item_#{new_tag.id} .al-trigger")
      gear.click

      [:assignment_menu, :quiz_menu].each do |other_type|
        link = f("#context_module_item_#{new_tag.id} li.#{other_type} a.menu_tool_link")
        expect(link).not_to be_displayed
      end

      link = f("#context_module_item_#{new_tag.id} li.wiki_page_menu a.menu_tool_link")
      expect(link).to be_displayed
      expect(link.text).to match_ignoring_whitespace(@tool.label_for(:wiki_page_menu))
      expect(link['href']).to eq course_external_tool_url(@course, @tool, launch_type: 'wiki_page_menu', :module_items => [new_tag.id])
    end

    it "should not show add links to newly created module items if not exportable" do
      get "/courses/#{@course.id}/modules"
      wait_for_ajaximations

      f("#context_module_#{@module1.id} .add_module_item_link").click
      wait_for_ajaximations
      click_option('#add_module_item_select', 'external_url', :value)
      replace_content(f('#content_tag_create_url'), 'http://www.example.com')
      replace_content(f('#content_tag_create_title'), 'new item')

      fj('.add_item_button:visible').click
      wait_for_ajaximations

      new_tag = ContentTag.last

      gear = f("#context_module_item_#{new_tag.id} .al-trigger")
      gear.click
      link = f("#context_module_item_#{new_tag.id} li.ui-menu-item a.menu_tool_link")
      expect(link).not_to be_displayed
    end
  end

  context "new module items", :priority => "2" do
    def verify_persistence(title)
      refresh_page
      expect(f('#context_modules')).to include_text(title)
    end

    before (:each) do
      course_with_teacher_logged_in
      set_course_draft_state
      get "/courses/#{@course.id}/modules"
    end

    it "new discussion item should persist after refresh " do
      add_new_module_item('#discussion_topics_select', 'Discussion', '[ New Topic ]', 'New Discussion Title')
      verify_persistence('New Discussion Title')
    end

    it "new quiz item should persist after refresh " do
      add_new_module_item('#quizs_select', 'Quiz', '[ New Quiz ]', 'New Quiz Title')
      verify_persistence('New Quiz Title')
    end

    it "new wiki page item should persist after refresh " do
      add_new_module_item('#wiki_pages_select', 'Content Page', '[ New Page ]', 'New Page Title')
      verify_persistence('New Page Title')
    end
  end
end
