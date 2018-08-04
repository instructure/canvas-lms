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
require_relative '../../common'

class DiscussionsIndex
  class << self
    include SeleniumDependencies

    # ---------------------- Page ----------------------
    def visit(course)
      get("/courses/#{course.id}/discussion_topics/")
      wait_for_ajaximations
    end

    def new_discussion_url
      '/discussion_topics/new'
    end

    def individual_discussion_url(discussion)
      context_type = discussion.context.is_a?(Course) ? "courses" : "groups"
      context_id = discussion.context.id
      "/#{context_type}/#{context_id}/discussion_topics/#{discussion.id}"
    end

    # ---------------------- Controls ----------------------
    def filter_dropdown
      f('select[name="filter-dropdown"]')
    end

    def filter_item(item_name)
      fj("option:contains(\"#{item_name}\")")
    end

    def search_box
      f('input[name="discussion_search"]')
    end

    def add_discussion_button
      f('#add_discussion')
    end

    def confirm_delete_button
      f('#confirm_delete_discussion')
    end

    def discussion_css(title)
      "a:contains(#{title})"
    end

    def discussions_list
      ff('.ic-item-row')
    end

    def discussion_group(group_name)
      fj("div:contains('#{group_name}')")
    end

    # ---------------------- Discussion ----------------------
    def discussion(title)
      fj(discussion_title_css(title))
    end

    def discussion_title_css(title)
      ".ic-discussion-row:contains('#{title}')"
    end

    def discussion_title(title)
      f('a', discussion(title))
    end

    def discussion_sections(title)
      # section_elements = ff('#sections', discussion(title))
      # section_elements.map(&:text)
    end

    def discussion_unread_pill(title)
      f('.ic-unread-badge__unread-count', discussion(title)).text
    end

    def discussion_unread_number(title)
      discussion_unread_pill(title).text
    end

    def publish_button(title)
      f('.publish-button', discussion(title))
    end

    def subscribe_button(title)
      f('.subscribe-button', discussion(title))
    end

    def discussion_availability(title)
      f('.discussion-availability', discussion(title))
    end

    # ---------------------- Discussion Menu ----------------------
    def discussion_menu(title)
      f('.discussions-index-manage-menu button', discussion(title))
    end

    def discussion_settings_button
      f('#discussion_settings')
    end

    def delete_menu_option
      f('#delete-discussion-menu-option')
    end

    def confirm_delete_modal_button
      f('#confirm_delete_discussions')
    end

    def pin_menu_option
      f('#togglepinned-discussion-menu-option')
    end

    def summary_content
      f('.ic-announcement-row__content')
    end

    def close_for_comment_menu_option
      f('#togglelocked-discussion-menu-option')
    end

    def duplicate_menu_option
      f('#duplicate-discussion-menu-option')
    end

    def create_discussions_checkbox
      fj("label:contains('Create discussion')")
    end

    def discussion_settings_submit_button
      f('#submit_discussion_settings')
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

    def click_delete_menu_option(title)
      discussion_menu(title).click
      delete_menu_option.click
    end

    def click_delete_modal_confirm
      confirm_delete_modal_button.click
    end

    def click_pin_menu_option(title)
      discussion_menu(title).click
      pin_menu_option.click
    end

    def click_close_for_comments_menu_option(title)
      discussion_menu(title).click
      close_for_comment_menu_option.click
    end

    def click_duplicate_menu_option(title)
      discussion_menu(title).click
      duplicate_menu_option.click
    end

    def click_confirm_delete
      confirm_delete_button.click
    end

    def click_on_discussion(title)
      discussion_title(title).click
    end

    def click_discussion_settings_button
      discussion_settings_button.click
      wait_for_ajax_requests
    end

    def click_create_discussions_checkbox
      create_discussions_checkbox.click
    end

    def submit_discussion_settings
      discussion_settings_submit_button.click
    end

    def click_add_discussion
       add_discussion_button.click
    end

    def click_publish_button(title)
      publish_button(title).click
    end

    def click_subscribe_button(title)
      subscribe_button(title).click
    end
  end
end
