module CustomValidators
  def validate_breadcrumb_link(link_element, breadcrumb_text)
    expect_new_page_load { link_element.click }
    if breadcrumb_text != nil
      breadcrumb = f('#breadcrumbs')
      expect(breadcrumb).to include_text(breadcrumb_text)
    end
    expect(driver.execute_script("return INST.errorCount;")).to eq 0
  end

  def check_domready
    dom_is_ready = driver.execute_script "return window.seleniumDOMIsReady"
    requirejs_resources_loaded = driver.execute_script "return !requirejs.s.contexts._.defQueue.length"
    dom_is_ready and requirejs_resources_loaded
  end

  def check_image(element)
    require 'open-uri'
    expect(element).to be_displayed
    expect(element.tag_name).to eq 'img'
    temp_file = open(element.attribute('src'))
    expect(temp_file.size).to be > 0
  end

  def check_file(element)
    require 'open-uri'
    expect(element).to be_displayed
    expect(element.tag_name).to eq 'a'
    temp_file = open(element.attribute('href'))
    expect(temp_file.size).to be > 0
    temp_file
  end

  def check_element_has_focus(element)
    active_element = driver.execute_script('return document.activeElement')
    expect(active_element).to eq(element)
  end

  def check_element_attrs(element, attrs)
    expect(element).to be_displayed
    attrs.each do |k, v|
      if v.is_a? Regexp
        expect(element.attribute(k)).to match v
      else
        expect(element.attribute(k)).to eq v
      end
    end
  end

  def expect_flash_message(type = :warning, message = nil)
    message = Regexp.new(Regexp.escape(message)) if message.is_a?(String)
    wait_for method: :expect_flash_message, ignore: [Selenium::WebDriver::Error::StaleElementReferenceError] do
      messages = disable_implicit_wait { driver.find_elements :css, "#flash_message_holder .ic-flash-#{type}" }
      text = messages.map(&:text).join('\n')
      message ? !!text.match(message) : messages.present?
    end or raise(RSpec::Expectations::ExpectationNotMetError, "expected flash #{type} message#{message ? " " + message.inspect : ""}, none found", CallStackUtils.useful_backtrace)
  end

  def expect_no_flash_message(type = :warning, message = nil)
    message = Regexp.new(Regexp.escape(message)) if message.is_a?(String)
    wait_for method: :expect_no_flash_message, ignore: [Selenium::WebDriver::Error::StaleElementReferenceError] do
      messages = disable_implicit_wait { driver.find_elements :css, "#flash_message_holder .ic-flash-#{type}" }
      text = messages.map(&:text).join('\n')
      message ? !text.match(message) : messages.empty?
    end or raise(RSpec::Expectations::ExpectationNotMetError, "expected no flash #{type} message#{message ? " " + message.inspect : ""}, one was found", CallStackUtils.useful_backtrace)
  end

  def assert_flash_notice_message(okay_message_regex)
    expect_flash_message :success, okay_message_regex
  end

  def assert_flash_warning_message(warn_message_regex)
    expect_flash_message :warning, warn_message_regex
  end

  def assert_flash_error_message(fail_message_regex)
    expect_flash_message :error, fail_message_regex
  end

  def assert_error_box(selector)
    box = driver.execute_script <<-JS, selector
      var $result = $(arguments[0]).data('associated_error_box');
      return $result ? $result.toArray() : []
    JS
    expect(box.length).to eq 1
    expect(box[0]).to be_displayed
  end

  def expect_new_page_load(accept_alert = false)
    driver.execute_script("window.INST = window.INST || {}; INST.still_on_old_page = true;")
    yield
    wait_for method: :expect_new_page_load do
      begin
        driver.execute_script("return window.INST && INST.still_on_old_page !== true;")
      rescue Selenium::WebDriver::Error::UnhandledAlertError, Selenium::WebDriver::Error::UnknownError
        raise unless accept_alert
        driver.switch_to.alert.accept
      end
    end
    wait_for_dom_ready
    wait_for_ajaximations
  end
end
