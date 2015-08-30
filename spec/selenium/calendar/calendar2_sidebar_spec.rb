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

    describe "sidebar" do
      describe "mini calendar" do
        it "should add the event class to days with events" do
          c = make_event
          get "/calendar2"

          events = ff("#minical .event")
          expect(events.size).to eq 1
          expect(events.first.text.strip).to eq c.start_at.day.to_s
        end

        it "should change the main calendars month on click", priority: "1", test_id: 140224 do
          title_selector = ".navigation_title"
          get "/calendar2"

          # turns out that sometimes you don't have any days from other months showing
          # whoda thunk that? (curse you february 2015!)
          while f("#minical .fc-other-month").nil?
            f("#minical .fc-button-prev").click
            wait_for_ajaximations
          end

          orig_titles = ff(title_selector).map(&:text)
          f("#minical .fc-other-month").click

          expect(orig_titles).not_to eq ff(title_selector).map(&:text)
        end
      end

      it "should show the event in the mini calendar", priority: "1", test_id: 138849 do
        # lock to a particular day (the 13th because why not)
        # otherwise it turns out this spec will break on almost every 31st
        date = Date.new(Time.now.year, Time.now.month, 13) - 1.month
        assignment_model(:course => @course,
                         :title => "ricochet",
                         :due_at => date.to_time)
        get "/calendar2"
        wait_for_ajax_requests

        #Because it is in a past month, it should not be on the mini calendar
        expect(f(".event")).to be_nil

        #Go back a month
        f(".fc-button-prev").click

        #look for the event on the mini calendar
        expect(f(".event").text).to include("13")
      end

      describe "contexts list" do
        it "should toggle event display when context is clicked" do
          make_event :context => @course, :start => Time.now
          get "/calendar2"

          f('.context_list_context .context-list-toggle-box').click
          context_course_item = fj('.context_list_context:nth-child(2)')
          expect(context_course_item).to have_class('checked')
          expect(f('.fc-event')).to be_displayed

          fj('.context_list_context:nth-child(2) .context-list-toggle-box').click
          expect(context_course_item).to have_class('not-checked')
          expect(element_exists('.fc_event')).to be_falsey
        end

        it "should constrain context selection to 10" do
          30.times do |x|
            course_with_teacher(:course_name => "Course #{x + 1}", :user => @user, :active_all => true).course
          end

          get "/calendar2"
          ff('.context_list_context').each(&:click)
          expect(ff('.context_list_context.checked').count).to eq 10
        end

        it "should validate calendar feed display" do
          get "/calendar2"

          f('#calendar-feed a').click
          expect(f('#calendar_feed_box')).to be_displayed
        end

        it "should remove calendar item if calendar is unselected", priority: "1", test_id: 138861 do
          title = "blarg"
          make_event :context => @course, :start => Time.now, :title => title
          load_month_view

          #expect event to be on the calendar
          expect(f('.fc-event-title').text).to include title

          # Click the toggle button. First button should be user, second should be course
          ff(".context-list-toggle-box")[1].click
          expect(f('.fc-event-title')).to be_nil

          #Turn back on the calendar and verify that your item appears
          ff(".context-list-toggle-box")[1].click
          expect(f('.fc-event-title').text).to include title
        end
      end

      describe "undated calendar items" do
        it "should show undated events after clicking link", priority: "1", test_id: 138847 do
          e = make_event :start => nil, :title => "pizza party"
          get "/calendar2"

          f("#undated-events-button").click
          wait_for_ajaximations
          undated_events = ff("#undated-events > ul > li")
          expect(undated_events.size).to eq 1
          expect(undated_events.first.text).to match /#{e.title}/
        end

        it "should truncate very long undated event titles" do
          make_event :start => nil, :title => "asdfjkasldfjklasdjfklasdjfklasjfkljasdklfjasklfjkalsdjsadkfljasdfkljfsdalkjsfdlksadjklsadjsadklasdf"
          get "/calendar2"

          f("#undated-events-button").click
          wait_for_ajaximations
          undated_events = ff("#undated-events > ul > li")
          expect(undated_events.size).to eq 1
          expect(undated_events.first.text).to eq "asdfjkasldfjklasdjfklasdjfklasjf..."
        end
      end
    end
  end
end
