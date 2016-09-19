require File.expand_path(File.dirname(__FILE__) + '/../common')
require File.expand_path(File.dirname(__FILE__) + '/../helpers/calendar2_common')

describe "calendar2" do
  include_context "in-process server selenium tests"
  include Calendar2Common

  before(:each) do
    Account.default.tap do |a|
      a.settings[:show_scheduler]   = true
      a.save!
    end
  end

  context "as a teacher" do
    before(:each) do
      course_with_teacher_logged_in
    end
    context "event creation" do
      it "should create an event by hitting the '+' in the top bar" do
        event_title = 'new event'
        get "/calendar2"

        fj('#create_new_event_link').click
        edit_event_dialog = f('#edit_event_tabs')
        expect(edit_event_dialog).to be_displayed
      end

      it "should create an event with a location name" do
        event_name = 'event with location'
        create_middle_day_event(event_name, false, true)
        fj('.fc-event:visible').click
        expect(fj('.event-details-content:visible')).to include_text('location title')
      end

      it 'should create an event with location name and address' do
        get "/calendar2"
        event_title = 'event title'
        location_name = 'my house'
        location_address = '555 test street'
        find_middle_day.click
        edit_event_dialog = f('#edit_event_tabs')
        expect(edit_event_dialog).to be_displayed
        edit_event_form = edit_event_dialog.find('#edit_calendar_event_form')
        title = edit_event_form.find('#calendar_event_title')
        expect(title).to be_displayed
        replace_content(title, event_title)
        expect_new_page_load { f('.more_options_link').click }
        expect(driver.current_url).to match /start_date=\d\d\d\d-\d\d-\d\d/  # passed in ISO format, not localized
        expect(f('.title')).to have_value event_title
        expect(f('#editCalendarEventFull .btn-primary').text).to eq "Create Event"
        replace_content(f('#calendar_event_location_name'), location_name)
        replace_content(f('#calendar_event_location_address'), location_address)
        expect_new_page_load { submit_form(f('#editCalendarEventFull')) }
        wait = Selenium::WebDriver::Wait.new(timeout: 5)
        wait.until { !fj('.fc-event:visible').nil? }
        fj('.fc-event:visible').click
        event_content = fj('.event-details-content:visible')
        expect(event_content).to include_text(location_name)
        expect(event_content).to include_text(location_address)
      end

      it "should go to calendar event modal when a syllabus link is clicked", priority: "1", test_id: 186581 do
        event_title = "Test Event"
        make_event(title: event_title, context: @course)

        # Verifies we are taken to the event in Calendar after clicking on it in Syllabus
        get "/courses/#{@course.id}/assignments/syllabus"
        fj("a:contains('#{event_title}')").click
        wait_for_ajaximations

        expect(fj('.event-details-header:visible')).to be_displayed
        expect(f('.view_event_link')).to include_text(event_title)
      end

      it "should be able to create an event for a group" do
        group(:context => @course)

        get "/groups/#{@group.id}"
        expect_new_page_load { f('.event-list-view-calendar').click }
        event_name = 'some name'
        create_calendar_event(event_name, false, false, false)

        event = @group.calendar_events.last
        expect(event.title).to eq event_name
      end

      it "should create a recurring event", priority: "1", test_id: 223510 do
        Account.default.enable_feature!(:recurring_calendar_events)
        get '/calendar2'
        expect(f('#context-list li:nth-of-type(1)').text).to include(@teacher.name)
        expect(f('#context-list li:nth-of-type(2)').text).to include(@course.name)
        fj('.calendar .fc-week .fc-today').click
        edit_event_dialog = f('#edit_event_tabs')
        expect(edit_event_dialog).to be_displayed
        edit_event_form = edit_event_dialog.find('#edit_calendar_event_form')
        title = edit_event_form.find('#calendar_event_title')
        replace_content(title, "Test Event")
        replace_content(f("input[type=text][name= 'start_time']"), "6:00am")
        replace_content(f("input[type=text][name= 'end_time']"), "6:00pm")
        click_option(f('.context_id'), @course.name)
        expect_new_page_load { f('.more_options_link').click }
        expect(f('.title')).to have_value "Test Event"
        f('#duplicate_event').click
        replace_content(f("input[type=number][name='duplicate_count']"), 2)

        expect_new_page_load{f('button[type="submit"]').click}
        expect(CalendarEvent.count).to eq(3)
        repeat_event = CalendarEvent.where(title: "Test Event")
        expect((repeat_event[0].start_at).to_date).to eq(Time.zone.now.to_date)
        expect((repeat_event[1].start_at).to_date).to eq((Time.zone.now + 1.week).to_date)
        expect((repeat_event[2].start_at).to_date).to eq((Time.zone.now + 2.weeks).to_date)
      end

      it "should create recurring section-specific events" do
        Account.default.enable_feature!(:recurring_calendar_events)
        section1 = @course.course_sections.first
        section2 = @course.course_sections.create!(:name => "other section")

        day1 = 1.day.from_now.to_date
        day2 = 2.days.from_now.to_date

        get '/calendar2'
        fj('.calendar .fc-week .fc-today').click
        edit_event_dialog = f('#edit_event_tabs')
        edit_event_form = edit_event_dialog.find('#edit_calendar_event_form')
        title = edit_event_form.find('#calendar_event_title')
        replace_content(title, "Test Event")
        click_option(f('.context_id'), @course.name)
        expect_new_page_load { f('.more_options_link').click }

        f('#use_section_dates').click

        f("#section_#{section1.id}_start_date").send_keys(day1.to_s)
        f("#section_#{section2.id}_start_date").send_keys(day2.to_s)

        ff(".date_start_end_row input.start_time").select(&:displayed?).each do |input|
          replace_content(input, "11:30am")
        end
        ff(".date_start_end_row input.end_time").select(&:displayed?).each do |input|
          replace_content(input, "1pm")
        end

        f('#duplicate_event').click
        replace_content(f("input[type=number][name='duplicate_count']"), 1)

        expect_new_page_load{f('button[type="submit"]').click}

        expect(CalendarEvent.count).to eq(6) # 2 parent events each with 2 child events
        s1_events = CalendarEvent.where(:context_code => section1.asset_string).where.not(:parent_calendar_event_id => nil).order(:start_at).to_a
        expect(s1_events[0].start_at.to_date).to eq day1
        expect(s1_events[1].start_at.to_date).to eq (day1 + 1.week)

        s2_events = CalendarEvent.where(:context_code => section2.asset_string).where.not(:parent_calendar_event_id => nil).order(:start_at).to_a
        expect(s2_events[0].start_at.to_date).to eq day2
        expect(s2_events[1].start_at.to_date).to eq (day2 + 1.week)
      end
    end
  end
end
