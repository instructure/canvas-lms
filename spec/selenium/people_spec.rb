require File.expand_path(File.dirname(__FILE__) + '/common')

describe "people" do
  it_should_behave_like "in-process server selenium tests"

  DEFAULT_PASSWORD = 'qwerty'

  def add_user(option_text, username, user_list_selector)
    click_option('#enrollment_type', option_text)
    driver.find_element(:css, 'textarea.user_list').send_keys(username)
    find_with_jquery('.verify_syntax_button').click
    wait_for_ajax_requests
    driver.find_element(:id, 'user_list_parsed').should include_text(username)
    driver.find_element(:css, '.add_users_button').click
    wait_for_ajaximations
    driver.find_element(:css, user_list_selector).should include_text(username)
  end

  def open_student_group_dialog
    driver.find_element(:css, '.add_category_link').click
    dialog = find_with_jquery('.ui-dialog:visible')
    dialog.should be_displayed
    dialog
  end

  def create_student_group(group_text = "new student group")
    expect_new_page_load { driver.find_element(:link, 'View Student Groups').click }
    open_student_group_dialog
    inputs = find_all_with_jquery('input:visible')
    inputs[0].clear
    inputs[0].send_keys(group_text)
    submit_form('#add_category_form')
    wait_for_ajaximations
    driver.find_element(:css, '#category_list').should include_text(group_text)
  end

  def enroll_student(student)
    e1 = @course.enroll_student(student)
    e1.workflow_state = 'active'
    e1.save!
    @course.reload
  end

  def create_user(student_name)
    user = User.create!(:name => student_name)
    user.register!
    user.pseudonyms.create!(:unique_id => student_name, :password => DEFAULT_PASSWORD, :password_confirmation => DEFAULT_PASSWORD)
    @course.reload
    user
  end

  def enroll_more_students
    student_1 = create_user("jake@test.com")
    student_2 = create_user("test@test.com")
    student_3 = create_user("new@test.com")
    student_4 = create_user("this@test.com")
    enroll_student(student_1)
    enroll_student(student_2)
    enroll_student(student_3)
    enroll_student(student_4)
  end

  context "people as a teacher" do

    before (:each) do
      course_with_teacher_logged_in

      #add first student
      @student_1 = User.create!(:name => 'student@test.com')
      @student_1.register!
      @student_1.pseudonyms.create!(:unique_id => 'student@test.com', :password => DEFAULT_PASSWORD, :password_confirmation => DEFAULT_PASSWORD)

      e1 = @course.enroll_student(@student_1)
      e1.workflow_state = 'active'
      e1.save!
      @course.reload

      #adding users for second selenium test to work correctly

      #teacher user
      @test_teacher = create_user('teacher@test.com')
      #student user
      @student_2 = create_user('student2@test.com')
      #ta user
      @test_ta = create_user('ta@test.com')
      #observer user
      @test_observer = create_user('observer@test.com')

      get "/courses/#{@course.id}/users"
    end

    it "should validate the main page" do
      users = driver.find_elements(:css, '.user_name')
      users[0].text.should == @teacher.name
      users[1].text.should == @student_1.name
    end

    it "should navigate to registered services on profile page" do
      driver.find_element(:link, I18n.t('links.view_services', 'View Registered Services')).click
      driver.find_element(:link, I18n.t('links.link_service', 'Link web services to my account')).click
      driver.find_element(:id, 'unregistered_services').should be_displayed
    end

    it "should add a teacher, ta, student, and observer" do
      expect_new_page_load { driver.find_element(:link, 'Manage Users').click }
      add_users_button = driver.find_element(:css, '.add_users_link')
      add_users_button.click
      add_user('Teachers', @test_teacher.name, 'ul.user_list.teacher_enrollments')
      add_user("Students", @student_2.name, 'ul.user_list.student_enrollments')
      add_user("TAs", @test_ta.name, 'ul.user_list.ta_enrollments')
      add_user("Observers", @test_observer.name, 'ul.user_list.observer_enrollments')
    end

    it "should make a new set of student groups" do
      create_student_group
    end

    it "should test self sign up help functionality" do
      expect_new_page_load { driver.find_element(:link, 'View Student Groups').click }
      open_student_group_dialog
      find_with_jquery('a.self_signup_help_link:visible').click
      help_dialog = driver.find_element(:css, '#self_signup_help_dialog')
      help_dialog.should be_displayed
    end

    it "should test self sign up functionality" do
      expect_new_page_load { driver.find_element(:link, 'View Student Groups').click }
      dialog = open_student_group_dialog
      dialog.find_element(:css, '#category_enable_self_signup').click
      dialog.find_element(:css, '#category_split_group_count').should_not be_displayed
      dialog.find_element(:css, '#category_create_group_count').should be_displayed
    end

    it "should test self sign up / group structure functionality" do
      group_count = "4"
      expect_new_page_load { driver.find_element(:link, 'View Student Groups').click }
      dialog = open_student_group_dialog
      dialog.find_element(:css, '#category_enable_self_signup').click
      dialog.find_element(:css, '#category_create_group_count').send_keys(group_count)
      submit_form('#add_category_form')
      wait_for_ajaximations
      driver.find_elements(:css, '.left_side .group_name').count.should == group_count.to_i
    end

    it "should test group structure functionality" do
      enroll_more_students

      group_count = 4
      expect_new_page_load { driver.find_element(:link, 'View Student Groups').click }
      dialog = open_student_group_dialog
      dialog.find_element(:css, '#category_split_groups').click
      dialog.find_element(:css, '#category_split_group_count').send_keys(group_count)
      submit_form('#add_category_form')
      wait_for_ajaximations
      driver.find_elements(:css, '.left_side .group_name').count.should == group_count.to_i
    end

    it "should edit a student group" do
      new_group_name = "new group edit name"
      create_student_group
      driver.find_element(:css, '.edit_category_link').click
      edit_form = driver.find_element(:css, '#edit_category_form')
      edit_form.find_element(:css, 'input#category_name').send_keys(new_group_name)
      submit_form(edit_form)
      wait_for_ajaximations
      find_with_jquery("h3.category_name").text.should == new_group_name
    end

    it "should delete a student group" do
      create_student_group
      driver.find_element(:css, '.delete_category_link').click
      keep_trying_until do
        driver.switch_to.alert.should_not be_nil
        driver.switch_to.alert.accept
        true
      end
      wait_for_ajaximations
      refresh_page
      driver.find_element(:css, '#no_groups_message').should be_displayed
    end

    it "should randomly assign students" do
      expected_student_count = "0 students"

      enroll_more_students

      group_count = 4
      expect_new_page_load { driver.find_element(:link, 'View Student Groups').click }
      dialog = open_student_group_dialog
      dialog.find_element(:css, '#category_split_group_count').send_keys(group_count)
      submit_form('#add_category_form')
      wait_for_ajaximations
      group_count.times do
        driver.find_element(:css, '.add_group_link').click
        driver.find_element(:css, '.button-container > .small-button').click
        wait_for_ajaximations
      end
      driver.find_element(:css, '.assign_students_link').click
      keep_trying_until do
        driver.switch_to.alert.should_not be_nil
        driver.switch_to.alert.accept
        true
      end
      wait_for_ajax_requests
      assert_flash_notice_message /Students assigned to groups/
      driver.find_element(:css, '.right_side .user_count').text.should == expected_student_count
    end

    it "should test prior enrollment functionality" do
      expect_new_page_load { driver.find_element(:link, 'Manage Users').click }
      expect_new_page_load { driver.find_element(:link, 'End this Course').click }
      expect_new_page_load { driver.find_element(:css, '.button-container > .big-button').click }
      get "/courses/#{@course.id}/users"
      expect_new_page_load { driver.find_element(:link, 'View Prior Enrollments').click }
      driver.find_element(:css, '#users').should include_text(@student_1.name)
    end

    def link_to_student(enrollment, student)
      enrollment.find_element(:css, ".link_enrollment_link").click
      wait_for_ajax_requests
      click_option("#student_enrollment_link_option", student.try(:name) || "[ No Link ]")
      submit_form("#link_student_dialog_form")
      wait_for_ajax_requests
    end

    it "should deal with observers linked to multiple students" do
      @students = []
      @obs = user_model(:name => "The Observer")
      2.times do |i|
        student_in_course(:name => "Student #{i}")
        @students << @student
        e = @course.observer_enrollments.create!(:user => @obs, :workflow_state => 'active')
        e.associated_user_id = @student.id
        e.save!
      end

      2.times do |i|
        student_in_course(:name => "Student #{i+2}")
        @students << @student
      end

      get "/courses/#{@course.id}/users/#{@obs.id}"
      driver.find_element(:css, ".more_user_information_link").click
      wait_for_animations

      enrollments = driver.find_elements(:css, ".enrollment")
      enrollments.length.should == 2
      enrollments[0].should include_text @students[0].name
      enrollments[1].should include_text @students[1].name

      link_to_student(enrollments[0], @students[2])
      enrollments[0].should include_text @students[2].name
      enrollments[1].should include_text @students[1].name

      link_to_student(enrollments[1], @students[3])
      enrollments[0].should include_text @students[2].name
      enrollments[1].should include_text @students[3].name

      @obs.reload
      @obs.enrollments.map { |e| e.associated_user_id }.sort.should == [@students[2].id, @students[3].id]

      link_to_student(enrollments[0], nil)
      link_to_student(enrollments[1], nil)
      enrollments[0].find_element(:css, ".associated_user").should_not be_displayed
      enrollments[1].find_element(:css, ".associated_user").should_not be_displayed

      link_to_student(enrollments[0], @students[0])
      link_to_student(enrollments[1], @students[1])
      enrollments[0].should include_text @students[0].name
      enrollments[1].should include_text @students[1].name

      @obs.reload
      @obs.enrollments.map { |e| e.associated_user_id }.sort.should == [@students[0].id, @students[1].id]
    end
  end

  context "people as a TA" do

    before (:each) do
      course_with_ta_logged_in(:active_all => true)
    end

    it "should validate that the TA cannot delete / conclude or reset course" do
      get "/courses/#{@course.id}/settings"
      f('.delete_course_link').should be_nil
      f('.reset_course_content_button').should be_nil
      get "/courses/#{@course.id}/confirm_action?event=conclude"
      f('.ui-state-error').should include_text('Unauthorized')
    end

    it "should validate that a TA cannot rename a teacher" do
      pending('bug 7106 - do not allow TA to edit teachers name') do
        teacher_enrollment = teacher_in_course(:name => 'teacher@example.com')
        get "/courses/#{@course.id}/users/#{teacher_enrollment.user.id}"
        driver.find_element(:css, '.edit_user_link').should_not be_displayed
      end
    end
  end
end
