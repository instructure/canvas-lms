module FeatureHelpers
  def wait_for(override = nil)
    Timeout.timeout(override || Capybara.default_max_wait_time) { loop until yield }
  end

  def accept_confirm
    wait  = Selenium::WebDriver::Wait.new ignore: Selenium::WebDriver::Error::NoAlertPresentError
    alert = wait.until { page.driver.browser.switch_to.alert }
    alert.accept
  end

  def dismiss_confirm
    wait  = Selenium::WebDriver::Wait.new ignore: Selenium::WebDriver::Error::NoAlertPresentError
    alert = wait.until { page.driver.browser.switch_to.alert }
    alert.dismiss
  end
end
