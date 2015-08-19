require_relative 'ios_common'

# ======================================================================================================================
# Shared Examples for iCanvas and Speedgrader Mobile Apps
# ======================================================================================================================

shared_context 'icanvas and speedgrader login credentials' do |app_name|
  before(:all) do
    user_with_pseudonym(username: 'teacher1', password: 'teacher')
  end

  context 'displays login view' do
    # using *mobiledev* as school rather than test instance because test instance will not have *.instructure.com*
    let(:school_name){ 'mobiledev' }
    let(:school_url){ school_name + '.instructure.com' }

    before(:each) do
      find_ele_by_attr('UIATextField', 'value', 'Find your school or district').send_keys(school_name)
      visible_buttons = buttons
      visible_buttons.size == 1 ? visible_buttons[0].click : visible_buttons[1].click
    end

    after(:each) do
      find_element(:id, 'Cancel').click if exists{ find_element(:id, 'Cancel') }
    end

    it 'displays correct url for selected school', priority: "1", test_id: pick_test_id_for_app(app_name, 14040, 303727) do
      wait_true(timeout: 10, interval: 0.250){ expect(find_element(:id, school_url)).to be_displayed }
    end

    it 'displays cancel button which returns to landing page', priority: "1", test_id: pick_test_id_for_app(app_name, 251028, 303728) do
      expect(find_element(:id, 'Cancel')).to be_displayed
      find_element(:id, 'Cancel').click
      expect(find_ele_by_attr('UIATextField', 'value', 'Find your school or district')).to be_displayed
    end
  end

  context 'user provides bad credentials' do
    before(:all) do
      enter_school
    end

    # Clear Email field between runs
    after(:each) do
      tag('UIATextField').clear
    end

    # Return to 'Find your school or district'
    after(:all) do
      button_exact('Cancel').click
    end

    it 'fails login with incorrect username', priority: "1", test_id: pick_test_id_for_app(app_name, 14042, 303723) do
      provide_credentials('Chester Copperpot', user_password(@user))
      verify_login_view('Chester Copperpot', 'Incorrect username and/or password')
    end

    it 'fails login when password omitted', priority: "1", test_id: pick_test_id_for_app(app_name, 238142, 303726) do
      provide_credentials('Chester Copperpot', '')
      verify_login_view('Chester Copperpot', 'No password was given')
    end

    it 'fails login with incorrect password', priority: "1", test_id: pick_test_id_for_app(app_name, 14043, 303724) do
      provide_credentials(@user.primary_pseudonym.unique_id, '1234')
      verify_login_view(@user.primary_pseudonym.unique_id, 'Incorrect username and/or password')
    end
  end

  context 'user forgot their password' do
    before(:each) do
      enter_school
    end

    # Return to 'Find your school or district'
    after(:each) do
      button_exact('Cancel').click
    end

    it 'routes to password reset view', priority: "1", test_id: pick_test_id_for_app(app_name, 235575, 303729) do
      text_exact('I don\'t know my password').click

      message = 'Enter your Email and we\'ll send you a link to change your password.'
      email = tag('UIATextField')
      expect(text_exact(message)).to be_displayed
      expect(email).to be_displayed
      expect(email.name).to eq(message)
      expect(email.text).to eq('Email')
      expect(button_exact('Request Password')).to be_displayed
      expect(text_exact('Back to Login')).to be_displayed

      # return to Login view
      text_exact('Back to Login').click
      expect(tag('UIASecureTextField')).to be_displayed
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

    it 'passes login and routes to home page', priority: "1", test_id: pick_test_id_for_app(app_name, 14041, 303730) do
      # App requests access to Canvas account; need to wait for next WebView to load
      wait_true(timeout: 10, interval: 0.250){ text_exact(app_login_message) }
      expect(text_exact(app_access_message)).to be_displayed

      # Verify paragraph text includes username
      links = tags('UIALink')
      expect(text_exact('You are logging into this app as')).to be_displayed
      expect(links[0].name).to eq(@user.primary_pseudonym.unique_id)
      expect(text_exact('.')).to be_displayed
      expect(button_exact('Log In')).to be_displayed
      expect(links[1].name).to eq('Cancel')
      expect(text_exact('Cancel')).to be_displayed
      expect(text_exact('Remember my authorization for this service')).to be_displayed

      # Toggle switch and click
      auth_switch = tag('UIASwitch')
      expect(auth_switch).to be_displayed
      expect(auth_switch.name).to eq('Remember my authorization for this service')
      auth_switch.click
      button_exact('Log In').click

      # User is occasionally polled here
      dismiss_user_polling
      wait_true(timeout: 10, interval: 0.250){ find_element(:id, app_login_success) }
    end
  end
end

# ======================================================================================================================
# Helper Methods
# ======================================================================================================================

def verify_login_view(username, error_message)
  wait_true(timeout: 10, interval: 0.250){ expect(tag('UIATextField').text).to eq(username) }
  expect(tag('UIASecureTextField').text).to eq('Password')
  find_ele_by_attr('UIAStaticText', 'name', error_message)
  expect(button_exact('Log In')).to be_displayed
  expect(text_exact('I don\'t know my password')).to be_displayed
  expect(find_element(:id, 'Cancel')).to be_displayed
end
