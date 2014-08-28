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

  def create_assignment_event(assignment_title, should_add_date = false)
    middle_number = find_middle_day.find_element(:css, '.fc-day-number').text
    find_middle_day.click
    edit_event_dialog = f('#edit_event_tabs')
    edit_event_dialog.should be_displayed
    edit_event_dialog.find_element(:css, '.edit_assignment_option').click
    edit_assignment_form = edit_event_dialog.find_element(:id, 'edit_assignment_form')
    title = edit_assignment_form.find_element(:id, 'assignment_title')
    keep_trying_until { title.displayed? }
    replace_content(title, assignment_title)
    add_date(middle_number) if should_add_date
    submit_form(edit_assignment_form)
    keep_trying_until { f('.fc-view-month .fc-event-title').should include_text(assignment_title) }
  end

  def create_calendar_event(event_title, should_add_date = false, should_add_location = false)
    middle_number = find_middle_day.find_element(:css, '.fc-day-number').text
    find_middle_day.click
    edit_event_dialog = f('#edit_event_tabs')
    edit_event_dialog.should be_displayed
    edit_event_form = edit_event_dialog.find_element(:id, 'edit_calendar_event_form')
    title = edit_event_form.find_element(:id, 'calendar_event_title')
    keep_trying_until { title.displayed? }
    replace_content(title, event_title)
    add_date(middle_number) if should_add_date
    replace_content(f('#calendar_event_location_name'), 'location title') if should_add_location
    submit_form(edit_event_form)
    wait_for_ajax_requests
    keep_trying_until { f('.fc-view-month .fc-event-title').should include_text(event_title) }
  end

  context "as a teacher" do

    before (:each) do
      course_with_teacher_logged_in
    end

    it "should allow viewing an unenrolled calendar via include_contexts" do
      pending('failed')
      # also make sure the redirect from calendar -> calendar2 keeps the param
      unrelated_course = Course.create!(:account => Account.default, :name => "unrelated course")
      # make the user an admin so they can view the course's calendar without an enrollment
      Account.default.account_users.create!(user: @user)
      CalendarEvent.create!(:title => "from unrelated one", :start_at => Time.now, :end_at => 5.hours.from_now) { |c| c.context = unrelated_course }
      keep_trying_until { CalendarEvent.last.title.should == "from unrelated one" }
      get "/courses/#{unrelated_course.id}/settings"
      f('#course_calendar_link')['href'].should match(/course_#{Course.last.id}/)
      f("#course_calendar_link").click

      # only the explicit context should be selected
      keep_trying_until do
        f("#context-list li[data-context=course_#{unrelated_course.id}]").should have_class('checked')
        f("#context-list li[data-context=course_#{@course.id}]").should have_class('not-checked')
        f("#context-list li[data-context=user_#{@user.id}]").should have_class('not-checked')
      end
    end

    describe "sidebar" do

      describe "mini calendar" do

        it "should add the event class to days with events" do
          c = make_event
          get "/calendar2"
          wait_for_ajax_requests

          events = ff("#minical .event")
          events.size.should == 1
          events.first.text.strip.should == c.start_at.day.to_s
        end

        it "should change the main calendars month on click" do
          title_selector = ".navigation_title"
          get "/calendar2"

          orig_titles = ff(title_selector).map(&:text)
          f("#minical .fc-other-month").click

          orig_titles.should_not == ff(title_selector).map(&:text)
        end
      end

      describe "contexts list" do
        it "should toggle event display when context is clicked" do
          make_event :context => @course, :start => Time.now
          get "/calendar2"

          f('.context_list_context').click
          context_course_item = fj('.context_list_context:nth-child(2)')
          context_course_item.should have_class('checked')
          f('.fc-event').should be_displayed

          context_course_item.click
          context_course_item.should have_class('not-checked')
          element_exists('.fc_event').should be_false
        end

        it "should constrain context selection to 10" do
          30.times do |x|
            course_with_teacher(:course_name => "Course #{x + 1}", :user => @user, :active_all => true).course
          end

          get "/calendar2"
          ff('.context_list_context').each(&:click)
          ff('.context_list_context.checked').count.should == 10
        end

        it "should validate calendar feed display" do
          get "/calendar2"

          f('#calendar-feed a').click
          f('#calendar_feed_box').should be_displayed
        end
      end

      describe "undated calendar items" do
        it "should show undated events after clicking link" do
          e = make_event :start => nil, :title => "pizza party"
          get "/calendar2"

          f("#undated-events-section .element_toggler").click
          wait_for_ajaximations
          undated_events = ff("#undated-events > ul > li")
          undated_events.size.should == 1
          undated_events.first.text.should =~ /#{e.title}/
        end

        it "should truncate very long undated event titles" do
          make_event :start => nil, :title => "asdfjkasldfjklasdjfklasdjfklasjfkljasdklfjasklfjkalsdjsadkfljasdfkljfsdalkjsfdlksadjklsadjsadklasdf"
          get "/calendar2"

          f("#undated-events-section .element_toggler").click
          wait_for_ajaximations
          undated_events = ff("#undated-events > ul > li")
          undated_events.size.should == 1
          undated_events.first.text.should == "asdfjkasldfjklasdjfklasdjfklasjf..."
        end
      end
    end

    describe "main calendar" do

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

      it "should remember the selected calendar view" do
        get "/calendar2"
        f("#month").should have_class('active')
        f('#agenda').click
        wait_for_ajaximations

        get "/calendar2"
        f('#agenda').should have_class('active')
      end

      it "should create an event through clicking on a calendar day" do
        create_middle_day_event
      end

      it "should show scheduler button if it is enabled" do
        get "/calendar2"
        f("#scheduler").should_not be_nil
      end

      it "should not show scheduler button if it is disabled" do
        account = Account.default.tap { |a| a.settings[:show_scheduler] = false; a.save! }
        get "/calendar2"
        wait_for_ajaximations
        ff('.calendar_view_buttons .ui-button').each do |button|
          button.text.should_not match(/scheduler/i)
        end
      end

      it "should drag and drop an event" do
        pending('drag and drop not working correctly')
        create_middle_day_event
        driver.action.drag_and_drop(f('.calendar .fc-event'), f('.calendar .fc-week:nth-child(2) .fc-last')).perform
        wait_for_ajaximations
        CalendarEvent.last.start_at.strftime('%d').should == f('.calendar .fc-week:nth-child(2) .fc-last .fc-day-number').text
      end

      it "should create an assignment by clicking on a calendar day" do
        create_middle_day_assignment
      end

      it "more options link should go to calendar event edit page" do
        create_middle_day_event
        f('.fc-event').click
        fj('.popover-links-holder:visible').should_not be_nil
        driver.execute_script("$('.edit_event_link').hover().click()")
        expect_new_page_load { driver.execute_script("$('#edit_calendar_event_form .more_options_link').hover().click()") }
        f('#breadcrumbs').text.should include 'Calendar Events'
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

        f('h1.title').text.should include(name)
      end

      it "more options link on assignments should go to assignment edit page" do
        name = 'super big assignment'
        create_middle_day_assignment(name)
        fj('.fc-event.assignment').click
        driver.execute_script("$('.edit_event_link').hover().click()")
        expect_new_page_load { driver.execute_script("$('.more_options_link').hover().click()") }
        f('#assignment_name').attribute(:value).should include(name)
      end

      it "should delete an event" do
        create_middle_day_event('doomed event')
        fj('.fc-event:visible').click
        wait_for_ajaximations
        driver.execute_script("$('.delete_event_link').hover().click()")
        wait_for_ajaximations
        driver.execute_script("$('.ui-dialog:visible .btn-primary').hover().click()")
        wait_for_ajaximations
        fj('.fc-event:visible').should be_nil
        # make sure it was actually deleted and not just removed from the interface
        get("/calendar2")
        wait_for_ajax_requests
        fj('.fc-event:visible').should be_nil
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
        fj('.fc-event-inner').should be_nil
        # make sure it was actually deleted and not just removed from the interface
        get("/calendar2")
        wait_for_ajax_requests
        fj('.fc-event-inner').should be_nil
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
        f('.delete_event_link').should be_nil
      end

      it "should let me message students who have signed up for an appointment" do
        date = Date.today.to_s
        create_appointment_group :new_appointments => [
            ["#{date} 12:00:00", "#{date} 13:00:00"],
            ["#{date} 13:00:00", "#{date} 14:00:00"],
        ]
        student1, student2 = 2.times.map do
          student_in_course :course => @course, :active_all => true
          @student
        end
        app1, app2 = AppointmentGroup.first.appointments
        app1.reserve_for(student1, student1)
        app2.reserve_for(student2, student2)

        get '/calendar2'
        wait_for_ajaximations
        fj('.fc-event').click
        wait_for_ajaximations

        driver.execute_script("$('.message_students').hover().click()")

        wait_for_ajaximations
        ff(".participant_list input").size.should == 1
        set_value f('textarea[name="body"]'), 'hello'
        fj('.ui-button:contains(Send)').click
        wait_for_ajaximations

        student1.conversations.first.messages.size.should == 1
        student2.conversations.should be_empty
      end

      it "editing an existing assignment should select the correct assignment group" do
        group1 = @course.assignment_groups.create!(:name => "Assignment Group 1")
        group2 = @course.assignment_groups.create!(:name => "Assignment Group 2")
        @course.active_assignments.create(:name => "Assignment 1", :assignment_group => group1, :due_at => Time.zone.now)
        assignment2 = @course.active_assignments.create(:name => "Assignment 2", :assignment_group => group2, :due_at => Time.zone.now)

        get "/calendar2"
        wait_for_ajaximations
        events = ff('.fc-event')
        event1 = events.detect { |e| e.text =~ /Assignment 1/ }
        event2 = events.detect { |e| e.text =~ /Assignment 2/ }
        event1.should_not be_nil
        event2.should_not be_nil
        event1.should_not == event2

        event1.click
        wait_for_ajaximations
        driver.execute_script("$('.edit_event_link').hover().click()")
        wait_for_ajaximations

        select = f('#edit_assignment_form .assignment_group')
        first_selected_option(select).attribute(:value).to_i.should == group1.id
        close_visible_dialog

        event2.click
        wait_for_ajaximations

        driver.execute_script("$('.edit_event_link').hover().click()")
        wait_for_ajaximations
        select = f('#edit_assignment_form .assignment_group')
        first_selected_option(select).attribute(:value).to_i.should == group2.id
        replace_content(f('.ui-dialog #assignment_title'), "Assignment 2!")
        submit_form('#edit_assignment_form')
        wait_for_ajaximations
        assignment2.reload.title.should == "Assignment 2!"
        assignment2.assignment_group.should == group2
      end

      it "editing an existing assignment should preserve more options link" do
        assignment = @course.active_assignments.create!(:name => "to edit", :due_at => Time.zone.now)
        get "/calendar2"
        f('.fc-event').click
        wait_for_ajaximations
        driver.execute_script("$('.edit_event_link').hover().click()")
        wait_for_ajaximations
        original_more_options = f('.more_options_link')['href']
        original_more_options.should_not match(/undefined/)
        replace_content(f('.ui-dialog #assignment_title'), "edited title")
        submit_form('#edit_assignment_form')
        wait_for_ajaximations
        assignment.reload
        wait_for_ajaximations
        assignment.title.should eql("edited title")

        fj('.fc-event').click
        wait_for_ajaximations
        driver.execute_script("$('.edit_event_link').hover().click()")
        wait_for_ajaximations
        fj('.more_options_link')['href'].should match(original_more_options)
      end

      it "should make an assignment undated if you delete the start date" do
        create_middle_day_assignment("undate me")
        keep_trying_until do
          fj('.fc-event-inner').click()
          driver.execute_script("$('.popover-links-holder .edit_event_link').hover().click()")
          f('.ui-dialog #assignment_due_at').displayed?
        end

        replace_content(f('.ui-dialog #assignment_due_at'), "")
        submit_form('#edit_assignment_form')
        wait_for_ajax_requests
        f("#undated-events-section .element_toggler").click
        f('.fc-event').should be_nil
        f('.undated_event_title').text.should == "undate me"
      end

      it "should change the month" do
        get "/calendar2"
        old_header_title = get_header_text
        change_calendar
        old_header_title.should_not == get_header_text
      end

      it "should change the week" do
        get "/calendar2"
        header_buttons = ff('.btn-group .btn')
        header_buttons[0].click
        wait_for_ajaximations
        old_header_title = get_header_text
        change_calendar(:prev)
        old_header_title.should_not == get_header_text
      end

      it "should test the today button" do
        get "/calendar2"
        current_month_num = Time.now.month
        current_month = Date::MONTHNAMES[current_month_num]

        change_calendar
        get_header_text.should_not == current_month
        change_calendar(:today)
        get_header_text.should == (current_month + ' ' + Time.now.year.to_s)
      end

      it "should navigate with jump-to-date control" do
        Account.default.change_root_account_setting!(:agenda_view, true)
        # needs to be 2 months out so it doesn't appear at the start of the next month
        eventStart = 2.months.from_now
        make_event(start: eventStart)

        get "/calendar2"
        wait_for_ajaximations
        f('.fc-event').should be_nil
        eventStartText = eventStart.strftime("%Y %m %d")
        quick_jump_to_date(eventStartText)
        f('.fc-event').should_not be_nil
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
        events.size.should == 2
        events.first.click

        details = f('.event-details')
        details.should_not be_nil
        details.text.should include(@course.default_section.name)
        details.find_element(:css, '.view_event_link')[:href].should include "/calendar_events/#{e1.id}" # links to parent event
      end

      context "event creation" do
        it "should create an event by hitting the '+' in the top bar" do
          event_title = 'new event'
          get "/calendar2"
          wait_for_ajaximations

          fj('#create_new_event_link').click
          edit_event_dialog = f('#edit_event_tabs')
          edit_event_dialog.should be_displayed
        end

        it "should create an event with a location name" do
          event_name = 'event with location'
          create_middle_day_event(event_name, false, true)
          fj('.fc-event:visible').click
          fj('.event-details-content:visible').should include_text('location title')
        end

        it 'should create an event with location name and address' do
          get "/calendar2"
          event_title = 'event title'
          location_name = 'my house'
          location_address = '555 test street'
          find_middle_day.click
          edit_event_dialog = f('#edit_event_tabs')
          edit_event_dialog.should be_displayed
          edit_event_form = edit_event_dialog.find_element(:id, 'edit_calendar_event_form')
          title = edit_event_form.find_element(:id, 'calendar_event_title')
          keep_trying_until { title.displayed? }
          replace_content(title, event_title)
          expect_new_page_load { f('.more_options_link').click }
          f('.title').attribute('value').should == event_title
          replace_content(f('#calendar_event_location_name'), location_name)
          replace_content(f('#calendar_event_location_address'), location_address)
          expect_new_page_load { submit_form(f('#editCalendarEventFull')) }
          fj('.fc-event:visible').click
          event_content = fj('.event-details-content:visible')
          event_content.should include_text(location_name)
          event_content.should include_text(location_address)
        end
      end

      context "event editing" do
        it "should allow editing appointment events" do
          create_appointment_group
          ag = AppointmentGroup.first
          student_in_course(:course => @course, :active_all => true)
          ag.appointments.first.reserve_for(@user, @user)

          get "/calendar2"
          wait_for_ajaximations

          open_edit_event_dialog
          description = 'description...'
          replace_content f('[name=description]'), description
          fj('.ui-button:contains(Update)').click
          wait_for_ajaximations

          ag.reload.appointments.first.description.should == description
          lambda { f('.fc-event') }.should_not raise_error
        end
      end

      context "time zone" do
        before do
          @user.time_zone = 'America/Denver'
          @user.save!
        end

        it "should display popup with correct day on an event" do
          local_now = @user.time_zone.now
          event_start = @user.time_zone.local(local_now.year, local_now.month, 15, 22, 0, 0)
          make_event(:start => event_start)
          get "/calendar2"
          wait_for_ajaximations
          f('.fc-event').click
          f('.event-details-timestring').text.should include event_start.strftime("%b %e")
        end

        it "should display popup with correct day on an assignment" do
          local_now = @user.time_zone.now
          event_start = @user.time_zone.local(local_now.year, local_now.month, 15, 22, 0, 0)
          @course.assignments.create!(
            title: 'test assignment',
            due_at: event_start,
            )
          get "/calendar2"
          wait_for_ajaximations
          f('.fc-event').click
          f('.event-details-timestring').text.should include event_start.strftime("%b %e")
        end

        it "should display popup with correct day on an assignment override" do
          @student = course_with_student_logged_in.user
          @student.time_zone = 'America/Denver'
          @student.save!

          local_now = @user.time_zone.now
          assignment_start = @user.time_zone.local(local_now.year, local_now.month, 15, 22, 0, 0)
          assignment = @course.assignments.create!(title: 'test assignment', due_at: assignment_start)

          override_start = @user.time_zone.local(local_now.year, local_now.month, 20, 22, 0, 0)
          override = assignment.assignment_overrides.create! do |o|
            o.title = 'test override'
            o.set_type = 'ADHOC'
            o.due_at = override_start
            o.due_at_overridden = true
          end
          override.assignment_override_students.create! do |link|
            link.user = @student
            link.assignment_override = override
          end

          get "/calendar2"
          wait_for_ajaximations
          f('.fc-event').click
          f('.event-details-timestring').text.should include override_start.strftime("%b %e")
        end


      end

    end

    context "week view" do

      it "should render assignments due just before midnight" do
        pending("fails on event count validation")
        assignment_model(:course => @course,
                         :title => "super important",
                         :due_at => Time.zone.now.beginning_of_day + 1.day - 1.minute)
        calendar_events = @teacher.calendar_events_for_calendar.last

        calendar_events.title.should == "super important"
        @assignment.due_date.should == (Time.zone.now.beginning_of_day + 1.day - 1.minute).to_date

        get "/calendar2"
        wait_for_ajaximations

        f('#week').click
        keep_trying_until do
          events = ff('.fc-event').select { |e| e.text =~ /due.*super important/ }
          # shows on monday night and tuesday morning
          events.size.should == 2
        end
      end

      it "should show short events at full height" do
        noon = Time.now.at_beginning_of_day + 12.hours
        event = @course.calendar_events.create! :title => "ohai", :start_at => noon, :end_at => noon + 5.minutes

        get "/calendar2"
        wait_for_ajax_requests
        f('#week').click

        elt = fj('.fc-event:visible')
        elt.size.height.should >= 18
      end

      it "should stagger pseudo-overlapping short events" do
        noon = Time.now.at_beginning_of_day + 12.hours
        first_event = @course.calendar_events.create! :title => "ohai", :start_at => noon, :end_at => noon + 5.minutes
        second_start = first_event.start_at + 6.minutes
        second_event = @course.calendar_events.create!(:title => "ohai", :start_at => second_start, :end_at => second_start + 5.minutes)

        get "/calendar2"
        wait_for_ajaximations
        f('#week').click
        wait_for_ajaximations

        elts = ffj('.fc-event:visible')
        elts.size.should eql(2)

        elt_lefts = elts.map { |elt| elt.location.x }.uniq
        elt_lefts.size.should eql(elts.size)
      end

      it "should not change duration when dragging a short event" do
        pending("dragging events doesn't seem to work")
        noon = Time.zone.now.at_beginning_of_day + 12.hours
        event = @course.calendar_events.create! :title => "ohai", :start_at => noon, :end_at => noon + 5.minutes
        get "/calendar2"
        wait_for_ajaximations
        f('#week').click
        wait_for_ajaximations

        elt = fj('.fc-event:visible')
        driver.action.drag_and_drop_by(elt, 0, 50)
        wait_for_ajax_requests
        event.reload.start_at.should eql(noon + 1.hour)
        event.reload.end_at.should eql(noon + 1.hour + 5.minutes)
      end

      it "should change duration of a short event when dragging resize handle" do
        pending("dragging events doesn't seem to work")
        noon = Time.zone.now.at_beginning_of_day + 12.hours
        event = @course.calendar_events.create! :title => "ohai", :start_at => noon, :end_at => noon + 5.minutes
        get "/calendar2"
        wait_for_ajaximations
        f('#week').click
        wait_for_ajaximations

        resize_handle = fj('.fc-event:visible .ui-resizable-handle')
        driver.action.drag_and_drop_by(resize_handle, 0, 50).perform
        wait_for_ajaximations

        event.reload.start_at.should eql(noon)
        event.end_at.should eql(noon + 1.hours + 30.minutes)
      end

      it "should show the right times in the tool tips for short events" do
        noon = Time.zone.now.at_beginning_of_day + 12.hours
        event = @course.calendar_events.create! :title => "ohai", :start_at => noon, :end_at => noon + 5.minutes
        get "/calendar2"
        wait_for_ajaximations
        f('#week').click
        wait_for_ajaximations

        elt = fj('.fc-event:visible')
        elt.attribute('title').should match(/12:00.*12:05/)
      end

      it "should update the event as all day if dragged to all day row" do
        pending("dragging events doesn't seem to work")
      end
    end

    context "agenda view" do
      before(:each) do
        account = Account.default
        account.settings[:agenda_view] = true
        account.save!
      end

      it "should display agenda events" do
        get '/calendar2'
        wait_for_ajaximations
        f('#agenda').click
        wait_for_ajaximations
        fj('.agenda-wrapper:visible').should be_present
      end

      it "should set the header in the format 'Oct 11, 2013'" do
        start_date = Time.now.beginning_of_day + 12.hours
        event = @course.calendar_events.create!(title: "ohai",
          start_at: start_date, end_at: start_date + 1.hour)
        get '/calendar2'
        wait_for_ajaximations
        f('#agenda').click
        wait_for_ajaximations
        f('.navigation_title').text.should match(/[A-Z][a-z]{2}\s\d{1,2},\s\d{4}/)
      end

      it "should respect context filters" do
        start_date = Time.now.utc.beginning_of_day + 12.hours
        event = @course.calendar_events.create!(title: "ohai",
          start_at: start_date, end_at: start_date + 1.hour)
        get '/calendar2'
        wait_for_ajaximations
        f('#agenda').click
        wait_for_ajaximations
        ffj('.ig-row').length.should == 1
        fj('.context-list-toggle-box:last').click
        wait_for_ajaximations
        ffj('.ig-row').length.should == 0
      end

      it "should be navigable via the jump-to-date control" do
        yesterday = 1.day.ago
        event = make_event(start: yesterday)
        get "/calendar2"
        wait_for_ajaximations
        f('#agenda').click
        wait_for_ajaximations
        ffj('.ig-row').length.should == 0
        quick_jump_to_date(yesterday.strftime("%b %-d %Y"))
        wait_for_ajaximations
        ffj('.ig-row').length.should == 1
      end

      it "should be navigable via the minical" do
        yesterday = 1.day.ago
        event = make_event(start: yesterday)
        get "/calendar2"
        wait_for_ajaximations
        f('#agenda').click
        wait_for_ajaximations
        ffj('.ig-row').length.should == 0
        f('.fc-button-prev').click
        f('.fc-day-number').click
        wait_for_ajaximations
        keep_trying_until { ffj('.ig-row').length.should == 1 }
      end

      it "should persist the start date across reloads" do
        get "/calendar2"
        wait_for_ajaximations
        f('#agenda').click
        next_year = 1.year.from_now.strftime("%Y")
        quick_jump_to_date(next_year)
        refresh_page
        wait_for_ajaximations
        f('.navigation_title').should include_text(next_year)
      end

      it "should transfer the start date when switching views" do
        get "/calendar2"
        wait_for_ajaximations
        f('.navigate_next').click()
        f('#agenda').click
        f('.navigation_title').should include_text(1.month.from_now.strftime("%b"))
        next_year = 1.year.from_now.strftime("%Y")
        quick_jump_to_date(next_year)
        f('#month').click
        f('.navigation_title').should include_text(next_year)
      end

      it "should display the displayed date range in the header" do
        tomorrow = 1.day.from_now
        event = make_event(start: tomorrow)
        get "/calendar2"
        wait_for_ajaximations
        f('#agenda').click
        wait_for_ajaximations
        f('.navigation_title').should include_text(Time.now.utc.strftime("%b %-d, %Y"))
        f('.navigation_title').should include_text(tomorrow.utc.strftime("%b %-d, %Y"))
      end

      it "should not display a date range if no events are found" do
        get "/calendar2"
        wait_for_ajaximations
        f('#agenda').click
        wait_for_ajaximations
        f('.navigation_title').should_not include_text('Invalid')
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
        ffj('.ig-row').length.should == 0
      end

      it "should display midnight assignments at 11:59" do
        assignment_model(:course => @course,
                         :title => "super important",
                         :due_at => Time.zone.now.beginning_of_day + 1.day - 1.minute)
        calendar_events = @teacher.calendar_events_for_calendar.last

        calendar_events.title.should == "super important"
        @assignment.due_date.should == (Time.zone.now.beginning_of_day + 1.day - 1.minute).to_date

        get "/calendar2"
        wait_for_ajaximations

        f('#agenda').click
        wait_for_ajaximations

        f('.ig-details').should include_text('11:59')
        f('.ig-row').click()
        fj('.event-details:visible time').should include_text('11:59')
      end
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
        fj('ul#context-list > li:nth-child(2) button').should be_nil # no button, can't add events
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
        fj("#popover-0").should be_displayed
        expect_new_page_load { driver.execute_script("$('#popover-0 .view_event_link').hover().click()") }


        f('#scheduler').should have_class('active')
        f('#appointment-group-list').should include_text(ag.title)
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
        events.size.should == 1
        events.first.text.should include "1p"
        events.first.click

        details = f('.event-details-content')
        details.should_not be_nil
        details.text.should include(@course.default_section.name)
      end

      it "should display title link and go to event details page" do
        make_event(:context => @course, :start => 0.days.from_now, :title => "future event")
        get "/calendar2"
        wait_for_ajaximations

        # click the event in the calendar
        fj('.fc-event').click
        fj("#popover-0").should be_displayed
        expect_new_page_load { driver.execute_script("$('.view_event_link').hover().click()") }

        page_title = f('.title')
        page_title.should be_displayed
        page_title.text.should == 'future event'
      end

      it "should not redirect but load the event details page" do
        event = make_event(:context => @course, :start => 2.months.from_now, :title => "future event")
        get "/courses/#{@course.id}/calendar_events/#{event.id}"
        page_title = f('.title')
        page_title.should be_displayed
        page_title.text.should == 'future event'
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
        pending('USE_OPTIMIZED_JS=true') unless ENV['USE_OPTIMIZED_JS']
        date = Date.new(2012, 7, 12)
        # Use event to  open to a specific and testable month
        event = calendar_event_model(:title => 'Test Event', :start_at => date, :end_at => (date + 1.hour))

        get "/courses/#{@course.id}/calendar_events/#{event.id}?calendar=1"
        wait_for_ajaximations
        fj('.calendar_header .navigation_title').text.should == 'Julio 2012'
        fj('#calendar-app .fc-sun').text.should == 'DOM'
        fj('#calendar-app .fc-mon').text.should == 'LUN'
        fj('#calendar-app .fc-tue').text.should == 'MAR'
        fj('#calendar-app .fc-wed').text.should == 'MIE'
        fj('#calendar-app .fc-thu').text.should == 'JUE'
        fj('#calendar-app .fc-fri').text.should == 'VIE'
        fj('#calendar-app .fc-sat').text.should == 'SAB'
      end
    end

    describe "mini calendar" do
      it "should display in Spanish" do
        pending('USE_OPTIMIZED_JS=true') unless ENV['USE_OPTIMIZED_JS']
        pending('RAILS_LOAD_ALL_LOCALES=true') unless ENV['RAILS_LOAD_ALL_LOCALES']
        get "/calendar2"
        wait_for_ajaximations
        # Get the spanish text for the current month/year
        expect_month_year = I18n.l(Date.today, :format => '%B %Y', :locale => 'es')
        fj('#minical h2').text.should == expect_month_year
      end
    end
  end
end
