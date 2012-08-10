require File.expand_path(File.dirname(__FILE__) + "/common")

describe "context_modules" do
  it_should_behave_like "in-process server selenium tests"

  context "as a student" do
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

      # shouldn't show the teacher's "show student progression" button
      ff('.module_progressions_link').should_not be_present

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
      it "should show the right nav when an item is in modules multiple times" do
        @assignment = @course.assignments.create!(:title => "some assignment")
        @atag1 = @module_1.add_item(:id => @assignment.id, :type => "assignment")
        @after1 = @module_1.add_item(:type => "external_url", :title => "url1", :url => "http://example.com/1")
        @atag2 = @module_2.add_item(:id => @assignment.id, :type => "assignment")
        @after2 = @module_2.add_item(:type => "external_url", :title => "url2", :url => "http://example.com/2")
        get "/courses/#{@course.id}/modules/items/#{@atag1.id}"
        wait_for_ajaximations
        prev = driver.find_element(:css, '#sequence_footer a.prev')
        URI.parse(prev.attribute('href')).path.should == "/courses/#{@course.id}/modules/items/#{@tag_1.id}"
        nxt = driver.find_element(:css, '#sequence_footer a.next')
        URI.parse(nxt.attribute('href')).path.should == "/courses/#{@course.id}/modules/items/#{@after1.id}"

        get "/courses/#{@course.id}/modules/items/#{@atag2.id}"
        wait_for_ajaximations
        prev = driver.find_element(:css, '#sequence_footer a.prev')
        URI.parse(prev.attribute('href')).path.should == "/courses/#{@course.id}/modules/items/#{@tag_2.id}"
        nxt = driver.find_element(:css, '#sequence_footer a.next')
        URI.parse(nxt.attribute('href')).path.should == "/courses/#{@course.id}/modules/items/#{@after2.id}"

        # if the user didn't get here from a module link, we show no nav,
        # because we can't know which nav to show
        get "/courses/#{@course.id}/assignments/#{@assignment.id}"
        wait_for_ajaximations
        prev = driver.find_element(:css, '#sequence_footer a.prev')
        prev.should_not be_displayed
        nxt = driver.find_element(:css, '#sequence_footer a.next')
        nxt.should_not be_displayed
      end

      it "should show the nav when going straight to the item if there's only one tag" do
        @assignment = @course.assignments.create!(:title => "some assignment")
        @atag1 = @module_1.add_item(:id => @assignment.id, :type => "assignment")
        @after1 = @module_1.add_item(:type => "external_url", :title => "url1", :url => "http://example.com/1")
        get "/courses/#{@course.id}/assignments/#{@assignment.id}"
        wait_for_ajaximations
        prev = driver.find_element(:css, '#sequence_footer a.prev')
        URI.parse(prev.attribute('href')).path.should == "/courses/#{@course.id}/modules/items/#{@tag_1.id}"
        nxt = driver.find_element(:css, '#sequence_footer a.next')
        URI.parse(nxt.attribute('href')).path.should == "/courses/#{@course.id}/modules/items/#{@after1.id}"
      end

      it "should show module navigation for group assignment discussions" do
        pending('intermittently fails')
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
