require File.expand_path(File.dirname(__FILE__) + '/helpers/context_modules_common')

describe "context_modules" do
  include_examples "in-process server selenium tests"
  context "as a teacher" do
    before (:each) do
      course_with_teacher_logged_in

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

    def create_modules(number_to_create, workflow_state = "unpublished")

      modules = []

      number_to_create.times do |i|
        m = @course.context_modules.create!(:name => "module #{i}")
        m.workflow_state = workflow_state
        m.workflow_state.should == workflow_state
        modules << m
      end
      modules
    end

    def open_admin_module_menu
      fj('#context_modules .admin-links.al-trigger').click
      wait_for_ajaximations
      sleep 1
    end

    def change_workflow_state_module
      fj('#context_modules .change-workflow-state-link').click()
      wait_for_ajaximations
    end

    def publish_module
      fj('#context_modules .admin-links.al-trigger').click
      keep_trying_until { f("#ui-id-2").should have_class('ui-state-open') }
      fj('#context_modules .change-workflow-state-link').click
      wait_for_ajaximations
    end

    def unpublish_module
      fj('#context_modules .admin-links.al-trigger').click
      keep_trying_until { f("#ui-id-1").should have_class('ui-state-open') }
      fj('#context_modules .change-workflow-state-link').click
      wait_for_ajaximations
    end

    it "should render as course home page" do
      create_modules(1)
      @course.default_view = 'modules'
      @course.save!
      get "/courses/#{@course.id}"

      wait_for_ajaximations
      f('.add_module_link').text.should_not be_nil
    end

    it "should show progressions link in modules home page" do
      create_modules(1)
      @course.default_view = 'modules'
      @course.save!

      get "/courses/#{@course.id}"
      wait_for_ajaximations

      f('.module_progressions_link').should be_displayed
    end

    it "should not show progressions link in modules home page for large rosters (MOOCs)" do
      create_modules(1)
      @course.default_view = 'modules'
      @course.large_roster = true
      @course.save!

      get "/courses/#{@course.id}"
      wait_for_ajaximations

      f('.module_progressions_link').should be_nil
    end

    it "publishes an unpublished module" do
      pending
      get "/courses/#{@course.id}/modules"

      add_module('New Module')
      publish_module
      open_admin_module_menu
      keep_trying_until { f('#context_modules .change-workflow-state-link').text.should == "Unpublish" }
    end

    it "unpublishes a published module" do
      pending
      get "/courses/#{@course.id}/modules"

      add_module('New Module')
      publish_module
      open_admin_module_menu
      keep_trying_until { f('#context_modules .change-workflow-state-link').text.should == "Unpublish" }
      change_workflow_state_module
      open_admin_module_menu
      keep_trying_until { f('#context_modules .change-workflow-state-link').text.should == "Publish" }
    end

    it "add unpublished_module css class when creating new module" do
      pending
      get "/courses/#{@course.id}/modules"

      add_module('New Module')
      f('.context_module').should have_class('unpublished_module')
      @course.context_modules.first.workflow_state.should == "unpublished"
    end

    it "allows you to publish a newly created module without reloading the page" do
      pending
      get "/courses/#{@course.id}/modules"

      add_module('New Module')
      f('.context_module').should have_class('unpublished_module')
      @course.context_modules.first.workflow_state.should == "unpublished"

      keep_trying_until do
        f('.admin-links.al-trigger').click
        hover_and_click('#context_modules .change-workflow-state-link')
        wait_for_ajax_requests
        f('.context_module').should have_class('published_module')
      end
    end

    it "should display all available modules in course through student progression" do
      new_student = student_in_course.user
      modules = create_modules(2, "active")

      #attach 1 assignment to module 1 and 2 assignments to module 2
      modules[0].add_item({:id => @assignment.id, :type => 'assignment'})
      modules[1].add_item({:id => @assignment2.id, :type => 'assignment'})
      modules[1].add_item({:id => @assignment3.id, :type => 'assignment'})

      get "/courses/#{@course.id}/modules"

      wait_for_ajax_requests
      f('.module_progressions_link').click
      wait_for_ajaximations
      f(".student_list").should be_displayed

      #validates the modules are displayed, are in the expected state, and include the correct student including current in progress module
      f(".module_#{modules[0].id} .progress").should include_text("no information")
      f(".module_#{modules[1].id} .progress").should include_text("no information")
      student_list = f(".student_list")
      keep_trying_until do
        student_list.should include_text(new_student.name)
        student_list.should include_text("none in progress")
      end
    end

    it "should refresh student progression page and display as expected" do
      new_student = student_in_course.user
      modules = create_modules(2, "active")

      #attach 1 assignment to module 1 and 2 assignments to module 2
      @tag_1 = modules[0].add_item({:id => @assignment.id, :type => 'assignment'})
      modules[0].completion_requirements = {@tag_1.id => {:type => 'must_view'}}
      modules[0].save!
      modules[0].completion_requirements.to_s.should include_text("must_view")

      modules[1].add_item({:id => @assignment2.id, :type => 'assignment'})
      @tag_3 = modules[1].add_item({:id => @assignment3.id, :type => 'assignment'})
      modules[1].completion_requirements = {@tag_3.id => {:type => 'must_submit'}}
      modules[1].save!
      modules[1].completion_requirements.to_s.should include_text("must_submit")

      get "/courses/#{@course.id}/modules"

      #opens the student progression link and validates all modules have no information"
      wait_for_ajaximations
      f('.module_progressions_link').click
      wait_for_ajaximations

      student_list = f(".student_list")
      student_list.should be_displayed
      student_list.should include_text(new_student.name)
      student_list.should include_text("none in progress")
      f(".module_#{modules[0].id} .progress").should include_text("no information")
      f(".module_#{modules[1].id} .progress").should include_text("no information")

      #updates the state for @assignment in module_1 for new_student be completed
      modules[0].update_for(new_student, :read, @tag_1)

      f('.refresh_progressions_link').click
      wait_for_ajaximations
      # fj for last 3 lines to avoid selenium caching
      fj(".student_list").should be_displayed
      keep_trying_until do
        fj(".module_#{modules[0].id} .progress").should include_text("completed")
        fj(".module_#{modules[1].id} .progress").should include_text("in progress")
        student_list.should include_text(new_student.name)
      end
    end
    #student_list.should include_text("module 2") ****Should update to module 2 but doesn't until renavigating to the page****

    it "should allow selecting specific student progression and update module state on screen" do
      pending('broken')

      new_student = student_in_course.user
      new_student2 = student_in_course.user

      modules = create_modules(2, "active")

      #attach 1 assignment to module 1 and 2 assignments to module 2 and add completion reqs
      @tag_1 = modules[0].add_item({:id => @assignment.id, :type => 'assignment'})
      modules[0].completion_requirements = {@tag_1.id => {:type => 'must_view'}}

      @tag_2 = modules[1].add_item({:id => @assignment2.id, :type => 'assignment'})
      @tag_3 = modules[1].add_item({:id => @assignment3.id, :type => 'assignment'})
      modules[1].completion_requirements = {@tag_3.id => {:type => 'must_submit'}}

      modules[0].save!
      modules[1].save!

      #updates new_student module state by completing @assignment
      modules[0].update_for(new_student, :read, @tag_1)

      get "/courses/#{@course.id}/modules"

      fj('.module_progressions_link').click
      wait_for_ajaximations
      fj(".student_list").should be_displayed


      #validates the second student has been selected and that the modules information is displayed as expected
      keep_trying_until do
        #selects the second student
        ffj(".student_list .student")[2].click
        wait_for_ajaximations

        f(".module_#{modules[0].id} .progress").should include_text("completed")
        f(".module_#{modules[1].id} .progress").should include_text("in progress")
      end
    end

    it "should rearrange child objects in same module" do
      get "/courses/#{@course.id}/modules"

      modules = create_modules(1, "active")

      #attach 1 assignment to module 1 and 2 assignments to module 2 and add completion reqs
      modules[0].add_item({:id => @assignment.id, :type => 'assignment'})
      modules[0].add_item({:id => @assignment2.id, :type => 'assignment'})

      refresh_page
      sleep 2 #not sure what we are waiting on but drag and drop will not work, unless we wait

      #setting gui drag icons to pass to driver.action.drag_and_drop
      a1_img = fj('.context_module_items .context_module_item:first .move_item_link img')
      a2_img = fj('.context_module_items .context_module_item:last .move_item_link img')

      #performs the change position
      driver.action.drag_and_drop(a2_img, a1_img).perform
      wait_for_ajaximations

      #validates the assignments switched, the number convention doesn't make sense, should be assignment == 2 and assignment2 == 1 but this is working
      keep_trying_until do
        @assignment.position.should == 2
        @assignment2.position.should == 3
      end
    end

    it "should rearrange child object to new module" do
      pending('drag and drop selenium not working')
      modules = create_modules(2, "active")

      #attach 1 assignment to module 1 and 2 assignments to module 2 and add completion reqs
      modules[0].add_item({:id => @assignment.id, :type => 'assignment'})
      modules[1].add_item({:id => @assignment2.id, :type => 'assignment'})

      refresh_page
      sleep 2 #not sure what we are waiting on but drag and drop will not work, unless we wait

      #setting gui drag icons to pass to driver.action.drag_and_drop
      a1_img = fj('#context_modules .context_module:first-child .context_module_items .context_module_item:first .move_item_link img')
      a2_img = fj('#context_modules .context_module:last-child .context_module_items .context_module_item:first .move_item_link img')

      #performs the change position
      driver.action.drag_and_drop(a2_img, a1_img).perform
      wait_for_ajaximations

      #validates the module 1 assignments are in the expected places and that module 2 context_module_items isn't present
      keep_trying_until do
        @assignment.position.should == 2
        @assignment2.position.should == 3
        fj('#context_modules .context_module:last-child .context_module_items .context_module_item').should be_nil
      end
    end

    it "should only display out-of on an assignment min score restriction when the assignment has a total" do
      get "/courses/#{@course.id}/modules"

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

      refresh_page

      keep_trying_until do
        f('.admin-links.al-trigger').click
        hover_and_click('#context_modules .edit_module_link')
        wait_for_ajax_requests
        f('#add_context_module_form').should be_displayed
      end
      assignment_picker = keep_trying_until do
        f('.add_completion_criterion_link').click
        fj('.assignment_picker:visible')
      end

      assignment_picker.find_element(:css, "option[value='#{content_tag_1.id}']").click
      requirement_picker = fj('.assignment_requirement_picker:visible')
      requirement_picker.find_element(:css, 'option[value="min_score"]').click
      driver.execute_script('return $(".points_possible_parent:visible").length').should > 0

      assignment_picker.find_element(:css, "option[value='#{content_tag_2.id}']").click
      requirement_picker.find_element(:css, 'option[value="min_score"]').click
      driver.execute_script('return $(".points_possible_parent:visible").length').should == 0
    end

    it "should show progressions link" do
      get "/courses/#{@course.id}/modules"

      add_module('New Module')

      f('.module_progressions_link').should be_displayed
    end

    it "should not show progressions link for large rosters (MOOCs)" do
      @course.large_roster = true
      @course.save!
      get "/courses/#{@course.id}/modules"

      add_module('New Module')

      f('.module_progressions_link').should be_nil
    end

    it "should delete a module" do
      get "/courses/#{@course.id}/modules"

      add_module('Delete Module')
      driver.execute_script("$('.context_module').addClass('context_module_hover')")
      f('.admin-links.al-trigger').click
      wait_for_ajaximations
      f('.delete_module_link').click
      driver.switch_to.alert.should_not be_nil
      driver.switch_to.alert.accept
      wait_for_ajaximations
      refresh_page
      f('#no_context_modules_message').should be_displayed
    end

    it "should edit a module" do
      get "/courses/#{@course.id}/modules"

      edit_text = 'Module Edited'
      add_module('Edit Module')
      context_module = f('.context_module')
      driver.action.move_to(context_module).perform
      f('.admin-links.al-trigger').click
      f('.edit_module_link').click
      f('.ui-dialog').should be_displayed
      edit_form = f('#add_context_module_form')
      edit_form.find_element(:id, 'context_module_name').send_keys(edit_text)
      submit_form(edit_form)
      edit_form.should_not be_displayed
      wait_for_ajaximations
      f('.context_module > .header').should include_text(edit_text)
    end

    it "should add and remove completion criteria" do
      get "/courses/#{@course.id}/modules"

      add_existing_module_item('#assignments_select', 'Assignment', @assignment.title)

      # add completion criterion
      context_module = f('.context_module')
      driver.action.move_to(context_module).perform
      f('.admin-links.al-trigger').click
      wait_for_ajaximations
      f('.edit_module_link').click
      wait_for_ajaximations
      f('.ui-dialog').should be_displayed
      edit_form = f('#add_context_module_form')
      f('.add_completion_criterion_link', edit_form).click
      wait_for_ajaximations
      click_option('#add_context_module_form .assignment_picker', @assignment.title, :text)
      click_option('#add_context_module_form .assignment_requirement_picker', 'must_submit', :value)
      submit_form(edit_form)
      edit_form.should_not be_displayed
      wait_for_ajax_requests

      # verify it was added
      @course.reload
      smodule = @course.context_modules.first
      smodule.should_not be_nil
      smodule.completion_requirements.should_not be_empty
      smodule.completion_requirements[0][:type].should == 'must_submit'

      # delete the criterion, then cancel the form
      driver.action.move_to(context_module).perform
      f('.admin-links.al-trigger').click
      wait_for_ajaximations
      f('.edit_module_link').click
      wait_for_ajaximations
      f('.ui-dialog').should be_displayed
      edit_form = f('#add_context_module_form')
      f('.completion_entry .delete_criterion_link', edit_form).click
      wait_for_ajaximations
      ff('.cancel_button', dialog_for(edit_form)).last.click
      wait_for_ajaximations

      # now delete the criterion frd
      # (if the previous step did even though it shouldn't have, this will error)
      driver.action.move_to(context_module).perform
      f('.admin-links.al-trigger').click
      wait_for_ajaximations
      f('.edit_module_link').click
      wait_for_ajaximations
      f('.ui-dialog').should be_displayed
      edit_form = f('#add_context_module_form')
      f('.completion_entry .delete_criterion_link', edit_form).click
      wait_for_ajaximations
      submit_form(edit_form)
      wait_for_ajax_requests

      # verify it's gone
      @course.reload
      @course.context_modules.first.completion_requirements.should == []

      # and also make sure the form remembers that it's gone (#8329)
      driver.action.move_to(context_module).perform
      f('.admin-links.al-trigger').click
      f('.edit_module_link').click
      f('.ui-dialog').should be_displayed
      edit_form = f('#add_context_module_form')
      ff('.completion_entry .delete_criterion_link', edit_form).should be_empty
    end

    it "should delete a module item" do
      get "/courses/#{@course.id}/modules"

      add_existing_module_item('#assignments_select', 'Assignment', @assignment.title)
      driver.execute_script("$('.context_module_item').addClass('context_module_item_hover')")
      wait_for_ajaximations
      f('.delete_item_link').click
      driver.switch_to.alert.should_not be_nil
      driver.switch_to.alert.accept
      wait_for_ajaximations
      keep_trying_until do
        f('.context_module_items').should_not include_text(@assignment.title)
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
      module_item.should include_text(item_edit_text)

      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      f('h1.title').text.should == item_edit_text

      expect_new_page_load { f('.modules').click }
      f("#context_module_item_#{tag.id} .title").text.should == item_edit_text
    end

    it "should add an assignment to a module" do
      get "/courses/#{@course.id}/modules"

      add_existing_module_item('#assignments_select', 'Assignment', @assignment.title)
    end

    it "should allow adding an item twice" do
      get "/courses/#{@course.id}/modules"

      item1 = add_existing_module_item('#assignments_select', 'Assignment', @assignment.title)
      item2 = add_existing_module_item('#assignments_select', 'Assignment', @assignment.title)
      item1.should_not == item2
      @assignment.reload.context_module_tags.size.should == 2
    end

    it "should rename all instances of an item" do
      get "/courses/#{@course.id}/modules"

      item1 = add_existing_module_item('#assignments_select', 'Assignment', @assignment.title)
      item2 = add_existing_module_item('#assignments_select', 'Assignment', @assignment.title)
      edit_module_item(item2) do |edit_form|
        replace_content(edit_form.find_element(:id, 'content_tag_title'), "renamed assignment")
      end
      all_items = ff(".context_module_item.Assignment_#{@assignment.id}")
      all_items.size.should == 2
      all_items.each { |i| i.find_element(:css, '.title').text.should == 'renamed assignment' }
      @assignment.reload.title.should == 'renamed assignment'
      run_jobs
      @assignment.context_module_tags.each { |tag| tag.title.should == 'renamed assignment' }

      # reload the page and renaming should still work on existing items
      get "/courses/#{@course.id}/modules"
      wait_for_ajaximations
      item3 = add_existing_module_item('#assignments_select', 'Assignment', @assignment.title)
      edit_module_item(item3) do |edit_form|
        replace_content(edit_form.find_element(:id, 'content_tag_title'), "again")
      end
      all_items = ff(".context_module_item.Assignment_#{@assignment.id}")
      all_items.size.should == 3
      all_items.each { |i| i.find_element(:css, '.title').text.should == 'again' }
      @assignment.reload.title.should == 'again'
      run_jobs
      @assignment.context_module_tags.each { |tag| tag.title.should == 'again' }
    end

    it "should add the 'with-completion-requirements' class to rows that have requirements" do
      set_course_draft_state
      mod = @course.context_modules.create! name: 'TestModule'
      tag = mod.add_item({:id => @assignment.id, :type => 'assignment'})

      mod.completion_requirements = {tag.id => {:type => 'must_view'}}
      mod.save

      get "/courses/#{@course.id}/modules"

      ig_rows = ff("#context_module_item_#{tag.id} .with-completion-requirements")
      ig_rows.should_not be_empty
    end

    it "should add a title attribute to the text header" do
      set_course_draft_state
      text_header = 'This is a really long module text header that should be truncated to exactly 98 characters plus the ... part so 101 characters really'
      mod = @course.context_modules.create! name: 'TestModule'
      tag1 = mod.add_item(title: text_header, type: 'sub_header')

      get "/courses/#{@course.id}/modules"
      locked_title = ff("#context_module_item_#{tag1.id} .locked_title[title]")

      locked_title[0].attribute(:title).should == text_header
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
      item1.should_not include_text('Renamed!')
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
      item1.should_not include_text('Renamed!')
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
      @ag2.assignments.length.should == 1
      @ag2.assignments.first.title.should == "New Quiz"
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
      f('.admin-links.al-trigger').click
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
      module_item.should include_text(header_text)
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
      f('.admin-links.al-trigger').click
      wait_for_ajaximations
      f('.add_module_item_link').click
      wait_for_ajaximations
      keep_trying_until do
        select_module_item('#add_module_item_select', 'External Tool')
        fj('.add_item_button:visible').click
        ff('.alert.alert-error').length.should == 1
      end
      fj('.alert.alert-error:visible').text.should == "An external tool can't be saved without a URL."
    end

    it "should hide module contents" do
      get "/courses/#{@course.id}/modules"

      add_existing_module_item('#assignments_select', 'Assignment', @assignment.title)
      f('.collapse_module_link').click
      wait_for_ajaximations
      f('.context_module .content').should_not be_displayed
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
      f("#context_module_#{db_module.id} .admin-links.al-trigger").click
      f("#context_module_#{db_module.id} .edit_module_link").click
      f('.ui-dialog').should be_displayed
      wait_for_ajaximations
      prereq_select = fj('.criterion select')
      option = first_selected_option(prereq_select)
      option.text.should == 'the module, ' + first_module_name
    end

    it "should rearrange modules" do
      m1 = @course.context_modules.create!(:name => 'module 1')
      m2 = @course.context_modules.create!(:name => 'module 2')

      get "/courses/#{@course.id}/modules"
      sleep 2 #not sure what we are waiting on but drag and drop will not work, unless we wait

      m1_img = fj('#context_modules .context_module:first-child .reorder_module_link img')
      m2_img = fj('#context_modules .context_module:last-child .reorder_module_link img')
      driver.action.drag_and_drop(m2_img, m1_img).perform
      wait_for_ajax_requests

      m1.reload
      m1.position.should == 2
      m2.reload
      m2.position.should == 1
    end

    it "should validate locking a module item display functionality" do
      get "/courses/#{@course.id}/modules"

      add_form = new_module_form
      lock_check = add_form.find_element(:id, 'unlock_module_at')
      lock_check.click
      wait_for_ajaximations
      add_form.find_element(:css, 'tr.unlock_module_at_details').should be_displayed
      lock_check.click
      wait_for_ajaximations
      add_form.find_element(:css, 'tr.unlock_module_at_details').should_not be_displayed
    end

    it "should properly change indent of an item with arrows" do
      get "/courses/#{@course.id}/modules"

      add_existing_module_item('#assignments_select', 'Assignment', @assignment.title)
      tag = ContentTag.last

      driver.execute_script("$('#context_module_item_#{tag.id} .indent_item_link').hover().click()")
      wait_for_ajaximations
      f("#context_module_item_#{tag.id}").should have_class('indent_1')

      tag.reload
      tag.indent.should == 1
    end

    it "should properly change indent of an item from edit dialog" do
      get "/courses/#{@course.id}/modules"

      add_existing_module_item('#assignments_select', 'Assignment', @assignment.title)
      tag = ContentTag.last

      driver.execute_script("$('#context_module_item_#{tag.id} .edit_item_link').hover().click()")
      click_option("#content_tag_indent_select", "Indent 1 Level")
      submit_form("#edit_item_form")
      wait_for_ajaximations
      f("#context_module_item_#{tag.id}").should have_class('indent_1')

      tag.reload
      tag.indent.should == 1
    end

    it "should still display due date and points possible after indent change" do
      get "/courses/#{@course.id}/modules"

      module_item = add_existing_module_item('#assignments_select', 'Assignment', @assignment2.title)
      tag = ContentTag.last

      module_item.find_element(:css, ".due_date_display").text.should_not be_blank
      module_item.find_element(:css, ".points_possible_display").should include_text "10"

      # change indent with arrows
      driver.execute_script("$('#context_module_item_#{tag.id} .indent_item_link').hover().click()")
      wait_for_ajaximations

      module_item = f("#context_module_item_#{tag.id}")
      module_item.find_element(:css, ".due_date_display").text.should_not be_blank
      module_item.find_element(:css, ".points_possible_display").should include_text "10"

      # change indent from edit form
      driver.execute_script("$('#context_module_item_#{tag.id} .edit_item_link').hover().click()")
      click_option("#content_tag_indent_select", "Don't Indent")
      submit_form("#edit_item_form")
      wait_for_ajaximations

      module_item = f("#context_module_item_#{tag.id}")
      module_item.find_element(:css, ".due_date_display").text.should_not be_blank
      module_item.find_element(:css, ".points_possible_display").should include_text "10"
    end

    context "multiple overridden due dates" do
      def create_section_override(section, due_at)
        override = assignment_override_model(:assignment => @assignment)
        override.set = section
        override.override_due_at(due_at)
        override.save!
      end

      it "should indicate when course sections have multiple due dates" do
        modules = create_modules(1, "active")
        modules[0].add_item({:id => @assignment.id, :type => 'assignment'})

        cs1 = @course.default_section
        cs2 = @course.course_sections.create!

        create_section_override(cs1, 3.days.from_now)
        create_section_override(cs2, 4.days.from_now)

        get "/courses/#{@course.id}/modules"
        wait_for_ajaximations

        f(".due_date_display").text.should == "Multiple Due Dates"
      end

      it "should not indicate multiple due dates if the sections' dates are the same" do
        pending("needs to ignore base if all visible sections are overridden")
        modules = create_modules(1, "active")
        modules[0].add_item({:id => @assignment.id, :type => 'assignment'})

        cs1 = @course.default_section
        cs2 = @course.course_sections.create!

        due_at = 3.days.from_now
        create_section_override(cs1, due_at)
        create_section_override(cs2, due_at)

        get "/courses/#{@course.id}/modules"
        wait_for_ajaximations

        f(".due_date_display").text.should_not be_blank
        f(".due_date_display").text.should_not == "Multiple Due Dates"
      end

      it "should use assignment due date if there is no section override" do
        modules = create_modules(1, "active")
        modules[0].add_item({:id => @assignment.id, :type => 'assignment'})

        cs1 = @course.default_section
        cs2 = @course.course_sections.create!

        due_at = 3.days.from_now
        create_section_override(cs1, due_at)
        @assignment.due_at = due_at
        @assignment.save!

        get "/courses/#{@course.id}/modules"
        wait_for_ajaximations

        f(".due_date_display").text.should_not be_blank
        f(".due_date_display").text.should_not == "Multiple Due Dates"
      end

      it "should only use the sections the user is restricted to" do
        pending("needs to ignore base if all visible sections are overridden")
        modules = create_modules(1, "active")
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

        f(".due_date_display").text.should_not be_blank
        f(".due_date_display").text.should_not == "Multiple Due Dates"
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
      module_item.attribute('class').split.should include 'must_submit_requirement'
      f('.criterion', module_item).attribute('class').split.should include 'defined'
      driver.execute_script("return $('#context_module_item_#{tag.id} .criterion_type').text()").should == "must_submit"
    end

    it "should show a vdd tooltip summary for assignments with multiple due dates" do
      selector = "table.Assignment_#{@assignment2.id} .due_date_display"
      get "/courses/#{@course.id}/modules"
      add_existing_module_item('#assignments_select', 'Assignment', @assignment2.title)
      wait_for_ajaximations
      f(selector).should_not include_text "Multiple Due Dates"

      # add a second due date
      new_section = @course.course_sections.create!(:name => 'New Section')
      override = @assignment2.assignment_overrides.build
      override.set = new_section
      override.due_at = Time.zone.now + 1.day
      override.due_at_overridden = true
      override.save!

      get "/courses/#{@course.id}/modules"
      wait_for_ajaximations
      f(selector).should include_text "Multiple Due Dates"
      driver.mouse.move_to f("#{selector} a")
      wait_for_ajaximations

      tooltip = fj('.vdd_tooltip_content:visible')
      tooltip.should include_text 'New Section'
      tooltip.should include_text 'Everyone else'
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
      f(".due_date_display").text.should_not be_blank
      f(".due_date_display").text.should == @due_at.strftime('%b %-d, %Y')
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
      f(".due_date_display").text.should_not be_blank
      f(".due_date_display").text.should == @due_at.strftime('%b %-d, %Y')
    end

    it "when associated with a student, it should show the student's overridden due date" do
      @observer_enrollment = @course.enroll_user(@observer, 'ObserverEnrollment', :enrollment_state => 'active', :associated_user_id => @student.id)
      get "/courses/#{@course.id}/modules"

      wait_for_ajaximations
      f(".due_date_display").text.should_not be_blank
      f(".due_date_display").text.should_not == "Multiple Due Dates"
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
      f(".due_date_display").text.should == "Multiple Due Dates"
    end
  end

  describe "files" do
    FILE_NAME = 'some test file'

    before (:each) do
      course_with_teacher_logged_in
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

      f('.context_module_item').should include_text(FILE_NAME)
      file = @course.attachments.create!(:display_name => FILE_NAME, :uploaded_data => default_uploaded_data)
      file.context = @course
      file.save!
      Attachment.last.handle_duplicates(:overwrite)
      refresh_page
      f('.context_module_item').should include_text(FILE_NAME)
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
          @assignment_tag.id => { :type => 'must_submit' },
          @external_url_tag.id => { :type => 'must_view' } }
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

      f("#progression_student_#{@students[0].id}_module_#{@module1.id} .status").text.should include("Complete")
      f("#progression_student_#{@students[0].id}_module_#{@module2.id} .status").text.should include("Locked")
      f("#progression_student_#{@students[0].id}_module_#{@module3.id}").should be_nil

      f("#progression_student_#{@students[1].id}").click
      wait_for_ajaximations
      f("#progression_student_#{@students[1].id}_module_#{@module1.id} .status").text.should include("In Progress")
      f("#progression_student_#{@students[1].id}_module_#{@module1.id} .items").text.should_not include(@assignment_tag.title)
      f("#progression_student_#{@students[1].id}_module_#{@module1.id} .items").text.should include(@external_url_tag.title)
      f("#progression_student_#{@students[1].id}_module_#{@module2.id} .status").text.should include("Locked")

      f("#progression_student_#{@students[2].id}").click
      wait_for_ajaximations
      f("#progression_student_#{@students[2].id}_module_#{@module1.id} .status").text.should include("In Progress")
      f("#progression_student_#{@students[2].id}_module_#{@module1.id} .items").text.should include(@assignment_tag.title)
      f("#progression_student_#{@students[2].id}_module_#{@module1.id} .items").text.should_not include(@external_url_tag.title)
      f("#progression_student_#{@students[2].id}_module_#{@module2.id} .status").text.should include("Locked")

      f("#progression_student_#{@students[3].id}").click
      wait_for_ajaximations
      f("#progression_student_#{@students[3].id}_module_#{@module1.id} .status").text.should include("Unlocked")
      f("#progression_student_#{@students[3].id}_module_#{@module2.id} .status").text.should include("Locked")
    end

    it "should show progression to individual students" do
      user_session(@students[1])
      get "/courses/#{@course.id}/modules/progressions"

      wait_for_ajaximations
      f("#progression_students").should_not be_displayed
      f("#progression_student_#{@students[1].id}_module_#{@module1.id} .status").text.should include("In Progress")
      f("#progression_student_#{@students[1].id}_module_#{@module1.id} .items").text.should_not include(@assignment_tag.title)
      f("#progression_student_#{@students[1].id}_module_#{@module1.id} .items").text.should include(@external_url_tag.title)
      f("#progression_student_#{@students[1].id}_module_#{@module2.id} .status").text.should include("Locked")
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

      f("#progression_student_#{@students[1].id}").should be_nil
      f("#progression_student_#{@students[3].id}").should be_nil

      wait_for_ajaximations
      f("#progression_student_#{@students[0].id}_module_#{@module1.id} .status").text.should include("Complete")
      f("#progression_student_#{@students[0].id}_module_#{@module2.id} .status").text.should include("Locked")
      f("#progression_student_#{@students[0].id}_module_#{@module3.id}").should be_nil

      f("#progression_student_#{@students[2].id}").click
      wait_for_ajaximations
      f("#progression_student_#{@students[2].id}_module_#{@module1.id} .status").text.should include("In Progress")
      f("#progression_student_#{@students[2].id}_module_#{@module1.id} .items").text.should include(@assignment_tag.title)
      f("#progression_student_#{@students[2].id}_module_#{@module1.id} .items").text.should_not include(@external_url_tag.title)
      f("#progression_student_#{@students[2].id}_module_#{@module2.id} .status").text.should include("Locked")
    end
  end
end
