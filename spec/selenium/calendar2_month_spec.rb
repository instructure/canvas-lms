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

    describe "main month calendar" do

      it "should remember the selected calendar view" do
        get "/calendar2"
        expect(f("#month")).to have_class('active')
        f('#agenda').click
        wait_for_ajaximations

        get "/calendar2"
        expect(f('#agenda')).to have_class('active')
      end

      it "should create an event through clicking on a calendar day" do
        create_middle_day_event
      end

      it "should show scheduler button if it is enabled" do
        get "/calendar2"
        expect(f("#scheduler")).not_to be_nil
      end

      it "should not show scheduler button if it is disabled" do
        account = Account.default.tap { |a| a.settings[:show_scheduler] = false; a.save! }
        get "/calendar2"
        wait_for_ajaximations
        ff('.calendar_view_buttons .ui-button').each do |button|
          expect(button.text).not_to match(/scheduler/i)
        end
      end

      it "should drag and drop an event" do
        skip('drag and drop not working correctly')
        create_middle_day_event
        driver.action.drag_and_drop(f('.calendar .fc-event'), f('.calendar .fc-week:nth-child(2) .fc-last')).perform
        wait_for_ajaximations
        expect(CalendarEvent.last.start_at.strftime('%d')).to eq f('.calendar .fc-week:nth-child(2) .fc-last .fc-day-number').text
      end

      it "should create an assignment by clicking on a calendar day" do
        create_middle_day_assignment
      end

      it "more options link should go to calendar event edit page" do
        create_middle_day_event
        f('.fc-event').click
        expect(fj('.popover-links-holder:visible')).not_to be_nil
        driver.execute_script("$('.edit_event_link').hover().click()")
        expect_new_page_load { driver.execute_script("$('#edit_calendar_event_form .more_options_link').hover().click()") }
        expect(f('#breadcrumbs').text).to include 'Calendar Events'
      end

      it "should go to assignment page when clicking assignment title" do
        name = 'special assignment'
        create_middle_day_assignment(name)
        keep_trying_until do
          fj('.fc-event.assignment').click
          wait_for_ajaximations
          if (fj('.view_event_link').displayed?)
            expect_new_page_load { driver.execute_script("$('.view_event_link').hover().click()") }
          end
          fj('h1.title').displayed?
        end

        expect(f('h1.title').text).to include(name)
      end

      it "more options link on assignments should go to assignment edit page" do
        name = 'super big assignment'
        create_middle_day_assignment(name)
        fj('.fc-event.assignment').click
        driver.execute_script("$('.edit_event_link').hover().click()")
        expect_new_page_load { driver.execute_script("$('.more_options_link').hover().click()") }
        expect(f('#assignment_name').attribute(:value)).to include(name)
      end

      it "should publish a new assignment when toggle is clicked" do
        create_published_middle_day_assignment
        wait_for_ajax_requests
        fj('.fc-event.assignment').click
        driver.execute_script("$('.edit_event_link').hover().click()")
        driver.execute_script("$('.more_options_link').hover().click()")
        expect(f('#assignment-draft-state')).not_to include_text("Not Published")
      end

      it "should delete an event" do
        create_middle_day_event('doomed event')
        fj('.fc-event:visible').click
        wait_for_ajaximations
        driver.execute_script("$('.delete_event_link').hover().click()")
        wait_for_ajaximations
        driver.execute_script("$('.ui-dialog:visible .btn-primary').hover().click()")
        wait_for_ajaximations
        expect(fj('.fc-event:visible')).to be_nil
        # make sure it was actually deleted and not just removed from the interface
        get("/calendar2")
        wait_for_ajax_requests
        expect(fj('.fc-event:visible')).to be_nil
      end

      it "should delete an assignment" do
        create_middle_day_assignment
        keep_trying_until do
          fj('.fc-event-inner').click()
          driver.execute_script("$('.delete_event_link').hover().click()")
          fj('.ui-dialog .ui-dialog-buttonset').displayed?
        end
        wait_for_ajaximations
        driver.execute_script("$('.ui-dialog:visible .btn-primary').hover().click()")
        wait_for_ajaximations
        expect(fj('.fc-event-inner')).to be_nil
        # make sure it was actually deleted and not just removed from the interface
        get("/calendar2")
        wait_for_ajax_requests
        expect(fj('.fc-event-inner')).to be_nil
      end

      it "should not have a delete link for a frozen assignment" do
        PluginSetting.stubs(:settings_for_plugin).returns({"assignment_group_id" => "true"})
        frozen_assignment = @course.assignments.build(
            name: "frozen assignment",
            due_at: Time.zone.now,
            freeze_on_copy: true,
        )
        frozen_assignment.copied = true
        frozen_assignment.save!

        get("/calendar2")
        wait_for_ajaximations
        fj('.fc-event:visible').click
        wait_for_ajaximations
        expect(f('.delete_event_link')).to be_nil
      end

      it "should change the month" do
        get "/calendar2"
        old_header_title = get_header_text
        change_calendar
        expect(old_header_title).not_to eq get_header_text
      end

      it "should navigate with jump-to-date control" do
        Account.default.change_root_account_setting!(:agenda_view, true)
        # needs to be 2 months out so it doesn't appear at the start of the next month
        eventStart = 2.months.from_now
        make_event(start: eventStart)

        get "/calendar2"
        wait_for_ajaximations
        expect(f('.fc-event')).to be_nil
        eventStartText = eventStart.strftime("%Y %m %d")
        quick_jump_to_date(eventStartText)
        expect(f('.fc-event')).not_to be_nil
      end

      it "should show section-level events, but not the parent event" do
        @course.default_section.update_attribute(:name, "default section!")
        s2 = @course.course_sections.create!(:name => "other section!")
        date = Date.today
        e1 = @course.calendar_events.build :title => "ohai",
                                           :child_event_data => [
                                               {:start_at => "#{date} 12:00:00", :end_at => "#{date} 13:00:00", :context_code => @course.default_section.asset_string},
                                               {:start_at => "#{date} 13:00:00", :end_at => "#{date} 14:00:00", :context_code => s2.asset_string},
                                           ]
        e1.updating_user = @user
        e1.save!

        get "/calendar2"
        wait_for_ajaximations
        events = ffj('.fc-event:visible')
        expect(events.size).to eq 2
        events.first.click

        details = f('.event-details')
        expect(details).not_to be_nil
        expect(details.text).to include(@course.default_section.name)
        expect(details.find_element(:css, '.view_event_link')[:href]).to include "/calendar_events/#{e1.id}" # links to parent event
      end
    end
  end
end