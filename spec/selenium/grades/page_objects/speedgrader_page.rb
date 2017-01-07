class Speedgrader
  class << self
    include SeleniumDependencies

    def grade_value
      f('#grade_container input[type=text]').attribute('value')
    end

    def fraction_graded
      f("#x_of_x_graded")
    end

    def average_grade
      f("#average_score")
    end

    def grade_input
      f('#grading-box-extended')
    end

    def top_bar
      f("#content")
    end

    def closed_gp_notice_selector
      "#closed_gp_notice"
    end

    def visit(course, assignment)
      get "/courses/#{course.id}/gradebook/speed_grader?assignment_id=#{assignment.id}"
    end

    def enter_grade(grade)
      grade_input.send_keys(grade, :tab)
    end

    def current_grade
      grade_input['value']
    end

  end
end

