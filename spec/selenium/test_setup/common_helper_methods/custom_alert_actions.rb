#
# Copyright (C) 2015 - present Instructure, Inc.
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
    return if driver.browser == :safari
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
