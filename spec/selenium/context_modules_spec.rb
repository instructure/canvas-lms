require File.expand_path(File.dirname(__FILE__) + '/helpers/context_modules_common')

describe "context_modules" do
  it_should_behave_like "context module tests"

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
      @ag1 = @course.assignment_groups.create!(:name => "Assignment Group 1")
      @ag2 = @course.assignment_groups.create!(:name => "Assignment Group 2")

      @course.reload

      get "/courses/#{@course.id}/modules"
    end

    it "should only display 'out-of' on an assignment min score restriction when the assignment has a total" do
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

      keep_trying_until {
        hover_and_click('#context_modules .edit_module_link')
        wait_for_ajax_requests
        driver.find_element(:id, 'add_context_module_form').should be_displayed
      }
      assignment_picker = keep_trying_until {
        driver.find_element(:css, '.add_completion_criterion_link').click
        find_with_jquery('.assignment_picker:visible')
      }

      assignment_picker.find_element(:css, "option[value='#{content_tag_1.id}']").click
      requirement_picker = find_with_jquery('.assignment_requirement_picker:visible')
      requirement_picker.find_element(:css, 'option[value="min_score"]').click
      driver.execute_script('return $(".points_possible_parent:visible").length').should > 0

      assignment_picker.find_element(:css, "option[value='#{content_tag_2.id}']").click
      requirement_picker.find_element(:css, 'option[value="min_score"]').click
      driver.execute_script('return $(".points_possible_parent:visible").length').should == 0
    end

    it "should add a module" do
      add_module('New Module')
      # should always show the student progressions button for teachers
      f('.module_progressions_link').should be_displayed
    end

    it "should delete a module" do
      add_module('Delete Module')
      driver.execute_script("$('.context_module').addClass('context_module_hover')")
      driver.find_element(:css, '.delete_module_link').click
      driver.switch_to.alert.should_not be_nil
      driver.switch_to.alert.accept
      wait_for_ajaximations
      refresh_page
      driver.find_element(:id, 'no_context_modules_message').should be_displayed
    end

    it "should edit a module" do
      edit_text = 'Module Edited'
      add_module('Edit Module')
      context_module = driver.find_element(:css, '.context_module')
      driver.action.move_to(context_module).perform
      driver.find_element(:css, '.edit_module_link').click
      driver.find_element(:css, '.ui-dialog').should be_displayed
      edit_form = driver.find_element(:id, 'add_context_module_form')
      edit_form.find_element(:id, 'context_module_name').send_keys(edit_text)
      submit_form(edit_form)
      edit_form.should_not be_displayed
      wait_for_ajaximations
      driver.find_element(:css, '.context_module > .header').should include_text(edit_text)
    end

    it "should add and remove completion criteria" do
      add_existing_module_item('#assignments_select', 'Assignment', @assignment.title)

      # add completion criterion
      context_module = f('.context_module')
      driver.action.move_to(context_module).perform
      f('.edit_module_link').click
      f('.ui-dialog').should be_displayed
      edit_form = driver.find_element(:id, 'add_context_module_form')
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
      f('.edit_module_link').click
      f('.ui-dialog').should be_displayed
      edit_form = driver.find_element(:id, 'add_context_module_form')
      f('.completion_entry .delete_criterion_link', edit_form).click
      wait_for_ajaximations
      f('.cancel_button', edit_form).click
      wait_for_ajaximations

      # now delete the criterion frd
      # (if the previous step did even though it shouldn't have, this will error)
      driver.action.move_to(context_module).perform
      f('.edit_module_link').click
      f('.ui-dialog').should be_displayed
      edit_form = driver.find_element(:id, 'add_context_module_form')
      f('.completion_entry .delete_criterion_link', edit_form).click
      wait_for_ajaximations
      submit_form(edit_form)
      wait_for_ajax_requests

      # verify it's gone
      @course.reload
      @course.context_modules.first.completion_requirements.should == []

      # and also make sure the form remembers that it's gone (#8329)
      driver.action.move_to(context_module).perform
      f('.edit_module_link').click
      f('.ui-dialog').should be_displayed
      edit_form = driver.find_element(:id, 'add_context_module_form')
      ff('.completion_entry .delete_criterion_link', edit_form).should be_empty
    end

    it "should delete a module item" do
      add_existing_module_item('#assignments_select', 'Assignment', @assignment.title)
      driver.execute_script("$('.context_module_item').addClass('context_module_item_hover')")
      driver.find_element(:css, '.delete_item_link').click
      driver.switch_to.alert.should_not be_nil
      driver.switch_to.alert.accept
      wait_for_ajaximations
      keep_trying_until do
        driver.find_element(:css, '.context_module_items').should_not include_text(@assignment.title)
        true
      end
    end

    it "should edit a module item and validate the changes stick" do
      item_edit_text = "Assignment Edit 1"
      module_item = add_existing_module_item('#assignments_select', 'Assignment', @assignment.title)
      tag = ContentTag.last
      edit_module_item(module_item) do |edit_form|
        replace_content(edit_form.find_element(:id, 'content_tag_title'), item_edit_text)
      end
      module_item = driver.find_element(:id, "context_module_item_#{tag.id}")
      module_item.should include_text(item_edit_text)

      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      driver.find_element(:css, 'h2.title').text.should == item_edit_text

      expect_new_page_load { driver.find_element(:css, '.modules').click }
      driver.find_element(:css, "#context_module_item_#{tag.id} .title").text.should == item_edit_text
    end

    it "should add an assignment to a module" do
      add_existing_module_item('#assignments_select', 'Assignment', @assignment.title)
    end

    it "should allow adding an item twice" do
      item1 = add_existing_module_item('#assignments_select', 'Assignment', @assignment.title)
      item2 = add_existing_module_item('#assignments_select', 'Assignment', @assignment.title)
      item1.should_not == item2
      @assignment.reload.context_module_tags.size.should == 2
    end

    it "should rename all instances of an item" do
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

    it "should not rename every text header when you rename one" do
      add_module('TestModule')

      # add a text header
      driver.find_element(:css, '.add_module_item_link').click
      select_module_item('#add_module_item_select', 'Text Header')
      wait_for_ajaximations
      title_input = find_with_jquery('input[name="title"]:visible')
      replace_content(title_input, 'First text header')
      driver.find_element(:css, '.add_item_button').click
      wait_for_ajaximations
      tag1 = ContentTag.last

      # and another one
      driver.find_element(:css, '.add_module_item_link').click
      select_module_item('#add_module_item_select', 'Text Header')
      wait_for_ajaximations
      title_input = find_with_jquery('input[name="title"]:visible')
      replace_content(title_input, 'Second text header')
      driver.find_element(:css, '.add_item_button').click
      wait_for_ajaximations
      tag2 = ContentTag.last

      # rename the second
      item2 = driver.find_element(:id, "context_module_item_#{tag2.id}")
      edit_module_item(item2) do |edit_form|
        replace_content(edit_form.find_element(:id, 'content_tag_title'), 'Renamed!')
      end

      # verify the first did not change
      item1 = driver.find_element(:id, "context_module_item_#{tag1.id}")
      item1.should_not include_text('Renamed!')
    end

    it "should add a quiz to a module" do
      add_existing_module_item('#quizs_select', 'Quiz', @quiz.title)
    end

    it "should add a new quiz to a module in a specific assignment group" do
      add_new_module_item('#quizs_select', 'Quiz', '[ New Quiz ]', "New Quiz") do
        click_option("select[name='quiz[assignment_group_id]']", @ag2.name)
      end
      @ag2.assignments.length.should == 1
      @ag2.assignments.first.title.should == "New Quiz"
    end

    it "should add a content page item to a module" do
      add_new_module_item('#wiki_pages_select', 'Content Page', '[ New Page ]', 'New Page Title')
    end

    it "should add a discussion item to a module" do
      add_new_module_item('#discussion_topics_select', 'Discussion', '[ New Topic ]', 'New Discussion Title')
    end

    it "should add a text header to a module" do
      header_text = 'new header text'
      add_module('Text Header Module')
      driver.find_element(:css, '.add_module_item_link').click
      select_module_item('#add_module_item_select', 'Text Header')
      keep_trying_until do
        replace_content(driver.find_element(:id, 'sub_header_title'), header_text)
        true
      end
      driver.find_element(:css, '.add_item_button').click
      wait_for_ajaximations
      tag = ContentTag.last
      module_item = driver.find_element(:id, "context_module_item_#{tag.id}")
      module_item.should include_text(header_text)
    end

    it "should add an external url item to a module" do
      add_new_external_item('External URL', 'www.google.com', 'Google')
    end

    it "should add an external tool item to a module" do
      add_new_external_item('External Tool', 'www.instructure.com', 'Instructure')
    end

    it "should hide module contents" do
      add_existing_module_item('#assignments_select', 'Assignment', @assignment.title)
      driver.find_element(:css, '.collapse_module_link').click
      wait_for_animations
      driver.find_element(:css, '.context_module .content').should_not be_displayed
    end

    it "should add 2 modules with the first one as a prerequisite" do
      pending("Bug 6711 - Prerequisite module doesn't save when creating and saving module in one step") do
        first_module_name = 'First Module'
        second_module_name = 'Second Module'

        add_module(first_module_name)
        #adding second module - can't use add_module method because a prerequisite needs to be added to this module
        add_form = new_module_form
        replace_content(add_form.find_element(:id, 'context_module_name'), second_module_name)
        driver.find_element(:css, '.ui-dialog .add_prerequisite_link').click
        wait_for_animations
        #have to do it this way because the select has no css attributes on it
        click_option('.criterion select', "the module, #{first_module_name}")
        submit_form(add_form)
        wait_for_ajaximations
        db_module = ContextModule.last
        context_module = driver.find_element(:id, "context_module_#{db_module.id}")
        driver.action.move_to(context_module).perform
        driver.find_element(:css, "#context_module_#{db_module.id} .edit_module_link").click
        driver.find_element(:css, '.ui-dialog').should be_displayed
        wait_for_ajaximations
        prereq_select = find_with_jquery('.criterion select')
        option = first_selected_option(prereq_select)
        option.text.should == 'the module, ' + first_module_name
      end
    end

    it "should rearrange modules" do
      skip_if_ie("Drag and Drop not working in IE, line 65")
      m1 = @course.context_modules.create!(:name => 'module 1')
      m2 = @course.context_modules.create!(:name => 'module 2')

      refresh_page
      sleep 2 #not sure what we are waiting on but drag and drop will not work, unless we wait

      m1_img = find_with_jquery('#context_modules .context_module:first-child .reorder_module_link img')
      m2_img = find_with_jquery('#context_modules .context_module:last-child .reorder_module_link img')
      driver.action.drag_and_drop(m2_img, m1_img).perform
      wait_for_ajax_requests

      m1.reload
      m1.position.should == 2
      m2.reload
      m2.position.should == 1
    end

    it "should validate locking a module item display functionality" do
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
      add_existing_module_item('#assignments_select', 'Assignment', @assignment.title)
      tag = ContentTag.last

      driver.execute_script("$('#context_module_item_#{tag.id} .indent_item_link').hover().click()")
      wait_for_ajaximations
      driver.find_element(:id, "context_module_item_#{tag.id}").attribute(:class).should include("indent_1")

      tag.reload
      tag.indent.should == 1
    end

    it "should properly change indent of an item from edit dialog" do
      add_existing_module_item('#assignments_select', 'Assignment', @assignment.title)
      tag = ContentTag.last

      driver.execute_script("$('#context_module_item_#{tag.id} .edit_item_link').hover().click()")
      click_option("#content_tag_indent_select", "Indent 1 Level")
      submit_form("#edit_item_form")
      wait_for_ajaximations
      driver.find_element(:id, "context_module_item_#{tag.id}").attribute(:class).should include("indent_1")

      tag.reload
      tag.indent.should == 1
    end

    it "should still display due date and points possible after indent change" do
      module_item = add_existing_module_item('#assignments_select', 'Assignment', @assignment2.title)
      tag = ContentTag.last

      module_item.find_element(:css, ".due_date_display").text.should_not be_blank
      module_item.find_element(:css, ".points_possible_display").should include_text "10"

      # change indent with arrows
      driver.execute_script("$('#context_module_item_#{tag.id} .indent_item_link').hover().click()")
      wait_for_ajaximations

      module_item = driver.find_element(:id, "context_module_item_#{tag.id}")
      module_item.find_element(:css, ".due_date_display").text.should_not be_blank
      module_item.find_element(:css, ".points_possible_display").should include_text "10"

      # change indent from edit form
      driver.execute_script("$('#context_module_item_#{tag.id} .edit_item_link').hover().click()")
      click_option("#content_tag_indent_select", "Don't Indent")
      submit_form("#edit_item_form")
      wait_for_ajaximations

      module_item = driver.find_element(:id, "context_module_item_#{tag.id}")
      module_item.find_element(:css, ".due_date_display").text.should_not be_blank
      module_item.find_element(:css, ".points_possible_display").should include_text "10"
    end

    it "should preserve completion criteria after indent change" do
      module_item = add_existing_module_item('#assignments_select', 'Assignment', @assignment2.title)
      tag = ContentTag.last

      # add completion criterion
      context_module = f('.context_module')
      driver.action.move_to(context_module).perform
      f('.edit_module_link').click
      edit_form = driver.find_element(:id, 'add_context_module_form')
      f('.add_completion_criterion_link', edit_form).click
      wait_for_ajaximations
      click_option('#add_context_module_form .assignment_picker', @assignment2.title, :text)
      click_option('#add_context_module_form .assignment_requirement_picker', 'must_contribute', :value)
      submit_form(edit_form)
      wait_for_ajax_requests

      # verify it shows up (both visually and in the template data)
      module_item = driver.find_element(:id, "context_module_item_#{tag.id}")
      module_item.attribute('class').split.should include 'must_contribute_requirement'
      f('.criterion', module_item).attribute('class').split.should include 'defined'
      driver.execute_script("return $('#context_module_item_#{tag.id} .criterion_type').text()").should == "must_contribute"

      # now indent the item
      driver.execute_script("$('#context_module_item_#{tag.id} .indent_item_link').hover().click()")
      wait_for_ajaximations

      # make sure the completion criterion was preserved
      module_item = driver.find_element(:id, "context_module_item_#{tag.id}")
      module_item.attribute('class').split.should include 'must_contribute_requirement'
      f('.criterion', module_item).attribute('class').split.should include 'defined'
      driver.execute_script("return $('#context_module_item_#{tag.id} .criterion_type').text()").should == "must_contribute"
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
      pending("bug 6233 - when replacing a file, module links are unexpectedly deleted") do
        course_module
        @module.add_item({:id => @file.id, :type => 'attachment'})
        get "/courses/#{@course.id}/modules"

        driver.find_element(:css, '.context_module_item').should include_text(FILE_NAME)
        file = @course.attachments.create!(:display_name => FILE_NAME, :uploaded_data => default_uploaded_data)
        file.context = @course
        file.save!
        Attachment.last.handle_duplicates(:overwrite)
        refresh_page
        driver.find_element(:css, '.context_module_item').should include_text(FILE_NAME)
      end
    end
  end
end
