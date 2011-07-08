require File.expand_path(File.dirname(__FILE__) + '/common')

describe "editing assignments" do
  it_should_behave_like "in-process server selenium tests"
  
  it "should allow creating a quiz assignment from 'more options'" do
    course_with_teacher_logged_in
    get "/courses/#{@course.id}/assignments"
    
    driver.find_element(:css, ".assignment_group .add_assignment_link").click
    form = driver.find_element(:css, "#add_assignment_form")
    form.find_element(:css, ".assignment_submission_types option[value='online_quiz']").click
    expect_new_page_load{ form.find_element(:css, ".more_options_link").click }
    
    driver.find_element(:css, ".submission_type_option option[value='none']").should be_selected
    driver.find_element(:css, ".assignment_type option[value='assignment']").click
    driver.find_element(:css, ".submission_type_option option[value='online']").click
    driver.find_element(:css, ".assignment_type option[value='quiz']").click
    
    expect_new_page_load{ driver.find_element(:css, "#edit_assignment_form button[type='submit']").click }
  end
end
