# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

class TeacherViewPageV2
  class << self
    include SeleniumDependencies

    # Selectors
    def details_tab
      fj("div[role='tab']:contains('Details')")
    end

    def assignment_tab
      fj("div[role='tab']:contains('Assignment')")
    end

    def peer_review_tab
      fj("div[role='tab']:contains('Peer Review')")
    end

    def assignment_type
      f("#AssignmentType")
    end

    # Methods & Actions
    def visit(course, assignment)
      course.enable_feature!(:assignment_enhancements_teacher_view)
      get "/courses/#{course.id}/assignments/#{assignment.id}"
      wait_for(method: nil, timeout: 1) do
        assignment_type
      end
    end

    def assignment_title(title)
      fj("h1:contains(#{title})")
    end

    def publish_button
      f("button[data-testid='assignment-publish-menu']")
    end

    def publish_status(workflow_state)
      fj("button:contains(#{workflow_state.capitalize})")
    end

    def status_pill
      f("span[data-testid='assignment-status-pill']")
    end

    def edit_button
      f("a[data-testid='edit-button']")
    end

    def assign_to_button
      f("button[data-testid='assign-to-button']")
    end

    def speedgrader_button
      f("a[data-testid='speedgrader-button']")
    end

    def assign_to_tray
      f("div[data-testid='item-assign-to-card']")
    end

    def options_button
      f("button[data-testid='assignment-options-button']")
    end

    def peer_reviews_option
      f("a[data-testid='peer-review-option']")
    end

    def send_to_option
      f("button[data-testid='send-to-option']")
    end

    def send_to_modal
      f("span[data-testid='send-to-modal']")
    end

    def copy_to_option
      f("button[data-testid='copy-to-option']")
    end

    def copy_to_tray
      f("span[data-testid='copy-to-tray']")
    end

    def download_submissions_option
      f("button[data-testid='download-submissions-option']")
    end

    def download_submissions_button
      f("a[data-testid='download_button']")
    end

    def previous_assignment_button
      f("[data-testid='previous-assignment-button']")
    end

    def next_assignment_button
      f("[data-testid='next-assignment-button']")
    end

    def peer_review_allocation_rules_link
      f("a[data-testid='peer-review-allocation-rules-link']")
    end

    def allocation_rules_tray
      fj("h2:contains('Allocation Rules')")
    end

    def allocation_rules_tray_close_button
      f("span[data-testid='allocation-rules-tray-close-button'] button")
    end

    def allocation_rule_cards
      ff("div[data-testid='allocation-rule-card-wrapper']")
    end

    def delete_allocation_rule_button(rule_card)
      f("button[data-testid='delete-allocation-rule-button']", rule_card)
    end

    def delete_error_alert
      f("div[data-testid='delete-error-alert']")
    end

    def add_rule_button
      f("button[data-testid='add-rule-button']")
    end

    def edit_rule_button(rule_card)
      f("button[id^='edit-rule-button-']", rule_card)
    end

    def assignment_description
      f("[data-testid='assignments-2-assignment-description']")
    end

    def create_rule_modal
      f("span[data-testid='create-rule-modal']")
    end

    def edit_rule_modal
      f("span[data-testid='edit-rule-modal']")
    end

    def modal_close_button
      f("span[data-testid='allocation-rule-modal-close-button'] button")
    end

    def target_type_reviewer_radio
      fj("label:contains('Rule for a reviewer')")
    end

    def target_type_reviewee_radio
      fj("label:contains('Rule for recipient of a review')")
    end

    def target_type_reciprocal_radio
      fj("label:contains('Reciprocal review')")
    end

    def target_select_input
      f("input#target-select")
    end

    def subject_select_input
      f("input#subject-select-main")
    end

    def review_type_must_review_radio
      fj("label:contains('Must review')")
    end

    def review_type_must_not_review_radio
      fj("label:contains('Must not review')")
    end

    def review_type_should_review_radio
      fj("label:contains('Should review')")
    end

    def review_type_should_not_review_radio
      fj("label:contains('Should not review')")
    end

    def add_subject_button
      f("button[data-testid='add-subject-button']")
    end

    def modal_save_button
      f("button[data-testid='save-button']")
    end

    def modal_cancel_button
      f("button[data-testid='cancel-button']")
    end

    def select_student_option(student_name)
      fj("span[role='option']:contains('#{student_name}')")
    end

    def delete_additional_subject_field_button(key)
      f("button[data-testid='delete-additional-subject-field-#{key}-button']")
    end

    def additional_subject_select_input(key)
      f("input#subject-select-#{key}")
    end

    def validation_error_message
      fj("span:contains('is required')")
    end

    def create_error_alert
      fj("div:contains('An error occurred while creating the rule')")
    end

    def edit_error_alert
      fj("div:contains('An error occurred while editing the rule')")
    end

    def student_search_error_alert
      fj("div:contains('An error occurred while searching for')")
    end

    def allocation_rules_search_input
      f("input[data-testid='allocation-rules-search-input']")
    end

    def clear_search_button
      f("button[data-testid='clear-search-button']")
    end

    def no_search_results_message
      f("div[data-testid='no-search-results']")
    end

    def pagination_button(page_text)
      pagination_nav = f("nav[data-testid='allocation-rules-pagination']")
      fj("button:contains('#{page_text}')", pagination_nav)
    end

    def allocation_rules_loading_spinner
      f("span[data-testid='allocation-rules-loading-spinner']")
    end

    def fetch_rules_error_alert
      f("div[data-testid='fetch-rules-error-alert']")
    end

    def wait_for_spinner(&)
      wait_for_transient_element('svg[role="img"] circle', &)
      wait_for_ajaximations
    end

    def peer_review_status_hint
      f("div[data-testid='peer-review-status-hint']")
    end

    def peer_review_status_hints
      ff("div[data-testid='peer-review-status-hint']")
    end
  end
end
