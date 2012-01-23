require File.expand_path(File.dirname(__FILE__) + "/common")

describe "context_modules" do
  it_should_behave_like "in-process server selenium tests"

  context "context modules as a teacher" do

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
      add_form.submit
      wait_for_ajaximations
      add_form.should_not be_displayed
      driver.find_element(:id, 'context_modules').should include_text(module_name)
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

    def io
      require 'action_controller'
      require 'action_controller/test_process.rb'
      ActionController::TestUploadedFile.new(File.expand_path(File.dirname(__FILE__) + '/../fixtures/scribd_docs/doc.doc'), 'application/msword', true)
    end

    before (:each) do
      course_with_teacher_logged_in

      #have to add quiz and assignment to be able to add them to a new module
      @quiz = @course.assignments.create!(:title => 'quiz assignment', :submission_types => 'online_quiz')
      @assignment = @course.assignments.create(:title => 'assignment 1', :submission_types => 'online_text_entry')
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
      edit_form.submit
      edit_form.should_not be_displayed
      wait_for_ajaximations
      driver.find_element(:css, '.context_module > .header').should include_text(edit_text)
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

    it "should edit a module item" do
      item_edit_text = "Assignment Edit 1"
      module_item = add_existing_module_item('#assignments_select', 'Assignment', @assignment.title)
      tag = ContentTag.last
      context_module_item = driver.find_element(:id, "context_module_item_#{tag.id}")
      driver.action.move_to(context_module_item).perform
      module_item.find_element(:css, '.edit_item_link').click
      edit_form = driver.find_element(:id, 'edit_item_form')
      replace_content(edit_form.find_element(:id, 'content_tag_title'), item_edit_text)
      edit_form.submit
      wait_for_ajaximations
      module_item = driver.find_element(:id, "context_module_item_#{tag.id}")
      module_item.should include_text(item_edit_text)
    end

    it "should add an assignment to a module" do
      add_existing_module_item('#assignments_select', 'Assignment', @assignment.title)
    end

    it "should add a quiz to a module" do
      add_existing_module_item('#quizs_select', 'Quiz', @quiz.title)
    end

    it "should add a file item to a module" do
      #adding file to course
      @folder = @course.folders.create!(:name => "test folder", :workflow_state => "visible")
      @file = @folder.active_file_attachments.build(:uploaded_data => io)
      @file.context = @course
      @file.save!

      #have to refresh the page for the file to show up in the select
      refresh_page
      add_existing_module_item('#attachments_select', 'File', 'doc.doc')
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
      pending("bug 6711 - test is finished just waiting on bug fix")
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
      add_form.submit
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
      add_form.find_element(:css, 'tr.unlock_module_at_details').should_not be_displayed
      lock_check.click
      wait_for_ajaximations
      add_form.find_element(:css, 'tr.unlock_module_at_details').should be_displayed
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

      go_to_modules
    end

    it "should validate that course modules show up correctly" do

      context_modules = driver.find_elements(:css, '.context_module')
      #initial check to make sure everything was setup correctly
      validate_context_module_status_text(0, IN_PROGRESS_TEXT)
      validate_context_module_status_text(1, LOCKED_TEXT)
      validate_context_module_status_text(2, LOCKED_TEXT)

      context_modules[1].find_element(:css, '.context_module_criterion').should include_text(@module_1.name)
      context_modules[2].find_element(:css, '.context_module_criterion').should include_text(@module_2.name)
    end

    it "should move a student through context modules in sequential order" do
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
      #sequential error validation
      get "/courses/#{@course.id}/modules/items/#{@assignment_2.id}"
      driver.find_element(:id, 'content').should include_text("hasn't been unlocked yet")
      driver.find_element(:id, 'module_prerequisites_list').should be_displayed
    end
  end
end
