#
# Copyright (C) 2017 - present Instructure, Inc.
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

class AnnouncementIndex
  class << self
    include SeleniumDependencies

    # ---------------------- Page ----------------------
    def visit(course)
      get("/courses/#{course.id}/announcements/")
      wait_for_ajaximations
    end

    def visit_groups_index(group)
      get("/groups/#{group.id}/announcements/")
      wait_for_ajaximations
    end

    def new_announcement_url
      '/discussion_topics/new?is_announcement=true'
    end

    def individual_announcement_url(announcement)
      "/discussion_topics/#{announcement.id}"
    end

    # ---------------------- Controls ----------------------
    def filter_dropdown
      fj('select[name="filter-dropdown"]')
    end

    def filter_item(item_name)
      fj("option:contains(\"#{item_name}\")")
    end

    def search_box
      f('input[name="announcements_search"]')
    end

    def lock_button
      f('#lock_announcements')
    end

    def delete_button
      f('#delete_announcements')
    end

    def confirm_delete_button
      f('#confirm_delete_announcements')
    end

    def add_announcement_button
      f('#add_announcement')
    end

    def open_external_feeds
      f('#external_feed').click
    end

    # ---------------------- Announcement ----------------------
    # def announcement_titles
    #   announcements = ff(".discussion_topic")
    #   announcements.map! { |x| f(".discussion-title", x).text }
    # end

    def announcement(title)
      fj(".ic-announcement-row:contains('#{title}')")
    end

    def announcement_title_css(title)
      ".ic-announcement-row:contains('#{title}')"
    end

    def announcement_title(title)
      f('h3', announcement(title))
    end

    def announcement_checkbox(title)
      f('input[type="checkbox"] + label', announcement(title))
    end

    def announcement_sections(title)
      # section_elements = ff('#sections', announcement(title))
      # section_elements.map(&:text)
    end

    def announcement_unread_pill(title)
      f('.ic-unread-badge__unread-count', announcement(title))
    end

    def announcement_unread_number(title)
      announcement_unread_pill(title).text
    end

    def announcement_menu(title)
      f('.ic-item-row__manage-menu button', announcement(title))
    end

    def delete_menu
      f('#delete-announcement-menu-option')
    end

    def lock_menu
      f('#lock-announcement-menu-option')
    end

    def announcement_locked_icon(title)
      # f('.lock', announcement(title))
    end

    # ---------------------- Actions ----------------------
    def select_filter(filter_name)
      filter_dropdown.click
      filter_item(filter_name).click
    end

    def enter_search(title)
      set_value(search_box, title)
      driver.action.send_keys(:enter).perform
      wait_for_ajaximations
    end

    def check_announcement(title)
      announcement_checkbox(title).click
    end

    def toggle_lock
      lock_button.click
      wait_for_ajaximations
    end

    def click_delete
      delete_button.click
    end

    def click_delete_menu(title)
      announcement_menu(title).click
      delete_menu.click
    end

    def click_lock_menu(title)
      announcement_menu(title).click
      lock_menu.click
    end

    def click_confirm_delete
      confirm_delete_button.click
    end

    def click_on_announcement(title)
      announcement_title(title).click
    end

    def click_add_announcement
       add_announcement_button.click
    end

    def delete_announcement_manually(title)
      check_announcement(title)
      click_delete
      click_confirm_delete
    end
  end
end
