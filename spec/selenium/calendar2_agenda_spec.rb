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

    context "agenda view" do
      before(:each) do
        account = Account.default
        account.settings[:agenda_view] = true
        account.save!
      end

      it "should create a new event" do
        get '/calendar2'
        wait_for_ajaximations
        f('#agenda').click
        wait_for_ajaximations
        expect(fj('.agenda-wrapper:visible')).to be_present
        f('#create_new_event_link').click
        fj('.ui-dialog:visible .btn-primary').click
        wait_for_ajaximations
        expect(ffj('.ig-row').length).to eq 1 #expects there to be one new event on Agenda index page
      end

      it "should display agenda events" do
        get '/calendar2'
        wait_for_ajaximations
        f('#agenda').click
        wait_for_ajaximations
        expect(fj('.agenda-wrapper:visible')).to be_present
      end

      it "should set the header in the format 'Oct 11, 2013'" do
        start_date = Time.now.beginning_of_day + 12.hours
        event = @course.calendar_events.create!(title: "ohai",
                                                start_at: start_date, end_at: start_date + 1.hour)
        get '/calendar2'
        wait_for_ajaximations
        f('#agenda').click
        wait_for_ajaximations
        expect(f('.navigation_title').text).to match(/[A-Z][a-z]{2}\s\d{1,2},\s\d{4}/)
        sleep 30
      end

      it "should respect context filters" do
        start_date = Time.now.utc.beginning_of_day + 12.hours
        event = @course.calendar_events.create!(title: "ohai",
                                                start_at: start_date, end_at: start_date + 1.hour)
        get '/calendar2'
        wait_for_ajaximations
        f('#agenda').click
        wait_for_ajaximations
        expect(ffj('.ig-row').length).to eq 1
        fj('.context-list-toggle-box:last').click
        wait_for_ajaximations
        expect(ffj('.ig-row').length).to eq 0
      end

      it "should be navigable via the jump-to-date control" do
        yesterday = 1.day.ago
        event = make_event(start: yesterday)
        get "/calendar2"
        wait_for_ajaximations
        f('#agenda').click
        wait_for_ajaximations
        expect(ffj('.ig-row').length).to eq 0
        quick_jump_to_date(yesterday.strftime("%b %-d %Y"))
        wait_for_ajaximations
        expect(ffj('.ig-row').length).to eq 1
      end

      it "should be navigable via the minical" do
        yesterday = 1.day.ago
        event = make_event(start: yesterday)
        get "/calendar2"
        wait_for_ajaximations
        f('#agenda').click
        wait_for_ajaximations
        expect(ffj('.ig-row').length).to eq 0
        f('.fc-button-prev').click
        f('#right-side .fc-day-number').click
        wait_for_ajaximations
        keep_trying_until { expect(ffj('.ig-row').length).to eq 1 }
      end

      it "should persist the start date across reloads" do
        get "/calendar2"
        wait_for_ajaximations
        f('#agenda').click
        next_year = 1.year.from_now.strftime("%Y")
        quick_jump_to_date(next_year)
        refresh_page
        wait_for_ajaximations
        expect(f('.navigation_title')).to include_text(next_year)
      end

      it "should transfer the start date when switching views" do
        get "/calendar2"
        wait_for_ajaximations
        f('.navigate_next').click()
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
        get "/calendar2"
        wait_for_ajaximations
        f('#agenda').click
        wait_for_ajaximations
        expect(f('.navigation_title')).to include_text(Time.now.utc.strftime("%b %-d, %Y"))
        expect(f('.navigation_title')).to include_text(tomorrow.utc.strftime("%b %-d, %Y"))
      end

      it "should not display a date range if no events are found" do
        get "/calendar2"
        wait_for_ajaximations
        f('#agenda').click
        wait_for_ajaximations
        expect(f('.navigation_title')).not_to include_text('Invalid')
      end

      it "should allow editing events" do
        tomorrow = 1.day.from_now
        event = make_event(start: tomorrow)
        get "/calendar2"
        wait_for_ajaximations
        f('#agenda').click
        wait_for_ajaximations
        f('.ig-row').click()
        f('.event-details .delete_event_link').click()
        fj('.ui-dialog:visible .btn-primary').click()
        wait_for_ajaximations
        expect(ffj('.ig-row').length).to eq 0
      end

      it "should display midnight assignments at 11:59" do
        assignment_model(:course => @course,
                         :title => "super important",
                         :due_at => Time.zone.now.beginning_of_day + 1.day - 1.minute)
        calendar_events = @teacher.calendar_events_for_calendar.last

        expect(calendar_events.title).to eq "super important"
        expect(@assignment.due_date).to eq (Time.zone.now.beginning_of_day + 1.day - 1.minute).to_date

        get "/calendar2"
        wait_for_ajaximations

        f('#agenda').click
        wait_for_ajaximations

        expect(f('.ig-details')).to include_text('11:59')
        f('.ig-row').click()
        expect(fj('.event-details:visible time')).to include_text('11:59')
      end
    end
  end
end
