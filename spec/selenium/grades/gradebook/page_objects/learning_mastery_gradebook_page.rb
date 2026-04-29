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

class LearningMasteryGradebookPage
  class << self
    include SeleniumDependencies

    def exceeds_mastery_icon_id
      "exceeds-mastery"
    end

    def mastery_icon_id
      "mastery"
    end

    def near_mastery_icon_id
      "near-mastery"
    end

    def below_mastery_icon_id
      "remediation"
    end

    def not_mastered_icon_id
      "no_evidence"
    end

    def unassessed_icon_id
      "unassessed"
    end

    def score_icon_selector(icon_id)
      "svg[id='#{icon_id}']"
    end

    def pagination_controls_selector
      "[data-testid=\"gradebook-pagination\"]"
    end

    def per_page_dropdown_selector
      '[data-testid="per-page-selector"]'
    end

    def gradebook_menu
      f('[data-testid="lmgb-gradebook-menu"]')
    end

    def mastery_scales_filter
      f('[data-testid="proficiency-filter"]')
    end

    def student_cells
      ff('[data-testid="student-cell"]')
    end

    def outcome_headers
      ff('[data-testid^="outcome-header"]')
    end

    def student_outcome_cell(student_id, outcome_id)
      f("[data-testid='student-outcome-score-#{student_id}-#{outcome_id}']")
    end

    def export_csv_button
      f('[data-testid="export-button"]')
    end

    def pagination_controls
      f(pagination_controls_selector)
    end

    def per_page_dropdown
      f('[data-testid="per-page-selector"]')
    end

    def per_page_dropdown_options
      INSTUI_Select_options(per_page_dropdown_selector)
    end

    def page_button(page_number)
      fj("#{pagination_controls_selector} button:contains('#{page_number}')")
    end

    def current_page_text
      f('button[aria-current="page"]').text
    end

    # Settings tray
    def settings_button
      f('[data-testid="lmgb-settings-button"]')
    end

    def settings_tray
      f('[data-testid="lmgb-settings-tray"]')
    end

    def settings_tray_selector
      '[data-testid="lmgb-settings-tray"]'
    end

    def close_settings_button
      f('[data-testid="lmgb-close-settings-button"]')
    end

    # Settings tray options
    # InstUI RadioInput renders input and label as siblings (label[for=id] + input[id]),
    # so click the label element directly to activate the radio
    def secondary_info_radio(label_text)
      fj("[data-testid='lmgb-settings-tray'] label:contains('#{label_text}')")
    end

    def display_filter_checkbox(label_text)
      fj("[data-testid='lmgb-settings-tray'] label:contains('#{label_text}')")
    end

    def score_display_radio(label_text)
      fj("[data-testid='lmgb-settings-tray'] label:contains('#{label_text}')")
    end

    # Search filters
    def student_search_input
      f('input[placeholder="Search Students"]')
    end

    def outcome_search_input
      f('input[placeholder="Search outcomes"]')
    end

    # Column header options menus
    # InstUI IconButton with screenReaderLabel renders the label as a visually-hidden
    # child span, not as aria-label. Use :contains to find by that text.
    def student_header_options_button
      fj("button:contains('Student Options')")
    end

    def outcome_header_options_button(outcome_title)
      fj("button:contains('#{outcome_title} options')")
    end

    def contributing_score_header(outcome_id, alignment_id)
      f("[data-testid='contributing-score-header-#{outcome_id}-#{alignment_id}']")
    end

    def contributing_score_headers
      ff('[data-testid^="contributing-score-header"]')
    end

    def contributing_score_header_options_button(assignment_title)
      fj("button:contains('#{assignment_title} options')")
    end

    # Menu items (found after opening a menu)
    # Use attribute-starts-with to match menuitem, menuitemradio, menuitemcheckbox
    def menu_item(text)
      fj("[role^='menuitem']:contains('#{text}')")
    end

    def menu_item_radio(text)
      fj("[role='menuitemradio']:contains('#{text}')")
    end

    # Student cell details
    def student_secondary_info_elements
      ff('[data-testid="student-secondary-info"]')
    end

    def student_avatars
      ff('[data-testid="student-avatar"]')
    end

    # Contributing score cells
    def contributing_score_cell(student_id, outcome_id, alignment_id)
      f("[data-testid='student-outcome-score-#{student_id}-#{outcome_id}-#{alignment_id}']")
    end

    # Student header
    def student_header
      f('[data-testid="student-header"]')
    end
  end
end
