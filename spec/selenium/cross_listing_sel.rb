require File.expand_path(File.dirname(__FILE__) + '/common')

shared_examples_for "cross-listing selenium tests" do
  it_should_behave_like "in-process server selenium tests"
  
  it "should allow cross-listing a section" do
    course_with_teacher_logged_in
    course = @course
    other_course = course_with_teacher(:active_course => true,
                            :user => @user,
                            :active_enrollment => true).course
    other_course.update_attribute(:name, "cool course")
    section = course.course_sections.first

    get "/courses/#{course.id}/sections/#{section.id}"
    driver.find_element(:css, ".crosslist_link").click
    form = driver.find_element(:css, "#crosslist_course_form")
    form.find_element(:css, ".submit_button").attribute(:disabled).should eql("true")
    form.should_not be_nil
    form.find_element(:css, "#course_id").click
    form.find_element(:css, "#course_id").send_keys("-1\n")
    keep_trying_until { driver.find_element(:css, "#course_autocomplete_name").text != "Confirming Course ID \"-1\"..." }
    driver.find_element(:css, "#course_autocomplete_name").text.should eql("Course ID \"-1\" not authorized for cross-listing")
    
    form.find_element(:css, "#course_id").click
    form.find_element(:css, "#course_id").clear
    form.find_element(:css, "#course_id").send_keys([:control, 'a'], other_course.id.to_s, "\n")
    keep_trying_until { driver.find_element(:css, "#course_autocomplete_name").text != "Confirming Course ID \"#{other_course.id}\"..." }
    driver.find_element(:css, "#course_autocomplete_name").text.should eql(other_course.name)
    form.find_element(:css, "#course_autocomplete_id").attribute(:value).should eql(other_course.id.to_s)
    form.find_element(:css, ".submit_button").attribute(:disabled).should eql("false")
    form.find_element(:css, ".submit_button").click
    keep_trying_until { driver.current_url.match(/courses\/#{other_course.id}/) }
    get "/courses/#{other_course.id}/sections/#{section.id}"
    driver.find_elements(:css, ".uncrosslist_link").length.should eql(0)
    
    course.enroll_teacher(@user).accept
    get "/courses/#{other_course.id}/sections/#{section.id}"
    driver.find_element(:css, ".uncrosslist_link").click
    driver.find_element(:css, "#uncrosslist_form").displayed?.should eql(true)
    driver.find_element(:css, "#uncrosslist_form .submit_button").click
    keep_trying_until { driver.current_url.match(/courses\/#{course.id}/) }
  end
end

describe "cross-listing Windows-Firefox-Tests" do
  it_should_behave_like "cross-listing selenium tests"
end

