require_relative 'android_common'

# ======================================================================================================================
# Shared Examples for Candroid and Speedgrader Mobile Apps
# ======================================================================================================================

shared_examples 'candroid and speedgrader landing page' do |app_name|
  it 'displays a landing page', priority: "1", test_id: pick_test_id_for_app(app_name, 221316, 295284) do
    # TODO: ask dev team to implement this for speedgrader
    expect(find_element(:id, 'help_button')).to be_truthy unless @app_name =~ /(speedgrader)/
    expect(find_element(:id, 'canvas_logo')).to be_truthy
    expect(find_element(:id, 'enterURL')).to be_truthy
    expect(find_element(:id, 'enterURL').text).to eq(default_url)
  end

  # TODO: ask dev team to implement this
  it 'routes to canvas guides', priority: "1", test_id: pick_test_id_for_app(app_name, 221317, 295285) do
    skip('Android SpeedGrader app does not have a Help menu on landing page') if @app_name =~ /(speedgrader)/
    find_element(:id, 'help_button').click
    find_element(:id, 'search_guides').click
    expect(tags('android.widget.ImageButton')[0].name).to eq('Navigate up')
    expect(text_exact('Canvas Guides')).to be_truthy
    tags('android.widget.ImageButton')[0].click
  end

  # TODO: ask dev team to implement this
  it 'routes to report a problem', priority: "1", test_id: pick_test_id_for_app(app_name, 221318, 295286) do
    skip('Android SpeedGrader app does not have a Help menu on landing page') if @app_name =~ /(speedgrader)/
    find_element(:id, 'help_button').click
    find_element(:id, 'report_problem').click
    begin
      hide_keyboard
    rescue Selenium::WebDriver::Error::UnknownError => ex # soft keyboard not present, cannot hide keyboard
      raise unless ex.message == 'Soft keyboard not present, cannot hide keyboard'
    end

    text_fields_id.each_with_index do |id, index|
      verify_text_field(scroll_to_text_field(id), index)
    end

    find_element(:id, 'severitySpinner').click
    severity_levels = ids('text')
    verify_severity_levels(severity_levels)
    severity_levels[4].click
    scroll_to_severity_spinner
    expect(find_element(:id, 'text').text).to eq('EXTREME CRITICAL EMERGENCY!!')
    expect(find_element(:id, 'dialog_custom_cancel').text).to eq('CANCEL')
    expect(find_element(:id, 'dialog_custom_confirm').text).to eq('SEND')

    find_element(:id, 'dialog_custom_cancel').click

    hide_keyboard unless exists{ find_element(:id, 'help_button') }
    expect(find_element(:id, 'help_button')).to be_truthy
    expect(find_element(:id, 'canvas_logo')).to be_truthy
    expect(find_element(:id, 'enterURL')).to be_truthy
    expect(find_element(:id, 'enterURL').text).to eq(default_url)
  end

  it 'lists possible schools when entering url and routes to school', priority: "1", test_id: pick_test_id_for_app(app_name, 221319, 295287) do
    find_element(:id, 'enterURL').send_keys('t')
    expect(find_element(:id, 'connect')).to be_truthy
    expect(find_element(:id, 'canvasNetworkHeader')).to be_truthy

    # wait for list of schools to populate
    sleep(0.100)
    schools = ids('name')
    expect(schools.size).to be >= 4
    school = schools[3]
    school_name = school.text
    school.click

    expect(tag('android.webkit.WebView')).to be_truthy
    expect(find_ele_by_attr('tag', 'android.widget.TextView', 'text', /([a-z]+)(.instructure.com)/))
      .to be_an_instance_of(Selenium::WebDriver::Element)
    back

    edit_url_text = find_element(:id,'enterURL')
    expect(edit_url_text.text).to match(/([a-z]+)(.instructure.com)/)
    expect(text_exact(school_name)).to be_truthy
    edit_url_text.clear
    expect(edit_url_text.text).to eq(default_url)
  end

  it 'routes to school login page when school is typed in', priority: "1", test_id: pick_test_id_for_app(app_name, 221321, 295289) do
    find_element(:id, 'enterURL').send_keys(@school)
    find_element(:id, 'connect').click

    # wait for webview to load
    wait_true(timeout: 10, interval: 0.100){ tag('android.webkit.WebView') }

    wait_true(timeout: 10, interval: 0.100){ first_textfield }
    wait_true(timeout: 10, interval: 0.100){ last_textfield }
    wait_true(timeout: 10, interval: 0.100){ button('Log in') }

    reset_password = find_ele_by_attr('tags', 'android.view.View', 'name', /I don't know my password/)
    expect(reset_password.name).to eq('I don\'t know my password')
    back
  end
end

# ======================================================================================================================
# Helper Methods
# ======================================================================================================================

def scroll_to_severity_spinner
  scroll_to_element(scroll_view: tag('android.widget.ScrollView'),
                    strategy: 'id',
                    id: 'severitySpinner',
                    time: 500,
                    direction: 'down',
                    attempts: 2)
end

def scroll_to_text_field(id)
  scroll_to_element(scroll_view: tag('android.widget.ScrollView'),
                    strategy: 'id',
                    id: id,
                    time: 500,
                    direction: 'down',
                    attempts: 2)
end

def text_fields_id
  %w(
    dialog_custom_title
    subject
    subjectEditText
    emailAddress
    emailAddressEditText
    description
    descriptionEditText
    severityPrompt
    severitySpinner
  )
end

def verify_text_field(text_field, index)
  expect(text_field).to be_an_instance_of(Selenium::WebDriver::Element)
  case index
  when 0
    expect(text_field.text).to eq('Report A Problem')
  when 1
    expect(text_field.text).to eq('Subject')
  when 3
    expect(text_field.text).to eq('Email Address')
  when 4
    expect(text_field.text).to match(/(Enter your email address)/) # '...' has issues with ==
  when 5
    expect(text_field.text).to eq('Description')
  when 6
    expect(text_field.text).to match(/(Write Something)/)          # '...' has issues with ==
  when 7
    expect(text_field.text).to eq('How is this affecting you?')
  end
end

def verify_severity_levels(severity_levels)
  expect(severity_levels.size).to be(5)
  severity_levels.each_index do |index|
    case index
    when 0
      # '...' has issues with ==
      expect(severity_levels[index].text).to match(/(Just a casual question, comment, idea, suggestion…)/)
    when 1
      expect(severity_levels[index].text).to eq('I need some help but it\'s not urgent.')
    when 2
      expect(severity_levels[index].text).to eq('Something\'s broken but I can work around it to get what I need done.')
    when 3
      expect(severity_levels[index].text).to eq('I can\'t get things done until I hear back from you.')
    when 4
      expect(severity_levels[index].text).to eq('EXTREME CRITICAL EMERGENCY!!')
    end
  end
end
