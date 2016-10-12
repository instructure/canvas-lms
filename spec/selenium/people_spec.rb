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
    f('#add-group-set').click
    dialog = fj('.ui-dialog:visible')
    expect(dialog).to be_displayed
    dialog
  end

  def create_student_group(group_text = "new student group")
    expect_new_page_load do
      f("#people-options .Button").click
      fln('View User Groups').click
    end
    open_student_group_dialog
    replace_content(f('#new_category_name'), group_text)
    submit_form('.group-category-create')
    wait_for_ajaximations
    expect(f('.collectionViewItems')).to include_text(group_text)
  end

  def enroll_student(student)
    e1 = @course.enroll_student(student)
    e1.workflow_state = 'active'
    e1.save!
    @course.reload
  end

  def enroll_ta(ta)
    e1 = @course.enroll_ta(ta)
    e1.workflow_state = 'active'
    e1.save!
    @course.reload
  end

  def create_user(student_name)
    user = User.create!(:name => student_name)
    user.register!
    user.pseudonyms.create!(:unique_id => student_name, :password => 'qwertyuiop', :password_confirmation => 'qwertyuiop')
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

  def open_dropdown_menu(selector = ".rosterUser")
    row = f(selector)
    driver.action.move_to(row).perform
    f("#{selector} .admin-links a.al-trigger").click
    expect(f("#{selector} .admin-links ul.al-options")).to be_displayed
  end

  def expect_dropdown_item(option, selector = ".rosterUser")
    expect(f("#{selector} .admin-links ul.al-options li a[data-event=#{option}]")).to be_truthy
  end

  def expect_no_dropdown_item(option, selector = ".rosterUser")
    expect(f("#{selector} .admin-links ul.al-options")).not_to contain_css("li a[data-event=#{option}]")
  end

  # Returns visibility boolean, assumes existence
  def dropdown_item_visible?(option, selector = ".rosterUser")
    f("#{selector} .admin-links ul.al-options li a[data-event=#{option}]").displayed?
  end

  def close_dropdown_menu
    driver.action.send_keys(:escape).perform
  end

  context "people as a teacher" do

    before (:each) do
      course_with_teacher_logged_in

      #add first student
      @student_1 = create_user('student@test.com')

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

      enroll_ta(@test_ta)

      get "/courses/#{@course.id}/users"
    end

    it "should have tabs" do
      expect(fj('.collectionViewItems>li:first').text).to match "Everyone"
    end

    it "should display a dropdown menu when item cog is clicked" do
      open_dropdown_menu
    end

    it "should display the option to remove a student from a course if manually enrolled" do
      open_dropdown_menu("tr[id=user_#{@student_1.id}]")
      expect(dropdown_item_visible?('removeFromCourse', "tr[id=user_#{@student_1.id}]")).to be true
    end

    it "should display the option to remove a student from a course has a SIS ID", priority: "1", test_id: 336018 do
      @course.sis_source_id = 'xyz'
      @course.save
      enroll_student(@student_2)
      # need to hit /users page again to show enrollment of 2nd student
      get "/courses/#{@course.id}/users"
      wait_for_ajaximations
      # check 1st student
      open_dropdown_menu("tr[id=user_#{@student_1.id}]")
      expect(dropdown_item_visible?('removeFromCourse', "tr[id=user_#{@student_1.id}]")).to be true
      close_dropdown_menu
      # check 2nd student
      open_dropdown_menu("tr[id=user_#{@student_2.id}]")
      expect(dropdown_item_visible?('removeFromCourse', "tr[id=user_#{@student_2.id}]")).to be true
    end

    it "should display remove option for student with/without SIS id", priority: "1", test_id: 332576 do
      enroll_student(@student_2)
      @student = user_with_managed_pseudonym
      @course.enroll_student(@student)
      @course.save
      get "/courses/#{@course.id}/users"
      # check 1st student
      open_dropdown_menu("tr[id=user_#{@student_1.id}]")
      expect(dropdown_item_visible?('removeFromCourse', "tr[id=user_#{@student_1.id}]")).to be true
      close_dropdown_menu
      # check 2nd student
      open_dropdown_menu("tr[id=user_#{@student_2.id}]")
      expect(dropdown_item_visible?('removeFromCourse', "tr[id=user_#{@student_2.id}]")).to be true
    end

    it "should display the option to remove a ta from the course" do
      open_dropdown_menu("tr[id=user_#{@test_ta.id}]")
      expect(dropdown_item_visible?('removeFromCourse', "tr[id=user_#{@test_ta.id}]")).to be true
    end

    it "should display activity report on clicking Student Interaction button", priority: "1", test_id: 244446 do
      f("#people-options .Button").click
      fln("Student Interactions Report").click
      expect(f("h1").text).to eq "Teacher Activity Report for #{@user.name}"
    end

    it "should not display Student Interaction button for a student", priority: "1", test_id: 244450  do
      user_session(@student_1)
      get "/courses/#{@course.id}/users"
      expect(f("#content")).not_to contain_link("Student Interactions Report")
    end

    it "should focus on the + Group Set button after the tabs" do
      driver.execute_script("$('.collectionViewItems > li:last a').focus()")
      active = driver.execute_script("return document.activeElement")
      active.send_keys(:tab)
      check_element_has_focus(fj('.group-categories-actions .btn-primary'))
    end

    it "should make sure focus is set to the X button each time the page changes" do
      f('#addUsers').click
      wait_for_ajaximations
      check_element_has_focus(f('.ui-dialog-titlebar-close'))
      f('#user_list_textarea').send_keys('student2@test.com')
      f('#next-step').click
      wait_for_ajaximations
      check_element_has_focus(f('.ui-dialog-titlebar-close'))
      f('#createUsersAddButton').click
      wait_for_ajaximations
      check_element_has_focus(f('.ui-dialog-titlebar-close'))
    end

    it "should validate the main page" do
      users = ff('.roster_user_name')
      expect(users[1].text).to match @student_1.name
      expect(users[0].text).to match @teacher.name
    end

    it "should navigate to registered services on profile page" do
      f("#people-options .Button").click
      fln('View Registered Services').click
      fln('Link web services to my account').click
      expect(f('#unregistered_services')).to be_displayed
    end

    it "should make a new set of student groups" do
      create_student_group
    end

    it "should test self sign up functionality" do
      f("#people-options .Button").click
      expect_new_page_load { fln('View User Groups').click }
      dialog = open_student_group_dialog
      dialog.find_element(:css, '#enable_self_signup').click
      expect(dialog.find_element(:css, '#split_groups')).not_to be_displayed
      expect(dialog).to include_text("groups now")
    end

    it "should test self sign up / group structure functionality" do
      group_count = "4"
      expect_new_page_load do
        f("#people-options .Button").click
        fln('View User Groups').click
      end
      dialog = open_student_group_dialog
      replace_content(f('#new_category_name'), 'new group')
      dialog.find_element(:css, '#enable_self_signup').click
      fj('input[name="create_group_count"]:visible').send_keys(group_count)
      submit_form('.group-category-create')
      wait_for_ajaximations
      expect(@course.groups.count).to eq 4
      expect(f('.groups-with-count')).to include_text("Groups (#{group_count})")
    end

    it "should test group structure functionality" do
      enroll_more_students

      group_count = "4"
      expect_new_page_load do
        f("#people-options .Button").click
        fln('View User Groups').click
      end
      dialog = open_student_group_dialog
      replace_content(f('#new_category_name'), 'new group')
      dialog.find_element(:css, '#split_groups').click
      fj('input[name="create_group_count"]:visible').send_keys(group_count)
      expect(@course.groups.count).to eq 0
      submit_form('.group-category-create')
      wait_for_ajaximations
      run_jobs
      wait_for_ajaximations
      expect(@course.groups.count).to eq group_count.to_i
      expect(f('.groups-with-count')).to include_text("Groups (#{group_count})")
    end

    it "should edit a student group" do
      new_group_name = "new group edit name"
      create_student_group
      fj('.group-category-actions:visible a:visible').click
      f('.edit-category').click
      edit_form = f('.group-category-edit')
      edit_form.find_element(:css, 'input[name="name"]').send_keys(new_group_name)
      submit_form(edit_form)
      wait_for_ajaximations
      expect(f(".collectionViewItems")).to include_text(new_group_name)
    end

    it "should delete a student group" do
      create_student_group
      fj('.group-category-actions:visible a:visible').click
      f('.delete-category').click
      keep_trying_until do
        expect(driver.switch_to.alert).not_to be_nil
        driver.switch_to.alert.accept
        true
      end
      wait_for_ajaximations
      refresh_page
      expect(f('.empty-groupset-instructions')).to be_displayed
    end

    it "should test prior enrollment functionality" do
      @course.complete
      get "/courses/#{@course.id}/users"
      expect_new_page_load do
        f("#people-options .Button").click
        fln('View Prior Enrollments').click
      end
      expect(f('#users')).to include_text(@student_1.name)
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
    end
  end

  context "people as a TA" do

    before (:each) do
      course_with_ta_logged_in(:active_all => true)
    end

    it "should validate that the TA cannot delete / conclude or reset course" do
      get "/courses/#{@course.id}/settings"
      expect(f("#content")).not_to contain_css('.delete_course_link')
      expect(f("#content")).not_to contain_css('.reset_course_content_button')
      get "/courses/#{@course.id}/confirm_action?event=conclude"
      expect(f('.ui-state-error')).to include_text('Unauthorized')
    end

    # TODO reimplement per CNVS-29609, but make sure we're testing at the right level
    it "should validate that a TA cannot rename a teacher"
  end

  context "course with multiple sections", priority: "2" do
    before(:each) do
      course_with_teacher_logged_in
      @section2 = @course.course_sections.create!(name: 'section2')
    end

    it "should save add people form data" do
      get "/courses/#{@course.id}/users"

      f('#addUsers').click
      wait_for_ajaximations

      expect(f('#create-users-step-1')).to be_displayed
      replace_content(f('#user_list_textarea'), 'student@example.com')
      click_option('#role_id', ta_role.id.to_s, :value)
      click_option('#course_section_id', 'Unnamed Course', :text)
      scroll_page_to_bottom
      move_to_click('#limit_privileges_to_course_section')
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
      f(".StudentEnrollment .icon-settings").click
      fln("Edit Sections").click
      f(".token_input.browsable").click
      section_input_element = driver.find_element(:name, "token_capture")
      section_input_element.send_keys("section2")
      f('.last.context').click
      wait_for_ajaximations
      ff('.ui-button-text')[1].click
      wait_for_ajaximations
      expect(ff(".StudentEnrollment")[0]).to include_text("section2")
    end

    it "should remove a student from a section", priority: "1", test_id: 296461 do
     @student = user
     @course.enroll_student(@student, allow_multiple_enrollments: true)
     @course.enroll_student(@student, section: @section2, allow_multiple_enrollments: true)
     get "/courses/#{@course.id}/users"
     f(".StudentEnrollment .icon-settings").click
     fln("Edit Sections").click
     fln("Remove user from section2").click
     ff('.ui-button-text')[1].click
     wait_for_ajaximations
     expect(ff(".StudentEnrollment")[0]).not_to include_text("section2")
    end

    it "should gray out sections the user doesn't have permission to remove" do
      @student = user_with_managed_pseudonym
      e = @course.enroll_student(@student, allow_multiple_enrollments: true)
      sis = @course.root_account.sis_batches.create
      e.sis_batch_id = sis.id
      e.save!
      get "/courses/#{@course.id}/users"
      ff(".icon-settings")[1].click
      fln("Edit Sections").click
      expect(f('#user_sections li.cannot_remove').text).to include @course.default_section.name

      # add another section (not via SIS) and ensure it remains editable
      f(".token_input.browsable").click
      section_input_element = driver.find_element(:name, "token_capture")
      section_input_element.send_keys("section2")
      f('.last.context').click
      wait_for_ajaximations
      expect(f("a[title='Remove user from section2']")).not_to be_nil
      f('.ui-dialog-buttonset .btn-primary').click
      wait_for_ajaximations

      ff(".icon-settings")[1].click
      fln("Edit Sections").click
      expect(f('#user_sections li.cannot_remove').text).to include @course.default_section.name
      expect(f("a[title='Remove user from section2']")).not_to be_nil
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
    expect(fj("#user_#{@student.id} td:nth-child(8)").text.strip).to eq "15:00"
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

  context "editing role" do
    before :once do
      course
      @section = @course.course_sections.create!(name: "section1")

      @teacher = user_with_pseudonym(:active_all => true)
      @enrollment = @course.enroll_teacher(@teacher)
    end

    before :each do
      admin_logged_in
    end

    it "should let observers have their roles changed if they don't have associated users" do
      @course.enroll_user(@teacher, "ObserverEnrollment", :allow_multiple_enrollments => true)

      get "/courses/#{@course.id}/users"

      open_dropdown_menu("#user_#{@teacher.id}")
      expect_dropdown_item('editRoles', "#user_#{@teacher.id}")
    end

    it "should not let observers with associated users have their roles changed" do
      student = user
      @course.enroll_student(student)
      @course.enroll_user(@teacher, "ObserverEnrollment", :allow_multiple_enrollments => true, :associated_user_id => student.id)

      get "/courses/#{@course.id}/users"

      open_dropdown_menu("#user_#{@teacher.id}")
      expect_no_dropdown_item('editRoles', "#user_#{@teacher.id}")
    end

    def open_role_dialog(user)
      f("#user_#{user.id} .admin-links a.al-trigger").click
      f("#user_#{user.id} .admin-links a[data-event='editRoles']").click
    end

    it "should let users change to an observer role" do
      get "/courses/#{@course.id}/users"

      open_role_dialog(@teacher)

      expect(f("#edit_roles #role_id option[selected]")).to include_text("Teacher")
      expect(f("#edit_roles #role_id option[value='#{student_role.id}']")).to be_present
      expect(f("#edit_roles #role_id option[value='#{observer_role.id}']")).to be_present
    end

    it "should not let users change to a type they don't have permission to manage" do
      @course.root_account.role_overrides.create!(:role => admin_role, :permission => 'manage_students', :enabled => false)

      get "/courses/#{@course.id}/users"

      open_role_dialog(@teacher)
      expect(f("#edit_roles #role_id option[value='#{ta_role.id}']")).to be_present
      expect(f("#content")).not_to contain_css("#edit_roles #role_id option[value='#{student_role.id}']")
    end

    it "should retain the same enrollment state" do
      role_name = 'Custom Teacher'
      role = @course.account.roles.create(:name => role_name)
      role.base_role_type = 'TeacherEnrollment'
      role.save!
      @enrollment.deactivate

      get "/courses/#{@course.id}/users"

      open_role_dialog(@teacher)
      click_option("#edit_roles #role_id", role.id.to_s, :value)
      f('.ui-dialog-buttonpane .btn-primary').click
      wait_for_ajaximations
      assert_flash_notice_message /Role successfully updated/

      expect(f("#user_#{@teacher.id}")).to include_text(role_name)
      @enrollment.reload
      expect(@enrollment).to be_deleted

      new_enrollment = @teacher.enrollments.not_deleted.first
      expect(new_enrollment.role).to eq role
      expect(new_enrollment.workflow_state).to eq "inactive"
    end

    it "should work with enrollments in different sections" do
      enrollment2 = @course.enroll_user(@teacher, "TeacherEnrollment", :allow_multiple_enrollments => true, :section => @section)

      get "/courses/#{@course.id}/users"

      open_role_dialog(@teacher)
      click_option("#edit_roles #role_id", ta_role.id.to_s, :value)
      f('.ui-dialog-buttonpane .btn-primary').click
      wait_for_ajaximations
      assert_flash_notice_message /Role successfully updated/

      expect(@enrollment.reload).to be_deleted
      expect(enrollment2.reload).to be_deleted

      new_enrollment1 = @teacher.enrollments.not_deleted.where(:course_section_id => @course.default_section).first
      new_enrollment2 = @teacher.enrollments.not_deleted.where(:course_section_id => @section).first
      expect(new_enrollment1.role).to eq ta_role
      expect(new_enrollment2.role).to eq ta_role
    end

    it "should work with preexiting enrollments in the destination role" do
      # should not try to overwrite this one
      enrollment2 = @course.enroll_user(@teacher, "TaEnrollment", :allow_multiple_enrollments => true)

      get "/courses/#{@course.id}/users"

      open_role_dialog(@teacher)
      click_option("#edit_roles #role_id", ta_role.id.to_s, :value)
      f('.ui-dialog-buttonpane .btn-primary').click
      wait_for_ajaximations
      assert_flash_notice_message /Role successfully updated/

      expect(@enrollment.reload).to be_deleted
      expect(enrollment2.reload).to_not be_deleted
    end

    it "should work with multiple enrollments in one section" do
      # shouldn't conflict with each other - should only add one enrollment for the new role
      enrollment2 = @course.enroll_user(@teacher, "TaEnrollment", :allow_multiple_enrollments => true)

      get "/courses/#{@course.id}/users"

      open_role_dialog(@teacher)
      expect(f("#edit_roles")).to include_text("This user has multiple roles") # warn them that both roles will be removed
      click_option("#edit_roles #role_id", student_role.id.to_s, :value)
      f('.ui-dialog-buttonpane .btn-primary').click
      wait_for_ajaximations
      assert_flash_notice_message /Role successfully updated/

      expect(@enrollment.reload).to be_deleted
      expect(enrollment2.reload).to be_deleted

      new_enrollment = @teacher.enrollments.not_deleted.first
      expect(new_enrollment.role).to eq student_role
    end

    it "should not show the option to edit roles for a soft-concluded course" do
      @course.conclude_at = 2.days.ago
      @course.restrict_enrollments_to_course_dates = true
      @course.save!

      get "/courses/#{@course.id}/users"
      open_dropdown_menu("#user_#{@teacher.id}")
      expect_no_dropdown_item('editRoles', "#user_#{@teacher.id}")
    end

    it "should not show the option to edit roles for a SIS imported enrollment" do
      sis = @course.root_account.sis_batches.create
      student = user_with_pseudonym(:active_all => true)
      enrollment = @course.enroll_teacher(student)
      enrollment.sis_batch_id = sis.id
      enrollment.save!

      user_session(@teacher)

      get "/courses/#{@course.id}/users"
      open_dropdown_menu("#user_#{student.id}")
      expect_no_dropdown_item('editRoles', "#user_#{student.id}")
    end

    it "should redirect to groups page " do
      user_session(@teacher)

      get "/courses/#{@course.id}/users"

      group_link = ff('#group_categories_tabs .ui-tabs-nav li').last
      expect(group_link).to include_text("Groups")

      expect_new_page_load { group_link.click }
      expect(driver.current_url).to include("/courses/#{@course.id}/groups")
    end
  end
end
