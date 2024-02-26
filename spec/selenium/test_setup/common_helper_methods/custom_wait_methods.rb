# frozen_string_literal: true

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
require_relative "state_poller"

module CustomWaitMethods
  # #initialize and #to_s are overwritten to allow message customization
  class SlowCodePerformance < ::Timeout::Error
    def initialize(message) # rubocop:disable Lint/MissingSuper
      @message = message
    end

    def to_s
      @message
    end
  end

  def wait_for_dom_ready
    result = driver.execute_async_script(<<~JS)
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
      }
    JS
    raise "left page before domready" if result != 0
  end

  # If we're looking for the loading image, we can't just do a normal assertion, because the image
  # could end up getting loaded too quickly.
  def wait_for_transient_element(selector)
    puts "wait for transient element #{selector}"
    driver.execute_script(<<~JS)
      window.__WAIT_FOR_LOADING_IMAGE = 0
      window.__WAIT_FOR_LOADING_IMAGE_CALLBACK = null

      var _checkAddedNodes = function(addedNodes) {
        try {
          for(var newNode of addedNodes) {
            if (!([Node.ELEMENT_NODE, Node.DOCUMENT_NODE, Node.DOCUMENT_FRAGMENT_NODE].includes(newNode.nodeType))) continue
            if (newNode.matches('#{selector}') || newNode.querySelector('#{selector}')) {
              window.__WAIT_FOR_LOADING_IMAGE = 1
            }
          }
        } catch (e) {
          console.error('CHECK ADDED NODES FAILED'); console.error(e)
        }
      }

      var _checkRemovedNodes = function(removedNodes) {
        try {
          if(window.__WAIT_FOR_LOADING_IMAGE !== 1) {
            return
          }

          for(var newNode of removedNodes) {
            if (!([Node.ELEMENT_NODE, Node.DOCUMENT_NODE, Node.DOCUMENT_FRAGMENT_NODE].includes(newNode.nodeType))) continue
            if (newNode.matches('#{selector}') || newNode.querySelector('#{selector}')) {
              observer.disconnect()

              window.__WAIT_FOR_LOADING_IMAGE = 2
              window.__WAIT_FOR_LOADING_IMAGE_CALLBACK && window.__WAIT_FOR_LOADING_IMAGE_CALLBACK()
            }
          }
        } catch (e) {
          console.error('CHECK REMOVED NODES FAILED'); console.error(e)
        }
      }

      var callback = function(mutationsList, observer) {
        for(var record of mutationsList) {
          _checkAddedNodes(record.addedNodes)
          _checkRemovedNodes(record.removedNodes)
        }
      }
      var observer = new MutationObserver(callback)
      observer.observe(document.body, { subtree: true, childList: true })
    JS

    yield

    result = driver.execute_async_script(<<~JS)
      var callback = arguments[arguments.length - 1]
      if (window.__WAIT_FOR_LOADING_IMAGE == 2) {
        callback(0)
      }
      window.__WAIT_FOR_LOADING_IMAGE_CALLBACK = function() {
        callback(0)
      }
    JS
    raise "element #{selector} did not appear or was not transient" if result != 0
  end

  # NOTE: for "__CANVAS_IN_FLIGHT_XHR_REQUESTS__" see "ui/boot/index.js"
  AJAX_REQUESTS_SCRIPT = "return window.__CANVAS_IN_FLIGHT_XHR_REQUESTS__"
  def wait_for_ajax_requests(bridge = nil)
    bridge = driver if bridge.nil?

    res = StatePoller.await(0) { bridge.execute_script(AJAX_REQUESTS_SCRIPT) || 0 }
    if res[:got] > 0 && !NoRaiseTimeoutsWhileDebugging.ever_run_a_debugger?
      raise SlowCodePerformance, "AJAX requests not done after #{res[:spent]}s: #{res[:got]}"
    end
  end

  # NOTE: for "$.timers" see https://github.com/jquery/jquery/blob/6c2c7362fb18d3df7c2a7b13715c2763645acfcb/src/effects.js#L638
  ANIMATION_COUNT_SCRIPT = "return (typeof($) !== 'undefined' && $.timers) ? $.timers.length : 0"
  ANIMATION_ELEMENTS_SCRIPT = <<~JS
    return $.timers.map(t => (
     t.elem.tagName + (t.elem.id?'#'+t.elem.id:'') + (t.elem.className?'.'+t.elem.className.replaceAll(' ','.'):'')
    ))
  JS
  def wait_for_animations(bridge = nil)
    bridge = driver if bridge.nil?

    res = StatePoller.await(0) { bridge.execute_script(ANIMATION_COUNT_SCRIPT) || 0 }
    if res[:got] > 0
      pending = (bridge.execute_script(ANIMATION_ELEMENTS_SCRIPT) || []).join("\n")
      raise SlowCodePerformance, "JQuery animations not done after #{res[:spent]}s: #{res[:got]}\n#{pending}"
    end
  end

  def wait_for_ajaximations(bridge = nil)
    wait_for_ajax_requests(bridge)
    wait_for_animations(bridge)
  end

  def wait_for_initializers(bridge = nil)
    bridge = driver if bridge.nil?

    bridge.execute_async_script <<~JS
      var callback = arguments[arguments.length - 1];

      // If canvasReadyState isn't defined, we're likely in an IFrame (such as the RCE)
      if (!window.location.href || !window.canvasReadyState || window.canvasReadyState === 'complete') {
        callback()
      }
      else {
        window.addEventListener('canvasReadyStateChange', function() {
          if (window.canvasReadyState === 'complete') {
            callback()
          }
        })
      }
    JS
  end

  def wait_for_children(selector)
    has_children = false
    while has_children == false
      has_children = element_has_children?(selector)
      wait_for_dom_ready
    end
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

  def pause_ajax(&)
    SeleniumDriverSetup.request_mutex.synchronize(&)
  end

  def keep_trying_until(seconds = SeleniumDriverSetup::SECONDS_UNTIL_GIVING_UP)
    frd_error = Selenium::WebDriver::Error::TimeoutError.new
    wait_for(timeout: seconds, method: :keep_trying_until) do
      yield
    rescue SeleniumExtensions::Error, Selenium::WebDriver::Error::StaleElementReferenceError # don't keep trying, abort ASAP
      raise
    rescue StandardError, RSpec::Expectations::ExpectationNotMetError
      frd_error = $ERROR_INFO
      nil
    end or CallStackUtils.raise(frd_error)
  end

  def keep_trying_for_attempt_times(attempts: 3, sleep_interval: 0.5)
    attempt = 0
    max_attempts = attempts
    begin
      attempt += 1
      yield
    rescue => e
      if attempt < max_attempts
        puts "\t Attempt #{attempt} failed! Retrying..."
        sleep sleep_interval
        retry
      end
      raise Selenium::WebDriver::Error::ElementNotInteractableError, e.message.to_s
    end
  end

  # pass in an Element pointing to the textarea that is tinified.
  def wait_for_tiny(element)
    # TODO: Better to wait for an event from tiny?
    parent = element.find_element(:xpath, "..")
    tiny_frame = nil
    keep_trying_until do
      tiny_frame = disable_implicit_wait { parent.find_element(:css, "iframe") }
    rescue => e
      puts e.inspect
      false
    end
    tiny_frame
  end

  # a slightly modified version of wait_for_tiny
  # that's simpler for the normal case where
  # there's only 1 RCE on  the pge
  def wait_for_rce(element = nil)
    element = f(element) if element.is_a? String
    element ||= f(".rce-wrapper")
    tiny_frame = nil
    keep_trying_until do
      tiny_frame = disable_implicit_wait { element.find_element(:css, "iframe") }
    rescue => e
      puts e.inspect
      false
    end
    tiny_frame
  end

  def disable_implicit_wait(&)
    ::SeleniumExtensions::FinderWaiting.disable(&)
  end

  # little wrapper around Selenium::WebDriver::Wait, notably it:
  # * is less verbose
  # * returns false (rather than raising) if the block never returns true
  # * doesn't rescue :allthethings: like keep_trying_until
  # * prevents nested waiting, cuz that's terrible
  def wait_for(...)
    ::SeleniumExtensions::FinderWaiting.wait_for(...)
  end

  def wait_for_no_such_element(method: nil, timeout: SeleniumExtensions::FinderWaiting.timeout)
    wait_for(method:, timeout:, ignore: []) do
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
