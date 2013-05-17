require File.expand_path(File.dirname(__FILE__) + '/common')

describe "courses" do
  it_should_behave_like "in-process server selenium tests"

  context "as a teacher" do

    def create_new_course
      get "/"
      f('[aria-controls="new_course_form"]').click
      f('[name="course[name]"]').send_keys "testing"
      f('.ui-dialog-buttonpane .btn-primary').click
    end

    before (:each) do
      account = Account.default
      account.settings = {:open_registration => true, :no_enrollments_can_create_courses => true, :teachers_can_create_courses => true}
      account.save!
    end

    it "should properly hide the wizard and remember its hidden state" do
      course_with_teacher_logged_in

      create_new_course

      wizard_box = f("#wizard_box")
      keep_trying_until { wizard_box.displayed? }
      wizard_box.find_element(:css, ".close_wizard_link").click

      refresh_page
      wait_for_animations # we need to give the wizard a chance to pop up
      wizard_box = f("#wizard_box")
      wizard_box.displayed?.should be_false

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

      wait_for_animations
      wizard_box = find_wizard_box
      wizard_box.find_element(:css, ".close_wizard_link").click
      wait_for_animations
      wizard_box.should_not be_displayed
      checklist_button = f('.wizard_popup_link')
      checklist_button.should be_displayed
      checklist_button.click
      wait_for_animations
      checklist_button.should_not be_displayed
      wizard_box = find_wizard_box
      wizard_box.find_element(:css, ".close_wizard_link").click
      wait_for_animations
      wizard_box.should_not be_displayed
      checklist_button.should be_displayed
    end

    it "should correctly update the course quota" do
      course_with_admin_logged_in

      # first try setting the quota explicitly
      get "/courses/#{@course.id}/details"
      driver.find_element(:link, 'Course Details').click
      form = f("#course_form")
      f("#course_form .edit_course_link").should be_displayed
      form.find_element(:css, ".edit_course_link").click
      quota_input = form.find_element(:css, "input#course_storage_quota_mb")
      replace_content(quota_input, "10")
      submit_form(form)
      keep_trying_until { f(".loading_image_holder").nil? rescue true }
      form.find_element(:css, ".course_info.storage_quota_mb").text.should == "10"

      # then try just saving it (without resetting it)
      get "/courses/#{@course.id}/details"
      form = f("#course_form")
      form.find_element(:css, ".course_info.storage_quota_mb").text.should == "10"
      form.find_element(:css, ".edit_course_link").click
      submit_form(form)
      keep_trying_until { f(".loading_image_holder").nil? rescue true }
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
      course1 = course_with_teacher_logged_in(:user => teacher, :active_all => 1).course
      student_in_course :user => student, :active_all => 1
      course2 = course_with_teacher(:user => teacher, :active_all => 1).course
      student_in_course :user => student, :active_all => 1
      create_session(student.pseudonyms.first, false)

      get "/courses/#{course1.id}/grades/#{student.id}"

      select = f('#course_url')
      options = select.find_elements(:css, 'option')
      options.length.should == 2
      select.click
      find_with_jquery('#course_url option:not([selected])').click

      driver.current_url.should match %r{/courses/#{course2.id}/grades}
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
      ff('.ui-state-error').length.should == 0
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

    it "should validate that a user cannot see a course they are not enrolled in" do
      login_as(@student.name)
      f('#menu').should_not include_text('Courses')
    end
  end
end
