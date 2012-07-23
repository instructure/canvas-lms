require File.expand_path(File.dirname(__FILE__) + '/common')

describe "course settings" do
  it_should_behave_like "in-process server selenium tests"

  before (:each) do
    course_with_teacher_logged_in
  end

  describe "course details" do
    def test_select_standard_for(context)
      grading_standard_for context
      get "/courses/#{@course.id}/settings"

      f('.edit_course_link').click
      f('.grading_standard_checkbox').click unless is_checked('.grading_standard_checkbox')
      f('.edit_letter_grades_link').click
      f('.find_grading_standard_link').click
      wait_for_ajaximations

      fj('.grading_standard_select:visible a').click
      fj('button.select_grading_standard_link:visible').click
      f('.done_button').click
      submit_form('#course_form')
      wait_for_ajaximations

      f('.grading_scheme_set').should include_text @standard.title
    end

    it "should allow selection of existing course grading standard" do
      test_select_standard_for @course
    end

    it "should allow selection of existing account grading standard" do
      test_select_standard_for @course.root_account
    end

    it "should show the self enrollment code and url once enabled" do
      a = Account.default
      a.courses << @course
      a.settings[:self_enrollment] = 'manually_created'
      a.save!
      get "/courses/#{@course.id}/settings"
      f('.edit_course_link').click
      f('.course_form_more_options_link').click
      f('#course_self_enrollment').click
      submit_form('#course_form')
      wait_for_ajaximations

      code = @course.reload.self_enrollment_code
      code.should_not be_nil
      message = f('.self_enrollment_message')
      message.text.should include(code)
      message.text.should_not include('self_enrollment_code')
    end
  end

  describe "course items" do

    it "should change course details" do
      course_name = 'new course name'
      course_code = 'new course-101'
      locale_text = 'English'

      get "/courses/#{@course.id}/settings"

      driver.find_element(:css, '.edit_course_link').click
      course_form = driver.find_element(:id, 'course_form')
      name_input = course_form.find_element(:id, 'course_name')
      replace_content(name_input, course_name)
      code_input = course_form.find_element(:id, 'course_course_code')
      replace_content(code_input, course_code)
      click_option('#course_locale', locale_text)
      driver.find_element(:css, '.course_form_more_options_link').click
      wait_for_animations
      driver.find_element(:css, '.course_form_more_options').should be_displayed
      submit_form(course_form)
      wait_for_ajaximations

      driver.find_element(:css, '.course_info').should include_text(course_name)
      driver.find_element(:css, '.course_code').should include_text(course_code)
      driver.find_element(:css, '.locale').should include_text(locale_text)
    end

    it "should add a section" do
      section_name = 'new section'
      get "/courses/#{@course.id}/settings#tab-sections"

      section_input = driver.find_element(:id, 'course_section_name')
      keep_trying_until { section_input.should be_displayed }
      replace_content(section_input, section_name)
      submit_form('#add_section_form')
      wait_for_ajaximations
      new_section = driver.find_elements(:css, 'ul#sections > .section')[1]
      new_section.should include_text(section_name)
    end

    it "should delete a section" do
      add_section('Delete Section')
      get "/courses/#{@course.id}/settings#tab-sections"

      driver.find_element(:css, '.section_link.delete_section_link').click
      keep_trying_until do
        driver.switch_to.alert.should_not be_nil
        driver.switch_to.alert.accept
        true
      end
      wait_for_ajaximations
      driver.find_elements(:css, 'ul#sections > .section').count.should == 1
    end

    it "should edit a section" do
      edit_text = 'Section Edit Text'
      add_section('Edit Section')
      get "/courses/#{@course.id}/settings#tab-sections"

      driver.find_element(:css, '.section_link.edit_section_link').click
      section_input = driver.find_element(:id, 'course_section_name')
      keep_trying_until { section_input.should be_displayed }
      replace_content(section_input, edit_text)
      section_input.send_keys(:return)
      wait_for_ajaximations
      driver.find_elements(:css, 'ul#sections > .section')[0].should include_text(edit_text)
    end

    it "should move a nav item to disabled" do
      get "/courses/#{@course.id}/settings#tab-navigation"
      disabled_div = driver.find_element(:id, 'nav_disabled_list')
      announcements_nav = driver.find_element(:id, 'nav_edit_tab_id_14')
      driver.action.click_and_hold(announcements_nav).
          move_to(disabled_div).
          release(disabled_div).
          perform
      driver.find_element(:id, 'nav_disabled_list').should include_text(announcements_nav.text)
    end
  end

  describe "course users" do

    it "should add a user to a section" do
      user = user_with_pseudonym(:active_user => true, :username => 'user@example.com', :name => 'user@example.com')
      section_name = 'Add User Section'
      add_section(section_name)
      get "/courses/#{@course.id}/settings#tab-users"

      add_button = driver.find_element(:css, '.add_users_link')
      keep_trying_until { add_button.should be_displayed }
      add_button.click
      click_option('#course_section_id_holder > #course_section_id', section_name)
      driver.find_element(:css, 'textarea.user_list').send_keys(user.name)
      driver.find_element(:css, '.verify_syntax_button').click
      wait_for_ajax_requests
      driver.find_element(:id, 'user_list_parsed').should include_text(user.name)
      driver.find_element(:css, '.add_users_button').click
      wait_for_ajax_requests
      refresh_page #needed to update the student count on the next page
      f("a[href='#tab-sections']").click
      new_section = driver.find_elements(:css, 'ul#sections > .section')[1]
      new_section.find_element(:css, '.users_count').should include_text("1")
    end

    it "should remove a user from a section" do
      username = "user@example.com"
      student_in_course(:name => username)
      @enrollment.course_section = @course_section; @enrollment.save

      get "/courses/#{@course.id}/settings#tab-users"
      driver.execute_script("$('#enrollment_#{@enrollment.id} .unenroll_user_link').click()")
      driver.switch_to.alert.accept
      wait_for_ajaximations
      driver.find_element(:id, 'tab-users').should_not include_text(username)
    end

    it "should move a user to a new section" do
      section_name = 'Move to Course Section'
      add_section(section_name)
      student_in_course
      @enrollment.course_section = @course_section; @enrollment.save

      get "/courses/#{@course.id}/settings#tab-users"
      driver.execute_script("$('#enrollment_#{@enrollment.id} .edit_section_link').click()")
      click_option("#enrollment_#{@enrollment.id} .course_section_id", section_name)
      wait_for_ajaximations
      driver.find_element(:css, "#enrollment_#{@enrollment.id} .section").should include_text(section_name)
    end

    it "should view the users enrollment details" do
      username = "user@example.com"
      student_in_course(:name => username, :active_all => true)
      @enrollment.course_section = @course_section; @enrollment.save

      get "/courses/#{@course.id}/settings#tab-users"
      driver.execute_script("$('#enrollment_#{@enrollment.id} .user_information_link').click()")
      enrollment_dialog = driver.find_element(:id, 'enrollment_dialog')
      enrollment_dialog.should be_displayed
      enrollment_dialog.should include_text(username + ' has already received and accepted the invitation')
    end

    def link_to_student(link, student)
      assoc_links = link.find_elements(:css, ".associated_user_link")
      if assoc_links[0].displayed? then
        assoc_links[0].click
      else
        assoc_links[1].click
      end
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

      get "/courses/#{@course.id}/settings#tab-users"

      links = driver.find_elements(:css, ".user_#{@obs.id} .enrollment_link")
      links.length.should == 2
      links[0].find_element(:css, ".associated_user_name").should include_text @students[0].name
      links[1].find_element(:css, ".associated_user_name").should include_text @students[1].name

      link_to_student(links[0], @students[2])
      links[0].find_element(:css, ".associated_user_name").should include_text @students[2].name
      links[1].find_element(:css, ".associated_user_name").should include_text @students[1].name

      link_to_student(links[1], @students[3])
      links[0].find_element(:css, ".associated_user_name").should include_text @students[2].name
      links[1].find_element(:css, ".associated_user_name").should include_text @students[3].name

      @obs.reload
      @obs.enrollments.map { |e| e.associated_user_id }.sort.should == [@students[2].id, @students[3].id]

      link_to_student(links[0], nil)
      link_to_student(links[1], nil)
      links[0].find_element(:css, ".unassociated").should include_text "link to"
      links[1].find_element(:css, ".unassociated").should include_text "link to"

      link_to_student(links[0], @students[0])
      link_to_student(links[1], @students[1])
      links[0].find_element(:css, ".associated_user_name").should include_text @students[0].name
      links[1].find_element(:css, ".associated_user_name").should include_text @students[1].name

      @obs.reload
      @obs.enrollments.map { |e| e.associated_user_id }.sort.should == [@students[0].id, @students[1].id]
    end

    it "should not show the student view student" do
      @fake_student = @course.student_view_student
      get "/courses/#{@course.id}/settings#tab-users"
      ff(".student_enrollments .user_#{@fake_student.id}").should be_empty
    end
  end

  context "course users multiple enrollments" do
    before (:each) do
      @username = "multiple@example.com"
      add_section("Section 1")
      @old_section = @course_section
      student_in_course(:name => @username)
      @enrollment.course_section = @course_section; @enrollment.save
      add_section("Section 2")
      multiple_student_enrollment(@user, @course_section)
    end

    it "should coalesce multiple enrollments under a single student" do
      get "/courses/#{@course.id}/settings#tab-users"

      driver.find_elements(:css, ".user_#{@user.id} .section").length.should == 2
      driver.find_elements(:css, ".user_#{@user.id} .links .unenroll_user_link").length.should == 0
    end

    it "should show individual course section remove icons" do
      get "/courses/#{@course.id}/settings#tab-users"

      driver.execute_script("$('.user_#{@user.id} .edit_section_link').click()")
      find_all_with_jquery(".user_#{@user.id} .sections .unenroll_user_link:visible").length.should == 2
    end

    it "should only remove a user from a single section" do
      get "/courses/#{@course.id}/settings#tab-users"

      driver.execute_script("$('.user_#{@user.id} .section_#{@course_section.id} .unenroll_user_link').click()")
      driver.switch_to.alert.accept
      wait_for_ajaximations
      driver.find_element(:id, 'tab-users').should include_text(@username)
      driver.find_element(:css, ".user_#{@user.id}").should include_text(@old_section.name)
    end

    it "should change the correct section when editing" do
      add_section("Section 3")

      get "/courses/#{@course.id}/settings#tab-users"

      driver.execute_script("$('.user_#{@user.id} .edit_section_link').click()")
      click_option(".user_#{@user.id} .section_#{@old_section.id} .course_section_id", @course_section.name)
      wait_for_ajaximations

      driver.find_element(:css, ".user_#{@user.id}").should_not include_text(@old_section.name)
      driver.find_element(:css, ".user_#{@user.id}").should include_text(@course_section.name)
    end
  end

  context "right sidebar" do
    it "should allow entering student view from the right sidebar" do
      @fake_student = @course.student_view_student
      get "/courses/#{@course.id}/settings"
      f(".student_view_button").click
      wait_for_dom_ready
      f("#identity .user_name").should include_text @fake_student.name
    end

    it "should allow leaving student view" do
      enter_student_view
      stop_link = f("#sv_bar .leave_student_view")
      stop_link.should include_text "Leave Student View"
      stop_link.click
      wait_for_dom_ready
      f("#identity .user_name").should include_text @teacher.name
    end

    it "should allow resetting student view" do
      @fake_student_before = @course.student_view_student
      enter_student_view
      reset_link = f("#sv_bar .reset_test_student")
      reset_link.should include_text "Reset Student"
      reset_link.click
      wait_for_dom_ready
      @fake_student_after = @course.student_view_student
      @fake_student_before.id.should_not eql @fake_student_after.id
    end

    it "should not include student view student in the statistics count" do
      @fake_student = @course.student_view_student
      get "/courses/#{@course.id}/settings"
      find_with_jquery('.summary tr:nth(1)').text.should match /Students:\s*None/
    end
  end
end
