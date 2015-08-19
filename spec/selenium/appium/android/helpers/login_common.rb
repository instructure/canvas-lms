require_relative 'android_common'

# ======================================================================================================================
# Shared Examples for Candroid and Speedgrader Mobile Apps
# ======================================================================================================================

shared_examples 'login credentials for candroid and speedgrader' do |app_name|
  before(:all) do
    user_with_pseudonym(username: 'teacher1', password: 'teacher')
  end

  after(:all) do
    logout(false)
  end

  context 'user provides bad credentials' do
    before(:each) do
      enter_school
    end

    # TODO: write test cases for bad credentials
  end

  context 'user forgot their password' do
    before(:each) do
      enter_school
    end

    after(:each) do
      back
    end

    it 'routes to password reset view', priority: "1", test_id: pick_test_id_for_app(app_name, 221322, 295519) do
      find_ele_by_attr('tags', 'android.view.View', 'name', /(I don't know my password)/).click

      wait_true(timeout: 10, interval: 0.100){ button_exact('Request Password') }
      expect(find_ele_by_attr('tags', 'android.view.View', 'name', /(change your password)/).name)
        .to eq('Enter your Email and we\'ll send you a link to change your password.')
      expect(first_textfield).to be_displayed # TODO: ask dev team for content descriptor

      back_to_login_view = find_ele_by_attr('tags', 'android.view.View', 'name', /Back to Login/)
      expect(back_to_login_view.name).to eq('Back to Login')
      back_to_login_view.click
    end
  end

  context 'user provides good credentials' do
    before(:each) do
      enter_school
      provide_credentials(@user.primary_pseudonym.unique_id, user_password(@user))
    end

    after(:each) do
      logout(false)
    end

    it 'passes login and routes to home page', priority: "1", test_id: pick_test_id_for_app(app_name, 221323, 295521) do
      wait_true(timeout: 10, interval: 0.250){ find_ele_by_attr('tags', 'android.view.View', 'name', app_login_message) }

      expect(find_ele_by_attr('tags', 'android.view.View', 'name', app_access_message))
        .to be_an_instance_of(Selenium::WebDriver::Element)
      expect(find_ele_by_attr('tags', 'android.view.View', 'name', /(You are logging into this app as)/))
        .to be_an_instance_of(Selenium::WebDriver::Element)
      expect(find_ele_by_attr('tags', 'android.view.View', 'name', /#{(@user.primary_pseudonym.unique_id)}/))
        .to be_an_instance_of(Selenium::WebDriver::Element)

      expect(find_ele_by_attr('tags', 'android.view.View', 'name', /Cancel/).name).to eq('Cancel')
      remember_auth = find_ele_by_attr('tags', 'android.widget.CheckBox', 'name', /Remember my authorization for this service/)
      expect(remember_auth.attribute('checked')).to eq('false')
      remember_auth.click
      expect(remember_auth.attribute('checked')).to eq('true')
      button('Log in').click

      skip_tutorial

      # User avatar displays on Home Page but takes time to load
      wait_true(timeout:10, interval: 0.250){ candroid_app ? find_element(:id, 'userProfilePic') : find_element(:id, 'courseSwitcher') }
    end
  end
end

# ======================================================================================================================
# Helper Methods
# ======================================================================================================================

def provide_credentials(username, password)
  first_textfield.send_keys(username)
  last_textfield.send_keys(password)
  button('Log in').click
end
