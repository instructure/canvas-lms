require File.expand_path(File.dirname(__FILE__) + '/common')

describe "user selenium tests" do
  it_should_behave_like "in-process server selenium tests"

  context "logins" do
    it "should allow setting passwords for new pseudonyms" do
      admin = User.create!
      Account.site_admin.add_user(admin)
      user_session(admin)

      @user = User.create!
      course.enroll_student(@user)

      get "/users/#{@user.id}"

      driver.find_element(:css, ".add_pseudonym_link").click
      driver.find_element(:css, "#edit_pseudonym_form #pseudonym_unique_id").send_keys('new_user')
      driver.find_element(:css, "#edit_pseudonym_form #pseudonym_password").send_keys('qwerty1')
      driver.find_element(:css, "#edit_pseudonym_form #pseudonym_password_confirmation").send_keys('qwerty1')
      driver.find_element(:css, '#edit_pseudonym_form button[type="submit"]').click
      wait_for_ajaximations

      new_login = driver.find_elements(:css, '.login').select { |e| e.attribute(:class) !~ /blank/ }.first
      new_login.should_not be_nil
      new_login.find_element(:css, '.account_name').text().should_not be_blank
      pseudonym = Pseudonym.by_unique_id('new_user').first
      pseudonym.valid_password?('qwerty1').should be_true
    end
  end
end
