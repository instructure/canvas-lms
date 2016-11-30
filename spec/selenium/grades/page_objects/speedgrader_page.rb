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

    def visit(course, assignment)
      get "/courses/#{course.id}/gradebook/speed_grader?assignment_id=#{assignment.id}"
    end
  end
end

