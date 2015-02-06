require File.expand_path(File.dirname(__FILE__) + '/common')

describe "login logout test", :priority => "2" do
  include_examples "in-process server selenium tests"

  def should_show_message(message_text, selector)
    expect(fj(selector)).to include_text(message_text)
    # the text isn't visible on the page so the webdriver .text method doesn't return it
    expect(driver.execute_script("return $('#flash_screenreader_holder').text()")).to eq message_text
  end

  def verify_logout
    expected_url = app_host + "/login"
    user_with_pseudonym({:active_user => true})
    login_as
    expect_new_page_load { f('.logout a').click }
    expect(driver.current_url).to eq expected_url
    expected_url
  end

  def go_to_forgot_password
    get "/"
    f('#login_forgot_password').click
  end

  before do
    @login_error_box_css = ".error_text:last"
  end

  it "should login successfully with correct username and password" do
    user_with_pseudonym({:active_user => true})
    login_as
    expect(f('.user_name').text).to eq @user.primary_pseudonym.unique_id
  end

  it "should show error message if wrong credentials are used" do
    login_as("fake@user.com", "fakepass", false)
    assert_flash_error_message /Incorrect username/
  end

  it "should show invalid password message if password is nil" do
    expected_error = "Invalid password"
    login_as("fake@user.com", nil, false)
    should_show_message(expected_error, @login_error_box_css)
  end

  it "should show invalid login message if username is nil" do
    expected_error = "Invalid login"
    login_as(nil, "123", false)
    should_show_message(expected_error, @login_error_box_css)
  end

  it "should should invalid login message if both username and password are nil" do
    expected_error = "Invalid login"
    login_as(nil, nil, false)
    should_show_message(expected_error, @login_error_box_css)
  end

  it "should prompt must be logged in message when accessing permission based pages while not logged in" do
    expected_url = verify_logout
    get "/grades"
    assert_flash_warning_message /You must be logged in to access this page/
    expect(driver.current_url).to eq expected_url
  end

  it "should validate i dont know my password functionality for email account" do
    user_with_pseudonym({:active_user => true})
    go_to_forgot_password
    f('#pseudonym_session_unique_id_forgot').send_keys(@user.primary_pseudonym.unique_id)
    submit_form('#forgot_password_form')
    wait_for_ajaximations
    assert_flash_notice_message /Password confirmation sent/
  end

  it "should validate back button works in forgot password page" do
    go_to_forgot_password
    f('.login_link').click
    expect(f('#login_form')).to be_displayed
  end

  it "should fail on an invalid authenticity token" do
    user_with_pseudonym({:active_user => true})
    destroy_session(true)
    driver.navigate.to(app_host + '/login')
    driver.execute_script "$.cookie('_csrf_token', '42')"
    fill_in_login_form("nobody@example.com", 'asdfasdf')
    assert_flash_error_message /Invalid Authenticity Token/
  end

  it "should login when a trusted referer exists" do
    Account.any_instance.stubs(:trusted_referer?).returns(true)
    user_with_pseudonym(active_user: true)
    destroy_session(true)
    driver.navigate.to(app_host + '/login')
    driver.execute_script "$.cookie('_csrf_token', '', { expires: -1 })"
    driver.execute_script "$('[name=authenticity_token]').remove()"
    fill_in_login_form("nobody@example.com", 'asdfasdf')
    expect(f('.user_name').text).to eq @user.primary_pseudonym.unique_id
  end
end
