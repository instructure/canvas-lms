# frozen_string_literal: true

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
require_relative "../../common"

class Discussion
  class << self
    include SeleniumDependencies

    # ---------------------- Selectors ---------------------
    def course_pacing_notice_selector
      "[data-testid='CoursePacingNotice']"
    end

    def assign_to_button_selector
      "button[data-testid='manage-assign-to']"
    end

    def grade_checkbox_selector
      "input[type=checkbox][value='graded']"
    end

    def topic_input_selector
      "input[placeholder='Topic Title']"
    end

    def points_possible_input_selector
      "input[data-testid='points-possible-input']"
    end

    def save_and_publish_button_selector
      "button[data-testid='save-and-publish-button']"
    end

    def save_selector
      "[data-testid='save-button']"
    end

    def section_warning_continue_selector
      "button[data-testid='continue-button']"
    end
    # ---------------------- Elements ----------------------

    def discussion_page_body
      f("body")
    end

    def create_reply_button
      f(".discussion-reply-box")
    end

    def post_reply_button
      fj('button:contains("Post Reply")')
    end

    def add_media_button
      f(".mce-i-media")
    end

    def close_media_modal_button
      f(".mce-close")
    end

    def media_modal
      fj('div:contains("Insert/edit media")')
    end

    def manage_discussion_button
      fj("[role='button']:contains('Manage Discussion')")
    end

    def send_to_menuitem
      fj("li:contains('Send To...')")
    end

    def copy_to_menuitem
      fj("li:contains('Copy To...')")
    end

    def course_pacing_notice
      f(course_pacing_notice_selector)
    end

    def assign_to_button
      f(assign_to_button_selector)
    end
    # ---------------------- Actions ----------------------

    def topic_title_input
      f(topic_input_selector)
    end

    def points_possible_input
      f(points_possible_input_selector)
    end

    def save_and_publish_button
      f(save_and_publish_button_selector)
    end

    def save_button
      f(save_selector)
    end

    def section_warning_continue_button
      f(section_warning_continue_selector)
    end

    # ---------------------- Actions ----------------------
    def visit(course, discussion)
      get("/courses/#{course.id}/discussion_topics/#{discussion.id}")
      wait_for_ajaximations
      # if already visited and scrolled down, can cause flakey
      # failures if not scrolled back up
      scroll_page_to_top
    end

    def start_reply_with_media
      create_reply_button.click
      add_media_button.click
    end

    def click_assign_to_button
      assign_to_button.click
    end

    def start_new_discussion(course_id)
      get "/courses/#{course_id}/discussion_topics/new"
    end

    def update_discussion_topic_title(title = "Default Discussion Title")
      topic_title_input.send_keys title
    end

    def update_discussion_message(message = "Default Discussion Message")
      type_in_tiny("textarea", message)
    end
  end
end
