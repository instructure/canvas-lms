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

require_relative "../../common"

module AccessibilityDashboard
  #------------------------------ Selectors -----------------------------
  def fix_button_selector
    "[data-testid='issue-remediation-button']"
  end

  def accessibility_checker_container_selector
    "#accessibility-checker-container"
  end

  def accessibility_issues_table_selector
    "[data-testid='accessibility-issues-table']"
  end

  def accessibility_issues_table_no_issues_selector
    "[data-testid='no-issues-row']"
  end

  #------------------------------ Elements ------------------------------
  def accessibility_table_cell(row_index, col_index)
    caption = "Content with accessibility issues"
    fxpath_table_cell(caption, row_index, col_index)
  end

  def fix_button(row_index)
    accessibility_table_cell(row_index, 2)
  end

  def accessibility_checker_container
    f(accessibility_checker_container_selector)
  end

  def accessibility_issues_table
    f(accessibility_issues_table_selector)
  end

  def accessibility_issues_table_no_issues
    f(accessibility_issues_table_no_issues_selector)
  end

  #------------------------------ Actions ------------------------------
  def visit_accessibility_home_page(course_id)
    get "/courses/#{course_id}/accessibility"
  end
end
