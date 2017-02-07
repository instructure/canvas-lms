require_relative '../common'
require_relative '../helpers/scheduler_common'

describe "scheduler" do
  include_context "in-process server selenium tests"
  include SchedulerCommon

  context "as a student" do
    before :once do
      Account.default.tap do |a|
        Account.default.enable_feature!(:better_scheduler)
        a.settings[:show_scheduler]   = true
        a.settings[:agenda_view]      = true
        a.save!
      end
      scheduler_setup
    end

    before :each do
      user_session(@student1)
      make_full_screen
      get "/calendar2"
    end

    it 'shows the find appointment button with feature flag turned on', priority: "1", test_id: 2908326 do
      expect(f('#select-course-component')).to contain_css("#FindAppointmentButton")
    end

    it 'changes the Find Appointment button to a close button once the modal to select courses is closed', priority: "1", test_id: 2916527 do
      f('#FindAppointmentButton').click
      expect(f('.ReactModalPortal')).to contain_css('.ReactModal__Layout')
      expect(f('.ReactModal__Header').text).to include('Select Course')
      f('.ReactModal__Footer-Actions .btn').click
      expect(f('#FindAppointmentButton')).to include_text('Close')
    end

    it 'shows appointment slots on calendar in Find Appointment mode', priority: "1", test_id: 2925320 do
      open_select_courses_modal(@course1.name)
      # the order they come back could vary depending on whether they split
      # days, but we expect them all to be rendered
      titles = [@app1.title, @app1.title, @app3.title]
      ff('.fc-content .fc-title').sort_by(&:text).zip(titles).each do |node, title|
        expect(node).to include_text(title)
      end
      close_select_courses_modal

      # open again to see if appointment group spanning two content appears on selecting the other course also
      open_select_courses_modal(@course3.name)
      expect(f('.fc-content .fc-title')).to include_text(@app3.title)
    end

    it 'hides the already reserved appointment slot for the student', priority: "1", test_id: 2925694 do
      open_select_courses_modal(@course1.name)
      num_slots = ff('.fc-time').size
      @app1.appointments.first.reserve_for(@student2, @student2)
      # close and open again to reload the page
      close_select_courses_modal
      refresh_page
      open_select_courses_modal(@course1.name)
      expected_time = format_time_for_view(@app1.new_appointments.last.start_at)
      expect(ff('.fc-time').size).to eq(num_slots-1)
      expect(ff('.fc-content .fc-title')[0]).to include_text(@app1.title)
      actual_time = ff('.fc-time')[0].text
      expect(expected_time).to include actual_time
    end

  end
end



