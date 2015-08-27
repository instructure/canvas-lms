module CustomSeleniumActions

  def skip_if_ie(additional_error_text)
    skip("skipping test, fails in IE : " + additional_error_text) if driver.browser == :internet_explorer
  end

  # f means "find" this is a shortcut to finding elements
  def f(selector, scope = nil)
    (scope || driver).find_element :css, selector
  rescue
    nil
  end

  # short for find with link
  def fln(link_text, scope = nil)
    (scope || driver).find_element :link, link_text
  rescue
    nil
  end

  # short for find with jquery
  def fj(selector, scope = nil)
    find_with_jquery selector, scope
  rescue
    nil
  end

  # same as `f` except tries to find several elements instead of one
  def ff(selector, scope = nil)
    (scope || driver).find_elements :css, selector
  rescue
    []
  end

  # same as find with jquery but tries to find several elements instead of one
  def ffj(selector, scope = nil)
    find_all_with_jquery selector, scope
  rescue
    []
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

  def exec_cs(script, *args)
    driver.execute_script(CoffeeScript.compile(script), *args)
  end

  # a varable named `callback` is injected into your function for you, just call it to signal you are done.
  def exec_async_cs(script, *args)
    to_compile = "var callback = arguments[arguments.length - 1]; #{CoffeeScript.compile(script)}"
    driver.execute_async_script(script, *args)
  end

  def in_frame(id)
    saved_window_handle = driver.window_handle
    driver.switch_to.frame(id)
    yield
  ensure
    driver.switch_to.window saved_window_handle
  end

  def is_checked(css_selector)
    driver.execute_script('return $("'+css_selector+'").prop("checked")')
  end

  def get_value(selector)
    driver.execute_script("return $(#{selector.inspect}).val()")
  end

  def get_options(selector, scope=nil)
    Selenium::WebDriver::Support::Select.new(f(selector, scope)).options
  end

  def element_exists(css_selector)
    !ffj(css_selector).empty?
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

  def type_in_tiny(tiny_controlling_element, text)
    scr = "$(#{tiny_controlling_element.to_s.to_json}).editorBox('execute', 'mceInsertContent', false, #{text.to_s.to_json})"
    driver.execute_script(scr)
  end

  def hover_and_click(element_jquery_finder)
    expect(fj(element_jquery_finder.to_s)).to be_present
    driver.execute_script(%{$(#{element_jquery_finder.to_s.to_json}).trigger('mouseenter').click()})
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
    driver.execute_script(input['onchange']) if input['onchange']
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

  def replace_content(el, value)
    el.clear
    el.send_keys(value)
  end

  # can pass in either an element or a forms css
  def submit_form(form)
    submit_button_css = 'button[type="submit"]'
    button = form.is_a?(Selenium::WebDriver::Element) ? form.find_element(:css, submit_button_css) : f("#{form} #{submit_button_css}")
    # the button may have been hidden via fixDialogButtons
    dialog = dialog_for(button)
    if !button.displayed? && dialog
      submit_dialog(dialog)
    else
      button.click
    end
  end

  def proceed_form(form)
    proceed_button_css = 'button[type="button"]'
    button = form.is_a?(Selenium::WebDriver::Element) ? form.find_element(:css, proceed_button_css) : f("#{form} #{proceed_button_css}")
    # the button may have been hidden via fixDialogButtons
    dialog = dialog_for(button)
    if !button.displayed? && dialog
      submit_dialog(dialog)
    else
      button.click
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
    wait_for_js
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
end