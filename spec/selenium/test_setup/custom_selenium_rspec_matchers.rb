RSpec::Matchers.define :have_class do |class_name|
  match do |element|
    !!element.attribute('class').match(class_name)
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

RSpec::Matchers.define :have_value do |value_attribute|
  match do |element|
    !!element.attribute('value').match(value_attribute)
  end

  failure_message do |element|
    "expected #{element.inspect} to have value #{value_attribute}, actual class names: #{element.attribute('value')}"
  end

  failure_message_when_negated do |element|
    "expected #{element.inspect} to NOT have value #{value_attribute}, actual value names: #{element.attribute('value')}"
  end
end

RSpec::Matchers.define :have_attribute do |attribute, attribute_value|
  match do |element|
    !!element.attribute(attribute).match(attribute_value)
  end

  failure_message do |element|
    "expected #{element.inspect} to have attribute #{attribute_value}, actual attribute type: #{element.attribute('#{attribute.to_s}')}"
  end

  failure_message_when_negated do |element|
    "expected #{element.inspect} to NOT have attribute #{attribute_value}, actual attribute type: #{element.attribute('#{attribute.to_s}')}"
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
    disable_implicit_wait do # so find_element calls return ASAP
      wait_for_no_such_element(method: :contain_css) { f(selector, element) }
    end
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
    disable_implicit_wait do # so find_element calls return ASAP
      wait_for_no_such_element(method: :contain_link) { fln(text, element) }
    end
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
