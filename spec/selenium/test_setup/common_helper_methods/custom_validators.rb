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

module CustomValidators
  def validate_breadcrumb_link(link_element, breadcrumb_text)
    expect_new_page_load { link_element.click }
    unless breadcrumb_text.nil?
      breadcrumb = f("#breadcrumbs")
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
    require "open-uri"
    expect(element).to be_displayed
    expect(element.tag_name).to eq "img"
    temp_file = URI.parse(element.attribute("src")).open
    expect(temp_file.size).to be > 0
  end

  def check_file(element)
    require "open-uri"
    expect(element).to be_displayed
    expect(element.tag_name).to eq "a"
    temp_file = URI.parse(element.attribute("href")).open
    expect(temp_file.size).to be > 0
    temp_file
  end

  def check_element_has_focus(element)
    active_element = driver.execute_script("return document.activeElement")
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
    if message
      keep_trying_until(5) do
        disable_implicit_wait do
          expect(ff("#flash_message_holder .ic-flash-#{type}").any? { |el| el.text.include?(message.to_s) }).to be true
        end
      end
    else
      expect(f("#flash_message_holder .ic-flash-#{type}")).to be_displayed
    end
  end

  def expect_instui_flash_message(message = nil)
    text = ":contains(#{message.inspect})" if message
    expect(f("#flashalert_message_holder")).to contain_jqcss(text)
  end

  def expect_no_flash_message(type = :warning, message = nil)
    selector = ".ic-flash-#{type}"
    selector << ":contains(#{message.inspect})" if message
    expect(f("#flash_message_holder")).not_to contain_jqcss(selector)
  end

  def expect_no_instui_flash_message
    expect(f("body")).not_to contain_css("#flashalert_message_holder")
  end

  def assert_flash_notice_message(okay_message)
    expect_flash_message :success, okay_message
  end

  def assert_flash_warning_message(warn_message)
    expect_flash_message :warning, warn_message
  end

  def assert_flash_error_message(fail_message)
    expect_flash_message :error, fail_message
  end

  def assert_error_box(selector)
    box = driver.execute_script <<~JS, selector
      var $result = $(arguments[0]).data('associated_error_box');
      return $result ? $result.toArray() : []
    JS
    expect(box.length).to eq 1
    expect(box[0]).to be_displayed
  end

  def wait_for_new_page_load(accept_alert = false)
    driver.execute_script("window.INST = window.INST || {}; INST.still_on_old_page = true;")
    yield if block_given?
    wait_for(method: :wait_for_new_page_load) do
      raise if !accept_alert && alert_present?

      driver.switch_to.alert.accept rescue Selenium::WebDriver::Error::NoSuchAlertError
      driver.execute_script("return window.INST && INST.still_on_old_page !== true;")
    end or return false
    wait_for_initializers
    wait_for_dom_ready
    wait_for_ajaximations
    true
  end

  def expect_new_page_load(accept_alert = false, &)
    success = wait_for_new_page_load(accept_alert, &)
    expect(success).to be, "expected new page load, none happened"
  end
end
