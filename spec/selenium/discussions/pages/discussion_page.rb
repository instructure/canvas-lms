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
  end
end
