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

class AiExperiencesIndexPage
  class << self
    include SeleniumDependencies

    # ---------------------- Page Navigation ----------------------

    def visit_ai_experiences(course_id)
      get "/courses/#{course_id}/ai_experiences"
    end

    def ai_experiences_url(course_id)
      "/courses/#{course_id}/ai_experiences"
    end

    # ---------------------- Selectors ----------------------

    def page_heading_selector
      "h1"
    end

    def create_new_button_selector
      '[data-testid="ai-expriences-index-create-new-button"]'
    end

    def ai_experience_link_selector
      '[data-testid="ai-experiences-index-show-link"]'
    end

    def publish_button_selector
      '[data-testid="ai-experience-publish-toggle"]'
    end

    def options_menu_button_selector
      '[data-testid="ai-experience-menu"]'
    end

    def edit_menu_item_selector
      '[data-testid="ai-experiences-index-edit-menu-item"]'
    end

    def test_conversation_menu_item_selector
      '[data-testid="ai-experiences-index-test-conversation-menu-item"]'
    end

    def delete_menu_item_selector
      '[data-testid="ai-experiences-index-delete-menu-item"]'
    end

    # ---------------------- Page Elements ----------------------

    def page_heading
      f(page_heading_selector)
    end

    def create_new_button
      f(create_new_button_selector)
    end

    def ai_experience_links
      element_exists?(ai_experience_link_selector) ? ff(ai_experience_link_selector) : []
    end

    def ai_experience_link_by_title(title)
      ai_experience_links.find { |link| link.text == title }
    end

    def ai_experience_row(title)
      link = ai_experience_link_by_title(title)
      return nil unless link

      # Navigate up to the row container (View component wrapping the entire row)
      link.find_element(:xpath, "./ancestor::div[@data-testid or contains(@class, 'view')]")
    end

    def publish_buttons
      ff(publish_button_selector)
    end

    def publish_button_for_title(title)
      # Find the index of the experience with this title
      index = ai_experience_links.index { |link| link.text == title }
      return nil unless index

      # Get the corresponding publish button by index
      publish_buttons[index]
    end

    def options_menu_buttons
      ff(options_menu_button_selector)
    end

    def options_menu_button_for_title(title)
      # Find the index of the experience with this title
      index = ai_experience_links.index { |link| link.text == title }
      return nil unless index

      # Get the corresponding options menu button by index
      options_menu_buttons[index]
    end

    def edit_menu_item
      f(edit_menu_item_selector)
    end

    def test_conversation_menu_item
      f(test_conversation_menu_item_selector)
    end

    def delete_menu_item
      f(delete_menu_item_selector)
    end

    def published_status_text_for_title(title)
      link = ai_experience_link_by_title(title)
      return nil unless link

      # Navigate up several levels to find the parent row View component
      row_container = link.find_element(:xpath, "./ancestor::div[contains(@class, 'view')]/ancestor::div[contains(@class, 'view')]")
      # Find all text elements
      all_text = row_container.text
      if all_text.include?("Not published")
        "Not published"
      elsif all_text.include?("Published")
        "Published"
      end
    end

    # ---------------------- Actions ----------------------

    def click_create_new
      create_new_button.click
    end

    def click_ai_experience_title(title)
      link = ai_experience_link_by_title(title)
      link&.click
    end

    def click_publish_button(title)
      button = publish_button_for_title(title)
      return unless button

      button.click
      wait_for_ajaximations
    end

    def click_options_menu(title)
      button = options_menu_button_for_title(title)
      button&.click
      wait_for_ajaximations
    end

    def click_edit_option
      edit_menu_item.click
    end

    def click_test_conversation_option
      test_conversation_menu_item.click
    end

    def click_delete_option
      delete_menu_item.click
    end

    # Combined actions for common workflows
    def edit_ai_experience(title)
      click_options_menu(title)
      click_edit_option
    end

    def delete_ai_experience(title)
      click_options_menu(title)
      click_delete_option
      # Handle confirmation dialog
      driver.switch_to.alert.accept
      wait_for_ajaximations
    end

    def test_ai_experience_conversation(title)
      click_options_menu(title)
      click_test_conversation_option
    end

    # ---------------------- Helper/Query Methods ----------------------

    def ai_experience_exists?(title)
      !ai_experience_link_by_title(title).nil?
    end

    def ai_experience_published?(title)
      status_text = published_status_text_for_title(title)
      return false unless status_text

      status_text.downcase == "published"
    end

    def ai_experience_not_published?(title)
      status_text = published_status_text_for_title(title)
      return false unless status_text

      status_text.downcase.include?("not published")
    end

    def ai_experience_count
      ai_experience_links.length
    end

    def create_new_button_displayed?
      element_exists?(create_new_button_selector)
    end

    delegate :text, to: :page_heading, prefix: true

    def options_menu_displayed?
      !options_menu_buttons.empty?
    end
  end
end
