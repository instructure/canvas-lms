require_relative '../../common'

class GlobalGrades
  class << self
    include SeleniumDependencies

    def grading_period_dropdown(course)
      f('.grading_periods_selector', course)
    end

    def score(course)
      f('.percent', course)
    end

    def select_grading_period(course, grading_period)
      selected_course = course_row(course)
      click_option(grading_period_dropdown(selected_course), grading_period)
    end

    def get_score_for_course(course)
      selected_course = course_row(course)
      score(selected_course).text
    end

    def course_row(course)
      f('.course_details')
      courses = ff('tr')
      courses.each do |single_course|
        if f('.course a', single_course).text == course.name
          return single_course
        end
      end
      nil
    end

    def visit()
      get '/grades'
    end
  end
end
