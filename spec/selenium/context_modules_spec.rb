require File.expand_path(File.dirname(__FILE__) + "/common")

describe "context_modules" do
  it_should_behave_like "in-process server selenium tests"

  def io
    require 'action_controller'
    require 'action_controller/test_process.rb'
    ActionController::TestUploadedFile.new(File.expand_path(File.dirname(__FILE__) + '/../fixtures/scribd_docs/txt.txt'), 'text/plain', true)
  end

  def add_existing_module_item(item_select_selector, module_name, item_name)
    add_module(module_name + 'Module')
    driver.find_element(:css, '.add_module_item_link').click
    select_module_item('#add_module_item_select', module_name)
    select_module_item(item_select_selector + ' .module_item_select', item_name)
    driver.find_element(:css, '.add_item_button').click
    wait_for_ajaximations
    tag = ContentTag.last
    module_item = driver.find_element(:id, "context_module_item_#{tag.id}")
    module_item.should include_text(item_name)
    module_item
  end

  def select_module_item(select_element_css, item_text)
    click_option(select_element_css, item_text)
  end

  def new_module_form
    keep_trying_until do
      driver.find_element(:css, '.add_module_link').click
      driver.find_element(:css, '.ui-dialog').should be_displayed
    end
    add_form = driver.find_element(:id, 'add_context_module_form')
    add_form
  end

  def add_module(module_name = 'Test Module')
    add_form = new_module_form
    replace_content(add_form.find_element(:id, 'context_module_name'), module_name)
    submit_form(add_form)
    wait_for_ajaximations
    add_form.should_not be_displayed
    driver.find_element(:id, 'context_modules').should include_text(module_name)
  end

  def add_new_module_item(item_select_selector, module_name, new_item_text, item_title_text)
    add_module(module_name + 'Module')
    driver.find_element(:css, '.add_module_item_link').click
    select_module_item('#add_module_item_select', module_name)
    select_module_item(item_select_selector + ' .module_item_select', new_item_text)
    item_title = keep_trying_until do
      item_title = find_with_jquery('.item_title:visible')
      item_title.should be_displayed
      item_title
    end
    replace_content(item_title, item_title_text)
    yield if block_given?
    driver.find_element(:css, '.add_item_button').click
    wait_for_ajaximations
    tag = ContentTag.last
    module_item = driver.find_element(:id, "context_module_item_#{tag.id}")
    module_item.should include_text(item_title_text)
  end

  def add_new_external_item(module_name, url_text, page_name_text)
    add_module(module_name + 'Module')
    driver.find_element(:css, '.add_module_item_link').click
    select_module_item('#add_module_item_select', module_name)
    wait_for_ajaximations
    url_input = find_with_jquery('input[name="url"]:visible')
    title_input = find_with_jquery('input[name="title"]:visible')
    replace_content(url_input, url_text)

    replace_content(title_input, page_name_text)

    driver.find_element(:css, '.add_item_button').click
    wait_for_ajaximations
    tag = ContentTag.last
    module_item = driver.find_element(:id, "context_module_item_#{tag.id}")
    module_item.should include_text(page_name_text)
  end

  def course_module
    @module = @course.context_modules.create!(:name => "some module")
  end

  context "context modules as a teacher" do

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
      driver.execute_script("$('#context_module_item_#{tag.id}').addClass('context_module_item_hover')")
      module_item.find_element(:css, '.edit_item_link').click
      edit_form = driver.find_element(:id, 'edit_item_form')
      replace_content(edit_form.find_element(:id, 'content_tag_title'), item_edit_text)
      submit_form(edit_form)
      wait_for_ajaximations
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
        click_option(':input:visible.eq(3)', first_module_name)
        submit_form(add_form)
        wait_for_ajaximations
        db_module = ContextModule.last
        context_module = driver.find_element(:id, "context_module_#{db_module.id}")
        driver.action.move_to(context_module).perform
        driver.find_element(:css, "#context_module_#{db_module.id} .edit_module_link").click
        driver.find_element(:css, '.ui-dialog').should be_displayed
        wait_for_ajaximations
        prereq_select = find_all_with_jquery(':input:visible')[3]
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

  context "context modules as a student" do
    LOCKED_TEXT = 'locked'
    COMPLETED_TEXT = 'completed'
    IN_PROGRESS_TEXT = 'in progress'

    def create_context_module(module_name)
      context_module = @course.context_modules.create!(:name => module_name, :require_sequential_progress => true)
      context_module
    end

    def go_to_modules
      get "/courses/#{@course.id}/modules"
      wait_for_ajaximations
    end

    def validate_context_module_status_text(module_num, text_to_validate)
      context_modules_status = driver.find_elements(:css, '.context_module .progression_container')
      context_modules_status[module_num].should include_text(text_to_validate)
    end

    def navigate_to_module_item(module_num, link_text)
      context_modules = driver.find_elements(:css, '.context_module')
      expect_new_page_load { context_modules[module_num].find_element(:link, link_text).click }
      go_to_modules
    end

    before (:each) do
      course_with_student_logged_in
      #initial module setup
      @module_1 = create_context_module('Module One')
      @assignment_1 = @course.assignments.create!(:title => "assignment 1")
      @tag_1 = @module_1.add_item({:id => @assignment_1.id, :type => 'assignment'})
      @module_1.completion_requirements = {@tag_1.id => {:type => 'must_view'}}

      @module_2 = create_context_module('Module Two')
      @assignment_2 = @course.assignments.create!(:title => "assignment 2")
      @tag_2 = @module_2.add_item({:id => @assignment_2.id, :type => 'assignment'})
      @module_2.completion_requirements = {@tag_2.id => {:type => 'must_view'}}
      @module_2.prerequisites = "module_#{@module_1.id}"

      @module_3 = create_context_module('Module Three')
      @quiz_1 = @course.quizzes.create!(:title => "some quiz")
      @tag_3 = @module_3.add_item({:id => @quiz_1.id, :type => 'quiz'})
      @module_3.completion_requirements = {@tag_3.id => {:type => 'must_view'}}
      @module_3.prerequisites = "module_#{@module_2.id}"

      @module_1.save!
      @module_2.save!
      @module_3.save!
    end

    it "should validate that course modules show up correctly" do
      go_to_modules

      context_modules = driver.find_elements(:css, '.context_module')
      #initial check to make sure everything was setup correctly
      validate_context_module_status_text(0, IN_PROGRESS_TEXT)
      validate_context_module_status_text(1, LOCKED_TEXT)
      validate_context_module_status_text(2, LOCKED_TEXT)

      context_modules[1].find_element(:css, '.context_module_criterion').should include_text(@module_1.name)
      context_modules[2].find_element(:css, '.context_module_criterion').should include_text(@module_2.name)
    end

    it "should move a student through context modules in sequential order" do
      go_to_modules

      #sequential normal validation
      navigate_to_module_item(0, @assignment_1.title)
      validate_context_module_status_text(0, COMPLETED_TEXT)
      validate_context_module_status_text(1, IN_PROGRESS_TEXT)
      validate_context_module_status_text(2, LOCKED_TEXT)

      navigate_to_module_item(1, @assignment_2.title)
      validate_context_module_status_text(0, COMPLETED_TEXT)
      validate_context_module_status_text(1, COMPLETED_TEXT)
      validate_context_module_status_text(2, IN_PROGRESS_TEXT)

      navigate_to_module_item(2, @quiz_1.title)
      validate_context_module_status_text(0, COMPLETED_TEXT)
      validate_context_module_status_text(1, COMPLETED_TEXT)
      validate_context_module_status_text(2, COMPLETED_TEXT)
    end

    it "should validate that a student can't get to a locked context module" do
      go_to_modules

      #sequential error validation
      get "/courses/#{@course.id}/assignments/#{@assignment_2.id}"
      driver.find_element(:id, 'content').should include_text("hasn't been unlocked yet")
      driver.find_element(:id, 'module_prerequisites_list').should be_displayed
    end

    it "should allow a student view student to progress through module content" do
      course_with_teacher_logged_in(:course => @course, :active_all => true)
      @fake_student = @course.student_view_student

      enter_student_view

      #sequential error validation
      get "/courses/#{@course.id}/assignments/#{@assignment_2.id}"
      driver.find_element(:id, 'content').should include_text("hasn't been unlocked yet")
      driver.find_element(:id, 'module_prerequisites_list').should be_displayed

      go_to_modules

      #sequential normal validation
      navigate_to_module_item(0, @assignment_1.title)
      validate_context_module_status_text(0, COMPLETED_TEXT)
      validate_context_module_status_text(1, IN_PROGRESS_TEXT)
      validate_context_module_status_text(2, LOCKED_TEXT)

      navigate_to_module_item(1, @assignment_2.title)
      validate_context_module_status_text(0, COMPLETED_TEXT)
      validate_context_module_status_text(1, COMPLETED_TEXT)
      validate_context_module_status_text(2, IN_PROGRESS_TEXT)

      navigate_to_module_item(2, @quiz_1.title)
      validate_context_module_status_text(0, COMPLETED_TEXT)
      validate_context_module_status_text(1, COMPLETED_TEXT)
      validate_context_module_status_text(2, COMPLETED_TEXT)
    end

    describe "sequence footer" do
      it "should show module navigation for group assignment discussions" do
        group_assignment_discussion(:course => @course)
        @group.users << @student
        assignment_model(:course => @course)
        @module = ContextModule.create!(:context => @course)
        @page = wiki_page_model(:course => @course)
        i1 = @module.content_tags.create!(:context => @course, :content => @assignment, :tag_type => 'context_module')
        i2 = @module.content_tags.create!(:context => @course, :content => @root_topic, :tag_type => 'context_module')
        i3 = @module.content_tags.create!(:context => @course, :content => @page, :tag_type => 'context_module')
        @module2 = ContextModule.create!(:context => @course, :name => 'second module')
        get "/courses/#{@course.id}/modules/items/#{i2.id}"
        wait_for_ajaximations

        prev = driver.find_element(:css, '#sequence_footer a.prev')
        URI.parse(prev.attribute('href')).path.should == "/courses/#{@course.id}/modules/items/#{i1.id}"

        nxt = driver.find_element(:css, '#sequence_footer a.next')
        URI.parse(nxt.attribute('href')).path.should == "/courses/#{@course.id}/modules/items/#{i3.id}"
      end
    end
  end
end
