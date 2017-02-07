class Speedgrader
  class << self
    include SeleniumDependencies

    # components/elements
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

    def settings_link
      f('#settings_link')
    end

    def hide_students_chkbox
      f('#hide_student_names')
    end

    def selected_student
      f('span.ui-selectmenu-item-header')
    end

    def student_x_of_x_label
      f('#x_of_x_students_frd')
    end

    def student_dropdown_menu
      f('div.ui-selectmenu-menu.ui-selectmenu-open')
    end

    def next_student_btn
      f('#next-student-button')
    end

    def next_student
      f('.next')
    end

    def previous_student
      f('.prev')
    end

    def students_dropdown_button
      f('#students_selectmenu-button')
    end

    # action
    def visit(course, assignment)
      get "/courses/#{course.id}/gradebook/speed_grader?assignment_id=#{assignment.id}"
    end

    def enter_grade(grade)
      grade_input.send_keys(grade, :tab)
    end

    def current_grade
      grade_input['value']
    end

    def click_students_dropdown
      students_dropdown_button.click
    end

    def click_next_or_prev_student(direction_string)
      if direction_string.equal?(:next)
        next_student.click
      else
        previous_student.click
      end
    end

    def click_settings_link
      settings_link.click
    end

    def select_hide_student_names
      hide_students_chkbox
    end

    def click_next_student_btn
      next_student_btn.click
    end

  end
end

