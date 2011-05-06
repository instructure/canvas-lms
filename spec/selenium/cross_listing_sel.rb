require File.expand_path(File.dirname(__FILE__) + '/common')

shared_examples_for "cross-listing selenium tests" do
  it_should_behave_like "in-process server selenium tests"
  
  it "should allow cross-listing a section" do
    username = "nobody@example.com"
    password = "asdfasdf"
    u = user_with_pseudonym :active_user => true,
                            :username => username,
                            :password => password
    u.save!
    e = course_with_teacher :active_course => true,
                            :user => u,
                            :active_enrollment => true
    e.save!
    course = e.course
    other_course = course_with_teacher(:active_course => true,
                            :user => u,
                            :active_enrollment => true).course
    other_course.update_attribute(:name, "cool course")
    section = e.course_section
    login_as(username, password)

    get "/courses/#{e.course_id}/sections/#{section.id}"
    driver.find_element(:css, ".crosslist_link").click
    form = driver.find_element(:css, "#crosslist_course_form")
    form.find_element(:css, ".submit_button").attribute(:disabled).should eql("true")
    form.should_not be_nil
    form.find_element(:css, "#course_id").click
    form.find_element(:css, "#course_id").send_keys("-1\n")
    keep_trying { driver.find_element(:css, "#course_autocomplete_name").text != "Confirming Course ID \"-1\"..." }
    driver.find_element(:css, "#course_autocomplete_name").text.should eql("Course ID \"-1\" not authorized for cross-listing")
    
    form.find_element(:css, "#course_id").click
    form.find_element(:css, "#course_id").clear
    form.find_element(:css, "#course_id").send_keys([:control, 'a'], other_course.id.to_s, "\n")
    keep_trying { driver.find_element(:css, "#course_autocomplete_name").text != "Confirming Course ID \"#{other_course.id}\"..." }
    driver.find_element(:css, "#course_autocomplete_name").text.should eql(other_course.name)
    form.find_element(:css, "#course_autocomplete_id").value.should eql(other_course.id.to_s)
    form.find_element(:css, ".submit_button").attribute(:disabled).should eql("false")
    form.find_element(:css, ".submit_button").click
    keep_trying { driver.current_url.match(/courses\/#{other_course.id}/) }
    get "/courses/#{other_course.id}/sections/#{section.id}"
    driver.find_elements(:css, ".uncrosslist_link").length.should eql(0)
    
    course.enroll_teacher(u).accept
    get "/courses/#{other_course.id}/sections/#{section.id}"
    driver.find_element(:css, ".uncrosslist_link").click
    driver.find_element(:css, "#uncrosslist_form").displayed?.should eql(true)
    driver.find_element(:css, "#uncrosslist_form .submit_button").click
    keep_trying { driver.current_url.match(/courses\/#{e.course_id}/) }
  end
end

describe "cross-listing Windows-Firefox-Tests" do
  it_should_behave_like "cross-listing selenium tests"
end

