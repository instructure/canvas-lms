require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/calendar2_common')

describe "calendar2" do
  include_examples "in-process server selenium tests"

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

      it "should navigate to week view when week button is clicked", :priority => "2" do
        load_week_view
        expect(fj('.fc-view-agendaWeek:visible')).to be_present
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

    it "should change the week" do
      get "/calendar2"
      header_buttons = ff('.btn-group .btn')
      header_buttons[0].click
      wait_for_ajaximations
      old_header_title = get_header_text
      change_calendar(:prev)
      expect(old_header_title).not_to eq get_header_text
    end

    it "should create event by clicking on week calendar" do
      title = "from clicking week calendar"
      load_week_view

      #Clicking on the second row so it is not set as an all day event
      ff('.fc-widget-content')[1].click #click on calendar

      event_from_modal(title,false,false)
      expect(f('.fc-event-time').text).to include title
    end

    it "should create all day event on week calendar" do
      title = "all day event title"
      load_week_view

      #Clicking on the first instance of .fc-widget-content clicks in all day row
      f('.fc-widget-content').click #click on calendar

      event_from_modal(title,false,false)

      # Only all day events have the .fc-event-title class
      expect(f('.fc-event-title').text).to include title
    end

    it "should have a working today button" do
      load_week_view

      # Mini calendar on the right of page has this html element I am looking for so
      #   when checking for "today", we need to look for the second instance of the class

      # Check for highlight to be present on this week
      expect(ff(".fc-today")[1]).not_to be_nil

      # Change calendar week and make sure that the highlight is not there
      change_calendar
      expect(ff(".fc-today")[1]).to be_nil

      # Back to today. Make sure that the highlight is present s
      change_calendar(:today)
      expect(ff(".fc-today")[1]).not_to be_nil
    end

    it "should show the location when clicking on a calendar event" do
      location_name = "brighton"
      location_address = "cottonwood"

      # Make it an all day event so it will be visible on the screen/on top
      make_event(:location_name => location_name, :all_day => true, :location_address => location_address)
      load_week_view

      #Click calendar item to bring up event summary
      f(".fc-event-inner").click

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
  end
end
