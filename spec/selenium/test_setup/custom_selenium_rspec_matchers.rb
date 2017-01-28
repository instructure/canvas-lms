# assert the presence (or absence) of a css class on an element.
# will return as soon as the expectation is met, e.g.
#
#   headers = ff(".enhanceable_content.accordion .ui-accordion-header")
#   expect(headers[0]).to have_class('ui-state-active')
#   headers[1].click
#   expect(headers[0]).to have_class('ui-state-default')
RSpec::Matchers.define :have_class do |class_name|
  match do |element|
    wait_for(method: :have_class) do
      element.attribute('class').match(class_name)
    end
  end

  match_when_negated do |element|
    wait_for(method: :have_class) do
      !element.attribute('class').match(class_name)
    end
  end

  failure_message do |element|
    "expected #{element.inspect} to have class #{class_name}, actual class names: #{element.attribute('class')}"
  end

  failure_message_when_negated do |element|
    "expected #{element.inspect} to NOT have class #{class_name}, actual class names: #{element.attribute('class')}"
  end
end

RSpec::Matchers.define :include_text do |text|
  match do |element|
    wait_for(method: :include_text) do
      (@element_text = element.text).include?(text)
    end
  end

  match_when_negated do |element|
    wait_for(method: :include_text) do
      !(@element_text = element.text).include?(text)
    end
  end

  failure_message do |element|
    "expected #{element.inspect} text to include #{text}, actual text was: #{@element_text}"
  end

  failure_message_when_negated do |element|
    "expected #{element.inspect} text to NOT include #{text}, actual text was: #{@element_text}"
  end
end

# assert the presence (or absence) of certain text within the
# element's value attribute. will return as soon as the
# expectation is met, e.g.
#
#   expect(f('#name_input')).to have_value('Bob')
#
RSpec::Matchers.define :have_value do |value_attribute|
  match do |element|
    wait_for(method: :have_value) do
      element.attribute('value').match(value_attribute)
    end
  end

  match_when_negated do |element|
    wait_for(method: :have_value) do
      !element.attribute('value').match(value_attribute)
    end
  end

  failure_message do |element|
    "expected #{element.inspect} to have value #{value_attribute}, actual value: #{element.attribute('value')}"
  end

  failure_message_when_negated do |element|
    "expected #{element.inspect} to NOT have value #{value_attribute}, actual value: #{element.attribute('value')}"
  end
end

# assert the presence (or absence) of a value within an element's
# attribute. will return as soon as the expectation is met, e.g.
#
#   expect(f('.fc-event .fc-time')).to have_attribute('data-start', '11:45')
#
RSpec::Matchers.define :have_attribute do |attribute, attribute_value|
  match do |element|
    wait_for(method: :have_attribute) do
      element.attribute(attribute).match(attribute_value)
    end
  end

  match_when_negated do |element|
    wait_for(method: :have_attribute) do
      !element.attribute(attribute).match(attribute_value)
    end
  end

  failure_message do |element|
    "expected #{element.inspect}'s #{attribute} attribute to have value of #{attribute_value}, actual #{attribute} attribute value: #{element.attribute("#{attribute.to_s}")}"
  end

  failure_message_when_negated do |element|
    "expected #{element.inspect}'s #{attribute} attribute to NOT have value of #{attribute_value}, actual #{attribute} attribute type: #{element.attribute("#{attribute.to_s}")}"
  end
end

# assert whether or not an element is disabled.
# will return as soon as the expectation is met, e.g.
#
#   expect(f("#assignment_group_category_id")).to be_disabled
#
RSpec::Matchers.define :be_disabled do
  match do |element|
    wait_for(method: :be_disabled) do
      element.attribute(:disabled) == "true"
    end
  end

  match_when_negated do |element|
    wait_for(method: :be_disabled) do
      element.attribute(:disabled) != "true"
    end
  end

  failure_message do |element|
    "expected #{element.inspect}'s disabled attribute to be true, actual disabled attribute value: #{element.attribute(:disabled)}"
  end

  failure_message_when_negated do |element|
    "expected #{element.inspect}'s disabled attribute to NOT be true, actual disabled attribute type: #{element.attribute(:disabled)}"
  end
end

# assert the presence (or absence) of something inside the element via css
# selector. will return as soon as the expectation is met, e.g.
#
#   expect(f('#courses')).to contain_css("#course_123")
#   f('#delete_course').click
#   expect(f('#courses')).not_to contain_css("#course_123")
#
RSpec::Matchers.define :contain_css do |selector|
  match do |element|
    begin
      # rely on implicit_wait
      f(selector, element)
      true
    rescue Selenium::WebDriver::Error::NoSuchElementError
      false
    end
  end

  match_when_negated do |element|
    wait_for_no_such_element(method: :contain_css) { f(selector, element) }
  end
end

# assert the presence (or absence) of something inside the element via
# fake-jquery-css selector. will return as soon as the expectation is met,
# e.g.
#
#   expect(f('#weird-ui')).to contain_css(".something:visible")
#   f('#hide-things').click
#   expect(f('#weird-ui')).not_to contain_css(".something:visible")
#
RSpec::Matchers.define :contain_jqcss do |selector|
  match do |element|
    wait_for(method: :contain_jqcss) { find_with_jquery(selector, element) }
  end

  match_when_negated do |element|
    wait_for(method: :contain_jqcss) { !find_with_jquery(selector, element) }
  end
end

# assert the presence (or absence) of a link with certain text inside the
# element. will return as soon as the expectation is met, e.g.
#
#   expect(f('#weird-ui')).to contain_link("Click Here")
#   f('#hide-things').click
#   expect(f('#weird-ui')).not_to contain_link("Click Here")
#
RSpec::Matchers.define :contain_link do |text|
  match do |element|
    begin
      # rely on implicit_wait
      fln(text, element)
      true
    rescue Selenium::WebDriver::Error::NoSuchElementError
      false
    end
  end

  match_when_negated do |element|
    wait_for_no_such_element(method: :contain_link) { fln(text, element) }
  end
end

# assert whether or not an element is displayed. will wait up to
# IMPLICIT_WAIT_TIMEOUT seconds
RSpec::Matchers.define :be_displayed do
  match do |element|
    wait_for(method: :be_displayed) { element.displayed? }
  end

  match_when_negated do |element|
    wait_for(method: :be_displayed) { !element.displayed? }
  end
end

# assert the size of the collection. will wait up to IMPLICIT_WAIT_TIMEOUT
# seconds, and will reload the collection if it can (i.e. if it's the
# result of a ff/ffj call)
RSpec::Matchers.define :have_size do |size|
  match do |collection|
    wait_for(method: :have_size) do
      collection.reload! if collection.size != size && collection.respond_to?(:reload!)
      collection.size == size
    end
  end

  match_when_negated do |collection|
    wait_for(method: :have_size) do
      collection.reload! if collection.size == size && collection.respond_to?(:reload!)
      collection.size != size
    end
  end
end

# wait for something to become a new value. useful for those times when
# other implicit waits cannot be used, e.g.
#
# # trigger some ajax
# expect { User.count }.to become(1)
RSpec::Matchers.define :become do |size|
  def supports_block_expectations?
    true
  end

  match do |actual|
    raise "The `become` matcher expects a block, e.g. `expect { actual }.to become(value)`, NOT `expect(actual).to become(value)`" unless actual.is_a? Proc
    wait_for(method: :become) do
      disable_implicit_wait { actual.call == expected }
    end
  end
end
