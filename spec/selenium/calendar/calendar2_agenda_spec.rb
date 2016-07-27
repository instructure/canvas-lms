require_relative "../common"
require_relative "../helpers/calendar2_common"

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

    context "agenda view" do
      before(:each) do
        account = Account.default
        account.settings[:agenda_view] = true
        account.save!
      end

      it "should create a new event via plus button", priority: "1", test_id: 250293 do
        load_agenda_view

        # Clicks plus button, saves event, and verifies a row has been added
        expect(fj('.agenda-wrapper:visible')).to be_present
        f('#create_new_event_link').click
        fj('.ui-dialog:visible .btn-primary').click
        wait_for_ajaximations
        expect(ffj('.ig-row').length).to eq 1
      end

      it "should display agenda events" do
        load_agenda_view
        expect(fj('.agenda-wrapper:visible')).to be_present
      end

      it "should set the header in the format 'Oct 11, 2013'", priority: "1", test_id: 28546 do
        start_date = Time.now.beginning_of_day + 12.hours
        event = @course.calendar_events.create!(title: "ohai",
                                                start_at: start_date, end_at: start_date + 1.hour)
        load_agenda_view
        expect(f('.navigation_title').text).to match(/[A-Z][a-z]{2}\s\d{1,2},\s\d{4}/)
      end

      it "should respect context filters" do
        start_date = Time.now.utc.beginning_of_day + 12.hours
        event = @course.calendar_events.create!(title: "ohai",
                                                start_at: start_date, end_at: start_date + 1.hour)
        load_agenda_view
        expect(ff('.ig-row').length).to eq 1
        fj('.context-list-toggle-box:last').click
        wait_for_ajaximations
        expect(f("#content")).not_to contain_css('.ig-row')
      end

      it "should be navigable via the jump-to-date control" do
        yesterday = 1.day.ago
        event = make_event(start: yesterday)
        load_agenda_view
        expect(f("#content")).not_to contain_css('.ig-row')
        quick_jump_to_date(yesterday.strftime("%b %-d %Y"))
        wait_for_ajaximations
        expect(ff('.ig-row').length).to eq 1
      end

      it "should be navigable via the minical" do
        yesterday = 1.day.ago
        event = make_event(start: yesterday)
        load_agenda_view
        expect(f("#content")).not_to contain_css('.ig-row')
        f('.fc-prev-button').click
        f('#right-side .fc-day-number').click
        expect(ff('.ig-row').length).to eq 1
      end

      it "should persist the start date across reloads" do
        load_agenda_view
        next_year = 1.year.from_now.strftime("%Y")
        quick_jump_to_date(next_year)
        refresh_page
        wait_for_ajaximations
        expect(f('.navigation_title')).to include_text(next_year)
      end

      it "should transfer the start date when switching views" do
        get "/calendar2"
        f('.navigate_next').click
        f('#agenda').click
        expect(f('.navigation_title')).to include_text(1.month.from_now.strftime("%b"))
        next_year = 1.year.from_now.strftime("%Y")
        quick_jump_to_date(next_year)
        f('#month').click
        expect(f('.navigation_title')).to include_text(next_year)
      end

      it "should display the displayed date range in the header" do
        tomorrow = 1.day.from_now
        event = make_event(start: tomorrow)
        load_agenda_view
        expect(f('.navigation_title')).to include_text(format_date_for_view(Time.zone.now, :medium))
        expect(f('.navigation_title')).to include_text(format_date_for_view(tomorrow, :medium))
      end

      it "should not display a date range if no events are found" do
        load_agenda_view
        expect(f('.navigation_title')).not_to include_text('Invalid')
      end

      it "should allow deleting events", priority: "1", test_id: 138857 do
        tomorrow = 3.day.from_now
        event = make_event(start: tomorrow)

        load_agenda_view
        expect(f(".ig-title")).to include_text("User Event")

        f('.ig-row').click
        f('.event-details .delete_event_link').click
        fj('.ui-dialog:visible .btn-primary').click

        expect(f("#content")).not_to contain_css('.ig-row')
      end

      it "should allow deleting assignments", priority: "1", test_id: 138858 do
        title = "Maniac Mansion"
        @assignment = @course.assignments.create!(:name => title,:due_at => 3.day.from_now)

        load_agenda_view
        expect(f(".ig-title")).to include_text(title)

        f('.ig-row').click
        f('.event-details .delete_event_link').click
        fj('.ui-dialog:visible .btn-primary').click

        expect(f("#content")).not_to contain_css('.ig-row')
      end

      it "should allow deleting a quiz", priority: "1" do
        create_quiz

        load_agenda_view
        expect(f(".ig-title")).to include_text("Test Quiz")

        f('.ig-row').click
        f('.event-details .delete_event_link').click
        fj('.ui-dialog:visible .btn-primary').click

        expect(f("#content")).not_to contain_css('.ig-row')
      end

      it "should display midnight assignments at 11:59" do
        assignment_model(:course => @course,
                         :title => "super important",
                         :due_at => Time.zone.now.beginning_of_day + 1.day - 1.minute)
        calendar_events = @teacher.calendar_events_for_calendar.last

        expect(calendar_events.title).to eq "super important"
        expect(@assignment.due_date).to eq (Time.zone.now.beginning_of_day + 1.day - 1.minute).to_date

        load_agenda_view

        expect(f('.ig-details')).to include_text('11:59')
        f('.ig-row').click
        expect(fj('.event-details:visible time')).to include_text('11:59')
      end

      it "should have a working today button", priority: "1", test_id: 28550 do
        load_month_view
        #Go to a future calendar date to test going back
        change_calendar

        #Get the current date and make sure it is not in the header
        date = format_date_for_view(Time.zone.now, :medium)
        expect(f('.navigation_title').text).not_to include(date)

        #Go the agenda view and click the today button
        f('#agenda').click
        wait_for_ajaximations
        change_calendar(:today)

        #Make sure that today's date is in the header
        expect(f('.navigation_title').text).to include(date)
      end

      it "should show the location when clicking on a calendar event", priority: "1", test_id: 138890 do
        location_name = "brighton"
        location_address = "cottonwood"
        make_event(:location_name => location_name, :location_address => location_address)
        load_agenda_view

        #Click calendar item to bring up event summary
        f(".ig-row").click

        #expect to find the location name and address
        expect(f('.event-details-content')).to include_text(location_name)
        expect(f('.event-details-content')).to include_text(location_address)
      end

      it "should bring up a calendar date picker when clicking on the agenda range", priority: "1", test_id: 140223 do
        load_agenda_view

        #Click on the agenda header
        f('.navigation_title').click

        # Expect that a the event picker is present
        # Check various elements to verify that the calendar looks good
        expect(f('.ui-datepicker-header')).to include_text(Time.now.utc.strftime("%B"))
        expect(f('.ui-datepicker-calendar')).to include_text("Mo")
      end

      it "show quizes on agenda view", priority: "1", test_id: 138850 do
        create_quiz

        load_agenda_view
        expect(f(".agenda-event")).to include_text('Test Quiz')
      end

      it "should show assignment due dates for different sections", priority: "1", test_id: 138848 do
        assignment = @course.assignments.create!(name: 'Test Title', due_at: 1.day.from_now)

        # Create Sections and Differentiated Assignment
        s1 = @course.course_sections.create!(name: 'Section1')
        s2 = @course.course_sections.create!(name: 'Section2')
        s1_date = rand(2...9).day.from_now
        s2_date = s1_date + 1.days
        @override = create_section_override_for_assignment(assignment, course_section: s1, due_at: s1_date)
        @override = create_section_override_for_assignment(assignment, course_section: s2, due_at: s2_date)

        load_agenda_view
        expect(ff('.ig-row')).to have_size(3)

        # Verify Titles include section name
        agenda_array = ff('.ig-row')
        expect(f('.ig-title', agenda_array[1])).to include_text('Section1')
        expect(f('.ig-title', agenda_array[2])).to include_text('Section2')

        # Verify Dates
        date_array = ff('.agenda-day')
        expect(f('.agenda-date', date_array[1])).to include_text(format_date_for_view(s1_date, :short_with_weekday))
        expect(f('.agenda-date', date_array[2])).to include_text(format_date_for_view(s2_date, :short_with_weekday))
      end

      context "with a graded discussion created" do
        before(:each) do
          create_graded_discussion
        end

        it "should allow deleting a graded discussion", priority: "1", test_id: 138859 do
          load_agenda_view
          expect(f('.ig-title')).to include_text('Graded Discussion')

          f('.ig-row').click
          f('.event-details .delete_event_link').click
          fj('.ui-dialog:visible .btn-primary').click

          expect(f("#content")).not_to contain_css('.ig-row')
        end

        it "should allow editing via modal", priority: "1", test_id: 138855 do
          test_date = 2.days.from_now
          test_name = 'Test Title'
          load_agenda_view

          # Open Edit modal
          f('.ig-row').click
          wait_for_ajaximations
          f('.event-details .edit_event_link').click
          wait_for_ajaximations

          # Edit title and date
          replace_content(fj('.ui-dialog:visible #assignment_title'), test_name)
          replace_content(fj('.ui-dialog:visible #assignment_due_at'), test_date.to_formatted_s(:long))
          fj('.ui-dialog:visible .btn-primary').click
          wait_for_ajaximations

          # Verify edits
          expect(f('.ig-title')).to include_text(test_name)
          expect(f('.agenda-date')).to include_text(date_string(test_date, :short_with_weekday))
        end

        it "should allow editing via More Options", priority: "1", test_id: 420724 do
          skip('final load_agenda_view is fragile, needs analysis')
          test_date = 2.days.from_now.change(hours: 13, min: 59, sec: 0, usec: 0)
          test_title = 'Test Title'
          test_description = 'New Description'
          load_agenda_view

          # Open More Options window
          f('.ig-row').click
          wait_for_ajaximations
          f('.edit_event_link').click
          wait_for_ajaximations
          f('.event_button').click
          wait_for_ajaximations

          # Edit title, description, and date
          replace_content(f('#discussion-title.input-block-level'), test_title + '1')
          driver.execute_script "tinyMCE.activeEditor.setContent('#{test_description}')"
          replace_content(f('.DueDateInput'), format_time_for_view(test_date))
          f('.form-actions.flush .btn.btn-primary').click
          wait_for_ajaximations

          # Verify edited title, description, and date
          load_agenda_view
          expect(ff('.ig-row')).to have_size(1)
          f('.ig-row').click
          wait_for_ajaximations
          expect(f('.view_event_link')).to include_text(test_title)
          expect(f('.event-detail-overflow')).to include_text(test_description)
          expect(f('.event-details-timestring')).to include_text(format_time_for_view(test_date))
        end
      end
    end
  end

  context "as a student" do
    before(:each) do
        course_with_teacher(:active_all => true, :name => 'teacher@example.com')
        course_with_student_logged_in
      end

    it "student can not delete events created by a teacher", priority: "1", test_id: 138856 do
      # create an event as the teacher
      @course.calendar_events.create!(title: "Monkey Island", start_at: Time.zone.now.advance(days:4))

      # browse to the view as a student
      load_agenda_view

      # click on the event and rxpect there not to be a delete button
      f('.ig-row').click
      expect(f("#content")).not_to contain_css('.event-details .delete_event_link')
    end
  end
end
