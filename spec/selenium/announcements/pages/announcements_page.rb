#
# Copyright (C) 2018 - present Instructure, Inc.
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

require_relative '../../common'

module AnnouncementPageObject

  #---------------------------- Selectors ---------------------------


  #---------------------------- Elements ----------------------------
  def announcement(title)
    fj(".ic-announcement-row:contains('#{title}')")
  end

  def announcement_options_menu(title)
    f('.ic-item-row__manage-menu button', announcement(title))
  end

  def delete_announcement_option
    f('#delete-announcement-menu-option')
  end

  def confirm_delete_alert
    f('button#confirm_delete_announcements')
  end

  def announcements_main_content
    f('.announcements-v2__wrapper')
  end

  #------------------------ Actions & Methods ------------------------

  def visit_announcements(course_id)
    get "/courses/#{course_id}/announcements"
    begin
      f("[id*=Spinner]", announcements_main_content)
    rescue Selenium::WebDriver::Error::NoSuchElementError
    rescue SpecTimeLimit::Error
    end
    expect(announcements_main_content).not_to contain_jqcss("title:contains('Loading Announcements')")
  end
end
