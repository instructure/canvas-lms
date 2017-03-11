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

  context "as a student" do
    before(:each) do
      @student = course_with_student_logged_in(:active_all => true).user
    end

    describe "main calendar" do
      it "should validate appointment group popup link functionality" do
        create_appointment_group
        ag = AppointmentGroup.first
        ag.appointments.first.reserve_for @student, @me

        @user = @me
        get "/calendar2"

        fj('.fc-event:visible').click
        expect(fj("#popover-0")).to be_displayed
        expect_new_page_load { driver.execute_script("$('#popover-0 .view_event_link').hover().click()") }


        expect(f('#scheduler')).to have_class('active')
        expect(f('#appointment-group-list')).to include_text(ag.title)
      end

      it "should show section-level events for the student's section" do
        @course.default_section.update_attribute(:name, "default section!")
        s2 = @course.course_sections.create!(:name => "other section!")
        date = Date.today
        e1 = @course.calendar_events.build :title => "ohai",
                                           :child_event_data => [
                                               {:start_at => "#{date} 12:00:00", :end_at => "#{date} 13:00:00", :context_code => s2.asset_string},
                                               {:start_at => "#{date} 13:00:00", :end_at => "#{date} 14:00:00", :context_code => @course.default_section.asset_string},
                                           ]
        e1.updating_user = @teacher
        e1.save!

        get "/calendar2"
        events = ff('.fc-event')
        expect(events.size).to eq 1
        expect(events.first.text).to include "1p"
        expect(events.first).not_to have_class 'fc-draggable'
        events.first.click

        details = f('.event-details-content')
        expect(details).not_to be_nil
        expect(details.text).to include(@course.default_section.name)
      end

      it "should display title link and go to event details page" do
        make_event(:context => @course, :start => 0.days.from_now, :title => "future event")
        get "/calendar2"

        # click the event in the calendar
        fj('.fc-event').click
        expect(fj("#popover-0")).to be_displayed
        expect_new_page_load { driver.execute_script("$('.view_event_link').hover().click()") }

        page_title = f('.title')
        expect(page_title).to be_displayed
        expect(page_title.text).to eq 'future event'
      end

      it "should not redirect but load the event details page" do
        event = make_event(:context => @course, :start => 2.months.from_now, :title => "future event")
        get "/courses/#{@course.id}/calendar_events/#{event.id}"
        page_title = f('.title')
        expect(page_title).to be_displayed
        expect(page_title.text).to eq 'future event'
      end

      it "should let the group members create a calendar event for the group", priority: "1", test_id: 323330 do
        group = @course.groups.create!(name: "Test Group")
        group.add_user @student
        group.save!
        get '/calendar2'
        fj('.calendar .fc-week .fc-today').click
        edit_event_dialog = f('#edit_event_tabs')
        expect(edit_event_dialog).to be_displayed
        edit_event_form = edit_event_dialog.find('#edit_calendar_event_form')
        title = edit_event_form.find('#calendar_event_title')
        replace_content(title, "Test Event")
        replace_content(fj("input[type=text][name= 'start_time']"), "6:00am")
        replace_content(fj("input[type=text][name= 'end_time']"), "6:00pm")
        expect(get_options('.context_id').map(&:text)).to include(group.name)
        click_option(f('.context_id'), group.name)
        submit_form(f('#edit_calendar_event_form'))
        wait_for_ajaximations
        expect(CalendarEvent.last.title).to eq("Test Event")
      end
    end
  end

  context "as a spanish student" do
    before (:each) do
      # Setup with spanish locale
      @student = course_with_student_logged_in(:active_all => true).user
      @student.locale = 'es'
      @student.save!
    end

    describe "main calendar" do
      it "should display in Spanish" do
        skip('USE_OPTIMIZED_JS=true') unless ENV['USE_OPTIMIZED_JS']
        date = Date.new(2012, 7, 12)
        # Use event to  open to a specific and testable month
        event = calendar_event_model(:title => 'Test Event', :start_at => date, :end_at => (date + 1.hour))

        get "/courses/#{@course.id}/calendar_events/#{event.id}?calendar=1"
        expect(fj('.calendar_header .navigation_title').text).to eq 'julio 2012'
        expect(fj('#calendar-app .fc-sun').text).to eq 'DOM.'
        expect(fj('#calendar-app .fc-mon').text).to eq 'LUN.'
        expect(fj('#calendar-app .fc-tue').text).to eq 'MAR.'
        expect(fj('#calendar-app .fc-wed').text).to eq 'MIÉ.'
        expect(fj('#calendar-app .fc-thu').text).to eq 'JUE.'
        expect(fj('#calendar-app .fc-fri').text).to eq 'VIE.'
        expect(fj('#calendar-app .fc-sat').text).to eq 'SÁB.'
      end
    end

    describe "mini calendar" do
      it "should display in Spanish" do
        skip('USE_OPTIMIZED_JS=true') unless ENV['USE_OPTIMIZED_JS']
        skip('RAILS_LOAD_ALL_LOCALES=true') unless ENV['RAILS_LOAD_ALL_LOCALES']
        get "/calendar2"
        # Get the spanish text for the current month/year
        expect_month_year = I18n.l(Date.today, :format => '%B %Y', :locale => 'es')
        expect(fj('#minical h2').text).to eq expect_month_year.downcase
      end
    end
  end
end
