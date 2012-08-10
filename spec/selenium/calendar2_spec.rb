require File.expand_path(File.dirname(__FILE__) + '/helpers/calendar2_common')

describe "calendar2" do
  it_should_behave_like "calendar2 selenium tests"

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
    f('.calendar .fc-week1 .fc-wed')
  end

  def change_calendar(css_selector = '.fc-button-next')
    f('.calendar .fc-header-left ' + css_selector).click
    wait_for_ajax_requests
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
    replace_content(title, assignment_title)
    add_date(middle_number) if should_add_date
    submit_form(edit_assignment_form)
    wait_for_ajax_requests
    keep_trying_until { f('.fc-view-month .fc-event-title').should include_text(assignment_title) }
  end

  def create_calendar_event(event_title, should_add_date = false)
    middle_number = find_middle_day.find_element(:css, '.fc-day-number').text
    edit_event_dialog = f('#edit_event_tabs')
    edit_event_dialog.should be_displayed
    edit_event_form = edit_event_dialog.find_element(:id, 'edit_calendar_event_form')
    title = edit_event_form.find_element(:id, 'calendar_event_title')
    replace_content(title, event_title)
    add_date(middle_number) if should_add_date
    submit_form(edit_event_form)
    wait_for_ajax_requests
    keep_trying_until { f('.fc-view-month .fc-event-title').should include_text(event_title) }
  end

  context "as a teacher" do

    before (:each) do
      course_with_teacher_logged_in
    end

    it "should allow viewing an unenrolled calendar via include_contexts" do
      # also make sure the redirect from calendar -> calendar2 keeps the param
      unrelated_course = Course.create!(:account => Account.default, :name => "unrelated course")
      # make the user an admin so they can view the course's calendar without an enrollment
      Account.default.add_user(@user)
      CalendarEvent.create!(:title => "from unrelated one", :start_at => Time.now, :end_at => 5.hours.from_now) { |c| c.context = unrelated_course }
      get "/courses/#{unrelated_course.id}/settings"
      expect_new_page_load { f("#course_calendar_link").click() }
      wait_for_ajax_requests
      # only the explicit context should be selected
      f("#context-list li[data-context=course_#{unrelated_course.id}]").should have_class('checked')
      f("#context-list li[data-context=course_#{@course.id}]").should have_class('not-checked')
      f("#context-list li[data-context=user_#{@user.id}]").should have_class('not-checked')
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

        it "should change the main calendar's month on click" do
          title_selector = "#calendar-app .fc-header-title"
          get "/calendar2"

          orig_title = f(title_selector).text
          f("#minical .fc-other-month").click

          orig_title.should_not == f(title_selector)
        end
      end

      describe "contexts list" do
        it "should have a menu for adding stuff" do
          get "/calendar2"

          contexts = ff("#context-list > li")

          # first context is the user
          actions = contexts[0].find_elements(:css, "li > a")
          actions.size.should == 1
          actions.first["data-action"].should == "add_event"

          # course context
          actions = contexts[1].find_elements(:css, "li > a")
          actions.size.should == 2
          actions.first["data-action"].should == "add_event"
          actions.second["data-action"].should == "add_assignment"
        end

        it "should create an event through the context list drop down" do
          event_title = 'new event'
          get "/calendar2"
          wait_for_ajaximations

          driver.execute_script(%{$(".context_list_context:nth-child(2)").trigger('mouseenter')})
          fj('ul#context-list li:nth-child(2) button').click
          f("#ui-menu-1-0").click
          edit_event_dialog = f('#edit_event_tabs')
          edit_event_dialog.should be_displayed
          create_calendar_event(event_title, true)
        end

        it "should create an assignment through the context list drop down" do
          assignment_title = 'new assignment'
          get "/calendar2"
          wait_for_ajaximations

          driver.execute_script(%{$(".context_list_context:nth-child(2)").trigger('mouseenter')})
          fj('ul#context-list li:nth-child(2) button').click
          f("#ui-menu-1-1").click
          edit_event_dialog = f('#edit_event_tabs')
          edit_event_dialog.should be_displayed
          create_assignment_event(assignment_title, true)
        end

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

          f(".undated-events-link").click
          wait_for_ajaximations
          undated_events = ff("#undated-events > ul > li")
          undated_events.size.should == 1
          undated_events.first.text.should =~ /#{e.title}/
        end
      end
    end

    describe "main calendar" do

      def get_header_text
        header = f('.calendar .fc-header .fc-header-title')
        header.text
      end

      def create_middle_day_event(name = 'new event')
        get "/calendar2"
        find_middle_day.click
        create_calendar_event(name)
      end

      def create_middle_day_assignment(name = 'new assignment')
        get "/calendar2"
        find_middle_day.click
        create_assignment_event(name)
      end

      it "should create an event through clicking on a calendar day" do
        create_middle_day_event
      end

      it "should drag and drop an event" do
        create_middle_day_event
        driver.action.drag_and_drop(f('.calendar .fc-event'), f('.calendar .fc-week2 .fc-last')).perform
        wait_for_ajaximations
        CalendarEvent.last.start_at.strftime('%d').should == f('.calendar .fc-week2 .fc-last .fc-day-number').text
      end

      it "should create an assignment by clicking on a calendar day" do
        create_middle_day_assignment
      end

      it "more options link should go to calendar event edit page" do
        create_middle_day_event

        f('.fc-event').click
        fj('.popover-links-holder:visible').should_not be_nil
        f('.event-details-links .edit_event_link').click
        expect_new_page_load { f('#edit_calendar_event_form .more_options_link').click }
        f('#breadcrumbs').text.should include 'Calendar Events'
      end

      it "more options link on assignments should go to assignment edit page" do
        name = 'super big assignment'
        create_middle_day_assignment(name)
        f('.fc-event.assignment').click
        f('.edit_event_link').click
        expect_new_page_load { f('.more_options_link').click }
        f('h2.title').text.should include(name)
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
        f('.fc-event').click
        f('.message_students').click
        wait_for_ajaximations
        ff(".participant_list input").size.should eql 1
        set_value f('textarea[name="body"]'), 'hello'
        fj('.ui-button:contains(Send)').click
        wait_for_ajaximations

        student1.conversations.first.messages.size.should eql 1
        student2.conversations.should be_empty
      end

      it "editing an existing assignment should select the correct assignment group" do
        group1 = @course.assignment_groups.create!(:name => "Assignment Group 1")
        group2 = @course.assignment_groups.create!(:name => "Assignment Group 2")
        @course.active_assignments.create(:name => "Assignment 1", :assignment_group => group1, :due_at => Time.zone.now)
        assignment2 = @course.active_assignments.create(:name => "Assignment 2", :assignment_group => group2, :due_at => Time.zone.now)

        get "/calendar2"

        events = ff('.fc-event')
        event1 = events.detect { |e| e.text =~ /Assignment 1/ }
        event2 = events.detect { |e| e.text =~ /Assignment 2/ }
        event1.should_not be_nil
        event2.should_not be_nil
        event1.should_not == event2

        event1.click
        f('.popover-links-holder .edit_event_link').click
        select = f('#edit_assignment_form .assignment_group')
        first_selected_option(select).attribute(:value).to_i.should == group1.id
        close_visible_dialog

        event2.click
        f('.popover-links-holder .edit_event_link').click
        select = f('#edit_assignment_form .assignment_group')
        first_selected_option(select).attribute(:value).to_i.should == group2.id
        replace_content(  f('div.ui-dialog #assignment_title'), "Assignment 2!")
        submit_form('#edit_assignment_form')
        wait_for_ajax_requests
        assignment2.reload.title.should == "Assignment 2!"
        assignment2.assignment_group.should == group2
      end

      it "should change the month" do
        get "/calendar2"
        old_header_title = get_header_text
        change_calendar
        old_header_title.should_not == get_header_text
      end

      it "should change the week" do
        get "/calendar2"
        header_buttons = ff('.ui-buttonset > label')
        header_buttons[0].click
        wait_for_ajaximations
        old_header_title = get_header_text
        change_calendar('.fc-button-prev')
        old_header_title.should_not == get_header_text
      end

      it "should test the today button" do
        get "/calendar2"
        current_month_num = Time.now.month
        current_month = Date::MONTHNAMES[current_month_num]

        change_calendar
        get_header_text.should_not == current_month
        f('.fc-button-today').click
        get_header_text.should == (current_month + ' ' + Time.now.year.to_s)
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
        events = ff('.fc-event')
        events.size.should eql 2
        events.first.click

        details = f('.event-details')
        details.should_not be_nil
        details.text.should include(@course.default_section.name)
        details.find_element(:css, '.view_event_link')[:href].should include "/calendar_events/#{e1.id}" # links to parent event
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

          ag.reload.appointments.first.description.should eql description
          lambda { f('.fc-event') }.should_not raise_error
        end
      end
    end

    context "week view" do
      it "should render assignments due just before midnight" do
        assignment_model :course => @course,
                         :title => "super important",
                         :due_at => Time.zone.now.beginning_of_week + 1.day - 1.minute

        get "/calendar2"
        wait_for_ajaximations
        f('label[for=week]').click
        wait_for_ajaximations

        events = ff('.fc-event').select{ |e| e.text == "super important" }
        # shows on monday night and tuesday morning, and doesn't have the time
        events.size.should eql 2
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

        keep_trying_until do
          driver.execute_script(%{$(".context_list_context:nth-child(1)").addClass('hovering')})
          fj('ul#context-list li:nth-child(1) button').click
          f("#ui-menu-0-0").click
          edit_event_dialog = f('#edit_event_tabs')
          edit_event_dialog.should be_displayed
        end
        tabs = ffj('.tab_list > li')
        tabs.count.should == 1
        tabs[0].should include_text('Event')
      end
    end

    describe "main calendar" do

      it "should validate appointment group popup link functionality" do
        create_appointment_group
        ag = AppointmentGroup.first
        ag.appointments.first.reserve_for @student, @me
        @user = @me
        get "/calendar2"
        wait_for_ajaximations

        f('.fc-event-title').click
        popover = f("#popover-0")
        popover.should be_displayed
        expect_new_page_load { popover.find_element(:css, '.view_event_link').click }
        wait_for_ajaximations
        is_checked('#scheduler').should be_true
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
        events.size.should eql 1
        events.first.text.should include "1p"
        events.first.click

        details = f('.event-details-content')
        details.should_not be_nil
        details.text.should include(@course.default_section.name)
      end

      it "should redirect to the calendar and show the selected event" do
        event = make_event(:context => @course, :start => 2.months.from_now, :title => "future event")
        get "/courses/#{@course.id}/calendar_events/#{event.id}"
        wait_for_ajaximations

        popup_title = f('.details_title')
        popup_title.should be_displayed
        popup_title.text.should eql "future event"
      end
    end
  end
end
