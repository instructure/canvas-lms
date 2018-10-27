#
# Copyright (C) 2016 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

require_relative '../common'
require_relative '../helpers/scheduler_common'

describe "scheduler" do
  include_context "in-process server selenium tests"
  include SchedulerCommon

  context "find appointment mode as a student" do
    before :once do
      Account.default.tap do |a|
        a.enable_feature!(:better_scheduler)
        a.settings[:show_scheduler]   = true
        a.settings[:agenda_view]      = true
        a.save!
      end
      scheduler_setup
    end

    before :each do
      user_session(@student1)
      make_full_screen
    end

    it 'shows the find appointment button with feature flag turned on', priority: "1", test_id: 2908326 do
      get "/calendar2"
      expect(f('#select-course-component')).to contain_css("#FindAppointmentButton")
    end

    it 'does not show the scheduler tab when the feature flag is turned on', priority: "1", test_id: 2926048 do
      get "/calendar2"
      expect(f('.calendar_view_buttons')).not_to contain_css('#scheduler')
    end

    it 'changes the Find Appointment button to a close button once the modal to select courses is closed', priority: "1", test_id: 2916527 do
      get "/calendar2"
      f('#FindAppointmentButton').click
      expect(f('[role="dialog"][aria-label="Select Course"]')).to contain_css('select')
      f('[role="dialog"][aria-label="Select Course"] button[type="submit"]').click
      expect(f('#FindAppointmentButton')).to include_text('Close')
    end

    it 'shows appointment slots on calendar in Find Appointment mode', priority: "1", test_id: 2925320 do
      get "/calendar2"
      open_select_courses_modal(@course1.name)
      # the order they come back could vary depending on whether they split
      # days, but we expect them all to be rendered
      expect(ffj(".fc-content .fc-title:contains(#{@app1.title})")).to have_size(2)
      expect(ffj(".fc-content .fc-title:contains(#{@app3.title})")).to have_size(1)
      close_select_courses_modal

      # open again to see if appointment group spanning two content appears on selecting the other course also
      open_select_courses_modal(@course2.name)
      expect(f('.fc-content .fc-title')).to include_text(@app3.title)
    end

    it 'hides the already reserved appointment slot for the student', priority: "1", test_id: 2925694 do
      reserve_appointment_for(@student2, @student2, @app1)
      get "/calendar2"
      open_select_courses_modal(@course1.name)
      expected_time = calendar_time_string(@app1.new_appointments.last.start_at)
      expect(ff('.fc-time')).to have_size(2)
      expect(f('.fc-content .fc-title')).to include_text(@app1.title)
      expect(f('.fc-time')).to include_text expected_time
    end

    it 'does not show the course name with no appointment in the drop down', priority: "1", test_id: 2925695 do
      get "/calendar2"
      f('#FindAppointmentButton').click
      options = get_options('.ic-Input')
      options.each do |option|
        expect(option.text).not_to include('Third Course')
      end
    end

    it 'hides the find appointment button for a student if there is no appointment group to sign up to', priority: "1", test_id: 3189024 do
      user_session(@student3)
      get "/calendar2"
      expect(f('#select-course-component')).not_to contain_css('#FindAppointmentButton')
    end

    it 'reserves appointment slots in find appointment mode', priority: "1", test_id: 2936790 do
      get "/calendar2"
      open_select_courses_modal(@course1.name)
      f('.fc-content').click
      wait_for_ajaximations
      move_to_click('.reserve_event_link')
      refresh_page
      expected_time = calendar_time_string(@app1.new_appointments.first.start_at)
      wait_for_ajaximations
      expect(f('.fc-content .fc-title')).to include_text(@app1.title)
      expect(f('.fc-time')).to include_text expected_time
    end

    it 'unreserves appointment slot', priority:"1", test_id: 2936791 do
      reserve_appointment_for(@student1, @student1, @app1)
      expect(@app1.appointments.first.workflow_state).to eq('locked')
      get "/calendar2"
      move_to_click('.fc-event.scheduler-event')
      wait_for_ajaximations
      move_to_click('.unreserve_event_link')
      expect(f('#delete_event_dialog')).to be_present
      f('.ui-dialog-buttonset .btn-primary').click
      # save the changes so the appointment object is updated
      @app1.save!
      expect(@app1.appointments.first.workflow_state).to eq('active')
    end

    it 'does not allow scheduling multiple appointment slots when it is restricted', priority: "1", test_id: 2936793 do
      reserve_appointment_for(@student1, @student1, @app1)
      get "/calendar2"
      open_select_courses_modal(@course1.name)
      expect(f('.fc-content .icon-calendar-add')).to be
      scroll_into_view('.fc-content .icon-calendar-add')
      f('.fc-content .icon-calendar-add').click
      wait_for_ajaximations
      f('.reserve_event_link').click
      wait_for_ajaximations
      visible_dialog_element = fj(".ui-dialog:contains('You are already signed up for')")
      title = visible_dialog_element.find_element(:css, '.ui-dialog-titlebar')
      expect(title.text).to include('Cancel existing reservation and sign up for this one?')
      f('.ui-dialog-buttonset .ui-button').click
      scroll_to(f('span[class="navigation_title_text"]'))
      ff('.fc-content .fc-title')[1].click
      wait_for_ajaximations
      expect(f('.event-details')).to contain_css('.reserve_event_link')
    end
  end
end
