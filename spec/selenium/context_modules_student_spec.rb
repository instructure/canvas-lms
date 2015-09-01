require File.expand_path(File.dirname(__FILE__) + "/common")
require File.expand_path(File.dirname(__FILE__) + '/helpers/context_modules_common')

describe "context modules" do
  include_context "in-process server selenium tests"

  context "as a student, with multiple modules", priority: "1" do
    before(:each) do
      @locked_text = 'locked'
      @completed_text = 'completed'
      @in_progress_text = 'in progress'

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
      @quiz_1.publish!
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
      expect(ff('.module_progressions_link')).not_to be_present

      context_modules = ff('.context_module')
      #initial check to make sure everything was setup correctly
      validate_context_module_status_text(0, @in_progress_text)
      validate_context_module_status_text(1, @locked_text)
      validate_context_module_status_text(2, @locked_text)

      expect(context_modules[1].find_element(:css, '.prerequisites_message')).to include_text(@module_1.name)
      expect(context_modules[2].find_element(:css, '.prerequisites_message')).to include_text(@module_2.name)
    end

    it "should not lock modules for observers" do
      @course.enroll_user(user, 'ObserverEnrollment', :enrollment_state => 'active', :associated_user_id => @student.id)
      user_session(@user)

      go_to_modules

      # shouldn't show the teacher's "show student progression" button
      expect(ff('.module_progressions_link')).not_to be_present

      context_modules = ff('.context_module')
      #initial check to make sure everything was setup correctly
      ff('.context_module .progression_container').each do |item|
        expect(item.text.strip).to be_blank
      end
      get "/courses/#{@course.id}/assignments/#{@assignment_2.id}"
      expect(f('#content')).not_to include_text("hasn't been unlocked yet")
    end

    it "should show overridden due dates for assignments" do
      override = assignment_override_model(:assignment => @assignment_2)
      override.override_due_at(4.days.from_now)
      override.save!
      override_student = override.assignment_override_students.build
      override_student.user = @student
      override_student.save!

      go_to_modules
      context_modules = ff('.context_module')
      expect(context_modules[1].find_element(:css, '.due_date_display').text).not_to be_blank
    end

    it "should move a student through context modules in sequential order" do
      go_to_modules

      #sequential normal validation
      navigate_to_module_item(0, @assignment_1.title)
      validate_context_module_status_text(0, @completed_text)
      validate_context_module_status_text(1, @in_progress_text)
      validate_context_module_status_text(2, @locked_text)

      navigate_to_module_item(1, @assignment_2.title)
      validate_context_module_status_text(0, @completed_text)
      validate_context_module_status_text(1, @completed_text)
      validate_context_module_status_text(2, @in_progress_text)

      navigate_to_module_item(2, @quiz_1.title)
      validate_context_module_status_text(0, @completed_text)
      validate_context_module_status_text(1, @completed_text)
      validate_context_module_status_text(2, @completed_text)
    end

    it "should show progression in large_roster courses" do
      @course.large_roster = true
      @course.save!
      go_to_modules
      navigate_to_module_item(0, @assignment_1.title)
      validate_context_module_status_text(0, @completed_text)
    end

    it "should validate that a student can't get to a locked context module" do
      go_to_modules
      #sequential error validation
      get "/courses/#{@course.id}/assignments/#{@assignment_2.id}"
      expect(f('#content')).to include_text("hasn't been unlocked yet")
      expect(f('#module_prerequisites_list')).to be_displayed
    end

    it "should validate that a student can't get to locked external items" do
      external_tool = @course.context_external_tools.create!(:url => "http://example.com/ims/lti",
          :consumer_key => "asdf", :shared_secret => "hjkl", :name => "external tool")

      @module_2.reload
      tag_1 = @module_2.add_item(:id => external_tool.id, :type => "external_tool", :url => external_tool.url)
      tag_2 = @module_2.add_item(:type => 'external_url', :url => 'http://example.com/lolcats',
                                  :title => 'pls view', :indent => 1)

      tag_1.publish!
      tag_2.publish!

      get "/courses/#{@course.id}/modules/items/#{tag_1.id}"
      expect(f('#content')).to include_text("hasn't been unlocked yet")
      expect(f('#module_prerequisites_list')).to be_displayed

      get "/courses/#{@course.id}/modules/items/#{tag_2.id}"
      expect(f('#content')).to include_text("hasn't been unlocked yet")
      expect(f('#module_prerequisites_list')).to be_displayed
    end

    it "should validate that a student can't get to an unpublished context module item" do
      @module_2.workflow_state = 'unpublished'
      @module_2.save!

      get "/courses/#{@course.id}/assignments/#{@assignment_2.id}"
      expect(f('#content')).to include_text("is not available yet")
      expect(f('#module_prerequisites_list')).to be_nil
    end

    it "should validate that a student can't see an unpublished context module item", priority: "1", test_id: 126745 do
      @assignment_2.workflow_state = 'unpublished'
      @assignment_2.save!

      module1_unpublished_tag = @module_1.add_item({:id => @assignment_2.id, :type => 'assignment'})
      @module_1.completion_requirements = {@tag_1.id => {:type => 'must_view'}, module1_unpublished_tag.id => {:type => 'must_view'}}
      @module_1.save!
      expect(@module_1.completion_requirements.map{|h| h[:id]}).to include(@tag_1.id)
      expect(@module_1.completion_requirements.map{|h| h[:id]}).to include(module1_unpublished_tag.id) # unpublished requirements SHOULD remain

      module2_published_tag = @module_2.add_item({:id => @quiz_1.id, :type => 'quiz'})
      @module_2.save!

      go_to_modules

      context_modules = ff('.context_module')
      expect(context_modules[0].find_element(:css, '.context_module_items')).not_to include_text(@assignment_2.name)
      expect(context_modules[1].find_element(:css, '.context_module_items')).not_to include_text(@assignment_2.name)

      # Should go to the next module
      get "/courses/#{@course.id}/assignments/#{@assignment_1.id}"
      nxt = f('.module-sequence-footer a.pull-right')
      expect(URI.parse(nxt.attribute('href')).path).to eq "/courses/#{@course.id}/modules/items/#{module2_published_tag.id}"

      # Should redirect to the published item
      get "/courses/#{@course.id}/modules/#{@module_2.id}/items/first"
      expect(driver.current_url).to match %r{/courses/#{@course.id}/quizzes/#{@quiz_1.id}}
    end

    it "should validate that a students cannot see unassigned differentiated assignments" do
      @assignment_2.only_visible_to_overrides = true
      @assignment_2.save!

      @course.enable_feature!(:differentiated_assignments)
      @student.enrollments.each(&:destroy)
      @overriden_section = @course.course_sections.create!(name: "test section")
      student_in_section(@overriden_section, user: @student)

      go_to_modules

      context_modules = ff('.context_module')
      expect(context_modules[0].find_element(:css, '.context_module_items')).not_to include_text(@assignment_2.name)
      expect(context_modules[1].find_element(:css, '.context_module_items')).not_to include_text(@assignment_2.name)

      # Should not redirect to the hidden assignment
      get "/courses/#{@course.id}/modules/#{@module_2.id}/items/first"
      expect(driver.current_url).not_to match %r{/courses/#{@course.id}/assignments/#{@assignment_2.id}}

      create_section_override_for_assignment(@assignment_2, {course_section: @overriden_section})

      # Should redirect to the now visible assignment
      get "/courses/#{@course.id}/modules/#{@module_2.id}/items/first"
      expect(driver.current_url).to match %r{/courses/#{@course.id}/assignments/#{@assignment_2.id}}
    end

    it "should lock module until a given date", priority: "1", test_id: 126741 do
      mod_lock = @course.context_modules.create! name: 'a_locked_mod', unlock_at: 1.day.from_now
      go_to_modules
      expect(fj("#context_module_content_#{mod_lock.id} .unlock_details").text).to include_text 'Will unlock'
    end

    it "should allow a student view student to progress through module content" do
      course_with_teacher_logged_in(:course => @course, :active_all => true)
      @fake_student = @course.student_view_student

      enter_student_view

      #sequential error validation
      get "/courses/#{@course.id}/assignments/#{@assignment_2.id}"
      expect(f('#content')).to include_text("hasn't been unlocked yet")
      expect(f('#module_prerequisites_list')).to be_displayed

      go_to_modules

      #sequential normal validation
      navigate_to_module_item(0, @assignment_1.title)
      validate_context_module_status_text(0, @completed_text)
      validate_context_module_status_text(1, @in_progress_text)
      validate_context_module_status_text(2, @locked_text)

      navigate_to_module_item(1, @assignment_2.title)
      validate_context_module_status_text(0, @completed_text)
      validate_context_module_status_text(1, @completed_text)
      validate_context_module_status_text(2, @in_progress_text)

      navigate_to_module_item(2, @quiz_1.title)
      validate_context_module_status_text(0, @completed_text)
      validate_context_module_status_text(1, @completed_text)
      validate_context_module_status_text(2, @completed_text)
    end

    context "next and previous buttons", priority: "2" do

      def verify_next_and_previous_buttons_display
        wait_for_ajaximations
        expect(f('.module-sequence-footer a.pull-left')).to be_displayed
        expect(f('.module-sequence-footer a.pull-right')).to be_displayed
      end

      def module_setup
        course_with_teacher_logged_in(:active_all => true)
        @module = @course.context_modules.create!(:name => "module")

        #create module items
        #add first and last module items to get previous and next displayed
        @assignment1 = @course.assignments.create!(:title => 'first item in module')
        @assignment2 = @course.assignments.create!(:title => 'assignment')
        @assignment3 = @course.assignments.create!(:title => 'last item in module')
        @quiz = @course.quizzes.create!(:title => 'quiz assignment')
        @quiz.publish!
        @wiki = @course.wiki.wiki_pages.create!(:title => "wiki", :body => 'hi')
        @discussion = @course.discussion_topics.create!(:title => 'discussion')

        #add items to module
        @module.add_item :type => 'assignment', :id => @assignment1.id
        @module.add_item :type => 'assignment', :id => @assignment2.id
        @module.add_item :type => 'quiz', :id => @quiz.id
        @module.add_item :type => 'wiki_page', :id => @wiki.id
        @module.add_item :type => 'discussion_topic', :id => @discussion.id
        @module.add_item :type => 'assignment', :id => @assignment3.id

        #add external tool
        @tool = @course.context_external_tools.create!(:name => "new tool", :consumer_key => "key", :shared_secret => "secret", :domain => 'example.com', :custom_fields => {'a' => '1', 'b' => '2'})
        @external_tool_tag = @module.add_item({
                                                  :type => 'context_external_tool',
                                                  :title => 'Example',
                                                  :url => 'http://www.example.com',
                                                  :new_tab => '0'
                                              })
        @external_tool_tag.publish!
        #add external url
        @external_url_tag = @module.add_item({
                                                 :type => 'external_url',
                                                 :title => 'pls view',
                                                 :url => 'http://example.com/lolcats'
                                             })
        @external_url_tag.publish!

        #add another assignment at the end to create a bookend, provides next and previous for external url
        @module.add_item :type => 'assignment', :id => @assignment3.id
      end

      before(:each) do
        module_setup
      end

      it "should show previous and next buttons for quizzes" do
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
        verify_next_and_previous_buttons_display
      end

      it "should show previous and next buttons for assignments" do
        get "/courses/#{@course.id}/assignments/#{@assignment2.id}"
        verify_next_and_previous_buttons_display
      end

      it "should show previous and next buttons for wiki pages" do
        get "/courses/#{@course.id}/pages/#{@wiki.id}"
        verify_next_and_previous_buttons_display
      end

      it "should show previous and next buttons for discussions" do
        get "/courses/#{@course.id}/discussion_topics/#{@discussion.id}"
        verify_next_and_previous_buttons_display
      end

      it "should show previous and next buttons for external tools" do
        get "/courses/#{@course.id}/modules/items/#{@external_tool_tag.id}"
        verify_next_and_previous_buttons_display
      end

      it "should show previous and next buttons for external urls" do
        get "/courses/#{@course.id}/modules/items/#{@external_url_tag.id}"
        verify_next_and_previous_buttons_display
      end
    end

    describe "sequence footer" do
      it "should show the right nav when an item is in modules multiple times" do
        @assignment = @course.assignments.create!(:title => "some assignment")
        @atag1 = @module_1.add_item(:id => @assignment.id, :type => "assignment")
        @after1 = @module_1.add_item(:type => "external_url", :title => "url1", :url => "http://example.com/1")
        @after1.publish!
        @atag2 = @module_2.add_item(:id => @assignment.id, :type => "assignment")
        @after2 = @module_2.add_item(:type => "external_url", :title => "url2", :url => "http://example.com/2")
        @after2.publish!
        get "/courses/#{@course.id}/modules/items/#{@atag1.id}"
        prev = f('.module-sequence-footer a.pull-left')
        expect(URI.parse(prev.attribute('href')).path).to eq "/courses/#{@course.id}/modules/items/#{@tag_1.id}"
        nxt = f('.module-sequence-footer a.pull-right')
        expect(URI.parse(nxt.attribute('href')).path).to eq "/courses/#{@course.id}/modules/items/#{@after1.id}"

        get "/courses/#{@course.id}/modules/items/#{@atag2.id}"
        prev = f('.module-sequence-footer a.pull-left')
        expect(URI.parse(prev.attribute('href')).path).to eq "/courses/#{@course.id}/modules/items/#{@tag_2.id}"
        nxt = f('.module-sequence-footer a.pull-right')
        expect(URI.parse(nxt.attribute('href')).path).to eq "/courses/#{@course.id}/modules/items/#{@after2.id}"

        # if the user didn't get here from a module link, we show no nav,
        # because we can't know which nav to show
        get "/courses/#{@course.id}/assignments/#{@assignment.id}"
        prev = f('.module-sequence-footer a.pull-left')
        expect(prev).to be_nil
        nxt = f('.module-sequence-footer a.pull-right')
        expect(nxt).to be_nil
      end

      it "should show the nav when going straight to the item if there's only one tag" do
        @assignment = @course.assignments.create!(:title => "some assignment")
        @atag1 = @module_1.add_item(:id => @assignment.id, :type => "assignment")
        @after1 = @module_1.add_item(:type => "external_url", :title => "url1", :url => "http://example.com/1")
        @after1.publish!
        get "/courses/#{@course.id}/assignments/#{@assignment.id}"
        prev = f('.module-sequence-footer a.pull-left')
        expect(URI.parse(prev.attribute('href')).path).to eq "/courses/#{@course.id}/modules/items/#{@tag_1.id}"
        nxt = f('.module-sequence-footer a.pull-right')
        expect(URI.parse(nxt.attribute('href')).path).to eq "/courses/#{@course.id}/modules/items/#{@after1.id}"
      end

      it "should show module navigation for group assignment discussions" do
        skip('intermittently fails')
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

        prev = f('.module-sequence-footer a.pull-left')
        expect(URI.parse(prev.attribute('href')).path).to eq "/courses/#{@course.id}/modules/items/#{i1.id}"

        nxt = f('.module-sequence-footer a.pull-right')
        expect(URI.parse(nxt.attribute('href')).path).to eq "/courses/#{@course.id}/modules/items/#{i3.id}"
      end
    end

    context 'mark as done' do
      def setup
        @mark_done_module = create_context_module('Mark Done Module')
        page = @course.wiki.wiki_pages.create!(:title => "The page", :body => 'hi')
        @tag = @mark_done_module.add_item({:id => page.id, :type => 'wiki_page'})
        @mark_done_module.completion_requirements = {@tag.id => {:type => 'must_mark_done'}}
        @mark_done_module.save!
      end

      def navigate_to_wikipage(title)
        els = ff('.context_module_item')
        el = els.find {|e| e.text =~ /#{title}/}
        el.find_element(:css, 'a').click
        wait_for_ajaximations
      end

      it "On the modules page: the user sees an incomplete module with a 'mark as done' requirement. The user clicks on the module item, marks it as done, and back on the modules page can now see that the module is completed" do
        setup
        go_to_modules
        expect(f('.progression_state').text).to eq "in progress"
        navigate_to_wikipage 'The page'
        el = f '#mark-as-done-checkbox'
        expect(el).to_not be_nil
        expect(el).to_not be_selected
        el.click
        go_to_modules
        el = f "#context_modules .context_module[data-module-id='#{@mark_done_module.id}']"
        expect(f('.progression_state', el).text).to eq "completed"
        expect(f("#context_module_item_#{@tag.id} .requirement-description .must_mark_done_requirement .fulfilled")).to be_displayed
        expect(f("#context_module_item_#{@tag.id} .requirement-description .must_mark_done_requirement .unfulfilled")).to_not be_displayed
      end
    end
  end

  it "should fetch locked module prerequisites" do
    course_with_teacher(:active_all => true)
    student_in_course(:course => @course, :active_all => true)
    @module = @course.context_modules.create!(:name => "module", :require_sequential_progress => true)
    @assignment = @course.assignments.create!(:title => "assignment")
    @assignment2 = @course.assignments.create!(:title => "assignment2")

    @tag1 = @module.add_item :id => @assignment.id, :type => 'assignment'
    @tag2 = @module.add_item :id => @assignment2.id, :type => 'assignment'

    @module.completion_requirements = {@tag1.id => {:type => 'must_view'}, @tag2.id => {:type => 'must_view'}}
    @module.save!

    user_session(@student)

    get "/courses/#{@course.id}/assignments/#{@assignment2.id}"

    wait_for_ajaximations
    expect(f("#module_prerequisites_list")).to be_displayed
    expect(f(".module_prerequisites_fallback")).to_not be_displayed
  end

  it "should validate that a student can see published and not see unpublished context module", priority: "1", test_id: 126744 do
    course_with_teacher(active_all: true)
    student_in_course(course: @course, active_all: true)
    @module = @course.context_modules.create!(name: "module")
    @module_1 = @course.context_modules.create!(name: "module_1")
    @module_1.workflow_state = 'unpublished'
    @module_1.save!
    user_session(@student)
    go_to_modules
    expect(f("#context_modules").text).to eq "module"
    expect(f("#context_modules").text).not_to include_text "module_1"
  end

  it "should unlock module after a given date", priority: "1", test_id: 126746 do
    course_with_teacher(active_all: true)
    student_in_course(course: @course, active_all: true)
    mod_lock = @course.context_modules.create! name: 'a_locked_mod', unlock_at: 1.day.ago
    user_session(@student)
    go_to_modules
    expect(fj("#context_module_content_#{mod_lock.id} .unlock_details").text).not_to include_text 'Will unlock'
  end
end
