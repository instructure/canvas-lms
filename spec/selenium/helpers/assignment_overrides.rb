# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

module AssignmentOverridesSeleniumHelper
  def visit_new_assignment_page
    get "/courses/#{@course.id}/assignments/new"
  end

  def fill_assignment_title(title)
    replace_content(f("#assignment_name"), title.to_s)
  end

  def fill_assignment_overrides
    f(".datePickerDateField[data-date-type='due_at']")
      .send_keys(format_date_for_view(due_at))
    f(".datePickerDateField[data-date-type='unlock_at']")
      .send_keys(format_date_for_view(unlock_at))
    f(".datePickerDateField[data-date-type='lock_at']")
      .send_keys(format_date_for_view(lock_at))
  end

  def update_assignment!
    expect_new_page_load { submit_form("#edit_assignment_form") }
  end

  def due_at
    Time.zone.now
  end

  def unlock_at
    Time.zone.now.advance(days: -7)
  end

  def lock_at
    Time.zone.now.advance(days: 4)
  end

  def compare_assignment_times(a)
    expect(a.due_at.to_date).to eq due_at.to_date
    expect(a.unlock_at.to_date).to eq unlock_at.to_date
    expect(a.lock_at.to_date).to eq lock_at.to_date
  end

  def create_assignment!
    @course.assignments.create!(
      title: "due tomorrow",
      due_at:,
      unlock_at:,
      lock_at:
    )
  end

  def visit_assignment_edit_page(assign)
    get "/courses/#{@course.id}/assignments/#{assign.id}/edit"
  end

  def first_due_at_element
    fj(".datePickerDateField[data-date-type='due_at']:first")
  end

  def first_unlock_at_element
    fj(".datePickerDateField[data-date-type='unlock_at']:first")
  end

  def first_lock_at_element
    fj(".datePickerDateField[data-date-type='lock_at']:first")
  end

  def last_due_at_element
    fj(".datePickerDateField[data-date-type='due_at']:last")
  end

  def last_unlock_at_element
    fj(".datePickerDateField[data-date-type='unlock_at']:last")
  end

  def last_lock_at_element
    fj(".datePickerDateField[data-date-type='lock_at']:last")
  end

  def add_override
    f("#add_due_date").click
    wait_for_ajaximations
  end

  def select_last_override_section(override_name)
    fj(".ic-tokeninput-input:last").send_keys(override_name)
    wait_for_ajaximations
    ffxpath("//div[contains(text(),'#{override_name}')]").last.click
  end

  def select_first_override_section(override_name)
    fj(".ic-tokeninput-input:first").send_keys(override_name)
    wait_for_ajaximations
    ffxpath("//div[contains(text(),'#{override_name}')]").first.click
  end

  def select_first_override_header(override_name)
    driver.switch_to.default_content
    fj(".ic-tokeninput-input:first").send_keys(override_name)
    wait_for_ajaximations
    fj(".ic-tokeninput-list [role='option']:visible:first").click
    wait_for_ajaximations
  end

  def assign_dates_for_first_override_section(opts = {})
    first_due_at_element.send_keys(opts.fetch(:due_at, Time.zone.now.advance(days: 3)))
    first_unlock_at_element.send_keys(opts.fetch(:unlock_at, Time.zone.now.advance(days: -1)))
    first_lock_at_element.send_keys(opts.fetch(:lock_at, Time.zone.now.advance(days: 3)))
  end

  def assign_dates_for_last_override_section(opts = {})
    last_due_at_element.send_keys(opts.fetch(:due_at, Time.zone.now.advance(days: 5)))
    last_unlock_at_element.send_keys(opts.fetch(:unlock_at, Time.zone.now.advance(days: -1)))
    last_lock_at_element.send_keys(opts.fetch(:lock_at, Time.zone.now.advance(days: 5)))
    last_lock_at_element.send_keys(:tab)
  end

  def find_vdd_time(override_context)
    @due_at_time = format_time_for_view(override_context.due_at)
    @lock_at_time = format_time_for_view(override_context.lock_at)
    @unlock_at_time = format_time_for_view(override_context.unlock_at)
  end

  def add_due_date_override(assignment, due_at = Time.zone.now.advance(days: 1))
    user = @user
    new_section = @course.course_sections.create!(name: "New Section")
    student_in_section(new_section)
    override = assignment.assignment_overrides.build
    override.set = new_section
    override.due_at = due_at
    override.due_at_overridden = true
    override.save!
    @user = user
  end

  def add_user_specific_due_date_override(assignment, opts = {})
    user = @user
    new_section = opts.fetch(:section, @course.course_sections.create!(name: "New Section"))
    student_in_section(new_section)
    override = assignment.assignment_overrides.build
    override.set = new_section
    override.due_at = opts.fetch(:due_at, Time.zone.now.advance(days: 3))
    override.due_at_overridden = true
    override.lock_at = opts.fetch(:lock_at, Time.zone.now.advance(days: 3))
    override.lock_at_overridden = true
    override.unlock_at = opts.fetch(:unlock_at, Time.zone.now.advance(days: -1))
    override.unlock_at_overridden = true
    override.save!
    @user = user
    @override = override
    @new_section = new_section
  end

  def prepare_vdd_scenario
    @course = course_model
    @course.name = "VDD Course"
    @course.offer!

    # must have two sections: A and B
    @section_a = @course.course_sections.create!(name: "Section A")
    @section_b = @course.course_sections.create!(name: "Section B")

    # must have a published quiz with variable due dates
    create_quiz_with_vdd
  end

  def enroll_section_a_student
    @student1 = user_with_pseudonym(username: "student1@example.com", active_all: 1)
    @course.self_enroll_student(@student1, section: @section_a)
  end

  def enroll_section_b_student
    @student2 = user_with_pseudonym(username: "student2@example.com", active_all: 1)
    @course.self_enroll_student(@student2, section: @section_b)
  end

  def prepare_vdd_scenario_for_first_observer
    prepare_vdd_scenario

    enroll_section_a_student
    enroll_section_b_student

    # 1 observer linked to both students
    @observer1 = user_with_pseudonym(username: "observer1@example.com", active_all: 1)
    @course.enroll_user(
      @observer1,
      "ObserverEnrollment",
      enrollment_state: "active",
      allow_multiple_enrollments: true,
      section: @section_a,
      associated_user_id: @student1.id
    )
    @course.enroll_user(
      @observer1,
      "ObserverEnrollment",
      enrollment_state: "active",
      allow_multiple_enrollments: true,
      section: @section_b,
      associated_user_id: @student2.id
    )
  end

  def prepare_vdd_scenario_for_second_observer
    prepare_vdd_scenario

    enroll_section_b_student

    # 1 observer linked to student enrolled in Section B
    @observer2 = user_with_pseudonym(username: "observer2@example.com", active_all: 1)
    @course.enroll_user(
      @observer2,
      "ObserverEnrollment",
      enrollment_state: "active",
      section: @section_b,
      associated_user_id: @student2.id
    )
  end

  def prepare_vdd_scenario_for_first_student
    prepare_vdd_scenario
    enroll_section_a_student
  end

  def prepare_vdd_scenario_for_second_student
    prepare_vdd_scenario
    enroll_section_b_student
  end

  def prepare_vdd_scenario_for_teacher
    prepare_vdd_scenario

    @teacher1 = user_with_pseudonym(username: "teacher1@example.com", active_all: 1)
    @course.enroll_teacher(@teacher1, section: @section_a).accept!
    @course.enroll_teacher(@teacher1, section: @section_b, allow_multiple_enrollments: true).accept!
  end

  def prepare_vdd_scenario_for_ta
    prepare_vdd_scenario

    @ta1 = user_with_pseudonym(username: "ta1@example.com", active_all: 1)
    @course.enroll_ta(@ta1, section: @section_a).accept!
    @course.enroll_ta(@ta1, section: @section_b, allow_multiple_enrollments: true).accept!
  end

  def create_quiz_with_vdd
    assignment_quiz([], course: @course)
    set_quiz_dates_for_section_a
    set_quiz_dates_for_section_b
  end

  def set_quiz_dates_for_section_a
    now = Time.zone.now

    @quiz.update_attribute(:due_at, now.advance(days: 2))
    @quiz.update_attribute(:unlock_at, now)
    @quiz.update_attribute(:lock_at, now.advance(days: 3))

    @due_at_a = @quiz.due_at
    @unlock_at_a = @quiz.unlock_at
    @lock_at_a = @quiz.lock_at
  end

  def set_quiz_dates_for_section_b
    now = Time.zone.now

    add_user_specific_due_date_override(
      @quiz,
      section: @section_b,
      due_at: now.advance(days: 4),
      unlock_at: now.advance(days: 1),
      lock_at: now.advance(days: 4)
    )

    @due_at_b = @override.due_at
    @unlock_at_b = @override.unlock_at
    @lock_at_b = @override.lock_at
  end

  def obtain_due_date(section)
    case section
    when @section_a
      date = obtain_date_from_quiz_show_page(1, 1)
    when @section_b
      date = obtain_date_from_quiz_show_page(2, 1)
    end
    date
  end

  def obtain_availability_start_date(section)
    case section
    when @section_a
      date = obtain_date_from_quiz_show_page(1, 3)
    when @section_b
      date = obtain_date_from_quiz_show_page(2, 3)
    end
    date
  end

  def obtain_availability_end_date(section)
    case section
    when @section_a
      date = obtain_date_from_quiz_show_page(1, 4)
    when @section_b
      date = obtain_date_from_quiz_show_page(2, 4)
    end
    date
  end

  def obtain_date_from_quiz_show_page(row_number, cell_number, load_page = false)
    get "/accounts/#{@account.id}/courses/#{@course.id}/quizzes/#{@quiz.id}" if load_page
    f("tr:nth-child(#{row_number}) td:nth-child(#{cell_number}) .screenreader-only")
  end

  def validate_quiz_show_page(message)
    expect(f("#quiz_show")).to include_text(message)
  end

  def validate_vdd_quiz_tooltip_dates(context_selector, message)
    driver.action.move_to(fln("Multiple Dates", f(context_selector.to_s))).perform
    expect(fj(".ui-tooltip:visible")).to include_text(message.to_s)
  end

  def create_assignment_override(assignment, section, due_date)
    override = assignment.assignment_overrides.build
    override.set = section
    override.due_at = due_date.days.from_now
    override.save!
  end
end
