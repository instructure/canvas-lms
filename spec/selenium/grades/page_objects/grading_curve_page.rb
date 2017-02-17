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
