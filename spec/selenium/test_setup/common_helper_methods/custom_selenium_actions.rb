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
# with this program. If not, see <http://www.gnu.org/licenses/>

module CustomSeleniumActions

  def skip_if_ie(additional_error_text)
    skip("skipping test, fails in IE : #{additional_error_text}") if driver.browser == :internet_explorer
  end

  def skip_if_firefox(additional_error_text)
    skip("skipping test, fails in Firefox: #{additional_error_text}") if driver.browser == :firefox
  end

  def skip_if_chrome(additional_error_text)
    skip("skipping test, fails in Chrome: #{additional_error_text}") if driver.browser == :chrome
  end

  def skip_if_safari(additional_error_text)
    return unless driver.browser == :safari
    case additional_error_text
    when :alert
      additional_error_text = "SafariDriver doesn't support alerts"
    end
    skip("skipping test, fails in Safari: #{additional_error_text}")
  end

  def find_radio_button_by_value(value, scope = nil)
    fj("input[type=radio][value=#{value}]", scope)
  end

  # find an element via css selector
  #
  # like other selenium methods, this will wait until it finds the
  # element on the page, and will eventually raise if it's not found
  #
  # if you need to assert the non-existence of something, instead
  # consider using the contain_css matcher, as it will return as soon as
  # it can (but wait if necessary), e.g.
  #
  #   expect(f('#content')).not_to contain_css('.this-should-be-gone')
  def f(selector, scope = nil)
    stale_element_protection do
      (scope || driver).find_element :css, selector
    end
  end
  alias find f

  # short for find with link
  def fln(link_text, scope = nil)
    stale_element_protection do
      (scope || driver).find_element :link, link_text
    end
  end

  # short for find with link partial text
  def flnpt(partial_link_text, scope = nil)
    stale_element_protection do
      (scope || driver).find_element :partial_link_text, partial_link_text
    end
  end

  # find an element via fake-jquery-css selector
  #
  # useful for fake-jquery-css like `:visible`. if you're using
  # vanilla css, prefer `f` over `fj`.
  #
  # like other selenium methods, this will wait until it finds the
  # element on the page, and will eventually raise if it's not found
  #
  # if you need to assert the non-existence of something, instead consider
  # using the contain_jqcss matcher, as it will return as soon as it
  # can (but wait if necessary), e.g.
  #
  #   expect(f('#content')).not_to contain_jqcss('.gone:visible')
  def fj(selector, scope = nil)
    stale_element_protection do
      wait_for(method: :fj) do
        find_with_jquery selector, scope
      end or raise Selenium::WebDriver::Error::NoSuchElementError, "Unable to locate element: #{selector.inspect}"
    end
  end

  # Find an element via xpath
  def fxpath(xpath, scope = nil)
    stale_element_protection do
      (scope || driver).find_element :xpath, xpath
    end
  end

  # same as `f`, but returns all matching elements
  #
  # like other selenium methods, this will wait until it finds elements on
  # the page, and will eventually raise if none are found
  def ff(selector, scope = nil)
    reloadable_collection do
      (scope || driver).find_elements(:css, selector)
    end
  end
  alias find_all ff

  # same as `fj`, but returns all matching elements
  #
  # like other selenium methods, this will wait until it finds elements on
  # the page, and will eventually raise if none are found
  def ffj(selector, scope = nil)
    reloadable_collection do
      result = nil
      wait_for(method: :ffj) do
        result = find_all_with_jquery(selector, scope)
        result.present?
      end or raise Selenium::WebDriver::Error::NoSuchElementError, "Unable to locate element: #{selector.inspect}"
      result
    end
  end

  # Find a collection of elements via xpath
  def ffxpath(xpath, scope = nil)
    reloadable_collection do
      (scope || driver).find_elements(:xpath, xpath)
    end
  end

  def find_with_jquery(selector, scope = nil)
    driver.execute_script("return $(arguments[0], arguments[1] && $(arguments[1]))[0];", selector, scope)
  end

  def find_all_with_jquery(selector, scope = nil)
    driver.execute_script("return $(arguments[0], arguments[1] && $(arguments[1])).toArray();", selector, scope)
  end

  # pass full selector ex. "#blah td tr" , the attribute ex. "style" type,
  # and the value ex. "Red"
  def fba(selector, attrib, value)
    f("#{selector} [#{attrib}='#{value}']")
  end

  def in_frame(id, loading_locator = nil)
    saved_window_handle = driver.window_handle
    if loading_locator.nil?
      driver.switch_to.frame(id)
    else
      disable_implicit_wait do
        keep_trying_until(3) do
          # when it does switch frame but loading element did not exist we need to switch back then switch to iframe again
          driver.switch_to.window saved_window_handle
          driver.switch_to.frame(id)
          expect(f(loading_locator)).to be_displayed
        end
      end
    end
    begin
      yield
    ensure
      driver.switch_to.window saved_window_handle
    end
  end

  # Find the parent of an element via xpath
  def parent_fxpath(element)
    stale_element_protection do
      element.find_element(:xpath,"..")
    end
  rescue Selenium::WebDriver::Error::NoSuchElementError
    raise "Parent node for given element was not found"
  end

  # Find the parent of an element via JS
  def parent_fjs(element)
    stale_element_protection do
      driver.execute_script("return arguments[0].parentNode;", element)
    end
  rescue Selenium::WebDriver::Error::NoSuchElementError
    raise "Parent node for given element was not found"
  end

  # Find the grandparent of an element via xpath
  def grandparent_fxpath(element)
    stale_element_protection do
      element.find_element(:xpath,"../..")
    end
  rescue Selenium::WebDriver::Error::NoSuchElementError
    raise "Grandparent node for given element was not found, please check if parent nodes are present"
  end

  # Find an element with reference to another element, via xpath
  def find_from_element_fxpath(element, xpath)
    stale_element_protection do
      element.find_element(:xpath, xpath)
    end
  rescue Selenium::WebDriver::Error::NoSuchElementError
    raise "No element with reference to given element was found. Please recheck the xpath : #{xpath}"
  end

  # This helps us get runtime element values for an attribute
  # usage example : expect(element_value_for_attr(element, attribute)).to eq('true')
  def element_value_for_attr(element, attr)
    element.attribute(attr)
  rescue Selenium::WebDriver::Error::UnknownError
    raise "Attribute may not be passed correctly. Please recheck attribute passed, and its format : #{attr}"
  end

  # find button with fj, and the text it contains
  # usage example: find_button ("Save")
  def find_button(label = "", scope = nil)
    fj("button:contains('#{label}')", scope)
  end

  # find table with fj, and the caption it contains
  # usage example: find_table ("Grade Changes")
  def find_table(caption = "", scope = nil)
    fj("table:contains('#{caption}')", scope)
  end

  def fxpath_table_cell(caption, row_index, col_index)
    fxpath("//table[caption= '#{caption}']/tbody/tr[#{row_index}]/td[#{col_index}]")
  end

  def is_checked(css_selector)
    !!fj(css_selector)[:checked]
  end

  def get_value(selector)
    driver.execute_script("return $(#{selector.inspect}).val()")
  end

  def get_options(selector, scope=nil)
    Selenium::WebDriver::Support::Select.new(f(selector, scope)).options
  end

  # this is a smell; you should know what's on the page you're testing,
  # so conditionally doing stuff based on elements == :poop:
  def element_exists?(selector)
    disable_implicit_wait { f(selector) }
    true
  rescue Selenium::WebDriver::Error::NoSuchElementError
    false
  end

  def element_has_children?(selector)
    disable_implicit_wait { f(selector).find_elements(:xpath, ".//*") }
    true
  rescue Selenium::WebDriver::Error::NoSuchElementError
    false
  end

  def first_selected_option(select_element)
    select = Selenium::WebDriver::Support::Select.new(select_element)
    option = select.first_selected_option
    option
  end

  def dialog_for(node)
    node.find_element(:xpath, "ancestor-or-self::div[contains(@class, 'ui-dialog')]") rescue false
  end

  # for when you have something like a textarea's value and you want to match it's contents
  # against a css selector.
  # usage:
  # find_css_in_string(some_textarea[:value], '.some_selector').should_not be_empty
  def find_css_in_string(string_of_html, css_selector)
    driver.execute_script("return $('<div />').append('#{string_of_html}').find('#{css_selector}')")
  end

  def select_all_in_tiny(tiny_controlling_element)
    # This used to be a direct usage of "editorBox", which is sorta crummy because
    # we don't want acceptance tests to have special implementation knowledge of
    # the system under test.
    #
    # This script is a bit bigger, but interacts more like a user would by
    # selecting the contents we want to manipulate directly. the reason it looks so
    # cumbersome is because tinymce has it's actual interaction point down in
    # an iframe.
    src = %Q{
      var $iframe = $("##{tiny_controlling_element.attribute(:id)}").siblings('.mce-tinymce').find('iframe');
      var iframeDoc = $iframe[0].contentDocument;
      var domElement = iframeDoc.getElementsByTagName("body")[0];
      var selection = iframeDoc.getSelection();
      var range = iframeDoc.createRange();
      range.selectNodeContents(domElement);
      selection.removeAllRanges();
      selection.addRange(range);
    }
    driver.execute_script(src)
  end

  def assert_can_switch_views!
    fj('a.switch_views:visible,a.toggle_question_content_views_link:visible')
  rescue Selenium::WebDriver::Error::NoSuchElementError
    raise "switch views is not available!"
  end

  def switch_editor_views(tiny_controlling_element)
    if !tiny_controlling_element.is_a?(String)
      tiny_controlling_element = "##{tiny_controlling_element.attribute(:id)}"
    end
    selector = tiny_controlling_element.to_s.to_json
    assert_can_switch_views!
    driver.execute_script(%Q{
      $(#{selector}).parent().parent().find("a.switch_views:visible, a.toggle_question_content_views_link:visible").click();
    })
  end

  def clear_tiny(tiny_controlling_element, iframe_id=nil)
    if iframe_id
      in_frame iframe_id do
        tinymce_element = f("body")
        while tinymce_element.text.length > 0 do
          tinymce_element.click
          tinymce_element.send_keys(Array.new(100, :backspace))
          tinymce_element = f("body")
        end
      end
    else
      assert_can_switch_views!
      switch_editor_views(tiny_controlling_element)
      tiny_controlling_element.clear
      switch_editor_views(tiny_controlling_element)
    end
  end

  def type_in_tiny(tiny_controlling_element, text, clear: false)
    selector = tiny_controlling_element.to_s.to_json
    keep_trying_until do
      driver.execute_script("return $(#{selector}).siblings('.mce-tinymce').length > 0;")
    end

    iframe_id = driver.execute_script("return $(#{selector}).siblings('.mce-tinymce').find('iframe')[0];")['id']

    clear_tiny(tiny_controlling_element, iframe_id) if clear

    if text.length > 100 || text.lines.size > 1
      switch_editor_views(tiny_controlling_element)
      html = "<p>" + ERB::Util.html_escape(text).gsub("\n", "</p><p>") + "</p>"
      driver.execute_script("return $(#{selector}).val(#{html.inspect})")
      switch_editor_views(tiny_controlling_element)
    else
      in_frame iframe_id do
        tinymce_element = f("body")
        tinymce_element.click
        tinymce_element.send_keys(text)
      end
    end
  end

  def hover_and_click(element_jquery_finder)
    if fj(element_jquery_finder).present?
      driver.execute_script(%{$(#{element_jquery_finder.to_s.to_json}).trigger('mouseenter').click()})
    end
  end

  # This function is to be used as a last resort ONLY
  # Make sure that you have tried:
  # 1.) finding and clicking the element with f, fj, fln, and flnpt statements.
  # 2.) attempts to wait
  # 3.) attempt to click blocking items by finding them instead
  # 4.) attempts to find and click blocking items with xpath
  #
  # This function is to be used if:
  # 1.) the above are still fragile
  # 2.) clicking an item works intermittently
  # 3.) an item is not covered (as this should cause a failure)
  # 4.) an item is UNIQUE ON THE PAGE.
  #
  # If this function is used:
  # 1.) make sure your jquery selector always finds ONLY THE ELEMENT YOU WANT
  #   1a.) attempting to click a non-unique element may remain fragile.
  #
  # 2.) This function will click items that are not visible or covered.
  #
  # 3.) This function will likely have trouble clicking links. Use fln instead.
  def force_click(element_jquery_finder)
    fj(element_jquery_finder)
    driver.execute_script(%{$(#{element_jquery_finder.to_s.to_json}).click()})
  end

  def hover(element)
    element.with_stale_element_protection do
      driver.action.move_to(element).perform
    end
  end

  def set_value(input, value)
    case input.tag_name
      when 'select'
        input.find_element(:css, "option[value='#{value}']").click
      when 'input'
        case input.attribute(:type)
          when 'checkbox'
            input.click if (!input.selected? && value) || (input.selected? && !value)
          else
            replace_content(input, value)
        end
      else
        replace_content(input, value)
    end
  end

  def click_option(select_css, option_text, select_by = :text)
    element = fj(select_css)
    select = Selenium::WebDriver::Support::Select.new(element)
    select.select_by(select_by, option_text)
  end

  def close_visible_dialog
    visible_dialog_element = fj('.ui-dialog:visible')
    visible_dialog_element.find_element(:css, '.ui-dialog-titlebar-close').click
    expect(visible_dialog_element).not_to be_displayed
  end

  def datepicker_prev(day_text = '15')
    datepicker = f('#ui-datepicker-div')
    datepicker.find_element(:css, '.ui-datepicker-prev').click
    fj("#ui-datepicker-div a:contains(#{day_text})").click
    datepicker
  end

  def datepicker_next(day_text = '15')
    datepicker = f('#ui-datepicker-div')
    datepicker.find_element(:css, '.ui-datepicker-next').click
    fj("#ui-datepicker-div a:contains(#{day_text})").click
    datepicker
  end

  def datepicker_current(day_text = '15')
    fj("#ui-datepicker-div a:contains(#{day_text})").click
  end

  MODIFIER_KEY = RUBY_PLATFORM =~ /darwin/ ? :command : :control
  def replace_content(el, value, options = {})
    # Removed the javascript select(), it was causing stale element exceptions
    # el.clear doesn't work with textboxes that have a pattern attribute that's why we have :backspace.
    # We are treating the chrome browser different because Selenium cannot send :command key to chrome on Mac.
    # This is a known issue and hasn't been solved yet. https://bugs.chromium.org/p/chromedriver/issues/detail?id=30
    case driver.browser
    when :firefox, :safari, :internet_explorer
      keys = [[MODIFIER_KEY, "a"], :backspace]
    when :chrome
      el.clear
      keys = [:backspace]
    end
    keys << value
    keys << :tab if options[:tab_out]
    el.send_keys(*keys)
  end

  # can pass in either an element or a forms css
  def submit_form(form)
    submit_button_css = 'button[type="submit"]'
    button = form.is_a?(Selenium::WebDriver::Element) ? form.find_element(:css, submit_button_css) : f("#{form} #{submit_button_css}")
    button.click
  end

  # can pass in either an element or a forms css
  def scroll_to_submit_button_and_click(form)
    submit_button_css = 'button[type="submit"]'
    button = form.is_a?(Selenium::WebDriver::Element) ? form.find_element(:css, submit_button_css) : f("#{form} #{submit_button_css}")
    scroll_to(button)
    driver.action.move_to(button).click.perform
  end

  def trigger_form_submit_event(form)
    form_element = form.is_a?(Selenium::WebDriver::Element) ? form : f(form)
    form_element.submit
  end

  def submit_dialog_form(form)
    # used to be called submit_form, but it turns out that if you're
    # searching for a dialog that doesn't exist it's suuuuuper slow
    submit_button_css = 'button[type="submit"]'
    button = form.is_a?(Selenium::WebDriver::Element) ? form.find_element(:css, submit_button_css) : f("#{form} #{submit_button_css}")
    # the button may have been hidden via fixDialogButtons
    dialog = dialog_for(button)
    if !button.displayed? && dialog
      submit_dialog(dialog)
    else
      raise "use submit_form instead"
    end
  end

  def submit_dialog(dialog, submit_button_css = ".ui-dialog-buttonpane .button_type_submit")
    dialog = f(dialog) unless dialog.is_a?(Selenium::WebDriver::Element)
    dialog = dialog_for(dialog)
    dialog.find_elements(:css, submit_button_css).last.click
  end

  ##
  # load the simulate plugin to simulate a drag events (among other things)
  # will only load it once even if its called multiple times
  def load_simulate_js
    @load_simulate_js ||= begin
      js = File.read('spec/selenium/helpers/jquery.simulate.js')
      driver.execute_script js
    end
  end

  # when selenium fails you, reach for .simulate
  # takes a CSS selector for jQuery to find the element you want to drag
  # and then the change in x and y you want to drag
  def drag_with_js(selector, x, y)
    load_simulate_js
    driver.execute_script "$('#{selector}').simulate('drag', { dx: #{x}, dy: #{y} })"
  end

  ##
  # drags an element matching css selector `source_selector` onto an element
  # matching css selector `target_selector`
  #
  # sometimes seleniums drag and drop just doesn't seem to work right this
  # seems to be more reliable
  def js_drag_and_drop(source_selector, target_selector)
    source = f source_selector
    source_location = source.location

    target = f target_selector
    target_location = target.location

    dx = target_location.x - source_location.x
    dy = target_location.y - source_location.y

    drag_with_js source_selector, dx, dy
  end

  ##
  # drags the source element to the target element and waits for ajaximations
  def drag_and_drop_element(source, target)
    driver.action.drag_and_drop(source, target).perform
    wait_for_ajaximations
  end

  ##
  # returns true if a form validation error message is visible, false otherwise
  def error_displayed?
    # after it fades out, it's still visible, just off the screen
    driver.execute_script("return $('.error_text:visible').filter(function(){ return $(this).offset().left >= 0 }).length > 0")
  end

  def double_click(selector)
    el = driver.find_element :css, selector
    driver.action.double_click(el).perform
  end

  def replace_value(selector, value)
    driver.execute_script("$('#{selector}').val(#{value})")
  end

  def current_active_element
    driver.switch_to.active_element
  end

  def move_to_click(selector)
    el = driver.find_element :css, selector
    driver.action.move_to(el).click.perform
  end

  def move_to_click_element(element)
    driver.action.move_to(element).click.perform
  end

  def scroll_to(element)
    element_location = "#{element.location['y']}"
    driver.execute_script('window.scrollTo(0, ' + element_location + ');')
  end

  def flash_message_selector
    '#flash_message_holder li'
  end

  def dismiss_flash_messages
    ff(flash_message_selector).each(&:click)
  end

  def dismiss_flash_messages_if_present
    unless (find_all_with_jquery(flash_message_selector).length) == 0
      find_all_with_jquery(flash_message_selector).each(&:click)
    end
  end

  def scroll_into_view(selector)
    driver.execute_script("$(#{selector.to_json})[0].scrollIntoView()")
  end

  # see public/javascripts/vendor/jquery.scrollTo.js
  # target can be:
  #  - A number position (will be applied to all axes).
  #  - A string position ('44', '100px', '+=90', etc ) will be applied to all axes
  #  - A string selector, that will be relative to the element to scroll ( 'li:eq(2)', etc )
  #  - A hash { top:x, left:y }, x and y can be any kind of number/string like above.
  #  - A percentage of the container's dimension/s, for example: 50% to go to the middle.
  #  - The string 'max' for go-to-end.
  def scroll_element(selector, target)
    driver.execute_script("$(#{selector.to_json}).scrollTo(#{target.to_json})")
  end

  def stale_element_protection
    element = yield
    element.finder_proc = proc do
      disable_implicit_wait { yield }
    end
    element
  end

  def reloadable_collection
    collection = yield
    SeleniumExtensions::ReloadableCollection.new(collection, proc do
      disable_implicit_wait { yield }
    end)
  end
end
