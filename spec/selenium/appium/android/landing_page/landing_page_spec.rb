require_relative '../helpers/android_common'
require_relative 'landing_page_common'

describe 'landing page' do
  include_context 'in-process server selenium tests'

  before(:all) do
    RSpec.configure do |c|
      c.fail_fast = true
    end

    create_developer_key
    user_with_pseudonym(username: 'teacher', password: 'teacher')

    # TODO: uncomment this statement when Appium is integrated with Jenkins!
    # appium_init('Android')
  end

  it 'displays a landing page', priority: "1", test_id: 221316 do
    skip('Appium not yet integrated with Jenkins')
    expect(exists{ find_element(:id, 'help_button') }).to be true
    expect(exists{ find_element(:id, 'canvas_logo') }).to be true
    expect(exists{ find_element(:id, 'enterURL') }).to be true
    expect(find_element(:id, 'enterURL').text).to eq('Find your school or district')
  end

  it 'routes to canvas guides', priority: "1", test_id: 221317 do
    skip('Appium not yet integrated with Jenkins')
    find_element(:id, 'help_button').click
    expect(exists{ find_element(:id, 'search_guides') }).to be true
    expect(exists{ find_element(:id, 'report_problem') }).to be true
    find_element(:id, 'search_guides').click
    expect(tags('android.widget.ImageButton')[0].name).to eq('Navigate up')
    expect(exists{ text_exact('Canvas Guides') }).to be true
    tags('android.widget.ImageButton')[0].click
  end

  it 'routes to report a problem', priority: "1", test_id: 221318 do
    skip('Appium not yet integrated with Jenkins')
    find_element(:id, 'help_button').click
    find_element(:id, 'report_problem').click
    begin
      hide_keyboard
    rescue Selenium::WebDriver::Error::UnknownError => ex # soft keyboard not present, cannot hide keyboard
      raise unless ex.message == 'Soft keyboard not present, cannot hide keyboard'
    end

    text_fields_id.each_with_index do |id, index|
      text_field = scroll_to_element(
        scroll_view: tag('android.widget.ScrollView'),
        id: id,
        time: 500,
        direction: 'down',
        attempts: 2
      )
      verify_text_field(text_field, index)
    end

    find_element(:id, 'severitySpinner').click
    severity_levels = ids('text')
    verify_severity_levels(severity_levels)

    severity_levels[4].click
    scroll_to_element(
      scroll_view: tag('android.widget.ScrollView'),
      id: 'severitySpinner',
      time: 500,
      direction: 'down',
      attempts: 2
    )
    expect(find_element(:id, 'text').text).to eq('EXTREME CRITICAL EMERGENCY!!')
    expect(exists{ find_element(:id, 'dialog_custom_cancel') }).to be true
    expect(exists{ find_element(:id, 'dialog_custom_confirm') }).to be true
    expect(find_element(:id, 'dialog_custom_cancel').text).to eq('CANCEL')
    expect(find_element(:id, 'dialog_custom_confirm').text).to eq('SEND')

    find_element(:id, 'dialog_custom_cancel').click

    hide_keyboard unless exists{ find_element(:id, 'help_button') }
    expect(exists{ find_element(:id, 'help_button') }).to be true
    expect(exists{ find_element(:id, 'canvas_logo') }).to be true
    expect(exists{ find_element(:id, 'enterURL') }).to be true
    expect(find_element(:id, 'enterURL').text).to eq('Find your school or district')
  end

  it 'lists possible schools when entering url and routes to school', priority: "1", test_id: 221319 do
    skip('Appium not yet integrated with Jenkins')
    find_element(:id, 'enterURL').send_keys('t')
    expect(exists{ find_element(:id, 'connect') }).to be true
    expect(exists{ find_element(:id, 'canvasNetworkHeader') }).to be true

    # wait for list of schools to populate
    sleep(0.100)
    schools = ids('name')
    expect(schools.size).to be > 4

    school = schools[3]
    school_name = school.text
    school.click

    expect(exists{ tag('android.webkit.WebView') }).to be true
    expect(find_ele_by_attr('tag', 'android.widget.TextView', 'text', /([a-z]+)(.instructure.com)/))
      .to be_an_instance_of(Selenium::WebDriver::Element)
    back

    edit_url_text = find_element(:id,'enterURL')
    expect(edit_url_text.text).to match(/([a-z]+)(.instructure.com)/)
    expect(exists{ text_exact(school_name) })

    edit_url_text.clear
    expect(edit_url_text.text).to eq('Find your school or district')
  end

  it 'routes to school login page when school is typed in', priority: "1", test_id: 221321 do
    skip('Appium not yet integrated with Jenkins')
    find_element(:id, 'enterURL').send_keys(@school)
    find_element(:id, 'connect').click

    # wait for webview to load
    expect(exists{ tag('android.webkit.WebView') }).to be true

    expect(exists(2){ first_textfield }).to be true
    expect(exists(2){ last_textfield }).to be true
    expect(exists(2){ button('Log in') }).to be true

    reset_password = find_ele_by_attr('tags', 'android.view.View', 'name', /I don't know my password/)
    expect(reset_password.name).to eq('I don\'t know my password')
  end

  it 'routes to password reset view', priority: "1", test_id: 221322 do
    skip('Appium not yet integrated with Jenkins')
    reset_password = find_ele_by_attr('tags', 'android.view.View', 'name', /I don't know my password/)
    reset_password.click

    # wait for webview to load
    expect(exists{ tag('android.webkit.WebView') }).to be true

    expect(find_ele_by_attr('tags', 'android.view.View', 'name', /Enter your Email.*/).name)
      .to eq('Enter your Email and we\'ll send you a link to change your password.')

    expect(first_textfield.name).to eq('Email')
    expect(exists{ button('Request Password') }).to be true

    back_to_login_view = find_ele_by_attr('tags', 'android.view.View', 'name', /Back to Login/)
    expect(back_to_login_view.name).to eq('Back to Login')
    back_to_login_view.click
    back
  end

  it 'logs into school', priority: "1", test_id: 221323 do
    skip('Appium not yet integrated with Jenkins')
    find_element(:id, 'enterURL').send_keys(@school)
    find_element(:id, 'connect').click

    email = first_textfield
    password = last_textfield
    login_button = button('Log in')

    email.send_keys(@user.primary_pseudonym.unique_id)
    password.send_keys(@user.primary_pseudonym.unique_id)
    login_button.click

    expect(find_ele_by_attr('tags', 'android.view.View', 'name', /Canvas for Android/))
      .to be_an_instance_of(Selenium::WebDriver::Element)
    expect(find_ele_by_attr('tags', 'android.view.View', 'name', /Canvas for Android is requesting access.*/))
      .to be_an_instance_of(Selenium::WebDriver::Element)
    expect(find_ele_by_attr('tags', 'android.view.View', 'name', /You are logging into this app as/))
      .to be_an_instance_of(Selenium::WebDriver::Element)
    expect(find_ele_by_attr('tags', 'android.view.View', 'name', /#{(@user.primary_pseudonym.unique_id)}/))
      .to be_an_instance_of(Selenium::WebDriver::Element)

    login_button = button('Log in')
    cancel_button = find_ele_by_attr('tags', 'android.view.View', 'name', /Cancel/)
    expect(cancel_button.name).to eq('Cancel')

    remember_auth = find_ele_by_attr('tags', 'android.widget.CheckBox', 'name', /Remember my authorization for this service/)
    expect(remember_auth.attribute('checked')).to eq('false')
    remember_auth.click
    expect(remember_auth.attribute('checked')).to eq('true')
    login_button.click
  end
end