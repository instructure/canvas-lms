require File.expand_path(File.dirname(__FILE__) + '/../common')

  def create_appointment_group(params={})
    tomorrow = Date.today.to_s
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
    tomorrow = Date.today.to_s
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
    keep_trying_until { expect(f('.edit_event_link')).to be_displayed }
    driver.execute_script("$('.edit_event_link').trigger('click')")
    wait_for_ajaximations
  end

def make_event(params = {})
  opts = {
      :context => @user,
      :start => Time.now,
      :description => "Test event"
  }.with_indifferent_access.merge(params)
  c = CalendarEvent.new :description => opts[:description],
                        :start_at => opts[:start],
                        :title => opts[:title]
  c.context = opts[:context]
  c.save!
  c
end

def find_middle_day
  f('.calendar .fc-week:nth-child(1) .fc-wed')
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
  wait_for_ajax_requests
end

def quick_jump_to_date(text)
  f('.navigation_title').click
  dateInput = keep_trying_until { f('.date_field') }
  dateInput.send_keys(text + "\n")
  wait_for_ajaximations
end

def add_date(middle_number)
  fj('.ui-datepicker-trigger:visible').click
  datepicker_current(middle_number)
end

def create_assignment_event(assignment_title, should_add_date = false, publish = false)
  middle_number = find_middle_day.find_element(:css, '.fc-day-number').text
  find_middle_day.click
  edit_event_dialog = f('#edit_event_tabs')
  expect(edit_event_dialog).to be_displayed
  edit_event_dialog.find_element(:css, '.edit_assignment_option').click
  edit_assignment_form = edit_event_dialog.find_element(:id, 'edit_assignment_form')
  title = edit_assignment_form.find_element(:id, 'assignment_title')
  keep_trying_until { title.displayed? }
  replace_content(title, assignment_title)
  add_date(middle_number) if should_add_date
  edit_assignment_form.find_element(:id, 'assignment_published').click if publish
  submit_form(edit_assignment_form)
  keep_trying_until { expect(f('.fc-view-month .fc-event-title')).to include_text(assignment_title) }
end

# Creates event from clicking on the mini calendar
def create_calendar_event(event_title, should_add_date = false, should_add_location = false)
  middle_number = find_middle_day.find_element(:css, '.fc-day-number').text
  find_middle_day.click
  edit_event_dialog = f('#edit_event_tabs')
  expect(edit_event_dialog).to be_displayed
  edit_event_form = edit_event_dialog.find_element(:id, 'edit_calendar_event_form')
  title = edit_event_form.find_element(:id, 'calendar_event_title')
  keep_trying_until { title.displayed? }
  replace_content(title, event_title)
  add_date(middle_number) if should_add_date
  replace_content(f('#calendar_event_location_name'), 'location title') if should_add_location
  submit_form(edit_event_form)
  wait_for_ajax_requests
  keep_trying_until { expect(f('.fc-view-month .fc-event-title')).to include_text(event_title) }
end


# Creates event from the 'edit event' modal
def event_from_modal(event_title, should_add_date = false, should_add_location = false)
  edit_event_dialog = f('#edit_event_tabs')
  expect(edit_event_dialog).to be_displayed
  edit_event_form = edit_event_dialog.find_element(:id, 'edit_calendar_event_form')
  title = edit_event_form.find_element(:id, 'calendar_event_title')
  keep_trying_until { title.displayed? }
  replace_content(title, event_title)
  add_date(middle_number) if should_add_date
  replace_content(f('#calendar_event_location_name'), 'location title') if should_add_location
  submit_form(edit_event_form)
  wait_for_ajax_requests
end

def get_header_text
  header = f('.calendar_header .navigation_title')
  header.text
end

def create_middle_day_event(name = 'new event', with_date = false, with_location = false)
  get "/calendar2"
  create_calendar_event(name, with_date, with_location)
end

def create_middle_day_assignment(name = 'new assignment')
  get "/calendar2"
  create_assignment_event(name)
end

def create_published_middle_day_assignment
  get "/calendar2"
  create_assignment_event(name = 'new assignment', false, true)
end

def load_week_view
  get "/calendar2"
  wait_for_ajaximations
  f('#week').click
  wait_for_ajaximations
end
