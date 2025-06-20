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
      ff('[data-testid="outcome-header"]')
    end

    def student_outcome_cell(student_id, outcome_id)
      f("[data-testid='student-outcome-score-#{student_id}-#{outcome_id}']")
    end

    def export_csv_button
      f('[data-testid="export-button"]')
    end
  end
end
