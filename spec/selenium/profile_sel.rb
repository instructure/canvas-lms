require File.expand_path(File.dirname(__FILE__) + '/common')

shared_examples_for "profile selenium tests" do
  it_should_behave_like "in-process server selenium tests"

  it "should not have any javascript errors while adding an email address" do
    course_with_student_logged_in
    
    get "/profile"
    driver.find_element(:css, ".add_email_link").click
    form = driver.find_element(:id, "register_email_address")
    form.find_element(:id, "pseudonym_unique_id").send_keys("nobody+1234@example.com")
    form.find_element(:class, "button").click
    
    confirmation_dialog = driver.find_element(:id, "confirm_email_channel")
    keep_trying_until { confirmation_dialog.displayed? }
    
    driver.execute_script("return INST.errorCount;").should == 0
    confirmation_dialog.find_element(:css, "button").click
    confirmation_dialog.displayed?.should be_false
  end
end

describe "course Windows-Firefox-Tests" do
  it_should_behave_like "profile selenium tests"
end
