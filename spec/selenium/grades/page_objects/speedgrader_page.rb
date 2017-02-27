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

    def comment_text_area
      f('#speedgrader_comment_textarea')
    end

    def comment_submit_button
      f('#comment_submit_button')
    end

    def delete_comment
      f('.delete_comment_link')
    end

    def submission_file_name
      f('#submission_files_list .submission-file .display_name')
    end

    def submission_to_view_dropdown
      f('#submission_to_view')
    end

    def attachment_button
      f('#add_attachment')
    end

    def attachment_input
      f('#comment_attachments input')
    end

    def attachment_link
      f('.display_name')
    end

    # action
    def visit(course_id, assignment_id)
      get "/courses/#{course_id}/gradebook/speed_grader?assignment_id=#{assignment_id}"
      visibility_check = grade_input
      keep_trying_until { visibility_check.displayed? }
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

    def add_comment_and_submit(comment)
      replace_content(comment_text_area, comment)
      comment_submit_button.click
    end

    def add_comment_attachment(file_path)
      attachment_button.click
      attachment_input.send_keys(file_path)
    end

    def click_submissions_to_view
      submission_to_view_dropdown.click
    end

    def select_option_submission_to_view(option_index)
      click_option(submission_to_view_dropdown, option_index, :value)
    end

  end
end
