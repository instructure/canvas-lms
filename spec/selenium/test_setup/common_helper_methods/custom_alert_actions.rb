module CustomAlertActions
  def alert_present?
    is_present = true
    begin
      driver.switch_to.alert
    rescue Selenium::WebDriver::Error::NoAlertPresentError
      is_present = false
    end
    is_present
  end

  def dismiss_alert
    keep_trying_until do
      alert = driver.switch_to.alert
      alert.dismiss
      true
    end
  end

  def accept_alert
    keep_trying_until do
      alert = driver.switch_to.alert
      alert.accept
      true
    end
  end

  def expect_fired_alert
    driver.execute_script(<<-JS)
      window.canvasTestSavedAlert = window.alert;
      window.canvasTestAlertFired = false;
      window.alert = function() {
        window.canvasTestAlertFired = true;
        return true;
      }
    JS

    yield

    keep_trying_until {
      driver.execute_script(<<-JS)
        var value = window.canvasTestAlertFired;
        window.canvasTestAlertFired = false;
        return value;
      JS
    }

    driver.execute_script(<<-JS)
      window.alert = window.canvasTestSavedAlert;
    JS
  end

  def close_modal_if_present
    # if an alert is present, this will trigger the error below
    block_given? ? yield : driver.title
  rescue Selenium::WebDriver::Error::UnhandledAlertError, Selenium::WebDriver::Error::UnknownError
    driver.switch_to.alert.accept
    # try again
    yield if block_given?
  end
end
