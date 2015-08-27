module AssignmentOverridesSeleniumHelper

  def visit_new_assignment_page
    get "/courses/#{@course.id}/assignments/new"
  end

  def fill_assignment_title(title)
    replace_content(f('#assignment_name'), title.to_s)
  end

  def fill_assignment_overrides
      fj(".datePickerDateField[data-date-type='due_at']")
        .send_keys(due_at.strftime('%b %-d, %y'))
      fj(".datePickerDateField[data-date-type='unlock_at']")
        .send_keys(unlock_at.strftime('%b %-d, %y'))
      fj(".datePickerDateField[data-date-type='lock_at']")
        .send_keys(lock_at.strftime('%b %-d, %y'))
  end

  def update_assignment!
    expect_new_page_load { submit_form('#edit_assignment_form') }
  end

  def due_at
    Time.zone.now
  end

  def unlock_at
    Time.zone.now.advance(days: -2)
  end

  def lock_at
    Time.zone.now.advance(days: 4)
  end

  def compare_assignment_times(a)
    expect(a.due_at.strftime('%b %-d, %y')).to eq due_at.to_date
      .strftime('%b %-d, %y')
    expect(a.unlock_at.strftime('%b %-d, %y')).to eq unlock_at.to_date
      .strftime('%b %-d, %y')
    expect(a.lock_at.strftime('%b %-d, %y')).to eq lock_at.to_date
      .strftime('%b %-d, %y')
  end

  def create_assignment!
    @course.assignments.create!(
      title: 'due tomorrow',
      due_at: due_at,
      unlock_at: unlock_at,
      lock_at: lock_at)
  end

  def visit_assignment_edit_page(assign)
    get "/courses/#{@course.id}/assignments/#{assign.id}/edit"
  end

  def first_due_at_element
    fj(".datePickerDateField:first[data-date-type='due_at']")
  end

  def first_unlock_at_element
    fj(".datePickerDateField:first[data-date-type='unlock_at']")
  end

  def first_lock_at_element
    fj(".datePickerDateField:first[data-date-type='lock_at']")
  end

  def last_due_at_element
    fj(".datePickerDateField:last[data-date-type='due_at']")
  end

  def last_unlock_at_element
    fj(".datePickerDateField:last[data-date-type='unlock_at']")
  end

  def last_lock_at_element
    fj(".datePickerDateField:last[data-date-type='lock_at']")
  end

  def add_override
    f('#add_due_date').click
    wait_for_ajaximations
  end

  def select_last_override_section(section_name)
    driver.switch_to.default_content
    fj('.ic-tokeninput-input:last').send_keys(section_name)
    wait_for_ajaximations
    fj(".ic-tokeninput-option:visible:last").click
    wait_for_ajaximations
  end

  def select_first_override_section(section_name)
    driver.switch_to.default_content
    fj('.ic-tokeninput-input:first').send_keys(section_name)
    wait_for_ajaximations
    fj(".ic-tokeninput-option:visible:first").click
    wait_for_ajaximations
  end

  def assign_dates_for_first_override_section(opts = {})
    first_due_at_element.send_keys(opts.fetch(:due_at, Time.zone.now.advance(days:3)))
    first_unlock_at_element.send_keys(opts.fetch(:unlock_at, Time.zone.now.advance(days:-1)))
    first_lock_at_element.send_keys(opts.fetch(:lock_at, Time.zone.now.advance(days:3)))
  end

  def assign_dates_for_last_override_section(opts = {})
    last_due_at_element.send_keys(opts.fetch(:due_at, Time.zone.now.advance(days:5)))
    last_unlock_at_element.send_keys(opts.fetch(:unlock_at, Time.zone.now.advance(days:-1)))
    last_lock_at_element.send_keys(opts.fetch(:lock_at, Time.zone.now.advance(days:5)))
  end

  def find_vdd_time(override_context)
    @due_at_time = override_context.due_at.strftime('%b %-d at %-l:%M') <<
                                                               override_context.lock_at.strftime('%p').downcase
    @lock_at_time = override_context.lock_at.strftime('%b %-d at %-l:%M') <<
                                                               override_context.lock_at.strftime('%p').downcase
    @unlock_at_time = override_context.unlock_at.strftime('%b %-d at %-l:%M') <<
                                                               override_context.unlock_at.strftime('%p').downcase
  end

  def add_due_date_override(assignment, due_at = Time.zone.now.advance(days:1))
    user = @user
    new_section = @course.course_sections.create!(name: 'New Section')
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
    new_section = opts.fetch(:section, @course.course_sections.create!(name: 'New Section'))
    student_in_section(new_section)
    override = assignment.assignment_overrides.build
    override.set = new_section
    override.due_at = opts.fetch(:due_at, Time.zone.now.advance(days:3))
    override.due_at_overridden = true
    override.lock_at = opts.fetch(:lock_at, Time.zone.now.advance(days:3))
    override.lock_at_overridden = true
    override.unlock_at = opts.fetch(:unlock_at, Time.zone.now.advance(days:-1))
    override.unlock_at_overridden = true
    override.save!
    @user = user
    @override = override
    @new_section = new_section
  end

  def prepare_multiple_due_dates_scenario
    @course = course_model
    @course.name = 'Test Course'
    @course.offer!

    # must have two sections: A and B
    @section_a = @course.course_sections.create!(name: 'Section A')
    @section_b = @course.course_sections.create!(name: 'Section B')

    # must have a published quiz with multiple due dates
    create_quiz_with_multiple_due_dates
  end

  def enroll_section_a_student
    @student1 = user_with_pseudonym(username: 'student1@example.com', active_all: 1)
    @course.self_enroll_student(@student1, section: @section_a)
  end

  def enroll_section_b_student
    @student2 = user_with_pseudonym(username: 'student2@example.com', active_all: 1)
    @course.self_enroll_student(@student2, section: @section_b)
  end

  def prepare_vdd_scenario_for_first_observer
    prepare_multiple_due_dates_scenario

    enroll_section_a_student
    enroll_section_b_student

    # 1 observer linked to both students
    @observer1 = user_with_pseudonym(username: 'observer1@example.com', active_all: 1)
    @course.enroll_user(
      @observer1,
      'ObserverEnrollment',
      enrollment_state: 'active',
      allow_multiple_enrollments: true,
      section: @section_a,
      associated_user_id: @student1.id
    )
    @course.enroll_user(
      @observer1,
      'ObserverEnrollment',
      enrollment_state: 'active',
      allow_multiple_enrollments: true,
      section: @section_b,
      associated_user_id: @student2.id
    )
  end

  def prepare_vdd_scenario_for_second_observer
    prepare_multiple_due_dates_scenario

    enroll_section_b_student

    # 1 observer linked to student enrolled in Section B
    @observer2 = user_with_pseudonym(username: 'observer2@example.com', active_all: 1)
    @course.enroll_user(
      @observer2,
      'ObserverEnrollment',
      enrollment_state: 'active',
      section: @section_b,
      associated_user_id: @student2.id
    )
  end

  def prepare_multiple_due_dates_scenario_for_teacher
    prepare_multiple_due_dates_scenario

    @teacher1 = user_with_pseudonym(username: 'teacher1@example.com', active_all: 1)
    @course.enroll_teacher(@teacher1, section: @section_a)
    @course.enroll_teacher(@teacher1, section: @section_b)
  end

  def prepare_multiple_due_dates_scenario_for_ta
    prepare_multiple_due_dates_scenario

    @ta1 = user_with_pseudonym(username: 'ta1@example.com', active_all: 1)
    @course.enroll_ta(@ta1, section: @section_a)
    @course.enroll_ta(@ta1, section: @section_b)
  end

  def create_quiz_with_multiple_due_dates
    now = Time.zone.now
    @due_at_a = now.advance(days: 2)
    @unlock_at_a = now
    @lock_at_a = now.advance(days: 3)

    assignment_quiz([], course: @course)
    @quiz.update_attribute(:due_at, @due_at_a)
    @quiz.update_attribute(:unlock_at, @unlock_at_a)
    @quiz.update_attribute(:lock_at, @lock_at_a)

    @due_at_b = now.advance(days: 4)
    @unlock_at_b = now.advance(days: 1)
    @lock_at_b = now.advance(days: 4)

    add_user_specific_due_date_override(
      @quiz,
      section: @section_b,
      due_at: @due_at_b,
      unlock_at: @unlock_at_b,
      lock_at: @lock_at_b
    )
    @quiz
  end

  def format_date_for_view(date)
    date.strftime('%b %-d')
  end

  def format_time_for_view(time)
    time.strftime('%b %-d at %-l:%M') << time.strftime('%p').downcase
  end

  def obtain_due_date(section)
    case section
    when @section_a
      date = obtain_date_from_quiz_summary(1, 1)
    when @section_b
      date = obtain_date_from_quiz_summary(2, 1)
    end
    date
  end

  def obtain_availability_start_date(section)
    case section
    when @section_a
      date = obtain_date_from_quiz_summary(1, 3)
    when @section_b
      date = obtain_date_from_quiz_summary(2, 3)
    end
    date
  end

  def obtain_availability_end_date(section)
    case section
    when @section_a
      date = obtain_date_from_quiz_summary(1, 4)
    when @section_b
      date = obtain_date_from_quiz_summary(2, 4)
    end
    date
  end

  def obtain_date_from_quiz_summary(row_number, cell_number, load_page=false)
    get "/accounts/#{@account.id}/courses/#{@course.id}/quizzes/#{@quiz.id}" if load_page
    fj("tr:nth-child(#{row_number}) td:nth-child(#{cell_number}) .screenreader-only", f('.assignment-dates'))
  end

  def validate_quiz_show_page(message)
    expect(f('#quiz_show').text).to include_text("#{message}")
  end

  def validate_quiz_dates(context_selector, message)
    keep_trying_until(2) do
      driver.mouse.move_to fln('Multiple Dates', f("#{context_selector}"))
      expect(fj('.ui-tooltip')).to include_text("#{message}")
    end
  end
end