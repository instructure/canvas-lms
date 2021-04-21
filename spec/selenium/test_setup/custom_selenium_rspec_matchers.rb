# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

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

RSpec::Matchers.define :have_text_absent do
  match do |element|
    wait_for(method: :have_text_absent) do
      element.text.blank?
    end
  end

  failure_message do |element|
    <<~FAILURE_MESSAGE
      Expected #{element.inspect} text to be absent but was instead present.

      Actual text was: "#{element.text}".
    FAILURE_MESSAGE
  end
end

RSpec::Matchers.define :have_text_present do
  match do |element|
    wait_for(method: :have_text_present) do
      element.text.present?
    end
  end

  failure_message do |element|
    <<~FAILURE_MESSAGE
      Expected #{element.inspect} text to be present but was instead blank.

      Actual text was: "#{element.text}".
    FAILURE_MESSAGE
  end
end

RSpec::Matchers.define :include_text do |text|
  match do |element|
    wait_for(method: :include_text) do
      element.text.include?(text)
    end
  end

  match_when_negated do |element|
    wait_for(method: :include_text) do
      element.text.exclude?(text)
    end
  end

  failure_message do |element|
    <<~FAILURE_MESSAGE
      Expected #{element.inspect} text to include "#{text}".

      Actual text was: "#{element.text}".
    FAILURE_MESSAGE
  end

  failure_message_when_negated do |element|
    <<~FAILURE_MESSAGE
      Expected #{element.inspect} text not to include "#{text}".

      Actual text was: "#{element.text}".
    FAILURE_MESSAGE
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
    <<~FAILURE_MESSAGE
      Expected #{element.inspect} to have value "#{value_attribute}".

      Actual value was: "#{element.attribute('value')}".
    FAILURE_MESSAGE
  end

  failure_message_when_negated do |element|
    <<~FAILURE_MESSAGE
      Expected #{element.inspect} not to have value "#{value_attribute}".

      Actual value was: "#{element.attribute('value')}".
    FAILURE_MESSAGE
  end
end

# assert the presence (or absence) of an attribute, optionally asserting
# its exact value or against a regex. will return as soon as the
# expectation is met, e.g.
#
#   # must have something set
#   expect(f('.fc-event .fc-time')).to have_attribute('data-start')
#
#   # must have a particular value set
#   expect(f('.fc-event .fc-time')).to have_attribute('data-start', '11:45')
#
#   # must match a regex
#   expect(f('.fc-event .fc-time')).to have_attribute('data-start', /\A\d\d?:\d\d\z/)
#
#   # must not have anything set
#   expect(f('.fc-event .fc-time')).not_to have_attribute('data-start')
#
#   # must not have this particular value set (can be a different value, or no value)
#   expect(f('.fc-event .fc-time')).not_to have_attribute('data-start', '11:45')
#
#   # must not match a regex
#   expect(f('.fc-event .fc-time')).not_to have_attribute('data-start', /\A\d\d?:\d\d\z/)
#
RSpec::Matchers.define :have_attribute do |*args|
  attribute = args.first
  expected_specified = args.size > 1
  expected = args[1]

  attribute_matcher = -> (actual) do
    if expected_specified
      actual.respond_to?(:match) ? actual.match(expected) : actual == expected
    else
      !actual.nil?
    end
  end

  match do |element|
    wait_for(method: :have_attribute) do
      attribute_matcher.call(element.attribute(attribute))
    end
  end

  match_when_negated do |element|
    wait_for(method: :have_attribute) do
      !attribute_matcher.call(element.attribute(attribute))
    end
  end

  failure_message do |element|
    "expected #{element.inspect}'s #{attribute} attribute to have value of #{expected || 'not nil'}, "\
      "actual #{attribute} attribute value: #{element.attribute(attribute.to_s)}"
  end

  failure_message_when_negated do |element|
    "expected #{element.inspect}'s #{attribute} attribute to NOT have value of #{expected || 'not nil'}, "\
      "actual #{attribute} attribute type: #{element.attribute(attribute.to_s)}"
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
      element.attribute(:disabled) == "true" || element.attribute("aria-disabled") == "true"
    end
  end

  match_when_negated do |element|
    wait_for(method: :be_disabled) do
      element.attribute(:disabled) != "true" && element.attribute("aria-disabled") != "true"
    end
  end

  failure_message do |element|
    "expected #{element.inspect}'s disabled attribute to be true, actual disabled attribute value: #{element.attribute(:disabled)}"
  end

  failure_message_when_negated do |element|
    "expected #{element.inspect}'s disabled attribute to NOT be true, actual disabled attribute type: #{element.attribute(:disabled)}"
  end
