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

module CustomWaitMethods
  def wait_for_dom_ready
    result = driver.execute_async_script(<<-JS)
      var callback = arguments[arguments.length - 1];
      if (document.readyState === "complete") {
        callback(0);
      } else {
        var leftPageBeforeDomReady = callback.bind(null, -1);
        window.addEventListener("beforeunload", leftPageBeforeDomReady);
        document.onreadystatechange = function() {
          if (document.readyState === "complete") {
            window.removeEventListener("beforeunload", leftPageBeforeDomReady);
            callback(0);
          }
        }
      };
    JS
    raise "left page before domready" if result != 0
  end

  def wait_for_ajax_requests
    result = driver.execute_async_script(<<-JS)
      var callback = arguments[arguments.length - 1];
      if (typeof($) == 'undefined') {
        callback(-1);
      } else if ($.active == 0) {
        callback(0);
      } else {
        var fallbackCallback = window.setTimeout(function() {
          callback(-2);
        }, #{SeleniumDriverSetup.timeouts[:script] * 1000 - 500});
        $(document).bind('ajaxStop.canvasTestAjaxWait', function() {
          // while there are no outstanding requests, a new one could be
          // chained immediately afterwards in this thread of execution,
          // e.g. $.get(url).then(() => $.get(otherUrl))
          //
          // so wait a tick just to be sure we're done
          setTimeout(function() {
            if ($.active == 0) {
              $(document).unbind('ajaxStop.canvasTestAjaxWait');
              window.clearTimeout(fallbackCallback);
              callback(0);
            }
          }, 0);
        });
      }
    JS
    result
  end

  def wait_for_animations
    driver.execute_async_script(<<-JS)
      var callback = arguments[arguments.length - 1];
      if (typeof($) == 'undefined') {
        callback(-1);
      } else if ($.timers.length == 0) {
        callback(0);
      } else {
        var _stop = $.fx.stop;
        $.fx.stop = function() {
          $.fx.stop = _stop;
          _stop.apply(this, arguments);
          callback(0);
        }
      }
    JS
  end

  def wait_for_ajaximations
    wait_for_ajax_requests
    wait_for_animations
  end

  def wait_for_stale_element(selector, jquery_selector: false)
    stale_element = true
    while stale_element == true
      begin
        wait_for_dom_ready
        if jquery_selector
          fj(selector)
        else
          f(selector)
        end
      rescue Selenium::WebDriver::Error::NoSuchElementError
        stale_element = false
      end
    end
  end

  def pause_ajax
    SeleniumDriverSetup.request_mutex.synchronize { yield }
  end

  def keep_trying_until(seconds = SeleniumDriverSetup::SECONDS_UNTIL_GIVING_UP)
    frd_error = Selenium::WebDriver::Error::TimeOutError.new
    wait_for(timeout: seconds, method: :keep_trying_until) do
      begin
        yield
      rescue SeleniumExtensions::Error, Selenium::WebDriver::Error::StaleElementReferenceError # don't keep trying, abort ASAP
        raise
      rescue StandardError, RSpec::Expectations::ExpectationNotMetError
        frd_error = $ERROR_INFO
        nil
      end
    end or CallStackUtils.raise(frd_error)
  end

  # pass in an Element pointing to the textarea that is tinified.
  def wait_for_tiny(element)
    # TODO: Better to wait for an event from tiny?
    parent = element.find_element(:xpath, '..')
    tiny_frame = nil
    keep_trying_until {
      begin
        tiny_frame = disable_implicit_wait { parent.find_element(:css, 'iframe') }
      rescue => e
        puts "#{e.inspect}"
        false
      end
    }
    tiny_frame
  end

  def disable_implicit_wait
    ::SeleniumExtensions::FinderWaiting.disable do
      yield
    end
  end

  # little wrapper around Selenium::WebDriver::Wait, notably it:
  # * is less verbose
  # * returns false (rather than raising) if the block never returns true
  # * doesn't rescue :allthethings: like keep_trying_until
  # * prevents nested waiting, cuz that's terrible
  def wait_for(*args, &block)
    ::SeleniumExtensions::FinderWaiting.wait_for(*args, &block)
  end

  def wait_for_no_such_element(method: nil)
    wait_for(method: method, ignore: []) do
      # so find_element calls return ASAP
      disable_implicit_wait do
        yield
        false
      end
    end
  rescue Selenium::WebDriver::Error::NoSuchElementError
    true
  end
end
