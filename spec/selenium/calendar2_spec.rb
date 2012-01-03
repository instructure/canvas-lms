require File.expand_path(File.dirname(__FILE__) + '/common')

describe "calendar2 selenium tests" do
  it_should_behave_like "in-process server selenium tests"

  def make_event(params = {})
    opts = {
      :context     => @user,
      :start       => Time.now,
      :description => "Test event"
    }.with_indifferent_access.merge(params)
    c = CalendarEvent.new :description => opts[:description],
                          :start_at => opts[:start]
    c.context = opts[:context]
    c.save!
    c
  end

  describe "sidebar" do
    before do
      course_with_teacher_logged_in
    end

    describe "mini calendar" do
      it "should add the event class to days with events" do
        c = make_event

        get "/calendar2"
        events = driver.find_elements(:css, "#minical .event")
        events.size.should == 1
        events.first.text.strip.should == c.start_at.day.to_s
      end

      it "should change the main calendar's month on click" do
        title_selector =  "#calendar-app .fc-header-title"

        get "/calendar2"

        orig_title = driver.find_element(:css, title_selector).text
        driver.find_element(:css, "#minical .fc-other-month").click

        orig_title.should_not == driver.find_element(:css, title_selector)
      end
    end

    describe "contexts list" do
      it "should toggle event display when context is clicked" do
        c1 = make_event :context => @user, :start => Time.now
        c2 = make_event :context => @course, :start => Time.now - 1.day

        assert_calendars_event_count = lambda do |n|
          driver.find_elements(:css, "#calendar-app .fc-event").size.should == n
          driver.find_elements(:css, "#minical .event").size.should == n
        end

        get "/calendar2"
        contexts = driver.find_elements(:css, "#context-list > li")
        contexts.each { |c| c["class"].should =~ /\bchecked\b/ }
        assert_calendars_event_count.call 2

        contexts.first.click
        contexts.first["class"].should =~ /\bnot-checked\b/
        assert_calendars_event_count.call 1
      end

      it "should have a menu for adding stuff" do
        contexts = driver.find_elements(:css, "#context-list > li")

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

      it "should allow creating undated calendar events"

      it "should allow creating undated assignments"
    end

    describe "undated events" do
      it "should show undated events after clicking link" do
        e = make_event :start => nil, :title => "pizza party"
        get "/calendar2"

        driver.find_element(:css, ".undated-events-link").click
        wait_for_ajaximations
        undated_events = driver.find_elements(:css, "#undated-events > ul > li")
        undated_events.size.should == 1
        undated_events.first.text.should =~ /#{e.title}/
      end
    end
  end
end
