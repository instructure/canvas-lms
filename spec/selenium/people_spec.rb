require File.expand_path(File.dirname(__FILE__) + '/common')

describe "people" do
  include_context "in-process server selenium tests"

  def add_user(option_text, username, user_list_selector)
    click_option('#enrollment_type', option_text)
    f('textarea.user_list').send_keys(username)
    fj('.verify_syntax_button').click
    wait_for_ajax_requests
    expect(f('#user_list_parsed')).to include_text(username)
    f('.add_users_button').click
    wait_for_ajaximations
    expect(f(user_list_selector)).to include_text(username)
  end

  def open_student_group_dialog
    f('.add_category_link').click
    dialog = fj('.ui-dialog:visible')
    expect(dialog).to be_displayed
    dialog
  end

  def create_student_group(group_text = "new student group")
    expect_new_page_load { fln('View User Groups').click }
    open_student_group_dialog
    inputs = ffj('input:visible')
    replace_content(inputs[0], group_text)
    submit_form('#add_category_form')
    wait_for_ajaximations
    expect(f('#category_list')).to include_text(group_text)
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
    user.pseudonyms.create!(:unique_id => student_name, :password => 'qwerty', :password_confirmation => 'qwerty')
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

  def open_dropdown_menu(selector: nil, option: nil, displayed: true)
    selector ||= ".rosterUser"
    row = f(selector)
    driver.action.move_to(row).perform
    f("#{selector} .admin-links a.al-trigger").click
    expect(f("#{selector} .admin-links ul.al-options")).to be_displayed
    if option
      to_be_or_not_to_be = displayed ? :to : :not_to
      expect(element_exists("#{selector} .admin-links ul.al-options li a[data-event=#{option}]")).send to_be_or_not_to_be, be_truthy
    end
  end

  context "people as a teacher" do

    before (:each) do
      course_with_teacher_logged_in

      #add first student
      @student_1 = create_user('student@test.com')
      Account.default.settings[:enable_manage_groups2] = false
      Account.default.save!

      enroll_student(@student_1)

      #adding users for tests to work correctly

      #teacher user
      @test_teacher = create_user('teacher@test.com')
      #student user
      @student_2 = create_user('student2@test.com')
      #ta user
      @test_ta = create_user('ta@test.com')
      #observer user
      @test_observer = create_user('observer@test.com')

      get "/courses/#{@course.id}/users"
      wait_for_ajaximations
    end

    it "should have tabs" do
      expect(fj('.collectionViewItems>li:first').text).to match "Everyone"
    end

    it "should display a dropdown menu when item cog is clicked" do
      open_dropdown_menu
    end

    it "should display the option to remove a student from a course if manually enrolled" do
      open_dropdown_menu(option: 'removeFromCourse')
    end

    it "should display activity report on clicking Student Interaction button", priority: "1", test_id: 244446 do
      fln("Student Interactions Report").click
      wait_for_ajaximations
      user_name = f(".user_name").text
      expect(f("h1").text).to eq "Teacher Activity Report for #{user_name}"
    end

    it "should not display Student Interaction button for a student", priority: "1", test_id: 244450  do
      user_session(@student_1)
      get "/courses/#{@course.id}/users"
      expect(fln("Student Interactions Report")).not_to be_present
    end

    it "should focus on the + Group Set button after the tabs" do
      driver.execute_script("$('.collectionViewItems > li:last a').focus()")
      active = driver.execute_script("return document.activeElement")
      active.send_keys(:tab)
      check_element_has_focus(fj('.group-categories-actions .btn-primary'))
    end

    it "should make sure focus is set to the 'Done' button when adding users" do
      f('#addUsers').click
      wait_for_ajaximations
      f('#user_list_textarea').send_keys('student2@test.com')
      f('#next-step').click
      wait_for_ajaximations
      f('#createUsersAddButton').click
      wait_for_ajaximations
      check_element_has_focus(f('.dialog_closer'))
    end

    it "should validate the main page" do
      users = ff('.roster_user_name')
      expect(users[1].text).to match @student_1.name
      expect(users[0].text).to match @teacher.name
    end

    it "should navigate to registered services on profile page" do
      fln('View Registered Services').click
      fln('Link web services to my account').click
      expect(f('#unregistered_services')).to be_displayed
    end

    it "should make a new set of student groups" do
      create_student_group
    end

    it "should test self sign up help functionality" do
      expect_new_page_load { fln('View User Groups').click }
      open_student_group_dialog
      fj('.self_signup_help_link:visible').click
      help_dialog = f('#self_signup_help_dialog')
      expect(help_dialog).to be_displayed
    end

    it "should test self sign up functionality" do
      expect_new_page_load { fln('View User Groups').click }
      dialog = open_student_group_dialog
      dialog.find_element(:css, '#category_enable_self_signup').click
      expect(dialog.find_element(:css, '#category_split_group_count')).not_to be_displayed
      expect(dialog.find_element(:css, '#category_create_group_count')).to be_displayed
    end

    it "should test self sign up / group structure functionality" do
      group_count = "4"
      expect_new_page_load { fln('View User Groups').click }
      dialog = open_student_group_dialog
      dialog.find_element(:css, '#category_enable_self_signup').click
      dialog.find_element(:css, '#category_create_group_count').send_keys(group_count)
      submit_form('#add_category_form')
      wait_for_ajaximations
      expect(@course.groups.count).to eq 4
      expect(f('.group_count')).to include_text("#{group_count} Groups")
    end

    it "should test group structure functionality" do
      enroll_more_students

      group_count = "4"
      expect_new_page_load { fln('View User Groups').click }
      dialog = open_student_group_dialog
      dialog.find_element(:css, '#category_split_groups').click
      replace_content(f('#category_split_group_count'), group_count)
      expect(@course.groups.count).to eq 0
      submit_form('#add_category_form')
      wait_for_ajaximations
      expect(@course.groups.count).to eq group_count.to_i
      expect(ffj('.left_side .group_name:visible').count).to eq group_count.to_i
    end

    it "should edit a student group" do
      new_group_name = "new group edit name"
      create_student_group
      f('.edit_category_link').click
      edit_form = f('#edit_category_form')
      edit_form.find_element(:css, 'input#category_name').send_keys(new_group_name)
      submit_form(edit_form)
      wait_for_ajaximations
      expect(fj(".category_name").text).to eq new_group_name
    end

    it "should delete a student group" do
      create_student_group
      f('.delete_category_link').click
      keep_trying_until do
        expect(driver.switch_to.alert).not_to be_nil
        driver.switch_to.alert.accept
        true
      end
      wait_for_ajaximations
      refresh_page
      expect(f('#no_groups_message')).to be_displayed
    end

    it "should randomly assign students" do
      expected_student_count = "0 students"

      enroll_more_students

      group_count = 4
      expect_new_page_load { fln('View User Groups').click }
      open_student_group_dialog
      submit_form('#add_category_form')
      wait_for_ajaximations
      group_count.times do
        f('.add_group_link').click
        f('.button-container > .btn-small').click
        wait_for_ajaximations
      end
      f('.assign_students_link').click
      keep_trying_until do
        expect(driver.switch_to.alert).not_to be_nil
        driver.switch_to.alert.accept
        true
      end
      wait_for_ajax_requests
      assert_flash_notice_message /Students assigned to groups/
      expect(f('.right_side .user_count').text).to eq expected_student_count
    end

    it "should test prior enrollment functionality" do
      @course.complete
      get "/courses/#{@course.id}/users"
      expect_new_page_load { fln('View Prior Enrollments').click }
      expect(f('#users')).to include_text(@student_1.name)
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
      f('.more_user_information_link').click
      wait_for_ajaximations
      enrollments = ff(".enrollment")
      expect(enrollments.length).to eq 2

      expect(enrollments[0]).to include_text @students[0].name
      expect(enrollments[1]).to include_text @students[1].name

      link_to_student(enrollments[0], @students[2])
      expect(enrollments[0]).to include_text @students[2].name
      expect(enrollments[1]).to include_text @students[1].name

      link_to_student(enrollments[1], @students[3])
      expect(enrollments[0]).to include_text @students[2].name
      expect(enrollments[1]).to include_text @students[3].name

      @obs.reload
      expect(@obs.enrollments.map { |e| e.associated_user_id }.sort).to eq [@students[2].id, @students[3].id]

      link_to_student(enrollments[0], nil)
      expect(enrollments[0].find_element(:css, ".associated_user")).not_to be_displayed

      link_to_student(enrollments[0], @students[0])
      link_to_student(enrollments[1], @students[1])
      expect(enrollments[0]).to include_text @students[0].name
      expect(enrollments[1]).to include_text @students[1].name

      @obs.reload
      expect(@obs.enrollments.map { |e| e.associated_user_id }.sort).to eq [@students[0].id, @students[1].id]
    end
  end

  context "people as a TA" do

    before (:each) do
      course_with_ta_logged_in(:active_all => true)
    end

    it "should validate that the TA cannot delete / conclude or reset course" do
      get "/courses/#{@course.id}/settings"
      expect(f('.delete_course_link')).to be_nil
      expect(f('.reset_course_content_button')).to be_nil
      get "/courses/#{@course.id}/confirm_action?event=conclude"
      expect(f('.ui-state-error')).to include_text('Unauthorized')
    end

    it "should validate that a TA cannot rename a teacher" do
      skip('bug 7106 - do not allow TA to edit teachers name')
      teacher_enrollment = teacher_in_course(:name => 'teacher@example.com')
      get "/courses/#{@course.id}/users/#{teacher_enrollment.user.id}"
      expect(f('.edit_user_link')).to_not be_displayed
    end
  end

  def add_a_section
    section_name = 'section2'
    get "/courses/#{@course.id}/settings#tab-sections"

    section_input = f('#course_section_name')
    keep_trying_until { expect(section_input).to be_displayed }
    replace_content(section_input, section_name)
    submit_form('#add_section_form')
    wait_for_ajaximations
    expect(ff('#sections > .section')[1]).to include_text(section_name)
  end

  context "course with multiple sections", priority: "2" do
    before (:each) do
      course_with_admin_logged_in
      add_a_section
    end

    it "should save add people form data" do
      get "/courses/#{@course.id}/users"

      f('#addUsers').click
      wait_for_ajaximations

      expect(f('#create-users-step-1')).to be_displayed
      replace_content(f('#user_list_textarea'), 'student@example.com')
      click_option('#role_id', ta_role.id.to_s, :value)
      click_option('#course_section_id', 'Unnamed Course', :text)
      f('#limit_privileges_to_course_section').click
      f('#next-step').click
      wait_for_ajaximations

      expect(f('#create-users-step-2')).to be_displayed
      f('.btn.createUsersStartOver').click
      wait_for_ajaximations

      #verify form and options have not changed
      expect(f('#create-users-step-1')).to be_displayed
      expect(f('#user_list_textarea').text).to eq 'student@example.com'
      expect(first_selected_option(f('#role_id')).text).to eq 'TA'
      expect(first_selected_option(f('#course_section_id')).text).to eq 'Unnamed Course'
      is_checked('#limit_privileges_to_course_section') == true
    end

    it "should add a student to a section", priority: "1", test_id: 296460 do
      student = create_user("student@example.com")
      enroll_student(student)
      get "/courses/#{@course.id}/users"
      ff(".icon-settings")[1].click
      fln("Edit Sections").click
      f(".token_input.browsable").click
      section_input_element = driver.find_element(:name, "token_capture")
      section_input_element.send_keys("section2")
      f('.last.context').click
      wait_for_ajaximations
      ff('.ui-button-text')[1].click
      wait_for_ajaximations
      expect(ff(".StudentEnrollment")[0].text).to include_text("section2")
    end

    it "should remove a student from a section", priority: "1", test_id: 296461 do
     sec1 = @course.course_sections.create!(name: "section1")
     sec2 = @course.course_sections.create!(name: "section2")
     @student = user
     @course.enroll_student(@student, section: sec1, allow_multiple_enrollments: true)
     @course.enroll_student(@student, section: sec2, allow_multiple_enrollments: true)
     get "/courses/#{@course.id}/users"
     ff(".icon-settings")[1].click
     fln("Edit Sections").click
     fln("Remove user from section2").click
     ff('.ui-button-text')[1].click
     wait_for_ajaximations
     expect(ff(".StudentEnrollment")[0].text).not_to include_text("section2")
    end
  end

  it "should get the max total activity time" do
    course_with_admin_logged_in
    sec1 = @course.course_sections.create!(name: "section1")
    sec2 = @course.course_sections.create!(name: "section2")
    @student = user
    e1 = @course.enroll_student(@student, section: sec1, allow_multiple_enrollments: true)
    @course.enroll_student(@student, section: sec2, allow_multiple_enrollments: true)
    Enrollment.where(:id => e1).update_all(:total_activity_time => 900)
    get "/courses/#{@course.id}/users"
    wait_for_ajaximations
    expect(fj("#user_#{@student.id} td:nth-child(7)").text.strip).to eq "15:00"
  end

  it "should filter by role ids" do
    account_model
    course_with_teacher_logged_in(:account => @account)
    old_role = custom_student_role("Role")
    old_role.deactivate!

    new_role = @account.roles.new(:name => old_role.name)
    new_role.base_role_type = "StudentEnrollment"
    new_role.save!
    new_role

    student_in_course(:course => @course, :role => new_role, :name => "number2")

    get "/courses/#{@course.id}/users"
    click_option("select[name=enrollment_role_id]", new_role.id.to_s, :value)
    wait_for_ajaximations
    expect(ff('tr.rosterUser').count).to eq 1
  end
end
