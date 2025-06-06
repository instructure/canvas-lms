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
# with this program. If not, see <http://www.gnu.org/licenses/>

module CustomSeleniumActions
  def skip_if_ie(additional_error_text)
    if driver.browser == :internet_explorer
      skip("skipping test, fails in IE : #{additional_error_text}")
    end
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
    stale_element_protection { (scope || driver).find_element :css, selector }
  end

  alias_method :find, :f

  # short for find with link
  def fln(link_text, scope = nil)
    stale_element_protection { (scope || driver).find_element :link, link_text }
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
  def fj(selector, scope = nil, timeout: nil)
    wait_opts = { method: :fj }
    wait_opts[:timeout] = timeout if timeout
    stale_element_protection do
      wait_for(**wait_opts) { find_with_jquery selector, scope } or
        raise Selenium::WebDriver::Error::NoSuchElementError,
              "Unable to locate element: #{selector.inspect}"
    end
  end

  # Find an element via xpath
  def fxpath(xpath, scope = nil)
    stale_element_protection { (scope || driver).find_element :xpath, xpath }
  end

  # same as `f`, but returns all matching elements
  #
  # like other selenium methods, this will wait until it finds elements on
  # the page, and will eventually raise if none are found
  def ff(selector, scope = nil)
    reloadable_collection { (scope || driver).find_elements(:css, selector) }
  end

  alias_method :find_all, :ff

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
      end or
        raise Selenium::WebDriver::Error::NoSuchElementError,
              "Unable to locate element: #{selector.inspect}"
      result
    end
  end

  # Find a collection of elements via xpath
  def ffxpath(xpath, scope = nil)
    reloadable_collection { (scope || driver).find_elements(:xpath, xpath) }
  end

  def find_by_test_id(test_id, scope = nil)
    f("[data-testid='#{test_id}']", scope)
  end

  def find_with_jquery(selector, scope = nil)
    driver.execute_script(
      "return $(arguments[0], arguments[1] && $(arguments[1]))[0];",
      selector,
      scope
    )
  end

  def find_all_with_jquery(selector, scope = nil)
    driver.execute_script(
      "return $(arguments[0], arguments[1] && $(arguments[1])).toArray();",
      selector,
      scope
    )
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
    stale_element_protection { element.find_element(:xpath, "..") }
  rescue Selenium::WebDriver::Error::NoSuchElementError
    raise "Parent node for given element was not found"
  end

  # Find the parent of an element via JS
  def parent_fjs(element)
    stale_element_protection { driver.execute_script("return arguments[0].parentNode;", element) }
  rescue Selenium::WebDriver::Error::NoSuchElementError
    raise "Parent node for given element was not found"
  end

  # Find the grandparent of an element via xpath
  def grandparent_fxpath(element)
    stale_element_protection { element.find_element(:xpath, "../..") }
  rescue Selenium::WebDriver::Error::NoSuchElementError
    raise "Grandparent node for given element was not found, please check if parent nodes are present"
  end

  # Find an element with reference to another element, via xpath
  def find_from_element_css(element, css)
    stale_element_protection { element.find_element(:css, css) }
  rescue Selenium::WebDriver::Error::NoSuchElementError
    raise "No element with reference to given element was found. Please recheck the css : #{css}"
  end

  # Find an element with reference to another element, via xpath
  def find_from_element_fxpath(element, xpath)
    stale_element_protection { element.find_element(:xpath, xpath) }
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

  def find_table_rows(caption = "", scope = nil)
    ffxpath("//table[caption='#{caption}']/tbody/tr", scope)
  end

  def fxpath_table_cell(caption, row_index, col_index)
    fxpath("//table[caption= '#{caption}']/tbody/tr[#{row_index}]/td[#{col_index}]")
  end

  def is_checked(css_selector)
    node = fj(css_selector)
    # 'checked' attribute is a boolean whereas 'aria-checked' is a
    # string representing the value of a boolean
    !!node[:checked] || node["aria-checked"] == "true"
  end

  def get_value(selector)
    script = "return document.querySelector(arguments[0]).value;"
    driver.execute_script(script, selector)
  end

  def get_options(selector, scope = nil)
    Selenium::WebDriver::Support::Select.new(f(selector, scope)).options
  end

  # conditionally doing stuff based on what elements are on the page
  # is a smell; you should know what's on the page you're testing.
  def element_exists?(selector, xpath = false)
    disable_implicit_wait { xpath ? fxpath(selector) : f(selector) }
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

  def get_parent_element(element)
    driver.execute_script("return arguments[0].parentNode;", element)
  end

  def first_selected_option(select_element)
    select = Selenium::WebDriver::Support::Select.new(select_element)
    select.first_selected_option
  end

  def dialog_for(node)
    node.find_element(:xpath, "ancestor-or-self::div[contains(@class, 'ui-dialog')]")
  rescue
    false
  end

  # for when you have something like a textarea's value and you want to match it's contents
  # against a css selector.
  # usage:
  # find_css_in_string(some_textarea[:value], '.some_selector').should_not be_empty
  def find_css_in_string(string_of_html, css_selector)
    driver.execute_script("return $('<div />').append('#{string_of_html}').find('#{css_selector}')")
  end

  def select_all_in_tiny(tiny_controlling_element)
    select_in_tiny(tiny_controlling_element, "body")
  end

  def select_in_tiny(tiny_controlling_element, css_selector)
    # This used to be a direct usage of "editorBox", which is sorta crummy because
    # we don't want acceptance tests to have special implementation knowledge of
    # the system under test.
    #
    # This script is a bit bigger, but interacts more like a user would by
    # selecting the contents we want to manipulate directly. the reason it looks so
    # cumbersome is because tinymce has it's actual interaction point down in
    # an iframe.
    src =
      "
      var $iframe = $(\"##{tiny_controlling_element.attribute(:id)}\").siblings('[role=\"application\"],[role=\"document\"]').find('iframe');
      var iframeDoc = $iframe[0].contentDocument;
      var domElement = iframeDoc.querySelector(\"#{css_selector}\")
      var selection = iframeDoc.getSelection();
      var range = iframeDoc.createRange();
      range.selectNodeContents(domElement);
      selection.removeAllRanges();
      selection.addRange(range);
    "
    driver.execute_script(src)
  end

  def assert_can_switch_views!
    fj("a.switch_views:visible,a.toggle_question_content_views_link:visible")
  rescue Selenium::WebDriver::Error::NoSuchElementError
    raise "switch views is not available!"
  end

  # controlling_element is a parent of the RCE you're interested in using.
  # the default controlling_element works fine if there is only 1 RCE on the page
  # or if you're interested in the first one of many
  def switch_editor_views(controlling_element = f(".rce-wrapper"))
    edit_btn = f("[data-btn-id='rce-edit-btn']", controlling_element)
    edit_btn.click
  end

  def switch_to_raw_html_editor
    button = f('button[data-btn-id="rce-editormessage-btn"]')
    if button.text == "Switch to raw HTML Editor"
      button.click
    end
  end

  def clear_tiny(tiny_controlling_element, iframe_id = nil)
    if iframe_id
      in_frame iframe_id do
        tinymce_element = f("body")
        until tinymce_element.text.empty?
          tinymce_element.click
          tinymce_element.send_keys([:control, "a"], :backspace)
        end
      end
    else
      assert_can_switch_views!
      switch_editor_views(tiny_controlling_element)
      tiny_controlling_element.clear
    end
  end

  def type_in_tiny(tiny_controlling_element_selector, text, clear: false)
    selector = tiny_controlling_element_selector.to_s.to_json
    tiny_controlling_element = fj(tiny_controlling_element_selector)
    mce_class = ".tox-tinymce"
    keep_trying_until do
      driver.execute_script("return $(#{selector}).siblings('#{mce_class}').length > 0;")
    end

    iframe_id =
      driver.execute_script("return $(#{selector}).siblings('#{mce_class}').find('iframe')[0];")[
        "id"
      ]
    clear_tiny(tiny_controlling_element, iframe_id) if clear

    if text.length > 100 || text.lines.size > 1
      switch_editor_views(
        fxpath('./ancestor::div[contains(@class, "rce-wrapper")]', tiny_controlling_element)
      )
      html = "<p>" + ERB::Util.html_escape(text).gsub("\n", "</p><p>") + "</p>"
      driver.execute_script("return $(#{selector}).val(#{html.inspect})")
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
      driver.execute_script(
        "$(#{element_jquery_finder.to_s.to_json}).trigger('mouseenter').click()"
      )
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
    driver.execute_script("$(#{element_jquery_finder.to_s.to_json}).click()")
  end

  def force_click_native(element_finder)
    f(element_finder)
    driver.execute_script("document.querySelector(#{element_finder.to_s.to_json}).click();")
  end

  def hover(element)
    element.with_stale_element_protection { driver.action.move_to(element).perform }
  end

  def set_value(input, value)
    case input.tag_name
    when "select"
      input.find_element(:css, "option[value='#{value}']").click
    when "input"
      case input.attribute(:type)
      when "checkbox"
        input.click if (!input.selected? && value) || (input.selected? && !value)
      else
        replace_content(input, value)
      end
    else
      replace_content(input, value)
    end
  end

  def search_for_option(select_css, option_text, option_value, match_by = :value)
    element = canvas_select(select_css)
    input_canvas_select(element, option_text)
    click_INSTUI_Select_option(element, option_value, match_by)
  end

  def click_option(select_css, option_text, select_by = :text)
    element = fj(select_css)
    if element.tag_name == "input"
      click_INSTUI_Select_option(element, option_text, select_by)
    else
      select = Selenium::WebDriver::Support::Select.new(element)
      select.select_by(select_by, option_text)
    end
  end

  def element_or_css(elem_or_css)
    elem_or_css.is_a?(String) ? fj(elem_or_css) : elem_or_css
  end

  def canvas_select(elem_or_css)
    element_or_css(elem_or_css)
  end

  def instui_select(elem_or_css)
    element_or_css(elem_or_css)
  end

  def instui_select_option(select, option_text, select_by: text)
    cselect = instui_select(select)
    option_list_id = cselect.attribute("aria-controls")
    if option_list_id.blank?
      cselect.click
      option_list_id = cselect.attribute("aria-controls")
    end

    if select_by == :text
      fj("##{option_list_id} [role='option']:contains(#{option_text})")
    else
      f("##{option_list_id} [role='option'][#{select_by}='#{option_text}']")
    end
  end

  def clear_canvas_select(select)
    cselect = canvas_select(select)
    # clear the input field
    cselect.send_keys [:control, "a"], :backspace
  end

  def input_canvas_select(select, text, option_exists: true)
    wait = Selenium::WebDriver::Wait.new(timeout: 5)
    cselect = canvas_select(select)
    clear_canvas_select(select)

    # if the option doesn't exist, we need to type the first word of the option
    # otherwise all space characters will be ignored
    unless option_exists
      cselect.send_keys(text.split.first)
      wait.until { cselect.attribute("aria-expanded") == "false" }
      return
    end

    text.split.flat_map { |w| [w, :space] }[0...-1].each do |word|
      cselect.send_keys(word)
      wait.until { cselect.attribute("aria-expanded") == "true" }
    end
  end

  # implementation of click_option for use with INSTU's Select
  # (tested with the CanvasSelect wrapper and instui SimpleSelect,
  # untested with a raw instui Select)
  def click_INSTUI_Select_option(select, option_text, select_by = :text)
    instui_select_option(select, option_text, select_by:).click
  end

  def INSTUI_Select_options(select)
    cselect = instui_select(select)
    cselect.click # open the options list
    option_list_id = cselect.attribute("aria-controls")
    ff("##{option_list_id} [role='option']")
  end

  def INSTUI_Menu_options(menu)
    menu = instui_select(menu)
    menu.click # option the options list
    ff("[aria-labelledby='#{menu.attribute("id")}'] [role='menuitemradio']")
  end

  def close_visible_dialog
    visible_dialog_element = fj(".ui-dialog:visible")
    visible_dialog_element.find_element(:css, ".ui-dialog-titlebar-close").click
    expect(visible_dialog_element).not_to be_displayed
  end

  def datepicker_prev(day_text = "15")
    datepicker = f("#ui-datepicker-div")
    datepicker.find_element(:css, ".ui-datepicker-prev").click
    fj("#ui-datepicker-div a:contains(#{day_text})").click
    datepicker
  end

  def datepicker_next(day_text = "15")
    datepicker = f("#ui-datepicker-div")
    datepicker.find_element(:css, ".ui-datepicker-next").click
    fj("#ui-datepicker-div a:contains(#{day_text})").click
    datepicker
  end

  def datepicker_current(day_text = "15")
    fj("#ui-datepicker-div a:contains(#{day_text})").click
  end

  MODIFIER_KEY = RUBY_PLATFORM.include?("darwin") ? :command : :control

  def replace_content(el, value, options = {})
    # el.clear doesn't work with textboxes that have a pattern attribute that's why we have :backspace.
    # We are treating the chrome browser different because Selenium cannot send :command key to chrome on Mac.
    # This is a known issue and hasn't been solved yet. https://bugs.chromium.org/p/chromedriver/issues/detail?id=30
    driver.execute_script("arguments[0].select();", el)
    keys = value.to_s.empty? ? [:backspace] : []
    keys << value
    el.send_keys(*keys)

    el.send_keys(:tab) if options[:tab_out]
    el.send_keys(:return) if options[:press_return]
  end

  def replace_and_proceed(el, value, options = {})
    replace_content(el, value, options.merge(tab_out: true))
  end

  # can pass in either an element or a forms css
  def submit_form(form)
    submit_button_css = 'button[type="submit"]'
    button = if form.is_a?(Selenium::WebDriver::Element)
               form.find_element(:css, submit_button_css)
             else
               f("#{form} #{submit_button_css}")
             end
    button.click
  end

  # can pass in either an element or a forms css
  def scroll_to_submit_button_and_click(form)
    submit_button_css = 'button[type="submit"]'
    button = if form.is_a?(Selenium::WebDriver::Element)
               form.find_element(:css, submit_button_css)
             else
               f("#{form} #{submit_button_css}")
             end
    scroll_into_view(button)
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
    button = if form.is_a?(Selenium::WebDriver::Element)
               form.find_element(:css, submit_button_css)
             else
               f("#{form} #{submit_button_css}")
             end

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

  # when selenium fails you, reach for .simulate
  # takes a CSS selector for jQuery to find the element you want to drag
  # and then the change in x and y you want to drag
  def drag_with_js(selector, x, y)
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
    wait_for_ajaximations
  end

  ##
  # drags the source element to the target element and waits for ajaximations
  def drag_and_drop_element(source, target)
    driver.action.drag_and_drop(source, target).perform
    wait_for_ajaximations
  end

  ##
  ## drags the source element by dx to the right and dy down
  def drag_and_drop_element_by(source, dx, dy)
    driver.action.drag_and_drop_by(source, dx, dy).perform
  end

  ##
  # returns true if a form validation error message is visible, false otherwise
  def error_displayed?(class_name = "error_text")
    # after it fades out, it's still visible, just off the screen
    driver.execute_script(
      "return $('.#{class_name}:visible').filter(function(){ return $(this).offset().left >= 0 }).length > 0"
    )
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

  def scroll_to_click_element(element)
    scroll_into_view(element)
    element.click
  end

  def move_to_click_element(element)
    driver.action.move_to(element).click.perform
  end

  def scroll_to(element)
    element_location = element.location["y"].to_s
    driver.execute_script("window.scrollTo(0, " + element_location + ");")
  end

  def flash_message_selector
    "#flash_message_holder .flash-message-container"
  end

  def dismiss_flash_messages
    ff(flash_message_selector).each(&:click)
  end

  def dismiss_flash_messages_if_present
    unless find_all_with_jquery(flash_message_selector).empty?
      find_all_with_jquery(flash_message_selector).each(&:click)
    end
  end

  # Scroll To Element (without executing Javascript)
  #
  # Moves the mouse to the middle of the given element. The element is scrolled
  # into view and its location is calculated using getBoundingClientRect.
  # Then the mouse is moved to optional offset coordinates from the element.
  #
  # Note that when using offsets, both coordinates need to be passed.
  #
  # element (Selenium::WebDriver::Element) — to move to.
  # right_by (Integer) (defaults to: nil) — Optional offset from the top-left corner.
  #   A negative value means coordinates right from the element.
  # down_by (Integer) (defaults to: nil) — Optional offset from the top-left corner.
  #   A negative value means coordinates above the element.
  def scroll_to_element(element, right_by = nil, down_by = nil)
    driver.action.move_to(element, right_by, down_by).perform
    wait_for_ajaximations
  end

  def scroll_into_view(target)
    if target.is_a?(Selenium::WebDriver::Element)
      driver.execute_script("arguments[0].scrollIntoView(true);", target)
    else
      driver.execute_script("$(#{target.to_json})[0].scrollIntoView()")
    end
  end

  # see packages/jquery-scroll-to-visible
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

  def stale_element_protection(&)
    element = yield
    element.finder_proc = proc { disable_implicit_wait(&) }
    element
  end

  def reloadable_collection(&)
    collection = yield
    SeleniumExtensions::ReloadableCollection.new(
      collection,
      proc { disable_implicit_wait(&) }
    )
  end

  # some elements in the RCE are loaded in stages (ex: math)
  # and aren't immediately clickable, even though they are visible
  def click_repeat(element)
    element.click
  rescue
    click_repeat(element)
  end

  # If you want to simulate a user's internet connection turning offline, use these methods.
  def turn_off_network
    driver.network_conditions = { offline: true, latency: 0, throughput: 0 }
  end

  def turn_on_network
    driver.network_conditions = { offline: false, latency: 0, throughput: -1 }
  end
end
