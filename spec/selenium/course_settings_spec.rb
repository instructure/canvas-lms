require File.expand_path(File.dirname(__FILE__) + '/common')

describe "course settings tests" do
  it_should_behave_like "in-process server selenium tests"

  def validate_text(element, text)
    element.text.should == text
  end

  def add_section(section_name)
    driver.find_element(:link, 'Sections').click
    section_input = driver.find_element(:id, 'course_section_name')
    keep_trying_until { section_input.should be_displayed }
    replace_content(section_input, section_name)
    driver.find_element(:id, 'add_section_form').submit
    wait_for_ajaximations
    new_section = driver.find_elements(:css, 'ul#sections > .section')[1]
    validate_text(new_section, section_name)
    new_section
  end

  before (:each) do
    course_with_teacher_logged_in
    get "/courses/#{@course.id}/settings"
  end

  it "should change course details" do
    course_name = 'new course name'
    course_code = 'new course-101'
    locale_text = 'English'

    driver.find_element(:css, '.edit_course_link').click
    course_form = driver.find_element(:id, 'course_form')
    name_input = course_form.find_element(:id, 'course_name')
    replace_content(name_input, course_name)
    code_input = course_form.find_element(:id, 'course_course_code')
    replace_content(code_input, course_code)
    locale_select = driver.find_element(:id, 'course_locale')
    click_option_by_text(locale_select, locale_text)
    driver.find_element(:css, '.course_form_more_options_link').click
    wait_for_animations
    driver.find_element(:css, '.course_form_more_options').should be_displayed
    course_form.submit
    wait_for_ajaximations

    validate_text(driver.find_element(:css, '.course_info'), course_name)
    validate_text(driver.find_element(:css, '.course_code'), course_code)
    validate_text(driver.find_element(:css, '.locale'), locale_text)
  end

  it "should add a section" do
    add_section('New Section')
  end

  it "should delete a section" do
    new_section = add_section('Delete Section')
    new_section.find_element(:css, '.delete_section_link').click
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
    new_section = add_section('Edit Section')
    new_section.find_element(:css, '.edit_section_link').click
    section_input = driver.find_element(:id, 'course_section_name')
    keep_trying_until { section_input.should be_displayed }
    replace_content(section_input, edit_text)
    section_input.send_keys(:return)
    wait_for_ajaximations
    validate_text(driver.find_elements(:css, 'ul#sections > .section')[1], edit_text)
  end

  it "should add a user to a section" do
    student = User.create!(:name => 'nobody2@example.com')
    student.register!
    student.pseudonyms.create!(:unique_id => 'nobody2@example.com', :password => 'qwerty', :password_confirmation => 'qwerty')
    @course.reload

    section_name = 'Move User Section'
    add_section(section_name)
    driver.find_element(:link, 'Users').click
    refresh_page
    add_button = driver.find_element(:css, '.add_users_link')
    keep_trying_until { add_button.should be_displayed }
    add_button.click
    select = driver.find_element(:css, '#course_section_id_holder > #course_section_id')
    click_option_by_text(select, section_name)
    driver.find_element(:css, 'textarea.user_list').send_keys(student.name)
    driver.find_element(:css, '.verify_syntax_button').click
    wait_for_ajax_requests
    driver.find_element(:id, 'user_list_parsed').should include_text(student.name)
    driver.find_element(:css, '.add_users_button').click
    wait_for_ajax_requests
    driver.find_element(:link, 'Sections').click
    refresh_page
    new_section = driver.find_elements(:css, 'ul#sections > .section')[1]
    new_section.find_element(:css, '.users_count').should include_text("1")
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
