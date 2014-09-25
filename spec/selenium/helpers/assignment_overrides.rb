module AssignmentOverridesSeleniumHelper

  def visit_new_assignment_page
    get "/courses/#{@course.id}/assignments/new"
  end

  def fill_assignment_title(title)
    replace_content(f('#assignment_name'), title.to_s)
  end

  def fill_assignment_overrides
      f('.due-date-overrides [name="due_at"]').
        send_keys(due_at.strftime('%b %-d, %y'))
      f('.due-date-overrides [name="unlock_at"]').
        send_keys(unlock_at.strftime('%b %-d, %y'))
      f('.due-date-overrides [name="lock_at"]').
        send_keys(lock_at.strftime('%b %-d, %y'))
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
    a.due_at.strftime('%b %-d, %y').should == due_at.to_date.
      strftime('%b %-d, %y')
    a.unlock_at.strftime('%b %-d, %y').should == unlock_at.to_date.
      strftime('%b %-d, %y')
    a.lock_at.strftime('%b %-d, %y').should == lock_at.to_date.
      strftime('%b %-d, %y')
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
    fj('.due-date-row:first [name="due_at"]')
  end

  def first_unlock_at_element
    fj('.due-date-row:first [name="unlock_at"]')
  end

  def first_lock_at_element
    fj('.due-date-row:first [name="lock_at"]')
  end

  def last_due_at_element
    fj('.due-date-row:last [name="due_at"]')
  end

  def last_unlock_at_element
    fj('.due-date-row:last [name="unlock_at"]')
  end

  def last_lock_at_element
    fj('.due-date-row:last [name="lock_at"]')
  end

  def add_override
    f('#add_due_date').click
    wait_for_ajaximations
  end

  def select_last_override_section(section_name)
    click_option('.due-date-row:last select', section_name)
    wait_for_ajaximations
  end

  def select_first_override_section(section_name)
    click_option('.due-date-row:first select', section_name)
    wait_for_ajaximations
  end

  def add_due_date_override(assignment)
    user = @user
    new_section = @course.course_sections.create!(:name => 'New Section')
    student_in_section(new_section)
    override = assignment.assignment_overrides.build
    override.set = new_section
    override.due_at = Time.zone.now.advance(days:1)
    override.due_at_overridden = true
    override.save!
    @user = user
  end

end

