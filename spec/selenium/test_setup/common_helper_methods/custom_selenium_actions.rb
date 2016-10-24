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

  def find(css)
    driver.find(css)
  end

  def find_all(css)
    driver.find_all(css)
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

  # short for find with link
  def fln(link_text, scope = nil)
    stale_element_protection do
      (scope || driver).find_element :link, link_text
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
      wait_for(method: :fj, timeout: driver.manage.timeouts.implicit_wait) do
        find_with_jquery selector, scope
      end or raise Selenium::WebDriver::Error::NoSuchElementError
    end
  end

  # same as `f`, but returns all matching elements
  #
  # like other selenium methods, this will wait until it finds elements on
  # the page, and will eventually raise if none are found
  def ff(selector, scope = nil)
    result = reloadable_collection do
      (scope || driver).find_elements :css, selector
    end
    raise Selenium::WebDriver::Error::NoSuchElementError unless result.present?
    result
  end

  # same as `fj`, but returns all matching elements
  #
  # like other selenium methods, this will wait until it finds elements on
  # the page, and will eventually raise if none are found
  def ffj(selector, scope = nil)
    reloadable_collection do
      result = nil
      wait_for(method: :ffj, timeout: driver.manage.timeouts.implicit_wait) do
        result = find_all_with_jquery(selector, scope)
        result.present?
      end or raise Selenium::WebDriver::Error::NoSuchElementError
      result
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

  def exec_cs(script, *args)
    driver.execute_script(CoffeeScript.compile(script), *args)
  end

  # a varable named `callback` is injected into your function for you, just call it to signal you are done.
  def exec_async_cs(script, *args)
    to_compile = "var callback = arguments[arguments.length - 1]; #{CoffeeScript.compile(script)}"
    driver.execute_async_script(script, *args)
  end

  def in_frame(id)
    f("[id=\"#{id}\"],[name=\"#{id}\"]") # ensure frame is loaded
    saved_window_handle = driver.window_handle
    driver.switch_to.frame(id)
    begin
      yield
    ensure
      driver.switch_to.window saved_window_handle
    end
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
      expect(tiny_controlling_element[:value]).to be_empty
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

    if text.length > 1000
      switch_editor_views(tiny_controlling_element)
      driver.execute_script("return $(#{selector}).val('#{text}')")
      switch_editor_views(tiny_controlling_element)
    else
      text_lines = text.split("\n")
      in_frame iframe_id do
        tinymce_element = f("body")
        tinymce_element.click
        if text_lines.size > 1
          text_lines.each_with_index do |line, index|
            tinymce_element.send_keys(line)
            tinymce_element.send_keys(:return) unless index >= text_lines.size - 1
          end
        else
          tinymce_element.send_keys(text)
        end
      end
    end
  end

  def hover_and_click(element_jquery_finder)
    if fj(element_jquery_finder).present?
      driver.execute_script(%{$(#{element_jquery_finder.to_s.to_json}).trigger('mouseenter').click()})
    end
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
    keys = [[MODIFIER_KEY, "a"], :backspace, value]
    keys << :tab if options[:tab_out]

    # We are treating the chrome browser different because currently Selenium cannot send :command key to the chrome.
    # This is a known issue and hasn't been solved yet. https://bugs.chromium.org/p/chromedriver/issues/detail?id=30
    if driver.browser == :chrome
      driver.execute_script("arguments[0].select()", el)
      keys.delete_at(0)
    end
    el.send_keys(*keys)
  end

  # can pass in either an element or a forms css
  def submit_form(form)
    submit_button_css = 'button[type="submit"]'
    button = form.is_a?(Selenium::WebDriver::Element) ? form.find_element(:css, submit_button_css) : f("#{form} #{submit_button_css}")
    button.click
  end

  def submit_dialog_form(form)
    # used to be called submit_form, but it turns out that if you're searching for a dialog that doesn't exist it's suuuuuper slow
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

  def double_click(selector)
    el = driver.find_element :css, selector
    driver.action.double_click(el).perform
  end

  def replace_value(selector, value)
    driver.execute_script("$('#{selector}').val(#{value})")
  end

  def move_to_click(selector)
    el = driver.find_element :css, selector
    driver.action.move_to(el).click.perform
  end

  def scroll_to(element)
    element_location = "#{element.location['y']}"
    driver.execute_script('window.scrollTo(0, ' + element_location + ');')
  end

  def dismiss_flash_messages
    ff("#flash_message_holder li").each(&:click)
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
