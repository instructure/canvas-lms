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

    context "week view" do

      it "should navigate to week view when week button is clicked", priority: "2" do
        load_week_view
        expect(fj('.fc-agendaWeek-view:visible')).to be_present
      end

      it "should render assignments due just before midnight" do
        skip("fails on event count validation")
        assignment_model(:course => @course,
                         :title => "super important",
                         :due_at => Time.zone.now.beginning_of_day + 1.day - 1.minute)
        calendar_events = @teacher.calendar_events_for_calendar.last

        expect(calendar_events.title).to eq "super important"
        expect(@assignment.due_date).to eq (Time.zone.now.beginning_of_day + 1.day - 1.minute).to_date

        load_week_view
        keep_trying_until do
          events = ff('.fc-event').select { |e| e.text =~ /due.*super important/ }
          # shows on monday night and tuesday morning
          expect(events.size).to eq 2
        end
      end

      it "should show short events at full height" do
        noon = Time.now.at_beginning_of_day + 12.hours
        event = @course.calendar_events.create! :title => "ohai", :start_at => noon, :end_at => noon + 5.minutes

        load_week_view

        elt = fj('.fc-event:visible')
        expect(elt.size.height).to be >= 18
      end

      it "should stagger pseudo-overlapping short events" do
        noon = Time.now.at_beginning_of_day + 12.hours
        first_event = @course.calendar_events.create! :title => "ohai", :start_at => noon, :end_at => noon + 5.minutes
        second_start = first_event.start_at + 6.minutes
        second_event = @course.calendar_events.create!(:title => "ohai", :start_at => second_start, :end_at => second_start + 5.minutes)

        load_week_view

        elts = ffj('.fc-event:visible')
        expect(elts.size).to eql(2)

        elt_lefts = elts.map { |elt| elt.location.x }.uniq
        expect(elt_lefts.size).to eql(elts.size)
      end

      it "should not change duration when dragging a short event" do
        skip("dragging events doesn't seem to work")
        noon = Time.zone.now.at_beginning_of_day + 12.hours
        event = @course.calendar_events.create! :title => "ohai", :start_at => noon, :end_at => noon + 5.minutes
        load_week_view

        elt = fj('.fc-event:visible')
        driver.action.drag_and_drop_by(elt, 0, 50)
        wait_for_ajax_requests
        expect(event.reload.start_at).to eql(noon + 1.hour)
        expect(event.reload.end_at).to eql(noon + 1.hour + 5.minutes)
      end

      it "should change duration of a short event when dragging resize handle" do
        skip("dragging events doesn't seem to work")
        noon = Time.zone.now.at_beginning_of_day + 12.hours
        event = @course.calendar_events.create! :title => "ohai", :start_at => noon, :end_at => noon + 5.minutes
        load_week_view

        resize_handle = fj('.fc-event:visible .ui-resizable-handle')
        driver.action.drag_and_drop_by(resize_handle, 0, 50).perform
        wait_for_ajaximations

        expect(event.reload.start_at).to eql(noon)
        expect(event.end_at).to eql(noon + 1.hours + 30.minutes)
      end

      it "should show the right times in the tool tips for short events" do
        noon = Time.zone.now.at_beginning_of_day + 12.hours
        event = @course.calendar_events.create! :title => "ohai", :start_at => noon, :end_at => noon + 5.minutes
        load_week_view

        elt = fj('.fc-event:visible')
        expect(elt.attribute('title')).to match(/12:00.*12:05/)
      end

      it "should update the event as all day if dragged to all day row" do
        skip("dragging events doesn't seem to work")
      end
    end

    it "should display correct dates after navigation arrow", priority: "1", test_id: 417600 do
      load_week_view
      quick_jump_to_date('Jan 1, 2012')
      change_calendar(:next)

      # Verify Week and Day labels are correct
      expect(get_header_text).to include_text("Jan 8 — 14, 2012")
      expect(f('.fc-sun')).to include_text('SUN 1/8')
    end

    it "should create event by clicking on week calendar", priority: "1", test_id: 138862 do
      title = "from clicking week calendar"
      load_week_view

      # Click non all-day event
      fj('.fc-agendaWeek-view .fc-time-grid .fc-slats .fc-widget-content:not(.fc-axis):first').click
      event_from_modal(title,false,false)
      expect(f('.fc-title').text).to include title
    end

    it "should create all day event on week calendar", priority: "1", test_id: 138865 do
      title = "all day event title"
      load_week_view

      # click all day event
      fj('.fc-agendaWeek-view .fc-week .fc-wed').click
      event_from_modal(title,false,false)
      expect(f('.fc-title').text).to include title
    end

    it "should have a working today button", priority: "1", test_id: 142042 do
      load_week_view

      # Mini calendar on the right of page has this html element I am looking for so
      #   when checking for "today", we need to look for the second instance of the class

      # Check for highlight to be present on this week
      expect(ff(".fc-agendaWeek-view .fc-today").size).to eq 2

      # Change calendar week until the highlight is not there (it should eventually)
      count = 0
      while ff(".fc-agendaWeek-view .fc-today").size > 0
        change_calendar
        count += 1
        raise if count > 10
      end

      # Back to today. Make sure that the highlight is present again
      change_calendar(:today)
      expect(ff(".fc-agendaWeek-view .fc-today").size).to eq 2
    end

    it "should show the location when clicking on a calendar event" do
      location_name = "brighton"
      location_address = "cottonwood"

      # Make it an all day event so it will be visible on the screen/on top
      make_event(:location_name => location_name, :all_day => true, :location_address => location_address)
      load_week_view

      #Click calendar item to bring up event summary
      f(".fc-event").click

      #expect to find the location name and address
      expect(f('.event-details-content').text).to include_text(location_name)
      expect(f('.event-details-content').text).to include_text(location_address)
    end

    it "should bring up a calendar date picker when clicking on the week range" do
      load_week_view
      #Click on the week header
      f('.navigation_title').click

      # Expect that a the event picker is present
      # Check various elements to verify that the calendar looks good
      expect(f('.ui-datepicker-header').text).to include_text(Time.now.utc.strftime("%B"))
      expect(f('.ui-datepicker-calendar').text).to include_text("Mo")
    end

    # calendar markup has changed significantly making this more difficult to test
    # but it still works based on manual testing
    # TODO: reimplement in a future PS

    # it "should extend event time with dragging", priority: "1", test_id: 138864 do
    #   # Create event on current day at 1:00 AM in current time zone
    #   start_time = Time.zone.now.beginning_of_day + 1.hour
    #   make_event(:start => start_time)
    #   load_week_view

    #   # Drag and drop to "Slot 11", which will result in event end at 6:00 AM
    #   drag_and_drop_element(fj('.ui-resizable-handle'), fj('.fc-slot11'))
    #   expect(fj('.fc-event-time')).to include_text('1:00 - 6:00')
    # end
  end
end
