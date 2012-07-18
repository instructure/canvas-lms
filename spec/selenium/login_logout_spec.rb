require File.expand_path(File.dirname(__FILE__) + '/common')

describe "login logout" do
  it_should_behave_like "in-process server selenium tests"

  USERNAME = "nobody@example.com"
  VALID_PASSWORD = "asdfasdf"
  LOGIN_ERROR_BOX = "div.error_text:last"

  def should_show_message(message_text, element)
    find_with_jquery(element).should include_text(message_text)
  end

  def verify_logout
    expected_url = app_host + "/login"
    user_with_pseudonym({:active_user => true})
    login_as
    expect_new_page_load { driver.find_element(:css, '.logout > a').click }
    driver.current_url.should == expected_url
    expected_url
  end

  def go_to_forgot_password
    get "/"
    driver.find_element(:css, '#login_forgot_password').click
  end

  it "should show error message if logging in with wrong credentials" do
    login_as("blah@blah.com", "somepassword", false)
    assert_flash_error_message /Incorrect username/
  end

  it "should show invalid password message if logging in with no password" do
    expected_error = "Invalid password"
    login_as(USERNAME, nil, false)
    should_show_message(expected_error, LOGIN_ERROR_BOX)
  end

  it "should show invalid login message if logging in with no username" do
    expected_error = "Invalid login"
    login_as(nil, VALID_PASSWORD, false)
    should_show_message(expected_error, LOGIN_ERROR_BOX)
  end

  it "should show invalid password message if logging in with no username and password" do
    expected_error = "Invalid login"
    login_as(nil, nil, false)
    should_show_message(expected_error, LOGIN_ERROR_BOX)
  end

  it "should validate logging in with correct credentials" do
    user_with_pseudonym({:active_user => true})
    login_as
    driver.find_element(:css, '.user_name').text.should == USERNAME
  end

  it "should test logging out with the correct page and navigating to a page after being logged out" do
    expected_url = verify_logout
    get "/grades"
    assert_flash_notice_message /You must be logged in to access this page/
    driver.current_url.should == expected_url
  end

  it "should validate i don't know my password functionality" do
    go_to_forgot_password
    driver.find_element(:css, '#pseudonym_session_unique_id_forgot').send_keys(USERNAME)
    submit_form('#forgot_password_form')
    wait_for_ajaximations
    assert_flash_notice_message /Password confirmation sent/
  end

  it "should validate back button works in forgot password page" do
    go_to_forgot_password
    driver.find_element(:css, '.login_link').click
    driver.find_element(:css, '#login_form').should be_displayed
  end
end