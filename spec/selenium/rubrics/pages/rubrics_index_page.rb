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

class RubricsIndex
  class << self
    include SeleniumDependencies

    def saved_rubrics_panel
      f('[data-testid="saved-rubrics-panel"]')
    end

    def archived_rubrics_panel
      f('[data-testid="archived-rubrics-panel"]')
    end

    def archived_rubrics_tab
      f('[id="tab-Archived"]')
    end

    def saved_rubrics_tab
      f('[id="tab-Saved"]')
    end

    def rubric_title_preview_link(rubric_id)
      f("[data-testid='rubric-title-preview-#{rubric_id}']")
    end

    def rubric_title(index)
      f("[data-testid='rubric-title-#{index}']")
    end

    def rubric_total_points(index)
      f("[data-testid='rubric-points-#{index}']")
    end

    def rubric_criterion_count(index)
      f("[data-testid='rubric-criterion-count-#{index}']")
    end

    def rubric_locations(index)
      f("[data-testid='rubric-locations-#{index}']")
    end

    def used_location_modal
      f("[data-testid='used-locations-modal']")
    end

    def rubric_name_header
      f("[data-testid='rubric-name-header']")
    end

    def rubric_points_header
      f("[data-testid='rubric-points-header']")
    end

    def rubric_criterion_header
      f("[data-testid='rubric-criterion-header']")
    end

    def rubric_locations_header
      f("[data-testid='rubric-locations-header']")
    end

    def rubric_popover(rubric_id)
      f("[data-testid='rubric-options-#{rubric_id}-button']")
    end

    def edit_rubric_button
      f("[data-testid='edit-rubric-button']")
    end

    def rubric_search_input
      f("[data-testid='rubric-search-bar']")
    end

    def create_rubric_button
      f("[data-testid='create-new-rubric-button']")
    end

    def archive_rubric_button
      f("[data-testid='archive-rubric-button']")
    end

    def unarchive_rubric_button
      f("[data-testid='archive-rubric-button']")
    end

    def duplicate_rubric_button
      f("[data-testid='duplicate-rubric-button']")
    end

    def duplicate_rubric_modal_button
      f("[data-testid='duplicate-rubric-modal-button']")
    end

    def delete_rubric_button
      f("[data-testid='delete-rubric-button']")
    end

    def delete_rubric_modal_button
      f("[data-testid='delete-rubric-modal-button']")
    end

    def flash_message
      f("[class='flashalert-message']")
    end

    def rubric_assessment_tray
      f("[data-testid='enhanced-rubric-assessment-tray']")
    end
  end
end
