require File.expand_path(File.dirname(__FILE__) + '/common')

describe "courses" do
  include_context "in-process server selenium tests"

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
        course_with_teacher_logged_in
      end

      def validate_action_button(postion, validation_text)
        action_button = ff('#course_status_actions button').send(postion)
        expect(action_button).to have_class('disabled')
        expect(action_button.text).to eq validation_text
      end

      it "should allow publishing of the course through the course status actions" do
        @course.workflow_state = 'claimed'
        @course.lock_all_announcements = true
        @course.save!
        get "/courses/#{@course.id}"
        course_status_buttons = ff('#course_status_actions button')
        expect(course_status_buttons.first).to have_class('disabled')
        expect(course_status_buttons.first.text).to eq 'Unpublished'
        expect(course_status_buttons.last).not_to have_class('disabled')
        expect(course_status_buttons.last.text).to eq 'Publish'
        expect_new_page_load { course_status_buttons.last.click }
        validate_action_button(:last, 'Published')

        @course.reload
        expect(@course.lock_all_announcements).to be_truthy
      end

      it "should allow unpublishing of a course through the course status actions" do
        get "/courses/#{@course.id}"
        course_status_buttons = ff('#course_status_actions button')
        expect(course_status_buttons.first).not_to have_class('disabled')
        expect(course_status_buttons.first.text).to eq 'Unpublish'
        expect(course_status_buttons.last).to have_class('disabled')
        expect(course_status_buttons.last.text).to eq 'Published'
        expect_new_page_load { course_status_buttons.first.click }
        validate_action_button(:first, 'Unpublished')
      end

      it "should allow publishing even if graded submissions exist" do
        course_with_student_submissions({submission_points: true, unpublished: true})
        get "/courses/#{@course.id}"
        course_status_buttons = ff('#course_status_actions button')
        expect(course_status_buttons.first).to have_class('disabled')
        expect(course_status_buttons.first.text).to eq 'Unpublished'
        expect(course_status_buttons.last).not_to have_class('disabled')
        expect(course_status_buttons.last.text).to eq 'Publish'
        expect_new_page_load { course_status_buttons.last.click }
        @course.reload
        expect(@course).to be_available
      end

      it "should not show course status if published and graded submissions exist" do
        course_with_student_submissions({submission_points: true})
        get "/courses/#{@course.id}"
        expect(f('#course_status')).to be_nil
      end

      it "should allow unpublishing of the course if submissions have no score or grade" do
        course_with_student_submissions
        get "/courses/#{@course.id}"
        course_status_buttons = ff('#course_status_actions button')
        expect_new_page_load { course_status_buttons.first.click }
        assert_flash_notice_message('successfully updated')
        validate_action_button(:first, 'Unpublished')
      end

    end

    describe 'course wizard' do
      def go_to_checklist
        get "/courses/#{@course.id}"
        f(".wizard_popup_link").click()
        wizard_box = f(".ic-wizard-box")
        keep_trying_until { expect(wizard_box).to be_displayed }
      end

      def check_if_item_complete(item)
        elem = "#wizard_#{item}.ic-wizard-box__content-trigger--checked"
        expect(f(elem)).to be_displayed
      end

      def check_if_item_not_complete(item)
        expect(f("#wizard_#{item}.ic-wizard-box__content-trigger")).to be_displayed
        expect(f("#wizard_#{item}.ic-wizard-box__content-trigger--checked")).to be_nil
      end

      it "should properly hide the wizard and remember its hidden state" do
        # For now we are not allowing the wizard to popup automatically
        # so this spec doesn't apply, it may in the future though.
        pending
        course_with_teacher_logged_in
        create_new_course
        wizard_box = f(".ic-wizard-box")
        keep_trying_until { expect(wizard_box).to be_displayed }
        f(".ic-wizard-box__close a").click
        refresh_page
        wait_for_ajaximations # we need to give the wizard a chance to pop up
        wizard_box = f(".ic-wizard-box")
        expect(wizard_box).to eq nil
        # un-remember the setting
        driver.execute_script "localStorage.clear()"
      end

      it "should open and close wizard after initial close" do
        # For now we are not allowing the wizard to popup automatically
        # so this spec doesn't apply, it may in the future though.
        pending
        def find_wizard_box
          wizard_box = keep_trying_until do
            wizard_box = f(".ic-wizard-box")
            expect(wizard_box).to be_displayed
            wizard_box
          end
          wizard_box
        end

        course_with_teacher_logged_in
        create_new_course

        wait_for_ajaximations
        wizard_box = find_wizard_box
        f(".ic-wizard-box__close a").click
        wait_for_ajaximations
        wizard_box = f(".ic-wizard-box")
        expect(wizard_box).to eq nil
        checklist_button = f('.wizard_popup_link')
        expect(checklist_button).to be_displayed
        checklist_button.click
        wait_for_ajaximations
        wizard_box = find_wizard_box
        f(".ic-wizard-box__close a").click
        wait_for_ajaximations
        wizard_box = f(".ic-wizard-box")
        expect(wizard_box).to eq nil
        expect(checklist_button).to be_displayed
      end

      it "should open up the choose home page dialog from the wizard" do
        course_with_teacher_logged_in
        create_new_course

        # Because of the specs about automatically opening are currently
        # pending, we need to cause the wizard to open by way of click. When
        # those specs are no longer pendings, the click line should be removed.
        go_to_checklist

        f("#wizard_home_page").click
        f(".ic-wizard-box__message-button a").click
        wait_for_ajaximations
        modal = f("#edit_course_home_content_form")
        expect(modal).to be_displayed
      end

      it "should have the correct initial state" do
        course_with_teacher_logged_in
        go_to_checklist

        check_if_item_not_complete('content_import')
        check_if_item_not_complete('add_assignments')
        check_if_item_not_complete('add_students')
        check_if_item_not_complete('add_files')
        check_if_item_not_complete('content_import')
        check_if_item_not_complete('select_navigation')
        check_if_item_complete('home_page')
        check_if_item_not_complete('course_calendar')
        check_if_item_not_complete('add_tas')
      end

      it "should complete 'Add Course Assignments' checklist item" do
        course_with_teacher_logged_in
        @course.assignments.create({name: "Test Assignment"})
        go_to_checklist
        check_if_item_complete('add_assignments')
      end

      it "should complete 'Add Students to the Course' checklist item" do
        course_with_teacher_logged_in
        student = user_with_pseudonym(:username => 'student@example.com', :active_all => 1)
        student_in_course(:user => student, :active_all => 1)
        go_to_checklist
        check_if_item_complete('add_students')
      end

      it "should complete 'Select Navigation Links' checklist item" do
        course_with_teacher_logged_in
        get "/courses/#{@course.id}"

        # Navigate to Navigation tab
        go_to_checklist
        f('#wizard_select_navigation').click()
        f('.ic-wizard-box__message-button a').click()

        # Modify Naviagtion
        f('#navigation_tab').click()
        f('.navitem.enabled.modules .al-trigger.al-trigger-gray').click()
        f('.navitem.enabled.modules .admin-links .disable_nav_item_link').click()
        f('#tab-navigation .btn').click()

        go_to_checklist
        check_if_item_complete('select_navigation')
      end

      it "should complete 'Add Course Calendar Events' checklist item" do
        course_with_teacher_logged_in
        get "/courses/#{@course.id}"

        # Navigate to Calendar tab
        go_to_checklist
        f('#wizard_course_calendar').click()
        f('.ic-wizard-box__message-button a').click()

        # Add Event
        f("#create_new_event_link").click()
        wait_for_ajaximations
        replace_content(f('#edit_calendar_event_form #calendar_event_title'), "Event")
        f("#edit_calendar_event_form button.event_button").click()
        wait_for_ajaximations

        go_to_checklist
        check_if_item_complete('course_calendar')
      end

      it "should complete 'Publish the Course' checklist item" do
        course_with_teacher_logged_in
        get "/courses/#{@course.id}"

        # Publish from Checklist
        go_to_checklist
        f('#wizard_publish_course').click()
        f('.ic-wizard-box__message-button button').click()

        go_to_checklist
        check_if_item_complete('publish_course')
      end
    end

    it "should correctly update the course quota" do
      course_with_admin_logged_in

      # first try setting the quota explicitly
      get "/courses/#{@course.id}/settings"
      f("#ui-id-1").click
      form = f("#course_form")
      expect(form).to be_displayed
      quota_input = form.find_element(:css, "input#course_storage_quota_mb")
      replace_content(quota_input, "10")
      submit_form(form)
      keep_trying_until { f(".loading_image_holder").nil? rescue true }
      value = f("#course_form input#course_storage_quota_mb")['value']
      expect(value).to eq "10"

      # then try just saving it (without resetting it)
      get "/courses/#{@course.id}/settings"
      form = f("#course_form")
      value = f("#course_form input#course_storage_quota_mb")['value']
      expect(value).to eq "10"
      submit_form(form)
      keep_trying_until { f(".loading_image_holder").nil? rescue true }
      form = f("#course_form")
      value = f("#course_form input#course_storage_quota_mb")['value']
      expect(value).to eq "10"

      # then make sure it's right after a reload
      get "/courses/#{@course.id}/settings"
      value = f("#course_form input#course_storage_quota_mb")['value']
      expect(value).to eq "10"
      @course.reload
      expect(@course.storage_quota).to eq 10.megabytes
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
      expect(options.length).to eq 2
      wait_for_ajaximations
      expect_new_page_load{ click_option('#course_url', course2.name) }
      expect(f('#section-tabs-header').text).to match course2.name
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
      expect(flash_message_present?(:error)).to be_falsey
      expect(ff('.roster .rosterUser').length).to eq 50
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
                                   :course_section => CourseSection.where(name: 'Two').first)

      # Test that only users in the approved section are displayed.
      get "/courses/#{@course.id}/users"
      wait_for_ajaximations
      expect(ff('.roster .rosterUser').length).to eq 2
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
      expect(sections.map(&:text).sort).to eq ["One", "One", "Two", "Unnamed Course", "Unnamed Course"]
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

      @course.enroll_user(user1, "StudentEnrollment", :section => section1, :role => role1).accept!
      @course.enroll_user(user1, "StudentEnrollment", :section => section2, :role => role2, :allow_multiple_enrollments => true).accept!
      roles_to_sections = {'CustomStudent1' => 'One', 'CustomStudent2' => 'Two'}

      get "/courses/#{@course.id}/users"

      wait_for_ajaximations

      role_wrappers = ff('.student_roster .users-wrapper')
      role_wrappers.each do |rw|
        role_name = ff('.h3', rw).first.text
        sections = ff('.section', rw)
        expect(sections.count).to eq 1
        expect(roles_to_sections[role_name]).to eq sections.first.text
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
        expect(ff(".course-home-sub-navigation-lti").size).to eq num_tools
      end

      it "should display course_home_sub_navigation lti apps (draft state on)" do
        course_with_teacher_logged_in(active_all: true)
        num_tools = 2
        num_tools.times { |index| create_course_home_sub_navigation_tool(name: "external tool #{index}") }
        get "/courses/#{@course.id}"
        expect(ff(".course-home-sub-navigation-lti").size).to eq num_tools
      end

      it "should include launch type parameter (draft state off)" do
        course_with_teacher_logged_in(active_all: true)
        create_course_home_sub_navigation_tool
        get "/courses/#{@course.id}"
        expect(f('.course-home-sub-navigation-lti').attribute("href")).to match(/launch_type=course_home_sub_navigation/)
      end

      it "should include launch type parameter (draft state on)" do
        course_with_teacher_logged_in(active_all: true)
        create_course_home_sub_navigation_tool
        get "/courses/#{@course.id}"
        expect(f('.course-home-sub-navigation-lti').attribute("href")).to match(/launch_type=course_home_sub_navigation/)
      end

      it "should only display active tools" do
        course_with_teacher_logged_in(active_all: true)
        tool = create_course_home_sub_navigation_tool
        tool.workflow_state = 'deleted'
        tool.save!
        get "/courses/#{@course.id}"
        expect(ff(".course-home-sub-navigation-lti").size).to eq 0
      end

      it "should not display admin tools to students" do
        course_with_teacher_logged_in(active_all: true)
        tool = create_course_home_sub_navigation_tool
        tool.course_home_sub_navigation['visibility'] = 'admins'
        tool.save!
        get "/courses/#{@course.id}"
        expect(ff(".course-home-sub-navigation-lti").size).to eq 1

        course_with_student_logged_in(course: @course, active_all: true)
        get "/courses/#{@course.id}"
        expect(ff(".course-home-sub-navigation-lti").size).to eq 0
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

      create_session(@student.pseudonym)
      get "/courses/#{@course.id}"
      f(".ic-notification button[name='accept'] ").click
      assert_flash_notice_message /Invitation accepted!/
    end

    it "should reject a course invitation" do
      enroll_student(@student, false)

      create_session(@student.pseudonym)
      get "/courses/#{@course.id}"
      f(".ic-notification button[name=reject]").click
      assert_flash_notice_message /Invitation canceled./
    end

    it "should display user groups on courses page" do
      group = Group.create!(:name => "group1", :context => @course)
      group.add_user(@student)
      enroll_student(@student, true)

      create_session(@student.pseudonym)
      get '/courses'

      content = f('#content')
      expect(content).to include_text('My Groups')
      expect(content).to include_text('group1')
    end
  end
end
