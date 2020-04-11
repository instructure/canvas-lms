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
    driver.execute_script("window.scrollTo(0, 0)")
  end

  def scroll_page_to_bottom
    driver.execute_script("window.scrollTo(0, document.body.scrollHeight)")
  end

  def resize_screen_to_standard
    driver.manage.window.maximize
  end

  def resize_screen_to_small
    driver.manage.window.resize_to(1200, 600)
  end

  def close_extra_windows
    while driver.window_handles.size > 1
      driver.switch_to.window(driver.window_handles.last)
      driver.close
    end
    driver.switch_to.window(driver.window_handles.first)
  end
end
