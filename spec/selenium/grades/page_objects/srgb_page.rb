require_relative '../../common'

class SRGB
  class << self
    include SeleniumDependencies

    def main_grade_input
      f('#student_and_assignment_grade')
    end

    def grade_for_label
      f("label[for='student_and_assignment_grade']")
    end

    def next_assignment_button
      fj("button:contains('Next Assignment')")
    end

    def submission_details_button
      f('#submission_details')
    end

    def notes_field
      f('#student_information textarea')
    end

    def final_grade
      f('#student_information .total-grade')
    end

    def assign_group_grade
      f('.assignment-group-grade .grade')
    end

    def secondary_id_label
      f('#student_information .secondary_id')
    end

    def grading_period_dropdown
      f('#grading_period_select')
    end

    def student_dropdown
      f('#student_select')
    end

    def assignment_dropdown
      f('#assignment_select')
    end

    def default_grade
      f("#set_default_grade")
    end

    # global checkboxes
    def ungraded_as_zero
      f('#ungraded')
    end

    def hide_student_names
      f('#hide_names_checkbox')
    end

    def concluded_enrollments
      f('#concluded_enrollments')
    end

    def show_notes_option
      f('#show_notes')
    end

    # content selection buttons
    def previous_student
      f('.student_navigation button.previous_object')
    end

    def next_student
      f('.student_navigation button.next_object')
    end

    def previous_assignment
      f('.assignment_navigation button.previous_object')
    end

    def next_assignment
      f('.assignment_navigation button.next_object')
    end

    # assignment information
    def assignment_link
      f('.assignment_selection a')
    end

    def speedgrader_link
      f('#assignment-speedgrader-link a')
    end

    def visit(course_id)
      get "/courses/#{course_id}/gradebook/change_gradebook_version?version=srgb"
    end

    def select_assignment(assignment)
      click_option(assignment_dropdown, assignment.name)
    end

    def select_student(student)
      click_option(student_dropdown, student.name)
    end

    def select_grading_period(grading_period)
      click_option(grading_period_dropdown, grading_period.title)
    end

    def enter_grade(grade)
      replace_content(main_grade_input, grade)
      tab_out_of_input(main_grade_input)
    end

    def current_grade
      main_grade_input['value']
    end

    def grading_enabled?
      main_grade_input.enabled?
    end

    def grade_srgb_assignment(input, grade)
      replace_content(input, grade)
    end

    def tab_out_of_input(input_selector)
      # This is a hack for a timing issue with SRGB
      2.times { input_selector.send_keys(:tab) }
      wait_for_ajaximations
    end

    def drop_lowest(course, num_assignment)
      ag = course.assignment_groups.first
      ag.rules_hash = {"drop_lowest"=>num_assignment}
      ag.save!
    end
  end
end

