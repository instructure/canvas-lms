require_relative 'ios_common'

# ======================================================================================================================
# Shared Examples for iCanvas and Speedgrader Mobile Apps
# ======================================================================================================================

shared_examples 'icanvas and speedgrader landing page' do |app_name|
  before(:all) do
    logout_all_users
  end

  it 'displays a landing page', priority: "1", test_id: pick_test_id_for_app(app_name, 9779, 303715) do
    expect(find_ele_by_attr('UIATextField', 'value', 'Find your school or district')).to be_displayed

    help_button = open_help_menu(app_name)
    verify_help_menu(true)
    close_help_menu(help_button)
    verify_help_menu(false)
  end

  it 'routes to find school domain help page', priority: "1", test_id: pick_test_id_for_app(app_name, 235571, 303716) do
    open_help_menu(app_name)
    verify_help_menu(true)
    button_exact('Find School Domain').click
    verify_help_menu(false)

    expect(find_element(:id, 'Back')).not_to be_displayed
    expect(find_element(:id, 'Help')).to be_displayed
    expect(find_element(:id, 'Done')).to be_displayed

    wait_true(timeout: 10, interval: 0.100){ text_exact('How do I find my institution\'s URL to access Canvas apps on my mobile device?') }

    button_exact('Done').click
  end

  context 'entering school url' do
    let(:school_name){ 'Utah Education Network'}
    let(:school_url){ 'uen.instructure.com'}
    let(:minimum_list_size){ 4 }

    after(:each) do
      find_element(:id, 'Cancel').click
      wait_true(timeout: 10, interval: 0.250){ expect(find_ele_by_attr('UIATextField', 'value', 'Find your school or district')).to be_displayed }
    end

    it 'lists possible schools when entering url and routes to school', priority: "1", test_id: pick_test_id_for_app(app_name, 235572, 303717) do
      find_school_text = find_ele_by_attr('UIATextField', 'value', 'Find your school or district')
      expect(tags('UIATableCell').size).to be 0

      # Sending any key should generate a list of possible school
      find_school_text.send_keys(school_name.split[0])
      school_list = tags('UIATableCell')
      expect(school_list.size).to be > minimum_list_size

      # Click on auto-generated text
      text_exact(school_name).click
      wait_true(timeout: 10, interval: 0.250){ find_element(:id, school_url) }
    end

    it 'routes to school login page when school is typed in', priority: "1", test_id: pick_test_id_for_app(app_name, 235573, 303718) do
      enter_school
      verify_empty_login_view
    end
  end
end

# ======================================================================================================================
# Helper Methods
# ======================================================================================================================

# TODO: fix when SpeedGrader Landing Page is updated
def open_help_menu(app_name)
  if app_name == 'icanvas'
    help_button = find_element(:id, 'Open help menu.')
  else
    help_button = buttons[0]
  end
  help_button.click
  help_button
end

# Help menu closes differently between iPhone and iPad devices
def close_help_menu(help_button)
  if device_is_iphone
    button_exact('Cancel').click
  else
    Appium::TouchAction.new.tap(x: help_button.location.x, y: help_button.location.y).perform
  end
end

def verify_help_menu(displayed)
  expect(exists{ text_exact('Help Menu') }).to be displayed
  expect(exists{ button_exact('Report a Problem') }).to be displayed
  expect(exists{ button_exact('Request a Feature') }).to be displayed
  expect(exists{ button_exact('Find School Domain') }).to be displayed
  expect(exists{ button_exact('Cancel') }).to be displayed if device_is_iphone # not displayed on iPads
end

def verify_empty_login_view
  wait(timeout: 10, interval: 0.250){ tag('UIASecureTextField') }
  expect(tag('UIATextField')).to be_displayed
  expect(tag('UIASecureTextField')).to be_displayed
  expect(button_exact('Log In')).to be_displayed
  expect(text_exact('I don\'t know my password')).to be_displayed
  expect(find_element(:id, 'Cancel')).to be_displayed
end
