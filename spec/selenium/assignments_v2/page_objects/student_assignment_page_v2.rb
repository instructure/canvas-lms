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

require_relative '../../common'

class StudentAssignmentPageV2
  class << self
    include SeleniumDependencies

    def visit(course, assignment)
      get "/courses/#{course.id}/assignments/#{assignment.id}/"
    end

    def assignment_locked_image
      f("img[alt='Assignment Locked']")
    end

    def lock_icon
      f("svg[name='IconLock']")
    end

    def submission_workflow_tracker
      f("div[data-testid='submission-workflow-tracker']")
    end

    def assignment_title(title)
      fj("h2 span:contains(#{title})")
    end

    def details_toggle
      f("button[data-test-id='assignments-2-assignment-toggle-details']")
    end

    def assignment_group_link
      f("a[data-testid='assignmentgroup-link']")
    end

    def due_date_css(due_at)
      "time:contains('#{due_at}')"
    end

    def points_possible_css(points_possible)
      "span:contains('#{points_possible}')"
    end

    def content_tablist
      f("div[data-testid='assignment-2-student-content-tabs']")
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

    def comment_text_area
      f('textarea')
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

    def save_text_entry_button
      f("button[data-testid='save-text-entry']")
    end

    def edit_text_entry_button
      f("button[data-testid='edit-text-draft']")
    end

    def text_display_area
      f("div[data-testid='attempt-tab']")
    end

    def text_entry_area
      f('iframe', f('.ic-RichContentEditor'))
    end

    def mce_iframe_id
      f('.mce-container iframe')['id']
    end

    def tiny_rce_ifr_id
      f('.tox-editor-container iframe')['id']
    end

    def wiki_body
      f('#tinymce')
    end

    def text_draft_contents
      in_frame tiny_rce_ifr_id do
        wiki_body.text
      end
    end

    def record_upload_button
      f("button[data-testid='media-modal-launch-button']")
    end

    def media_modal
      f("span[aria-label='Upload Media']")
    end

    def submit_button
      f('#submit-button')
    end

    def leave_a_comment(comment)
      replace_content(comment_text_area, comment)
      send_comment_button.click
    end

    def create_text_entry_draft(text)
      start_text_entry_button.click
      wait_for_tiny(text_entry_area)
      type_in_tiny('textarea', text)
      save_text_entry_button.click
    end

    def create_url_draft(url)
      url_text_box.send_keys(url)
    end

    def submit_assignment
      submit_button.click
    end
  end
end
