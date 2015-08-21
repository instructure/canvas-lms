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
      :title => "due tomorrow",
      :due_at => due_at,
      :unlock_at => unlock_at,
      :lock_at => lock_at)
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
    new_section = @course.course_sections.create!(:name => 'New Section')
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
    new_section = opts.fetch(:section, @course.course_sections.create!(:name => 'New Section'))
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


end

