# frozen_string_literal: true

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

require_relative "../../common"

class AnnouncementNewEdit
  class << self
    include SeleniumDependencies

    def visit_new(context)
      context_type = context.is_a?(Course) ? "courses" : "groups"
      get("/#{context_type}/#{context.id}/discussion_topics/new?is_announcement=true")
      wait_for_tiny(f("textarea[name=message]"))
    end

    def new_announcement_url
      "/discussion_topics/new?is_announcement=true"
    end

    def individual_announcement_url(announcement)
      "/discussion_topics/#{announcement.id}"
    end

    def full_individual_announcement_url(context, announcement)
      context_type = context.is_a?(Course) ? "courses" : "groups"
      "/#{context_type}/#{context.id}/discussion_topics/#{announcement.id}"
    end

    # -------------------- discussion_create + react_discussions_post flag elements -----------------

    def available_from_reset_button
      f("button[data-testid=reset-available-from-button]")
    end

    def available_until_reset_button
      f("button[data-testid=reset-available-until-button]")
    end

    def submit_button
      f("button[data-testid=announcement-submit-button]")
    end

    def publish_button
      fj("button:contains('Publish')")
    end

    def save_button
      fj("button:contains('Save')")
    end

    def notification_modal
      f('form[data-testid="send-notification-modal"]')
    end

    def notification_modal_send
      f("button[data-testid='send']", notification_modal)
    end

    def notification_modal_dont_send
      f("button[data-testid='no_send']", notification_modal)
    end

    def notification_modal_cancel
      f("button[data-testid='cancel']", notification_modal)
    end

    # ---------------------- Controls ----------------------
    def section_autocomplete_css
      "#sections_autocomplete_root input[type='text']"
    end

    def submit_announcement_form
      wait_for_new_page_load { submit_form(".form-actions") }
    end

    # NOTE: This *appends* to the existing content in the text area
    def add_message(message)
      type_in_tiny("textarea[name=message]", message)
    end

    def add_title(title)
      replace_content(f("input[name=title]"), title)
    end

    def section_error
      f("#sections_autocomplete_root").text
    end

    def select_a_section(section_name)
      fj(section_autocomplete_css).click
      if section_name.empty?
        driver.action.send_keys(:backspace).perform
      else
        set_value(fj(section_autocomplete_css), section_name)
        driver.action.send_keys(:enter).perform
      end
      wait_for_ajax_requests
    end

    def create_group_announcement(group, title, text)
      visit_new(group)
      replace_content(f("input[name=title]"), title)
      type_in_tiny("textarea[name=message]", text)
      submit_announcement_form
    end

    def edit_group_announcement(group, announcement, message)
      url_base = full_individual_announcement_url(group, announcement)
      get "#{url_base}/edit"
      wait_for_tiny(f("textarea[name=message]"))
      # Note that add_message *appends* to existing
      add_message(message)
      submit_announcement_form
    end
  end
end
