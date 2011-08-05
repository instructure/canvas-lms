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

  it "should successfully upload profile pictures" do
    a = Account.default
    a.enable_service('avatars')
    a.save!
    
    course_with_student_logged_in
    
    get "/profile"
    keep_trying_until { driver.find_element(:css, ".profile_pic_link.none") }.click
    dialog = driver.find_element(:id, "profile_pic_dialog")
    dialog.find_element(:css, ".profile_pic_list").find_elements(:css, "span.img").length.should == 2
    dialog.find_element(:css, ".add_pic_link").click
    filename, fullpath, data = get_file("graded.png")
    dialog.find_element(:id, 'attachment_uploaded_data').send_keys(fullpath)
    dialog.find_element(:css, 'button[type="submit"]').click
    spans = dialog.find_element(:css, ".profile_pic_list").find_elements(:css, "span.img")
    spans.length.should == 3
    keep_trying_until { spans.last.attribute('class') =~ /selected/ }
    dialog.find_element(:css, 'button.select_button').click
    keep_trying_until { driver.find_element(:css, '.profile_pic_link img').attribute('src') =~ %r{/images/thumbnails/} }
  end
end

describe "course Windows-Firefox-Tests" do
  it_should_behave_like "profile selenium tests"
end
