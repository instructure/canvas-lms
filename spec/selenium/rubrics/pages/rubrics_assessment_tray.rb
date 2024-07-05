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

class RubricAssessmentTray
  class << self
    include SeleniumDependencies

    def tray
      f("[data-testid='enhanced-rubric-assessment-tray']")
    end

    def traditional_grid_rubric_assessment_view
      f("[data-testid='rubric-assessment-traditional-view']")
    end

    def traditional_grid_rating_button(criterion_id, rating_index)
      f("[data-testid^='traditional-criterion-#{criterion_id}'][data-testid$='-ratings-#{rating_index}']")
    end

    def submit_rubric_assessment_button
      f("[data-testid='save-rubric-assessment-button']")
    end

    def comment_text_area(criterion_id)
      f("[data-testid='comment-text-area-#{criterion_id}']")
    end

    def clear_comment_button(criterion_id)
      f("[data-testid='clear-comment-button-#{criterion_id}']")
    end

    def rubric_assessment_instructor_score
      f("[data-testid='rubric-assessment-instructor-score']")
    end

    def rubric_assessment_view_mode_select
      f("[data-testid='rubric-assessment-view-mode-select']")
    end

    def rubric_traditional_view_option
      f("[data-testid='traditional-view-option']")
    end

    def rubric_horizontal_view_option
      f("[data-testid='horizontal-view-option']")
    end

    def rubric_vertical_view_option
      f("[data-testid='vertical-view-option']")
    end

    def modern_criterion_points_inputs(criterion_id)
      f("[data-testid='criterion-score-#{criterion_id}']")
    end

    def rating_details(rating_id)
      f("[data-testid='rating-details-#{rating_id}']")
    end

    def modern_rating_button(rating_id, index)
      f("[data-testid='rating-button-#{rating_id}-#{index}']")
    end

    def criterion_score_input(criterion_id)
      f("[data-testid='criterion-score-#{criterion_id}']")
    end

    def modern_view_points_inputs(criterion_id)
      f("[data-testid='criterion-score-#{criterion_id}']")
    end

    def free_form_comment_area(criterion_id)
      f("[data-testid='free-form-comment-area-#{criterion_id}']")
    end

    def save_comment_checkbox(criterion_id)
      f("[data-testid='save-comment-checkbox-#{criterion_id}']")
    end

    def comment_library(criterion_id)
      f("[data-testid='comment-library-#{criterion_id}']")
    end

    def comment_library_item(criterion_id, index)
      f("[data-testid='comment-library-option-#{criterion_id}-#{index}']")
    end
  end
end
