require File.expand_path(File.dirname(__FILE__) + '/../common')
require File.expand_path(File.dirname(__FILE__) + '/../helpers/calendar2_common')

describe "calendar2" do
  include_context "in-process server selenium tests"

  before (:each) do
    Account.default.tap do |a|
      a.settings[:show_scheduler]   = true
      a.save!
    end
  end

  context "as a teacher" do
    before (:each) do
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
        edit_event_form = edit_event_dialog.f('#edit_calendar_event_form')
        title = edit_event_form.f('#calendar_event_title')
        keep_trying_until { title.displayed? }
        replace_content(title, event_title)
        expect_new_page_load { f('.more_options_link').click }
        expect(f('.title').attribute('value')).to eq event_title
        expect(f('#editCalendarEventFull .btn-primary').text).to eq "Create Event"
        replace_content(f('#calendar_event_location_name'), location_name)
        replace_content(f('#calendar_event_location_address'), location_address)
        expect_new_page_load { submit_form(f('#editCalendarEventFull')) }
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

        keep_trying_until(5) {expect(fj('.event-details-header:visible')).to be_displayed}
        expect(f('.view_event_link')).to include_text(event_title)
      end
    end
  end
end
