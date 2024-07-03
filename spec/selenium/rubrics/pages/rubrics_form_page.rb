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

class RubricsForm
  class << self
    include SeleniumDependencies

    def rubric_title_input
      f("[data-testid='rubric-form-title']")
    end

    def save_rubric_button
      f("[data-testid='save-rubric-button']")
    end

    def add_criterion_button
      f("[data-testid='add-criterion-button']")
    end

    def save_criterion_button
      f("[data-testid='rubric-criterion-save']")
    end

    def rubric_criterion_modal
      f("[data-testid='rubric-criterion-modal']")
    end

    def criterion_name_input
      f("[data-testid='rubric-criterion-name-input']")
    end

    def criteria_row_names
      ff("[data-testid='rubric-criteria-row-description']")
    end

    def cancel_rubric_button
      f("[data-testid='cancel-rubric-save-button']")
    end

    def save_as_draft_button
      f("[data-testid='save-as-draft-button']")
    end

    def preview_rubric_button
      f("[data-testid='preview-rubric-button']")
    end

    def rubric_rating_order_select
      f("[data-testid='rubric-rating-order-select']")
    end

    def high_low_rating_order
      f("[data-testid='high_low_rating_order']")
    end

    def low_high_rating_order
      f("[data-testid='low_high_rating_order']")
    end

    def traditional_grid_rating_button(index)
      f("[data-testid^='traditional-criterion-'][data-testid$='-ratings-#{index}']")
    end

    def criterion_description_input
      f("[data-testid='rubric-criterion-description-input']")
    end

    def criteria_row_description
      f("[data-testid='rubric-criteria-row-long-description']")
    end

    def criterion_row_rating_accordion
      f("[data-testid='criterion-row-rating-accordion']")
    end

    def criterion_rating_scale_accordion_items
      ff("[data-testid='rating-scale-accordion-item']")
    end

    def create_from_outcome_button
      f("[data-testid='create-from-outcome-button']")
    end

    def outcome_link
      f("[class='outcome-link']")
    end

    def import_outcome_button
      ff("[class='btn-primary ui-button ui-widget ui-state-default ui-corner-all ui-button-text-only']")[0]
    end

    def rubric_criteria_row_outcome_tag
      f("[data-testid='rubric-criteria-row-outcome-tag']")
    end

    def add_rating_row_button
      f("[data-testid='add-rating-row']")
    end

    def rating_name_inputs
      ff("[data-testid='rating-name']")
    end

    def rating_description_inputs
      ff("[data-testid='rating-description']")
    end

    def remove_rating_buttons
      ff("[data-testid='remove-rating']")
    end

    def rubric_criteria_row_delete_button
      f("[data-testid='rubric-criteria-row-delete-button']")
    end

    def criterion_rating_scales
      ff("[data-testid='rating-scale']")
    end

    def criterion_rating_points_inputs
      ff("[data-testid='rating-points']")
    end

    def criterion_row_edit_buttons
      ff("[data-testid='rubric-criteria-row-edit-button']")
    end

    def cancel_criterion_button
      f("[data-testid='rubric-criterion-cancel']")
    end

    def rubric_criteria_row_duplicate_buttons
      ff("[data-testid='rubric-criteria-row-duplicate-button']")
    end

    def limited_edit_mode_message
      f("[data-testid='rubric-limited-edit-mode-alert']")
    end

    def non_editable_rating_points
      ff("[data-testid='rating-points-assessed']")
    end
  end
end
