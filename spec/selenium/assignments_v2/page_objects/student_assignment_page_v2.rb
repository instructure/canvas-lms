# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

class StudentAssignmentPageV2
  class << self
    include SeleniumDependencies

    def visit(course, assignment)
      get "/courses/#{course.id}/assignments/#{assignment.id}/"
    end

    def assignment_locked_image
      f("img[alt='Assignment Locked']")
    end

    def assignment_future_locked_image
      f("img[alt='Assignment locked until future date']")
    end

    def assignment_prerequisite_locked_image
      f("img[alt='Assignment Locked with Prerequisite']")
    end

    def attempt_dropdown
      f("input[data-testid='attemptSelect']")
    end

    def attempt_tab
      f("div[data-testid='attempt-tab']")
    end

    def file_input
      f('input[data-testid="input-file-drop"]')
    end

    def uploaded_files_table
      f('table[data-testid="uploaded_files_table"]')
    end

    def lock_icon
      f("svg[name='IconLock']")
    end

    def submission_workflow_tracker
      f("div[data-testid='submission-workflow-tracker']")
    end

    def assignment_title(title)
      fj("h1 span:contains(#{title})")
    end

    def details_toggle
      f("button[data-testid='assignments-2-assignment-toggle-details']")
    end

    def assignment_group_link
      f("a[data-testid='assignmentgroup-link']")
    end

    def modules_link
      f("a[data-testid='modules-link']")
    end

    def due_date_css(due_at)
      "time:contains('#{due_at}')"
    end

    def points_possible_css(points_possible)
      "span:contains('#{points_possible}')"
    end

    def comment_container
      f("div[data-testid='comments-container']")
    end

    def send_comment_button
      fj('button:contains("Send Comment")')
    end

    def view_feedback_button
      fj('button:contains("View Feedback")')
    end

    def view_feedback_badge
      f('div[data-testid="unread_comments_badge"]')
    end

    def tray_close_button
      f("span[data-testid='tray-close-button']")
    end

    def load_more_comments_button
      f("div[class='load-more-comments-button-container']")
    end

    def comment_text_area
      f("textarea")
    end

    def url_text_box
      f("input[type='url']")
    end

    def url_submission_link
      f("span[data-testid='url-submission-text")
    end

    def start_text_entry_button
      f("button[data-testid='start-text-entry']")
    end

    def edit_text_entry_button
      f("button[data-testid='edit-text-draft']")
    end

    def text_display_area
      text_entry_area
    end

    def text_entry_area
      f('[data-testid="text-editor"]')
    end

    def text_entry_text
      driver.execute_script(
        "return document.querySelector('iframe.tox-edit-area__iframe').contentDocument.body.textContent"
      )
    end

    def student_footer
      f('[data-testid="student-footer"]')
    end

    def mce_iframe_id
      f(".mce-container iframe")["id"]
    end

    def tiny_rce_ifr_id
      f(".tox-editor-container iframe")["id"]
    end

    def text_draft_contents
      in_frame tiny_rce_ifr_id do
        wiki_body.text
      end
    end

    def open_record_media_modal_button
      f("button[data-testid='open-record-media-modal-button']")
    end

    def open_upload_media_modal_button
      f("button[data-testid='open-upload-media-modal-button']")
    end

    def record_media_modal_panel
      fxpath("//div[@role='tab' and contains(text(),'Record')]")
    end

    def upload_media_modal_panel
      fxpath("//div[@role='tab' and contains(text(),'Computer')]")
    end

    def media_comment_button
      f("button[id='mediaCommentButton']")
    end

    def media_modal
      f("span[aria-label='Upload Media']")
    end

    def mark_as_done_toggle
      f("button[data-testid='set-module-item-completion-button']")
    end

    def missing_pill
      f("span[data-testid='missing-pill']")
    end

    def late_pill
      f("span[data-testid='late-pill']")
    end

    def rubric_toggle
      f("div[data-testid='rubric-tab']")
    end

    def similarity_pledge_checkbox
      f("input[data-testid='similarity-pledge-checkbox']")
    end

    def similarity_pledge
      f("div[data-testid='similarity-pledge']")
    end

    def submit_button
      f("#submit-button")
    end

    def submit_button_enabled
      f("#submit-button:not([disabled]")
    end

    def text_entry_submission_button
      f("div[data-testid='online_text_entry']")
    end

    def new_attempt_button
      f("button[data-testid='new-attempt-button']")
    end

    def cancel_attempt_button
      f("button[data-testid='cancel-attempt-button']")
    end

    def back_to_attempt_button
      f("button[data-testid='back-to-attempt-button']")
    end

    def footer
      f("div[data-testid='student-footer']")
    end

    def leave_a_comment(comment)
      replace_content(comment_text_area, comment)
      send_comment_button.click
    end

    def create_text_entry_draft(text)
      type_in_tiny("textarea", text)
    end

    def create_url_draft(url)
      url_text_box.send_keys(url)
    end

    def submit_assignment
      submit_button.click
    end

    def assignment_sub_header
      f('[data-testid="assignment-sub-header"]')
    end

    def peer_review_next_button
      f('[data-testid="peer-review-next-button"]')
    end

    def peer_review_close_button
      f('[data-testid="peer-review-close-button"]')
    end

    def peer_review_sub_header_text
      f('[data-testid="peer-review-sub-header-text"]').text
    end

    def peer_review_header_text
      f('[data-testid="peer-review-header-text"]').text
    end

    def fill_out_rubric_toggle
      f('[data-testid="fill-out-rubric-toggle"]')
    end

    def rubric_tab
      f('[data-testid="rubric-tab"]')
    end

    def select_rubric_criterion(criterion)
      ff(".rating-description").find { |elt| elt.displayed? && elt.text == criterion }.click
    end

    def submit_peer_review_button
      f('[data-testid="submit-peer-review-button"]')
    end

    def select_grader(grader)
      click_INSTUI_Select_option(f('[data-testid="select-grader-dropdown"]'), grader)
    end

    def rubric_comments
      f(".rubric-freeform")
    end

    def rubric_rating_selected
      f(".rating-tier.selected")
    end

    def peer_review_need_submission_reminder
      f("h4[data-testid='assignments-2-need-submission-pr-label-1']")
    end

    def peer_review_unavailible_reminder
      f("h4[data-testid='assignments-2-unavailable-pr-label-1']")
    end
  end
end
