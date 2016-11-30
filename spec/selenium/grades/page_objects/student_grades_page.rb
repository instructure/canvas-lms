class StudentGradesPage
  include SeleniumDependencies

  # Period components
  def period_options_css
    '.grading_periods_selector > option'
  end

  # Assignment components
  def assignment_titles_css
    '.student_assignment > th > a'
  end

  def visit_as_teacher(course, student)
    get "/courses/#{course.id}/grades/#{student.id}"
  end

  def visit_as_student(course)
    get "/courses/#{course.id}/grades"
  end

  def final_grade
    f('#submission_final-grade .grade')
  end

  def select_period_by_name(name)
    period = ff(period_options_css).find do |option|
      option.text == name
    end
    period.click
  end

  def assignment_titles
    ff(assignment_titles_css).map(&:text)
  end
end
