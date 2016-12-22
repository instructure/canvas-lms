module CustomScreenActions
  def scroll_page_to_top
    driver.execute_script("window.scrollTo(0, 0)")
  end

  def scroll_page_to_bottom
    driver.execute_script("window.scrollTo(0, document.body.scrollHeight)")
  end

  def make_full_screen
    w, h = driver.execute_script <<-JS
      if (window.screen) {
        return [ window.screen.availWidth, window.screen.availHeight ];
      }
      return [ 0, 0 ];
    JS

    if w > 0 && h > 0
      driver.manage.window.move_to(0, 0)
      driver.manage.window.resize_to(w, h)
    end
  end

  def resize_screen_to_normal
    w, h = driver.execute_script <<-JS
        if (window.screen) {
          return [window.screen.availWidth, window.screen.availHeight];
        }
    JS
    if w != 1200 || h != 600
      driver.manage.window.move_to(0, 0)
      driver.manage.window.resize_to(1200, 600)
    end
  end

  def resize_screen_to_default
    h = driver.execute_script <<-JS
      if (window.screen) {
        return window.screen.availHeight;
      }
    return 0;
    JS
    if h > 0
      driver.manage.window.move_to(0, 0)
      driver.manage.window.resize_to(1024, h)
    end
  end

  def close_extra_windows
    while driver.window_handles.size > 1
      driver.switch_to.window(driver.window_handles.last)
      driver.close
    end
    driver.switch_to.window(driver.window_handles.first)
    SeleniumDriverSetup.focus_viewport
  end
end
