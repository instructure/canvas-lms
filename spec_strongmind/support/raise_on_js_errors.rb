JavaScriptError = Class.new(StandardError)

# Raise on JS errors (i.e., things logged to the Chrome console as errors).
# Disregard HTTP 4xx errors because, while Chrome does log them as errors,
# back-end servers often use them to indicate statuses such as form validation
# errors, which may well be the intended effect of a test.
RSpec.configure do |config|
  config.after(type: :feature, js: true) do |example|
    # unless self.class.metadata[:js_errors] == false
    #   js_console_output       = page.driver.browser.manage.logs.get(:browser)
    #   http_4xx_error_detector = /the server responded with a status of 4/

    #   js_errors               = js_console_output.select do |log_item|
    #     log_item.level == 'SEVERE' && log_item.message !~ http_4xx_error_detector
    #   end

    #   if js_errors.present?
    #     exception_headline = 'This test caused JS errors.'
    #     exception_details = js_errors.map(&:message).map { |line| line.indent(2, ' ') }.join("\n")

    #     raise JavaScriptError, exception_headline + "\n" + exception_details
    #   end
    # end
  end
end
