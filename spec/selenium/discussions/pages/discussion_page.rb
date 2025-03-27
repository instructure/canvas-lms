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

    def assignee_selector_selector
      "[data-testid='assignee_selector']"
    end

    def assign_to_button_selector
      "button[data-testid='manage-assign-to']"
    end

    def assign_to_card_selector
      "[data-testid='item-assign-to-card']"
    end

    def assign_to_section_selector
      "#manage-assign-to-container"
    end

    def grade_checkbox_selector
      "input[type=checkbox][value='graded']"
    end

    def checkpoints_checkbox_selector
      "input[data-testid='checkpoints-checkbox']"
    end

    def topic_input_selector
      "input[placeholder='Topic Title']"
    end

    def pending_changes_pill_selector
      "[data-testid='pending_changes_pill']"
    end

    def points_possible_input_selector
      "input[data-testid='points-possible-input']"
    end

    def reply_to_topic_points_possible_input_selector
      "input[data-testid='points-possible-input-reply-to-topic']"
    end

    def reply_to_entry_required_count_input_selector
      "input[data-testid='reply-to-entry-required-count']"
    end

    def points_possible_reply_to_entry_input_selector
      "input[data-testid='points-possible-input-reply-to-entry']"
    end

    def save_and_publish_button_selector
      "button[data-testid='save-and-publish-button']"
    end

    def save_selector
      "[data-testid='save-button']"
    end

    def select_date_selector
      "input[placeholder='Select Date']"
    end

    def section_warning_continue_selector
      "button[data-testid='continue-button']"
    end

    def section_selection_selector
      "input[data-testid='section-select']"
    end

    def summarize_button_selector
      "[data-testid='summarize-button']"
    end

    def summary_text_selector
      "[data-testid='summary-text']"
    end

    def summary_error_selector
      "[data-testid='summary-error']"
    end

    def summary_like_button_selector
      "[data-testid='summary-like-button']"
    end

    def summary_dislike_button_selector
      "[data-testid='summary-dislike-button']"
    end

    def summary_generate_button_selector
      "[data-testid='summary-generate-button']"
    end

    def summary_user_input_selector
      "[data-testid='summary-user-input']"
    end

    def sync_to_sis_checkbox_selector
      "input[type=checkbox][value='post_to_sis']"
    end

    def group_discussion_checkbox_selector
      "input[type=checkbox][value='group-discussion']"
    end

    def group_category_select_selector
      "input[placeholder='Select a group category']"
    end

    def group_category_option_selector(group_cat_name)
      "li:contains('#{group_cat_name}')"
    end

    # ---------------------- Elements ----------------------
    def assignee_selector
      ff(assignee_selector_selector)
    end

    def assign_to_card
      f(assign_to_card_selector)
    end

    def discussion_page_body
      f("body")
    end

    def create_reply_button
      f(".discussion-reply-box")
    end

    def graded_checkbox
      f(grade_checkbox_selector)
    end

    def checkpoints_checkbox
      f(checkpoints_checkbox_selector)
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

    def summarize_button
      f(summarize_button_selector)
    end

    def summary_text
      f(summary_text_selector)
    end

    def summary_error
      f(summary_error_selector)
    end

    def summary_like_button
      f(summary_like_button_selector)
    end

    def summary_dislike_button
      f(summary_dislike_button_selector)
    end

    def summary_generate_button
      f(summary_generate_button_selector)
    end

    def summary_user_input
      f(summary_user_input_selector)
    end

    def sync_to_sis_checkbox
      f(sync_to_sis_checkbox_selector)
    end

    def mastery_path_toggle
      f("[data-testid='MasteryPathToggle'] svg[name='IconCheck'], [data-testid='MasteryPathToggle'] svg[name='IconX']")
    end

    # ---------------------- Actions ----------------------

    def topic_title_input
      f(topic_input_selector)
    end

    def points_possible_input
      f(points_possible_input_selector)
    end

    def reply_to_topic_points_possible_input
      f(reply_to_topic_points_possible_input_selector)
    end

    def reply_to_entry_required_count_input
      f(reply_to_entry_required_count_input_selector)
    end

    def points_possible_reply_to_entry_input
      f(points_possible_reply_to_entry_input_selector)
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

    def group_category_option(group_cat_name)
      fj(group_category_option_selector(group_cat_name))
    end

    def save_discussion
      f("button[type='submit']").click
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

    def click_graded_checkbox
      force_click_native(grade_checkbox_selector)
    end

    def click_checkpoints_checkbox
      force_click_native(checkpoints_checkbox_selector)
    end

    def click_summarize_button
      summarize_button.click
    end

    def click_summary_like_button
      summary_like_button.click
    end

    def click_summary_dislike_button
      summary_dislike_button.click
    end

    def click_summary_generate_button
      summary_generate_button.click
    end

    def click_sync_to_sis_checkbox
      force_click_native(sync_to_sis_checkbox_selector)
    end

    def click_group_discussion_checkbox
      force_click_native(group_discussion_checkbox_selector)
    end

    def click_group_category_select
      force_click_native(group_category_select_selector)
    end

    def click_group_category_option(group_cat_name)
      group_category_option(group_cat_name).click
    end

    def update_summary_user_input(user_input)
      summary_user_input.send_keys(user_input)
    end

    def pending_changes_pill_exists?
      element_exists?(pending_changes_pill_selector)
    end

    def select_date_input_exists?
      element_exists?(select_date_selector)
    end

    def section_selection_input_exists?
      element_exists?(section_selection_selector)
    end

    def start_new_discussion(course_id)
      get "/courses/#{course_id}/discussion_topics/new"
    end

    def update_discussion_topic_title(title = "Default Discussion Title")
      topic_title_input.send_keys([:control, "a"], :backspace)
      topic_title_input.send_keys title
    end

    def update_discussion_message(message = "Default Discussion Message")
      type_in_tiny("textarea", message)
    end
  end
end
