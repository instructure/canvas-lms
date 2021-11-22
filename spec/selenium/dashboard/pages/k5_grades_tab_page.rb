# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

require_relative '../../common'
require_relative '../../helpers/color_common'

module K5GradesTabPageObject
  include ColorCommon

  #------------------------- Selectors --------------------------

  def assignment_group_toggle_selector
    "[data-testid='assignment-group-toggle']"
  end

  def assignment_group_totals_selector
    "[data-testid='assignment-group-totals']"
  end

  def assignments_tab_selector
    "#tab-k5-assignments"
  end

  def course_grading_period_selector
    "[data-testid='select-course-grading-period']"
  end

  def empty_grades_image_selector
    "[data-testid='empty-grades-panda']"
  end

  def grades_assignment_anchor_selector
    "a"
  end

  def grading_period_dropdown_selector
    "#grading-period-select"
  end

  def grade_progress_bar_selector(value)
    "//*[@role = 'progressbar' and @value = '#{value}']"
  end

  def grades_table_row_selector
    "[data-testid='grades-table-row']"
  end

  def grades_assignments_links_selector
    "[data-testid='grades-table-row'] a"
  end

  def grade_title_selector(title)
    "div:contains('#{title}')"
  end

  def grades_total_selector
    "[data-testid='grades-total']"
  end

  def learning_mastery_tab_selector
    "#tab-k5-outcomes"
  end

  def new_grade_badge_selector
    "[data-testid='new-grade-indicator']"
  end

  def outcomes_group_selector
    "#outcomes"
  end

  def subject_grade_selector(value)
    "//*[@data-automation = 'course_grade' and text() = '#{value}']"
  end

  def view_grades_button_selector(course_id)
    "a[href = '/courses/#{course_id}/gradebook']"
  end

  #------------------------- Elements --------------------------

  def assignment_group_toggle
    f(assignment_group_toggle_selector)
  end

  def assignment_group_totals
    ff(assignment_group_totals_selector)
  end

  def assignments_tab
    f(assignments_tab_selector)
  end

  def course_grading_period
    f(course_grading_period_selector)
  end

  def empty_grades_image
    f(empty_grades_image_selector)
  end

  def grades_assignment_href(grade_row_element)
    element_value_for_attr(grade_row_element.find_element(:css, grades_assignment_anchor_selector), "href")
  end

  def grades_assignments_list
    ff(grades_table_row_selector)
  end

  def grades_assignments_links
    ff(grades_assignments_links_selector)
  end

  def grading_period_dropdown
    f(grading_period_dropdown_selector)
  end

  def grade_progress_bar(grade_value)
    fxpath(grade_progress_bar_selector(grade_value))
  end

  def grades_total
    f(grades_total_selector)
  end

  def learning_mastery_tab
    f(learning_mastery_tab_selector)
  end

  def new_grade_badge
    f(new_grade_badge_selector)
  end

  def outcomes_group
    f(outcomes_group_selector)
  end

  def subject_grade(grade_value)
    fxpath(subject_grade_selector(grade_value))
  end

  def subject_grades_title(title)
    fj(grade_title_selector(title))
  end

  def view_grades_button(course_id)
    f(view_grades_button_selector(course_id))
  end

  #----------------------- Actions & Methods -------------------------

  #----------------------- Click Items -------------------------------

  def click_assignment_group_toggle
    assignment_group_toggle.click
  end

  def click_learning_mastery_tab
    learning_mastery_tab.click
  end

  #------------------------------Retrieve Text----------------------#

  def grades_total_text
    grades_total.text
  end

  #----------------------------Element Management---------------------#
end
