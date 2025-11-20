# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

class AiExperiencesFormPage
  class << self
    include SeleniumDependencies

    # ---------------------- Page Navigation ----------------------

    def visit_new_ai_experience(course_id)
      get "/courses/#{course_id}/ai_experiences/new"
    end

    def visit_edit_ai_experience(course_id, experience_id)
      get "/courses/#{course_id}/ai_experiences/#{experience_id}/edit"
    end

    def new_ai_experience_url(course_id)
      "/courses/#{course_id}/ai_experiences/new"
    end

    def edit_ai_experience_url(course_id, experience_id)
      "/courses/#{course_id}/ai_experiences/#{experience_id}/edit"
    end

    # ---------------------- Selectors ----------------------

    def page_heading_selector
      "h1"
    end

    def title_input_selector
      '[data-testid="ai-experience-edit-title-input"]'
    end

    def description_textarea_selector
      '[data-testid="ai-experience-edit-description-input"]'
    end

    def facts_textarea_selector
      '[data-testid="ai-experience-edit-facts-input"]'
    end

    def learning_objective_textarea_selector
      '[data-testid="ai-experience-edit-learning-objective-input"]'
    end

    def pedagogical_guidance_textarea_selector
      '[data-testid="ai-experience-edit-pedagogical-guidance-input"]'
    end

    def cancel_button_selector
      '[data-testid="ai-experience-edit-cancel-button"]'
    end

    def save_as_draft_button_selector
      '[data-testid="ai-experience-save-as-draft-item"]'
    end

    def preview_menu_item_selector
      '[data-testid="ai-experience-edit-preview-item"]'
    end

    def options_menu_button_selector
      'button:contains("More options")'
    end

    def delete_menu_item_selector
      '[data-testid="ai-experience-edit-delete-menu-item"]'
    end

    def confirm_preview_button_selector
      '[data-testid="ai-experience-edit-confirm-preview-confirmation-button"]'
    end

    def cancel_preview_button_selector
      '[data-testid="ai-experience-edit-cancel-preview-confirmation-button"]'
    end

    def confirm_delete_button_selector
      '[data-testid="ai-experience-edit-confirm-delete-confirm-button"]'
    end

    def cancel_delete_button_selector
      '[data-testid="ai-experience-edit-cancel-delete-confirm-button"]'
    end

    # ---------------------- Page Elements ----------------------

    def page_heading
      f(page_heading_selector)
    end

    def title_input
      f(title_input_selector)
    end

    def description_textarea
      f(description_textarea_selector)
    end

    def facts_textarea
      f(facts_textarea_selector)
    end

    def learning_objective_textarea
      f(learning_objective_textarea_selector)
    end

    def pedagogical_guidance_textarea
      f(pedagogical_guidance_textarea_selector)
    end

    def cancel_button
      f(cancel_button_selector)
    end

    def save_as_draft_button
      f(save_as_draft_button_selector)
    end

    def preview_menu_item
      f(preview_menu_item_selector)
    end

    def options_menu_button
      fj(options_menu_button_selector)
    end

    def delete_menu_item
      f(delete_menu_item_selector)
    end

    def confirm_preview_button
      f(confirm_preview_button_selector)
    end

    def cancel_preview_button
      f(cancel_preview_button_selector)
    end

    def confirm_delete_button
      f(confirm_delete_button_selector)
    end

    def cancel_delete_button
      f(cancel_delete_button_selector)
    end

    # ---------------------- Actions ----------------------

    def fill_title(text)
      replace_content(title_input, text)
    end

    def fill_description(text)
      replace_content(description_textarea, text)
    end

    def fill_facts(text)
      replace_content(facts_textarea, text)
    end

    def fill_learning_objective(text)
      replace_content(learning_objective_textarea, text)
    end

    def fill_pedagogical_guidance(text)
      replace_content(pedagogical_guidance_textarea, text)
    end

    def fill_form(title:, description: "", facts: "", learning_objective:, pedagogical_guidance:)
      fill_title(title)
      fill_description(description) unless description.empty?
      fill_facts(facts) unless facts.empty?
      fill_learning_objective(learning_objective)
      fill_pedagogical_guidance(pedagogical_guidance)
    end

    def click_save_as_draft
      save_as_draft_button.click
      wait_for_ajaximations
    end

    def click_cancel
      cancel_button.click
    end

    def click_preview
      preview_menu_item.click
    end

    def click_delete
      # First click the options menu button to open the menu
      options_menu_button.click
      wait_for_ajaximations
      # Then click the delete menu item
      delete_menu_item.click
      wait_for_ajaximations
    end

    def confirm_preview
      confirm_preview_button.click
      wait_for_ajaximations
    end

    def cancel_preview
      cancel_preview_button.click
      wait_for_ajaximations
    end

    def confirm_delete
      confirm_delete_button.click
      wait_for_ajaximations
    end

    def cancel_delete
      cancel_delete_button.click
      wait_for_ajaximations
    end

    # ---------------------- Helper/Query Methods ----------------------

    delegate :text, to: :page_heading, prefix: true

    def title_value
      title_input.attribute("value")
    end

    def description_value
      description_textarea.text
    end

    def facts_value
      facts_textarea.text
    end

    def learning_objective_value
      learning_objective_textarea.text
    end

    def pedagogical_guidance_value
      pedagogical_guidance_textarea.text
    end

    def form_has_error?
      element_exists?('[role="alert"]')
    end

    def get_field_error(field_selector)
      field = f(field_selector)
      error_element = field.find_element(:xpath, "./following-sibling::span[contains(@class, 'error')]")
      error_element&.text
    end

    def save_button_disabled?
      save_as_draft_button.attribute("disabled") == "true"
    end
  end
end