end

# assert whether or not an element has an aria-diabled value of "true".
# will return as soon as the expectation is met, e.g.
#
#   expect(element).to be_aria_disabled
#
RSpec::Matchers.define :be_aria_disabled do
  match do |element|
    wait_for(method: :be_aria_disabled) do
      element.attribute('aria-disabled') == 'true'
    end
  end

  match_when_negated do |element|
    wait_for(method: :be_aria_disabled) do
      element.attribute('aria-disabled') != 'true'
    end
  end

  failure_message do |element|
    <<~FAILURE_MESSAGE
      Expected #{element.inspect}'s aria-disabled attribute to be true.

      Actual aria-disabled attribute value: "#{element.attribute('aria-disabled')}".
    FAILURE_MESSAGE
  end

  failure_message_when_negated do |element|
    <<~FAILURE_MESSAGE
      Expected #{element.inspect}'s aria-disabled attribute to be false.

      Actual aria-disabled attribute value: "#{element.attribute('aria-disabled')}"
    FAILURE_MESSAGE
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

# assert the presence (or absence) of a link with certain partial text inside the
# element. will return as soon as the expectation is met, e.g.
#
# given <a href="...">Click Here/a>
#   expect(f('#weird-ui')).to contain_link_partial_text("Here")
#   f('#hide-things').click
#   expect(f('#weird-ui')).not_to contain_link_partial_text("Here")
#
RSpec::Matchers.define :contain_link_partial_text do |text|
  match do |element|
    begin
      # rely on implicit_wait
      flnpt(text, element)
      true
    rescue Selenium::WebDriver::Error::NoSuchElementError
      false
    end
  end

  match_when_negated do |element|
    wait_for_no_such_element(method: :contain_link) { flnpt(text, element) }
  end
end

# assert whether or not an element meets the desired contrast ratio.
# will wait up to TIMEOUTS[:finder] seconds
require_relative '../helpers/color_common'
RSpec::Matchers.define :meet_contrast_ratio do |ratio = 3.5|
  match do |element|
    wait_for(method: :be_displayed) do
      LuminosityContrast.ratio(
        ColorCommon.rgba_to_hex(element.style('background-color')),
        ColorCommon.rgba_to_hex(element.style('color'))
      ) >= ratio
    end
  end

  match_when_negated do |element|
    wait_for(method: :be_displayed) do
      LuminosityContrast.ratio(
        ColorCommon.rgba_to_hex(element.style('background-color')),
        ColorCommon.rgba_to_hex(element.style('color'))
      ) < ratio
    end
  end
end


# assert whether or not an element is displayed. will wait up to
# TIMEOUTS[:finder] seconds
RSpec::Matchers.define :be_displayed do
  match do |element|
    wait_for(method: :be_displayed) { element.displayed? }
  end

  match_when_negated do |element|
    wait_for(method: :be_displayed) { !element.displayed? }
  end
end

# assert the size of the collection. will wait up to TIMEOUTS[:finder]
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

RSpec::Matchers.define :become_between do |min, max|
  def supports_block_expectations?
    true
  end

  match do |actual|
    raise "The `become` matcher expects a block, e.g. `expect { actual }.to become(value)`, NOT `expect(actual).to become(value)`" unless actual.is_a? Proc
    wait_for(method: :become) do
      disable_implicit_wait { a = actual.call; min < a && a < max }
    end
  end
end
