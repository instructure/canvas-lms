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

  context "as a student" do
    before (:each) do
      @student = course_with_student_logged_in(:active_all => true).user
    end

    describe "contexts list" do
      it "should not allow a student to create an assignment through the context list" do
        get "/calendar2"
        wait_for_ajaximations

        # first context is the user's calendar
        driver.execute_script(%{$(".context_list_context:nth-child(2)").addClass('hovering')})
        expect(fj('ul#context-list > li:nth-child(2) button')).to be_nil # no button, can't add events
      end
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
        wait_for_ajaximations
        events = ff('.fc-event')
        expect(events.size).to eq 1
        expect(events.first.text).to include "1p"
        events.first.click

        details = f('.event-details-content')
        expect(details).not_to be_nil
        expect(details.text).to include(@course.default_section.name)
      end

      it "should display title link and go to event details page" do
        make_event(:context => @course, :start => 0.days.from_now, :title => "future event")
        get "/calendar2"
        wait_for_ajaximations

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
        wait_for_ajaximations
        expect(fj('.calendar_header .navigation_title').text).to eq 'Julio 2012'
        expect(fj('#calendar-app .fc-sun').text).to eq 'DOM'
        expect(fj('#calendar-app .fc-mon').text).to eq 'LUN'
        expect(fj('#calendar-app .fc-tue').text).to eq 'MAR'
        expect(fj('#calendar-app .fc-wed').text).to eq 'MIE'
        expect(fj('#calendar-app .fc-thu').text).to eq 'JUE'
        expect(fj('#calendar-app .fc-fri').text).to eq 'VIE'
        expect(fj('#calendar-app .fc-sat').text).to eq 'SAB'
      end
    end

    describe "mini calendar" do
      it "should display in Spanish" do
        skip('USE_OPTIMIZED_JS=true') unless ENV['USE_OPTIMIZED_JS']
        skip('RAILS_LOAD_ALL_LOCALES=true') unless ENV['RAILS_LOAD_ALL_LOCALES']
        get "/calendar2"
        wait_for_ajaximations
        # Get the spanish text for the current month/year
        expect_month_year = I18n.l(Date.today, :format => '%B %Y', :locale => 'es')
        expect(fj('#minical h2').text).to eq expect_month_year
      end
    end
  end
end
