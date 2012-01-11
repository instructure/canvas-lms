require File.expand_path(File.dirname(__FILE__) + '/common')

describe "course settings tests" do
  it_should_behave_like "in-process server selenium tests"

  def add_section(section_name)
    @course.course_sections.create!(:name => section_name)
    @course.reload
  end

  def add_user_to_section(username = 'user@example.com', accept_invitation = true)
    cs = @course.course_sections.create!
    u = User.create!(:name => username)
    u.register!
    if accept_invitation
      @course.enroll_user(u, 'StudentEnrollment', :section => cs).accept
    else
      e = @course.enroll_user(u, 'StudentEnrollment', :section => cs)
      e.workflow_state = 'active'
      e.save!
    end
    @course.reload
    username
  end

  describe "course items" do

    before (:each) do
      course_with_teacher_logged_in
    end

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
      course_form.submit
      wait_for_ajaximations

      driver.find_element(:css, '.course_info').should include_text(course_name)
      driver.find_element(:css, '.course_code').should include_text(course_code)
      driver.find_element(:css, '.locale').should include_text(locale_text)
    end

    it "should add a section" do
      section_name = 'new section'
      get "/courses/#{@course.id}/settings"

      driver.find_element(:link, 'Sections').click
      section_input = driver.find_element(:id, 'course_section_name')
      keep_trying_until { section_input.should be_displayed }
      replace_content(section_input, section_name)
      driver.find_element(:id, 'add_section_form').submit
      wait_for_ajaximations
      new_section = driver.find_elements(:css, 'ul#sections > .section')[1]
      new_section.should include_text(section_name)
    end

    it "should delete a section" do
      add_section('Delete Section')
      get "/courses/#{@course.id}/settings"

      driver.find_element(:link, 'Sections').click
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
      get "/courses/#{@course.id}/settings"

      driver.find_element(:link, 'Sections').click
      driver.find_element(:css, '.section_link.edit_section_link').click
      section_input = driver.find_element(:id, 'course_section_name')
      keep_trying_until { section_input.should be_displayed }
      replace_content(section_input, edit_text)
      section_input.send_keys(:return)
      wait_for_ajaximations
      driver.find_elements(:css, 'ul#sections > .section')[0].should include_text(edit_text)
    end

    it "should move a nav item to disabled" do
      driver.find_element(:link, 'Navigation').click
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
    before (:each) do
      course_with_teacher_logged_in
    end

    it "should add a user to a section" do
      user = user_with_pseudonym(:active_user => true, :username => 'user@example.com', :name=> 'user@example.com')

      get "/courses/#{@course.id}/settings"
      section_name = 'Add User Section'
      add_section(section_name)
      driver.find_element(:link, 'Users').click
      refresh_page
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
      driver.find_element(:link, 'Sections').click
      refresh_page
      new_section = driver.find_elements(:css, 'ul#sections > .section')[1]
      new_section.find_element(:css, '.users_count').should include_text("1")
    end

    it "should remove a user from a section" do
      username = add_user_to_section

      get "/courses/#{@course.id}/settings"
      driver.find_element(:link, 'Users').click
      driver.execute_script("$('li#enrollment_2 .unenroll_user_link').click()")
      driver.switch_to.alert.accept
      keep_trying_until do
        driver.find_element(:id, 'tab-users').should_not include_text(username)
        true
      end
    end

    it "should move a user to a new section" do
      section_name = 'Unnamed Course'
      add_user_to_section

      get "/courses/#{@course.id}/settings"
      driver.find_element(:link, 'Users').click
      driver.execute_script("$('li#enrollment_2 .edit_section_link').click()")
      click_option('#course_section_id', section_name)
      wait_for_ajaximations
      driver.find_element(:css, 'li#enrollment_2 .section').should include_text(section_name)
    end

    it "should view the users enrollment details" do
      username = add_user_to_section('user@example.com', true)

      get "/courses/#{@course.id}/settings"
      driver.find_element(:link, 'Users').click
      driver.execute_script("$('li#enrollment_2 .user_information_link').click()")
      enrollment_dialog = driver.find_element(:id, 'enrollment_dialog')
      enrollment_dialog.should be_displayed
      enrollment_dialog.should include_text(username + ' has already received and accepted the invitation')
    end
  end
end
