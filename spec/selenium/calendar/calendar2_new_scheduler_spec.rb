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
    end

    it 'shows the find appointment button with feature flag turned on', priority: "1", test_id: 2908326 do
      get "/calendar2"
      expect(f('#select-course-component')).to contain_css("#FindAppointmentButton")
    end

    it 'changes the Find Appointment button to a close button once the modal to select courses is closed', priority: "1", test_id: 2916527 do
      get "/calendar2"
      f('#FindAppointmentButton').click
      expect(f('.ReactModalPortal')).to contain_css('.ReactModal__Layout')
      expect(f('.ReactModal__Header')).to include_text('Select Course')
      f('.ReactModal__Footer-Actions .btn').click
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
      open_select_courses_modal(@course3.name)
      expect(f('.fc-content .fc-title')).to include_text(@app3.title)
    end

    it 'hides the already reserved appointment slot for the student', priority: "1", test_id: 2925694 do
      @app1.appointments.first.reserve_for(@student2, @student2)
      get "/calendar2"
      open_select_courses_modal(@course1.name)
      expected_time = calendar_time_string(@app1.new_appointments.last.start_at)
      expect(ff('.fc-time')).to have_size(2)
      expect(f('.fc-content .fc-title')).to include_text(@app1.title)
      expect(f('.fc-time')).to include_text expected_time
    end
  end
end
