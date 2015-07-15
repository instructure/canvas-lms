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
      expect(severity_levels[index].text)
        .to match(/(Just a casual question, comment, idea, suggestion…)/)
    when 1
      expect(severity_levels[index].text)
        .to eq('I need some help but it\'s not urgent.')
    when 2
      expect(severity_levels[index].text)
        .to eq('Something\'s broken but I can work around it to get what I need done.')
    when 3
      expect(severity_levels[index].text)
        .to eq('I can\'t get things done until I hear back from you.')
    when 4
      expect(severity_levels[index].text)
        .to eq('EXTREME CRITICAL EMERGENCY!!')
    end
  end
end