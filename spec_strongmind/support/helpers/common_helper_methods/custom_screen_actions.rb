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

module CustomScreenActions
  def scroll_page_to_top
    execute_script("window.scrollTo(0, 0)")
  end

  def scroll_page_to_bottom
    execute_script("window.scrollTo(0, document.body.scrollHeight)")
  end

  def make_full_screen
    w, h = execute_script <<-JS
      if (window.screen) {
        return [ window.screen.availWidth, window.screen.availHeight ];
      }
      return [ 0, 0 ];
    JS

    if w > 0 && h > 0
      page.driver.manage.window.move_to(0, 0)
      page.driver.manage.window.resize_to(w, h)
    end
  end

  def resize_screen_to_normal
    w, h = execute_script <<-JS
        if (window.screen) {
          return [window.screen.availWidth, window.screen.availHeight];
        }
    JS
    if w != 1200 || h != 600
      page.driver.manage.window.move_to(0, 0)
      page.driver.manage.window.resize_to(1200, 600)
    end
  end

  def resize_screen_to_default
    h = execute_script <<-JS
      if (window.screen) {
        return window.screen.availHeight;
      }
    return 0;
    JS
    if h > 0
      page.driver.manage.window.move_to(0, 0)
      page.driver.manage.window.resize_to(1024, h)
    end
  end

  def close_extra_windows
    while page.driver.window_handles.size > 1
      page.driver.switch_to.window(page.driver.window_handles.last)
      page.driver.close
    end
    page.driver.switch_to.window(page.driver.window_handles.first)
    SeleniumDriverSetup.focus_viewport
  end
end
