# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

class ConditionalReleaseObjects
  class << self
    include SeleniumDependencies

    # Page edit
    def conditional_content_exists?
      element_exists?("#conditional_content")
    end

    # Assignment Index Page

    def assignment_kebob(page_title)
      fxpath("//button[.//*[text() = 'Settings for Assignment #{page_title}']]")
    end

    def edit_assignment(page_title)
      fxpath("//a[@aria-label='Edit Assignment #{page_title}']")
    end

    def due_at_exists?
      element_exists?("//*[contains(@class,'ui-dialog')]//input[@name='due_at']", true)
    end

    def points_possible_exists?
      element_exists?("//*[contains(@class,'ui-dialog')]//input[@name='points_possible']", true)
    end

    # Quizzes Page
    def quiz_conditional_release_link
      fxpath("//a[@href = '#mastery-paths-editor']")
    end

    def cr_editor_exists?
      element_exists?("#canvas-conditional-release-editor")
    end

    def disabled_cr_editor_exists?
      element_exists?("//li[@aria-disabled = 'true']/a[@href = '#mastery-paths-editor']", true)
    end

    # Assignment Edit
    def scoring_ranges
      ff(".cr-scoring-range")
    end

    def top_scoring_boundary
      f("[title='Top Bound']")
    end

    def lower_bound
      f("[title='Lower Bound']")
    end

    def division_cutoff1
      f("[title='Division cutoff 1']")
    end

    def division_cutoff2
      f("[title='Division cutoff 2']")
    end

    def must_not_be_empty_exists?
      element_exists?("//*[contains(@id,'error') and contains(text(),'must not be empty')]", true)
    end

    def these_scores_are_out_of_order_exists?
      element_exists?("//*[contains(@id,'error') and contains(text(),'these scores are out of order')]", true)
    end

    def must_be_a_number_exists?
      element_exists?("//*[contains(@id,'error') and contains(text(),'must be a number')]", true)
    end

    def number_is_too_small_exists?
      element_exists?("//*[contains(@id,'error') and contains(text(),'number is too small')]", true)
    end

    # Common Selectors
    def conditional_release_link
      f("#conditional_release_link")
    end

    def conditional_release_editor_exists?
      element_exists?("#canvas-conditional-release-editor")
    end

    def save_button
      f(".assignment__action-buttons .btn-primary")
    end

    def breakdown_graph_exists?
      element_exists?(".crs-breakdown-graph")
    end

    def last_add_assignment_button
      ff('.cr-scoring-range__add-assignment-button').last
    end

    def mp_assignment_checkbox(assignment_name)
      fxpath("//li[contains(@aria-label, 'assignment category icon for item name #{assignment_name}')]/label[@class = 'cr-label__cbox']")
    end

    def add_items_button
      find_button('Add Items')
    end

    def assignment_card_exists?(assignment_name)
      element_exists?("div[aria-label='#{assignment_name}']")
    end

    def or_toggle_button
      f("[title = 'Click to merge sets here']")
    end

    def and_toggle_button
      f("[title = 'Click to split set here']")
    end

    def or_toggle_button_exists?
      element_exists?("[title = 'Click to merge sets here']")
    end

    def and_toggle_button_exists?
      element_exists?("[title = 'Click to split set here']")
    end

    def assignment_options_button(assignment_name)
      fxpath("//*[@class = 'cr-assignment-card']//button[//*[contains(text(),'assignment #{assignment_name} options')]]")
    end

    def menu_option(menu_item)
      fxpath("//*[contains(text(),'#{menu_item}')]")
    end

    def assignment_exists_in_scoring_range?(ordered_range, assignment_name)
      element_exists?("//*[@class = 'cr-scoring-range' and position() = #{ordered_range}]//div[@aria-label = '#{assignment_name}']", true)
    end
  end
end
