require File.expand_path(File.dirname(__FILE__) + "/common")
require File.expand_path(File.dirname(__FILE__) + '/helpers/context_modules_common')

describe "context modules" do
  include_context "in-process server selenium tests"
  include ContextModulesCommon

  before :once do
    @course = course_model.tap(&:offer!)
    @teacher = teacher_in_course(course: @course, name: 'teacher', active_all: true).user
    @student = student_in_course(course: @course, name: 'student', active_all: true).user
  end

  context "as a student, with multiple modules", priority: "1" do
    before :once do
      @locked_icon = 'icon-lock'
      @completed_icon = 'icon-check'
      @in_progress_icon = 'icon-minimize'
      @open_item_icon = 'icon-mark-as-read'
      @no_icon = 'no-icon'

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

    before :each do
      user_session(@student)
    end

    it "should validate that course modules show up correctly" do
      go_to_modules
      # shouldn't show the teacher's "show student progression" button
      expect(f("#content")).not_to contain_css('.module_progressions_link')

      context_modules = ff('.context_module')
      #initial check to make sure everything was setup correctly
      validate_context_module_status_icon(@module_1.id, @no_icon)
      validate_context_module_status_icon(@module_2.id, @locked_icon)
      validate_context_module_status_icon(@module_3.id, @locked_icon)

      expect(context_modules[1].find_element(:css, '.prerequisites_message')).to include_text(@module_1.name)
      expect(context_modules[2].find_element(:css, '.prerequisites_message')).to include_text(@module_2.name)
    end

    it "should not lock modules for observers" do
      @course.enroll_user(user, 'ObserverEnrollment', :enrollment_state => 'active', :associated_user_id => @student.id)
      user_session(@user)

      go_to_modules

      # shouldn't show the teacher's "show student progression" button
      expect(f("#content")).not_to contain_css('.module_progressions_link')

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

    it "moves a student through context modules in sequential order", priority: "2", test_id: 126742 do
      go_to_modules

      #sequential normal validation
      navigate_to_module_item(0, @assignment_1.title)
      validate_context_module_status_icon(@module_1.id, @completed_icon)
      validate_context_module_status_icon(@module_2.id, @no_icon)
      validate_context_module_status_icon(@module_3.id, @locked_icon)

      navigate_to_module_item(1, @assignment_2.title)
      validate_context_module_status_icon(@module_1.id, @completed_icon)
      validate_context_module_status_icon(@module_2.id, @completed_icon)
      validate_context_module_status_icon(@module_3.id, @no_icon)

      navigate_to_module_item(2, @quiz_1.title)
      validate_context_module_status_icon(@module_1.id, @completed_icon)
      validate_context_module_status_icon(@module_2.id, @completed_icon)
      validate_context_module_status_icon(@module_3.id, @completed_icon)
    end

    it "should not cache a changed module requirement" do
      other_assmt = @course.assignments.create!(:title => "assignment")
      other_tag = @module_1.add_item({:id => other_assmt.id, :type => 'assignment'})
      @module_1.completion_requirements = {@tag_1.id => {:type => 'must_view'}, other_tag.id => {:type => 'must_view'}}
      @module_1.save!

      get "/courses/#{@course.id}/assignments/#{@assignment_1.id}"

      # fulfill the must_view
      go_to_modules
      validate_context_module_item_icon(@tag_1.id, @completed_icon)

      # change the req
      @module_1.completion_requirements = {@tag_1.id => {:type => 'must_submit'}, other_tag.id => {:type => 'must_view'}}
      @module_1.save!

      go_to_modules
      validate_context_module_item_icon(@tag_1.id, @open_item_icon)
    end

    it "should show progression in large_roster courses" do
      @course.large_roster = true
      @course.save!
      go_to_modules
      navigate_to_module_item(0, @assignment_1.title)
      validate_context_module_status_icon(@module_1.id, @completed_icon)
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
      expect(f("#content")).not_to contain_css('#module_prerequisites_list')
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
      nxt = f(ENV['CANVAS_FORCE_USE_NEW_STYLES'] ? '.module-sequence-footer-button--next' : '.module-sequence-footer a.pull-right')
      expect(nxt).to have_attribute("href", "/courses/#{@course.id}/modules/items/#{module2_published_tag.id}")

      # Should redirect to the published item
      get "/courses/#{@course.id}/modules/#{@module_2.id}/items/first"
      expect(driver.current_url).to match %r{/courses/#{@course.id}/quizzes/#{@quiz_1.id}}
    end

    it "should validate that a students cannot see unassigned differentiated assignments" do
      @assignment_2.only_visible_to_overrides = true
      @assignment_2.save!

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
      expect(fj("#context_module_content_#{mod_lock.id} .unlock_details")).to include_text 'Will unlock'
    end

    it "does not show the description of a discussion locked by module", priority: "1", test_id: 1426125 do
      module1 = @course.context_modules.create! name: 'a_locked_mod', unlock_at: 1.day.from_now
      discussion = @course.discussion_topics.create!(title: 'discussion', message: 'discussion description')
      module1.add_item type: 'discussion_topic', id: discussion.id
      get "/courses/#{@course.id}/discussion_topics/#{discussion.id}?module_item_id=#{ContentTag.last.id}"
      expect(f('.entry-content')).not_to contain_css('.discussion-section .message')
    end

    it "should allow a student view student to progress through module content" do
      skip_if_chrome('breaks because of masquerade_bar')
      # course_with_teacher_logged_in(:course => @course, :active_all => true)
      user_session(@teacher)
      @fake_student = @course.student_view_student

      enter_student_view

      #sequential error validation
      get "/courses/#{@course.id}/assignments/#{@assignment_2.id}"
      expect(f('#content')).to include_text("hasn't been unlocked yet")
      expect(f('#module_prerequisites_list')).to be_displayed

      go_to_modules

      #sequential normal validation
      navigate_to_module_item(0, @assignment_1.title)
      validate_context_module_status_icon(@module_1.id, @completed_icon)
      validate_context_module_status_icon(@module_2.id, @no_icon)
      validate_context_module_status_icon(@module_3.id, @locked_icon)

      navigate_to_module_item(1, @assignment_2.title)
      validate_context_module_status_icon(@module_1.id, @completed_icon)
      validate_context_module_status_icon(@module_2.id, @completed_icon)
      validate_context_module_status_icon(@module_3.id, @no_icon)

      scroll_page_to_bottom

      navigate_to_module_item(2, @quiz_1.title)
      validate_context_module_status_icon(@module_1.id, @completed_icon)
      validate_context_module_status_icon(@module_2.id, @completed_icon)
      validate_context_module_status_icon(@module_3.id, @completed_icon)
    end

    context "next and previous buttons", priority: "2" do

      def verify_next_and_previous_buttons_display
        wait_for_ajaximations
        expect(f(ENV['CANVAS_FORCE_USE_NEW_STYLES'] ? '.module-sequence-footer-button--previous' : '.module-sequence-footer a.pull-left')).to be_displayed
        expect(f(ENV['CANVAS_FORCE_USE_NEW_STYLES'] ? '.module-sequence-footer-button--next' : '.module-sequence-footer a.pull-right')).to be_displayed
      end

      def module_setup

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

      before :each do
        user_session(@teacher)
      end

      before :once do
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
        prev = f(ENV['CANVAS_FORCE_USE_NEW_STYLES'] ? '.module-sequence-footer-button--previous' : '.module-sequence-footer a.pull-left')
        expect(prev).to have_attribute("href", "/courses/#{@course.id}/modules/items/#{@tag_1.id}")
        nxt = f(ENV['CANVAS_FORCE_USE_NEW_STYLES'] ? '.module-sequence-footer-button--next' : '.module-sequence-footer a.pull-right')
        expect(nxt).to have_attribute("href", "/courses/#{@course.id}/modules/items/#{@after1.id}")

        get "/courses/#{@course.id}/modules/items/#{@atag2.id}"
        prev = f(ENV['CANVAS_FORCE_USE_NEW_STYLES'] ? '.module-sequence-footer-button--previous' : '.module-sequence-footer a.pull-left')
        expect(prev).to have_attribute("href", "/courses/#{@course.id}/modules/items/#{@tag_2.id}")
        nxt = f(ENV['CANVAS_FORCE_USE_NEW_STYLES'] ? '.module-sequence-footer-button--next' : '.module-sequence-footer a.pull-right')
        expect(nxt).to have_attribute("href", "/courses/#{@course.id}/modules/items/#{@after2.id}")

        # if the user didn't get here from a module link, we show no nav,
        # because we can't know which nav to show
        get "/courses/#{@course.id}/assignments/#{@assignment.id}"
        expect(f("#content")).not_to contain_css(ENV['CANVAS_FORCE_USE_NEW_STYLES'] ? '.module-sequence-footer-button--previous' : '.module-sequence-footer a.pull-left')
        expect(f("#content")).not_to contain_css(ENV['CANVAS_FORCE_USE_NEW_STYLES'] ? '.module-sequence-footer-button--next' : '.module-sequence-footer a.pull-right')
      end

      it "should show the nav when going straight to the item if there's only one tag" do
        @assignment = @course.assignments.create!(:title => "some assignment")
        @atag1 = @module_1.add_item(:id => @assignment.id, :type => "assignment")
        @after1 = @module_1.add_item(:type => "external_url", :title => "url1", :url => "http://example.com/1")
        @after1.publish!
        get "/courses/#{@course.id}/assignments/#{@assignment.id}"
        prev = f(ENV['CANVAS_FORCE_USE_NEW_STYLES'] ? '.module-sequence-footer-button--previous' : '.module-sequence-footer a.pull-left')
        expect(prev).to have_attribute("href", "/courses/#{@course.id}/modules/items/#{@tag_1.id}")
        nxt = f(ENV['CANVAS_FORCE_USE_NEW_STYLES'] ? '.module-sequence-footer-button--next' : '.module-sequence-footer a.pull-right')
        expect(nxt).to have_attribute("href", "/courses/#{@course.id}/modules/items/#{@after1.id}")
      end

      # TODO reimplement per CNVS-29600, but make sure we're testing at the right level
      it "should show module navigation for group assignment discussions"
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
        el.find_element(:css, 'a.title').click
        wait_for_ajaximations
      end

      it "On the modules page: the user sees an incomplete module with a 'mark as done' requirement. The user clicks on the module item, marks it as done, and back on the modules page can now see that the module is completed" do
        setup
        go_to_modules

        validate_context_module_status_icon(@mark_done_module.id, @no_icon)
        navigate_to_wikipage 'The page'
        el = f '#mark-as-done-checkbox'
        expect(el).to_not be_nil
        expect(el).to_not be_selected
        el.click
        go_to_modules
        el = f "#context_modules .context_module[data-module-id='#{@mark_done_module.id}']"
        validate_context_module_status_icon(@mark_done_module.id, @completed_icon)
        expect(f("#context_module_item_#{@tag.id} .requirement-description .must_mark_done_requirement .fulfilled")).to be_displayed
        expect(f("#context_module_item_#{@tag.id} .requirement-description .must_mark_done_requirement .unfulfilled")).to_not be_displayed
      end

      it "should still show the mark done button when navigating directly" do
        mod = create_context_module('Mark Done Module')
        page = @course.wiki.wiki_pages.create!(:title => "page", :body => 'hi')
        assmt = @course.assignments.create!(:title => "assmt")

        tag1 = mod.add_item({:id => page.id, :type => 'wiki_page'})
        tag2 = mod.add_item({:id => assmt.id, :type => 'assignment'})
        mod.completion_requirements = {tag1.id => {:type => 'must_mark_done'}, tag2.id => {:type => 'must_mark_done'}}
        mod.save!

        get "/courses/#{@course.id}/pages/#{page.url}"
        el = f '#mark-as-done-checkbox'
        expect(el).to_not be_nil
        expect(el).to_not be_selected
        el.click
        wait_for_ajaximations

        get "/courses/#{@course.id}/assignments/#{assmt.id}"
        el = f '#mark-as-done-checkbox'
        expect(el).to_not be_nil
        expect(el).to_not be_selected
        el.click
        wait_for_ajaximations

        prog = mod.evaluate_for(@user)
        expect(prog).to be_completed
      end
    end

    describe "module header icons" do
      def create_additional_assignment_for_module_1
        @assignment_4 = @course.assignments.create!(:title => "assignment 4")
        @tag_4 = @module_1.add_item({:id => @assignment_4.id, :type => 'assignment'})
        @module_1.completion_requirements = {@tag_1.id => {:type => 'must_view'},
                                             @tag_4.id => {:type => 'must_view'}}
        @module_1.save!
      end

      def make_module_1_complete_one
        @module_1.requirement_count = 1
        @module_1.save!
      end

      it "should show a pill message that says 'Complete All Items'", priority: "1", test_id: 250296 do
        go_to_modules
        vaildate_correct_pill_message(@module_1.id, 'Complete All Items')
      end

      it "should show a pill message that says 'Complete One Item'", priority: "1", test_id: 250295 do
        make_module_1_complete_one
        go_to_modules

        vaildate_correct_pill_message(@module_1.id, 'Complete One Item')
      end

      it "should show a completed icon when module is complete for 'Complete All Items' requirement" do
        create_additional_assignment_for_module_1
        go_to_modules

        navigate_to_module_item(0, @assignment_1.title)
        navigate_to_module_item(0, @assignment_4.title)
        vaildate_correct_pill_message(@module_1.id, 'Complete All Items')
        validate_context_module_status_icon(@module_1.id, @completed_icon)
      end

      it "should show a completed icon when module is complete for 'Complete One Item' requirement", priority: "1", test_id: 250542 do
        create_additional_assignment_for_module_1
        make_module_1_complete_one
        go_to_modules

        navigate_to_module_item(0, @assignment_1.title)
        vaildate_correct_pill_message(@module_1.id, 'Complete One Item')
        validate_context_module_status_icon(@module_1.id, @completed_icon)
      end

      it "should show a locked icon when module is locked", priority:"1", test_id: 250541 do
        go_to_modules
        validate_context_module_status_icon(@module_2.id, @locked_icon)
      end

      it "should show a warning in-progress icon when module has been started", priority: "1", test_id: 250543 do
        create_additional_assignment_for_module_1
        go_to_modules

        navigate_to_module_item(0, @assignment_1.title)
        validate_context_module_status_icon(@module_1.id, @in_progress_icon)
      end

      it "should not show an icon when module has not been started", priority: "1", test_id: 250540 do
        go_to_modules
        validate_context_module_status_icon(@module_1.id, @no_icon)
      end
    end

    describe "module item icons" do
      def add_non_requirement
        @assignment_4 = @course.assignments.create!(:title => "assignment 4")
        @tag_4 = @module_1.add_item({:id => @assignment_4.id, :type => 'assignment'})
        @module_1.save!
      end

      def add_min_score_assignment
        @assignment_4 = @course.assignments.create!(:title => "assignment 4")
        @tag_4 = @module_1.add_item({:id => @assignment_4.id, :type => 'assignment'})
        @module_1.completion_requirements = {@tag_1.id => {:type => 'must_view'},
                                             @tag_4.id => {:type => 'min_score', :min_score => 90}}
        @module_1.require_sequential_progress = false
        @module_1.save!
      end

      def make_past_due
        @assignment_4.submission_types = 'online_text_entry'
        @assignment_4.due_at = '2015-01-01'
        @assignment_4.save!
      end

      def grade_assignment(score)
        @assignment_4.grade_student(@user, :grade => score)
      end

      it "should show a completed icon when module item is completed", priority: "1", test_id: 250546 do
        go_to_modules
        navigate_to_module_item(0, @assignment_1.title)
        validate_context_module_item_icon(@tag_1.id, @completed_icon)
      end

      it "should show an incomplete circle icon when module item is requirement but not complete", priority: "1", test_id: 250544 do
        go_to_modules
        validate_context_module_item_icon(@tag_1.id, @open_item_icon)
      end

      it "should not show an icon when module item is not a requirement", priority: "1", test_id: 250545 do
        add_non_requirement
        go_to_modules
        validate_context_module_item_icon(@tag_4.id, @no_icon)
      end

      it "should show incomplete for differentiated assignments" do
        @course.course_sections.create!
        assignment = @course.assignments.create!(:title => "assignmentt")
        create_section_override_for_assignment(assignment)
        assignment.only_visible_to_overrides = true
        assignment.save!

        tag = @module_1.add_item({:id => assignment.id, :type => 'assignment'})
        @module_1.completion_requirements = {tag.id => {:type => 'min_score', :min_score => 90}}
        @module_1.require_sequential_progress = false
        @module_1.save!

        go_to_modules

        validate_context_module_item_icon(tag.id, @open_item_icon)
      end

      it "should show a warning icon when module item is a min score requirement that didn't meet score requirment", priority: "1", test_id: 250547 do
        add_min_score_assignment
        grade_assignment(50)
        go_to_modules

        validate_context_module_item_icon(@tag_4.id, @in_progress_icon)
      end

      it "should show an info icon when module item is a min score requirement that has not yet been graded" do
        add_min_score_assignment
        @assignment_4.submission_types = 'online_text_entry'
        @assignment_4.save!

        @assignment_4.submit_homework(@user, :body => "body")
        go_to_modules

        validate_context_module_item_icon(@tag_4.id, 'icon-info')
      end

      it "should show a completed icon when module item is a min score requirement that met the score requirement" do
        add_min_score_assignment
        grade_assignment(100)
        go_to_modules

        validate_context_module_item_icon(@tag_4.id, @completed_icon)
      end

      it "should show a warning icon when module item is past due and not submitted" do
        add_min_score_assignment
        make_past_due
        go_to_modules

        validate_context_module_item_icon(@tag_4.id, @in_progress_icon)
      end

      it "should show a completed icon when module item is past due but submitted" do
        add_min_score_assignment
        make_past_due
        grade_assignment(100)
        go_to_modules

        validate_context_module_item_icon(@tag_4.id, @completed_icon)
      end
    end
  end

  it "should fetch locked module prerequisites" do
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
    @module = @course.context_modules.create!(name: "module")
    @module_1 = @course.context_modules.create!(name: "module_1")
    @module_1.workflow_state = 'unpublished'
    @module_1.save!
    user_session(@student)
    go_to_modules
    # for a11y there is a hidden header now that gets read as part of the text hence the regex matching
    expect(f("#context_modules").text).to match(/module\s*module/)
    expect(f("#context_modules")).not_to include_text "module_1"
  end

  it "should unlock module after a given date", priority: "1", test_id: 126746 do
    mod_lock = @course.context_modules.create! name: 'a_locked_mod', unlock_at: 1.day.ago
    user_session(@student)
    go_to_modules
    expect(fj("#context_module_content_#{mod_lock.id} .unlock_details")).not_to include_text 'Will unlock'
  end

  it "should mark locked but visible assignments/quizzes/discussions as read" do
    # setting lock_at in the past will cause assignments/quizzes/discussions to still be visible
    # they just can't be submitted to anymore

    mod = @course.context_modules.create!(:name => "module")

    asmt = @course.assignments.create!(:title => "assmt", :lock_at => 1.day.ago)
    topic_asmt = @course.assignments.create!(:title => "topic assmt", :lock_at => 2.days.ago)

    topic = @course.discussion_topics.create!(:title => "topic", :assignment => topic_asmt)
    quiz = @course.quizzes.create!(:title => "quiz", :lock_at => 3.days.ago)
    quiz.publish!


    tag1 = mod.add_item({:id => asmt.id, :type => 'assignment'})
    tag2 = mod.add_item({:id => topic.id, :type => 'discussion_topic'})
    tag3 = mod.add_item({:id => quiz.id, :type => 'quiz'})

    mod.completion_requirements = {tag1.id => {:type => 'must_view'}, tag2.id => {:type => 'must_view'}, tag3.id => {:type => 'must_view'}}
    mod.save!

    user_session(@student)

    get "/courses/#{@course.id}/assignments/#{asmt.id}"
    expect(f("#assignment_show")).to include_text("This assignment was locked")
    get "/courses/#{@course.id}/discussion_topics/#{topic.id}"
    expect(f("#discussion_topic")).to include_text("This topic was locked")
    get "/courses/#{@course.id}/quizzes/#{quiz.id}"
    expect(f(".lock_explanation")).to include_text("This quiz was locked")

    prog = mod.evaluate_for(@student)
    expect(prog).to be_completed
    expect(prog.requirements_met.count).to eq 3
  end

  it "should not lock a page module item on first load" do
    user_session(@student)
    page = @course.wiki.wiki_pages.create!(:title => "some page", :body => "some body")
    page.set_as_front_page!

    mod = @course.context_modules.create!(:name => "module")
    tag = mod.add_item({:id => page.id, :type => 'wiki_page'})
    mod.require_sequential_progress = true
    mod.completion_requirements = {tag.id => {:type => 'must_view'}}
    mod.save!

    get "/courses/#{@course.id}/pages/#{page.url}"

    expect(f('.user_content')).to include_text(page.body)
  end
end
