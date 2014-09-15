require File.expand_path(File.dirname(__FILE__) + '/common')

describe "courses" do
  include_examples "in-process server selenium tests"

  context "as a teacher" do

    def create_new_course
      get "/"
      f('[aria-controls="new_course_form"]').click
      wait_for_ajaximations
      f('[name="course[name]"]').send_keys "testing"
      f('.ui-dialog-buttonpane .btn-primary').click
    end

    before (:each) do
      account = Account.default
      account.settings = {:open_registration => true, :no_enrollments_can_create_courses => true, :teachers_can_create_courses => true}
      account.save!
    end

    context 'draft state' do

      before(:each) do
        course_with_teacher_logged_in({draft_state: true})
      end

      def validate_action_button(postion, validation_text)
        action_button = ff('#course_status_actions button').send(postion)
        action_button.should have_class('disabled')
        action_button.text.should == validation_text
      end

      it "should allow publishing of the course through the course status actions" do
        @course.workflow_state = 'claimed'
        @course.save!
        get "/courses/#{@course.id}"
        course_status_buttons = ff('#course_status_actions button')
        f('.publish_course_in_wizard_link').should be_displayed
        course_status_buttons.first.should have_class('disabled')
        course_status_buttons.first.text.should == 'Unpublished'
        course_status_buttons.last.should_not have_class('disabled')
        course_status_buttons.last.text.should == 'Publish'
        expect_new_page_load { course_status_buttons.last.click }
        f('.publish_course_in_wizard_link').should be_nil
        validate_action_button(:last, 'Published')
      end

      it "should allow unpublishing of a course through the course status actions" do
        get "/courses/#{@course.id}"
        course_status_buttons = ff('#course_status_actions button')
        f('.publish_course_in_wizard_link').should be_nil
        course_status_buttons.first.should_not have_class('disabled')
        course_status_buttons.first.text.should == 'Unpublish'
        course_status_buttons.last.should have_class('disabled')
        course_status_buttons.last.text.should == 'Published'
        expect_new_page_load { course_status_buttons.first.click }
        f('.publish_course_in_wizard_link').should be_displayed
        validate_action_button(:first, 'Unpublished')
      end

      it "should not show course status if graded submissions exist" do
        course_with_student_submissions({submission_points: true, draft_state: true})
        get "/courses/#{@course.id}"
        f('#course_status').should be_nil
      end

      it "should allow unpublishing of the course if submissions have no score or grade" do
        course_with_student_submissions({draft_state: true})
        get "/courses/#{@course.id}"
        course_status_buttons = ff('#course_status_actions button')
        expect_new_page_load { course_status_buttons.first.click }
        assert_flash_notice_message('successfully updated')
        validate_action_button(:first, 'Unpublished')
      end

    end

    it "should properly hide the wizard and remember its hidden state" do
      course_with_teacher_logged_in

      create_new_course

      wizard_box = f("#wizard_box")
      keep_trying_until { wizard_box.should be_displayed }
      wizard_box.find_element(:css, ".close_wizard_link").click

      refresh_page
      wait_for_ajaximations # we need to give the wizard a chance to pop up
      wizard_box = f("#wizard_box")
      wizard_box.should_not be_displayed

      # un-remember the setting
      driver.execute_script "localStorage.clear()"
    end

    it "should open and close wizard after initial close" do
      def find_wizard_box
        wizard_box = keep_trying_until do
          wizard_box = f("#wizard_box")
          wizard_box.should be_displayed
          wizard_box
        end
        wizard_box
      end

      course_with_teacher_logged_in
      create_new_course

      wait_for_ajaximations
      wizard_box = find_wizard_box
      wizard_box.find_element(:css, ".close_wizard_link").click
      wait_for_ajaximations
      wizard_box.should_not be_displayed
      checklist_button = f('.wizard_popup_link')
      checklist_button.should be_displayed
      checklist_button.click
      wait_for_ajaximations
      checklist_button.should_not be_displayed
      wizard_box = find_wizard_box
      wizard_box.find_element(:css, ".close_wizard_link").click
      wait_for_ajaximations
      wizard_box.should_not be_displayed
      checklist_button.should be_displayed
    end

    it "should correctly update the course quota" do
      course_with_admin_logged_in

      # first try setting the quota explicitly
      get "/courses/#{@course.id}/details"
      f("#ui-id-1").click
      form = f("#course_form")
      f("#course_form .edit_course_link").should be_displayed
      form.find_element(:css, ".edit_course_link").click
      wait_for_ajaximations
      quota_input = form.find_element(:css, "input#course_storage_quota_mb")
      replace_content(quota_input, "10")
      submit_form(form)
      keep_trying_until { f(".loading_image_holder").nil? rescue true }
      form = f("#course_form")
      form.find_element(:css, ".course_info.storage_quota_mb").text.should == "10"

      # then try just saving it (without resetting it)
      get "/courses/#{@course.id}/details"
      form = f("#course_form")
      form.find_element(:css, ".course_info.storage_quota_mb").text.should == "10"
      form.find_element(:css, ".edit_course_link").click
      wait_for_ajaximations
      submit_form(form)
      keep_trying_until { f(".loading_image_holder").nil? rescue true }
      form = f("#course_form")
      form.find_element(:css, ".course_info.storage_quota_mb").text.should == "10"

      # then make sure it's right after a reload
      get "/courses/#{@course.id}/details"
      form = f("#course_form")
      form.find_element(:css, ".course_info.storage_quota_mb").text.should == "10"
      @course.reload
      @course.storage_quota.should == 10.megabytes
    end

    it "should redirect to the gradebook when switching courses when viewing a students grades" do
      teacher = user_with_pseudonym(:username => 'teacher@example.com', :active_all => 1)
      student = user_with_pseudonym(:username => 'student@example.com', :active_all => 1)

      course1 = course_with_teacher_logged_in(:user => teacher, :active_all => 1, :course_name => 'course1').course
      student_in_course(:user => student, :active_all => 1)

      course2 = course_with_teacher(:user => teacher, :active_all => 1, :course_name => 'course2').course
      student_in_course(:user => student, :active_all => 1)

      create_session(student.pseudonyms.first, false)

      get "/courses/#{course1.id}/grades/#{student.id}"

      select = f('#course_url')
      options = select.find_elements(:css, 'option')
      options.length.should == 2
      wait_for_ajaximations
      expect_new_page_load{ click_option('#course_url', course2.name) }
      f('#section-tabs-header').text.should match course2.name
    end

    it "should load the users page using ajax" do
      course_with_teacher_logged_in

      # Setup the course with > 50 users (to test scrolling)
      60.times do |n|
        @course.enroll_student(user)
      end

      @course.enroll_user(user, 'TaEnrollment')

      # Test that the page loads properly the first time.
      get "/courses/#{@course.id}/users"
      wait_for_ajaximations
      flash_message_present?(:error).should be_false
      ff('.roster .rosterUser').length.should == 50
    end

    it "should only show users that a user has permissions to view" do
      # Set up the test
      course(:active_course => true)
      %w[One Two].each do |name|
        section = @course.course_sections.create!(:name => name)
        @course.enroll_student(user, :section => section).accept!
      end
      user_logged_in
      enrollment = @course.enroll_ta(@user)
      enrollment.accept!
      enrollment.update_attributes(:limit_privileges_to_course_section => true,
                                   :course_section => CourseSection.find_by_name('Two'))

      # Test that only users in the approved section are displayed.
      get "/courses/#{@course.id}/users"
      wait_for_ajaximations
      ff('.roster .rosterUser').length.should == 2
    end

    it "should display users section name" do
      course_with_teacher_logged_in(:active_all => true)
      user1, user2 = [user, user]
      section1 = @course.course_sections.create!(:name => 'One')
      section2 = @course.course_sections.create!(:name => 'Two')
      @course.enroll_student(user1, :section => section1).accept!
      [section1, section2].each do |section|
        e = user2.student_enrollments.build
        e.workflow_state = 'active'
        e.course = @course
        e.course_section = section
        e.save!
      end

      get "/courses/#{@course.id}/users"
      wait_for_ajaximations
      sections = ff('.roster .section')
      sections.map(&:text).sort.should == ["One", "One", "Two", "Unnamed Course", "Unnamed Course"]
    end

    it "should display users section name properly when separated by custom roles" do
      course_with_teacher_logged_in(:active_all => true)
      user1 = user
      section1 = @course.course_sections.create!(:name => 'One')
      section2 = @course.course_sections.create!(:name => 'Two')

      role1 = @course.account.roles.build :name => "CustomStudent1"
      role1.base_role_type = "StudentEnrollment"
      role1.save!
      role2 = @course.account.roles.build :name => "CustomStudent2"
      role2.base_role_type = "StudentEnrollment"
      role2.save!

      @course.enroll_user(user1, "StudentEnrollment", :section => section1, :role_name => role1.name).accept!
      @course.enroll_user(user1, "StudentEnrollment", :section => section2, :role_name => role2.name, :allow_multiple_enrollments => true).accept!
      roles_to_sections = {'CustomStudent1' => 'One', 'CustomStudent2' => 'Two'}

      get "/courses/#{@course.id}/users"

      wait_for_ajaximations

      role_wrappers = ff('.student_roster .users-wrapper')
      role_wrappers.each do |rw|
        role_name = ff('.h3', rw).first.text
        sections = ff('.section', rw)
        sections.count.should == 1
        roles_to_sections[role_name].should == sections.first.text
      end
    end

    context "course_home_sub_navigation lti apps" do
      def create_course_home_sub_navigation_tool(options = {})
        @course.root_account.enable_feature!(:lor_for_account)
        defaults = {
          name: options[:name] || "external tool",
          consumer_key: 'test',
          shared_secret: 'asdf',
          url: 'http://example.com/ims/lti',
          course_home_sub_navigation: { icon_url: '/images/delete.png' },
        }
        @course.context_external_tools.create!(defaults.merge(options))
      end

      it "should display course_home_sub_navigation lti apps (draft state off)" do
        course_with_teacher_logged_in(active_all: true)
        num_tools = 3
        num_tools.times { |index| create_course_home_sub_navigation_tool(name: "external tool #{index}") }
        get "/courses/#{@course.id}"
        ff(".course-home-sub-navigation-lti").size.should == num_tools
      end

      it "should display course_home_sub_navigation lti apps (draft state on)" do
        course_with_teacher_logged_in(active_all: true)
        @course.account.enable_feature!(:draft_state)
        num_tools = 2
        num_tools.times { |index| create_course_home_sub_navigation_tool(name: "external tool #{index}") }
        get "/courses/#{@course.id}"
        ff(".course-home-sub-navigation-lti").size.should == num_tools
      end

      it "should include launch type parameter (draft state off)" do
        course_with_teacher_logged_in(active_all: true)
        create_course_home_sub_navigation_tool
        get "/courses/#{@course.id}"
        f('.course-home-sub-navigation-lti').attribute("href").should match(/launch_type=course_home_sub_navigation/)
      end

      it "should include launch type parameter (draft state on)" do
        course_with_teacher_logged_in(active_all: true)
        @course.account.enable_feature!(:draft_state)
        create_course_home_sub_navigation_tool
        get "/courses/#{@course.id}"
        f('.course-home-sub-navigation-lti').attribute("href").should match(/launch_type=course_home_sub_navigation/)
      end

      it "should only display active tools" do
        course_with_teacher_logged_in(active_all: true)
        tool = create_course_home_sub_navigation_tool
        tool.workflow_state = 'deleted'
        tool.save!
        get "/courses/#{@course.id}"
        ff(".course-home-sub-navigation-lti").size.should == 0
      end

      it "should not display admin tools to students" do
        course_with_teacher_logged_in(active_all: true)
        tool = create_course_home_sub_navigation_tool
        tool.course_home_sub_navigation['visibility'] = 'admins'
        tool.save!
        get "/courses/#{@course.id}"
        ff(".course-home-sub-navigation-lti").size.should == 1

        course_with_student_logged_in(course: @course, active_all: true)
        get "/courses/#{@course.id}"
        ff(".course-home-sub-navigation-lti").size.should == 0
      end
    end

  end

  context "course as a student" do

    def enroll_student(student, accept_invitation)
      if accept_invitation
        @course.enroll_student(student).accept
      else
        @course.enroll_student(student)
      end
    end

    before (:each) do
      course_with_teacher(:active_all => true, :name => 'discussion course')
      @student = user_with_pseudonym(:active_user => true, :username => 'student@example.com', :name => 'student@example.com', :password => 'asdfasdf')
      Account.default.settings[:allow_invitation_previews] = true
      Account.default.save!
    end

    it "should accept the course invitation" do
      enroll_student(@student, false)

      login_as(@student.name)
      get "/courses/#{@course.id}"
      f(".global-message .btn[name='accept'] ").click
      assert_flash_notice_message /Invitation accepted!/
    end

    it "should reject a course invitation" do
      enroll_student(@student, false)

      login_as(@student.name)
      get "/courses/#{@course.id}"
      f(".global-message .btn[name=reject]").click
      assert_flash_notice_message /Invitation canceled./
    end

    it "should display user groups on courses page" do
      group = Group.create!(:name => "group1", :context => @course)
      group.add_user(@student)

      login_as(@student.name)
      get '/courses'

      content = f('#content')
      content.should include_text('My Groups')
      content.should include_text('group1')
    end
  end
end
