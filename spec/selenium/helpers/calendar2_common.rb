require File.expand_path(File.dirname(__FILE__) + '/../common')

module Calendar2Common
  def create_course_assignment
    Assignment.new.tap do |a|
      a.id = 1
      a.title = 'test assignment'
      a.due_at = Time.now.utc.strftime("%Y-%m-%d 21:00:00")
      a.workflow_state = 'published'
      a.context_id = @course.id
      a.context_type = 'Course'
      a.save!
    end
  end

  def create_course_event
    CalendarEvent.new.tap do |c|
      c.id = 1
      c.title = 'test event'
      c.start_at = Time.now.utc.strftime("%Y-%m-%d 21:00:00")
      c.workflow_state = 'active'
      c.context_id = @course.id
      c.context_type = 'Course'
      c.save!
    end
  end

  def create_appointment_group(params={})
    tomorrow = (Date.today + 1.day).to_s
    default_params = {
        :title => "new appointment group",
        :contexts => [@course],
        :new_appointments => [
            [tomorrow + ' 12:00:00', tomorrow + ' 13:00:00'],
        ]
    }
    ag = AppointmentGroup.create!(default_params.merge(params))
    ag.publish!
    ag.title
  end

  def create_appointment_group_early(params={})
    tomorrow = (Date.today + 1.day).to_s
    default_params = {
        :title => "new appointment group",
        :contexts => [@course],
        :new_appointments => [
            [tomorrow + ' 7:00', tomorrow + ' 11:00:00'],
        ]
    }
    ag = AppointmentGroup.create!(default_params.merge(params))
    ag.publish!
    ag.title
  end

  def open_edit_event_dialog
    f('.fc-event').click
    expect(f('.edit_event_link')).to be_displayed
    f('.edit_event_link').click
    wait_for_ajaximations
  end

  def make_event(params = {})
    opts = {
        :context => @user,
        :start => Time.zone.now,
        :description => "Test event"
    }.with_indifferent_access.merge(params)
    c = CalendarEvent.new :description => opts[:description],
                          :start_at => opts[:start],
                          :end_at => opts[:end],
                          :title => opts[:title],
                          :location_name => opts[:location_name],
                          :location_address => opts[:location_address],
                          :all_day => opts[:all_day]
    c.context = opts[:context]
    c.save!
    c
  end

  def create_quiz
    due_at = 5.minutes.from_now
    unlock_at = Time.zone.now.advance(days:-2)
    lock_at = Time.zone.now.advance(days:4)
    title = 'Test Quiz'
    @context = @course
    @quiz = quiz_model
    @quiz.generate_quiz_data
    @quiz.due_at = due_at
    @quiz.lock_at = lock_at
    @quiz.unlock_at = unlock_at
    @quiz.title = title
    @quiz.save!
    @quiz
  end

  def create_graded_discussion
    @assignment = @course.assignments.create!(
      :title => 'assignment',
      :points_possible => 10,
      :due_at => Time.zone.now + 5.minutes,
      :submission_types => 'online_text_entry',
      :only_visible_to_overrides => true
    )
    @gd = @course.discussion_topics.create!(:title => 'Graded Discussion', :assignment => @assignment)
  end

  def find_middle_day
    fj('.calendar .fc-week:nth-child(1) .fc-wed:first')
  end

  def change_calendar(direction = :next)
    css_selector = case direction
                   when :next then
                     '.navigate_next'
                   when :prev then
                     '.navigate_prev'
                   when :today then
                     '.navigate_today'
                   else
                     raise "unrecognized direction #{direction}"
                   end

    f('.calendar_header ' + css_selector).click
    wait_for_ajaximations
  end

  def quick_jump_to_date(text)
    f('.navigation_title').click
    date_input = f('.date_field')
    date_input.send_keys(text + "\n")
    wait_for_ajaximations
  end

  def add_date(middle_number)
    fj('.ui-datepicker-trigger:visible').click
    datepicker_current(middle_number)
  end

  def create_assignment_event(assignment_title, should_add_date = false, publish = false)
    middle_number = find_middle_day['data-date']
    find_middle_day.click
    edit_event_dialog = f('#edit_event_tabs')
    expect(edit_event_dialog).to be_displayed
    edit_event_dialog.find('.edit_assignment_option').click
    edit_assignment_form = edit_event_dialog.find('#edit_assignment_form')
    title = edit_assignment_form.find('#assignment_title')
    keep_trying_until { title.displayed? }
    replace_content(title, assignment_title)
    add_date(middle_number) if should_add_date
    publish_toggle = edit_assignment_form.find('#assignment_published')
    move_to_click('label[for=assignment_published]') if publish
    submit_form(edit_assignment_form)
    expect(f('.fc-month-view .fc-event:not(.event_pending) .fc-title')).to include_text(assignment_title)
  end

  # Creates event from clicking on the mini calendar
  def create_calendar_event(event_title, should_add_date = false, should_add_location = false, should_duplicate = false)
    middle_number = find_middle_day['data-date']
    find_middle_day.click
    edit_event_dialog = f('#edit_event_tabs')
    expect(edit_event_dialog).to be_displayed
    edit_event_form = edit_event_dialog.find('#edit_calendar_event_form')
    title = edit_event_form.find('#calendar_event_title')
    keep_trying_until { title.displayed? }
    replace_content(title, event_title)
    add_date(middle_number) if should_add_date
    replace_content(f('#calendar_event_location_name'), 'location title') if should_add_location

    if should_duplicate
      f('#duplicate_event').click
      duplicate_options = edit_event_form.find('#duplicate_interval')
      keep_trying_until { duplicate_options.displayed? }
      duplicate_interval = edit_event_form.find('#duplicate_interval')
      duplicate_count = edit_event_form.find('#duplicate_count')
      replace_content(duplicate_interval, "1")
      replace_content(duplicate_count, "3")
      f('#append_iterator').click
    end

    submit_form(edit_event_form)
    wait_for_ajax_requests
    if should_duplicate
      4.times do |i|
        expect(ff('.fc-month-view .fc-title')[i]).to include_text("#{event_title} #{i + 1}")
      end
    else
      expect(f('.fc-month-view .fc-title')).to include_text(event_title)
    end
  end


  # Creates event from the 'edit event' modal
  def event_from_modal(event_title, should_add_date = false, should_add_location = false)
    edit_event_dialog = f('#edit_event_tabs')
    expect(edit_event_dialog).to be_displayed
    edit_event_form = edit_event_dialog.find('#edit_calendar_event_form')
    title = edit_event_form.find('#calendar_event_title')
    keep_trying_until { title.displayed? }
    replace_content(title, event_title)
    add_date(middle_number) if should_add_date
    replace_content(f('#calendar_event_location_name'), 'location title') if should_add_location
    submit_form(edit_event_form)
    wait_for_ajax_requests
  end

  def header_text
    header = f('.calendar_header .navigation_title')
    header.text
  end

  def create_middle_day_event(name = 'new event', with_date = false, with_location = false, with_duplicates = false)
    get "/calendar2"
    create_calendar_event(name, with_date, with_location, with_duplicates)
  end

  def create_middle_day_assignment(name = 'new assignment')
    get "/calendar2"
    create_assignment_event(name)
  end

  def create_published_middle_day_assignment
    get "/calendar2"
    create_assignment_event('new assignment', false, true)
  end

  def load_week_view
    get "/calendar2"
    f('#week').click
    wait_for_ajaximations
  end

  def load_month_view
    get "/calendar2"
    f('#month').click
    wait_for_ajaximations
  end

  def load_agenda_view
    get "/calendar2"
    f('#agenda').click
    wait_for_ajaximations
  end

  # This checks the date in the edit modal, since Week View and Month view events are placed via absolute
  # positioning and there is no other way to verify the elements are on the right date
  def assert_edit_modal_date(due_at)
    move_to_click('.fc-event')
    wait_for_ajaximations
    expect(f('.event-details-timestring')).to include_text(format_date_for_view(due_at))
  end

  def assert_title(title,agenda_view)
    if agenda_view
      expect(f('.ig-title')).to include_text(title)
    else
      expect(f('.fc-title')).to include_text(title)
    end
  end

  # The following methods verify that created events of all kinds are present in each view and have correct dates
  def assert_agenda_view(title,due)
    load_agenda_view
    assert_title(title,true)
    expect(f('.navigation_title')).to include_text(format_date_for_view(due))
  end

  def assert_week_view(title,due)
    load_week_view
    assert_title(title,false)
    assert_edit_modal_date(due)
  end

  def assert_month_view(title,due)
    load_month_view
    assert_title(title,false)
    assert_edit_modal_date(due)
  end

  def assert_views(title,due)
    assert_agenda_view(title,due)
    assert_week_view(title,due)
    assert_month_view(title,due)
  end
end
