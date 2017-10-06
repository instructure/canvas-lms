#
# Copyright (C) 2016 - present Instructure, Inc.
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

class GradingCurvePage
  include SeleniumDependencies

  private

  def grading_curve_dialog
    f("#curve_grade_dialog")
  end

  def average_score_input
    f("#middle_score")
  end

  def assign_zeroes_chkbox
    f("#assign_blanks")
  end

  def curve_grades_btn
    fj('.ui-dialog-buttonset .ui-button:contains("Curve Grades")')
  end

  public

  def grading_curve_dialog_title
    f('.ui-dialog-title')
  end

  def edit_grade_curve(score = "1")
    replace_content(average_score_input, score)
  end

  def curve_grade_submit
    curve_grades_btn.click
  end
end
