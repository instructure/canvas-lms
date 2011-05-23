require File.expand_path(File.dirname(__FILE__) + '/common')

shared_examples_for "course selenium tests" do
  it_should_behave_like "in-process server selenium tests"

  it "should allow moving a student to a different section" do
    username = "nobody@example.com"
    password = "asdfasdf"
    t = user_with_pseudonym :active_user => true,
                            :username => username,
                            :password => password
    t.save!
    e = course_with_teacher :active_course => true,
                            :user => t,
                            :active_enrollment => true
    e.save!
    c = e.course
    student = user :active_user => true
    se = c.enroll_student(student)
    section = c.course_sections.create!(:name => 'M/W/F')
    login_as(username, password)

    get "/courses/#{e.course_id}/details"
    driver.find_element(:css, '#tab-users-link').click
    student_user = driver.find_element(:css, ".user_list #enrollment_#{se.id}")
    section_label = student_user.find_element(:css, ".section")
    section_dropdown = student_user.find_element(:css, ".enrollment_course_section_form #course_section_id")
    section_label.displayed?.should be_true
    section_dropdown.displayed?.should be_false
    # hover over the user to make the links appear
    driver.execute_script("$('.user_list #enrollment_#{se.id} .links').css('visibility', 'visible')")
    edit_section_link = student_user.find_element(:css, ".edit_section_link")
    edit_section_link.displayed?.should be_true
    edit_section_link.click
    section_label.displayed?.should be_false
    section_dropdown.displayed?.should be_true
    section_dropdown.find_element(:css, "option[value=\"#{section.id.to_s}\"]").select

    keep_trying { !section_dropdown.displayed? }

    se.reload
    se.course_section_id.should == section.id
    section_label.displayed?.should be_true
    section_label.text.should == section.name
  end
end

describe "course Windows-Firefox-Tests" do
  it_should_behave_like "course selenium tests"
end
