#
# Copyright (C) 2012 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../common')
require File.expand_path(File.dirname(__FILE__) + '/../helpers/calendar2_common')

describe "scheduler" do
  include_context "in-process server selenium tests"
  include Calendar2Common

  context "as a teacher" do

    before(:once) do
      Account.default.tap do |a|
        a.settings[:show_scheduler]   = true
        a.settings[:agenda_view]      = true
        a.save!
      end
      course_with_teacher(active_all: true)
    end

    before(:each) do
      user_session(@teacher)

    end

    it "should validate the appointment group shows on all views after a student signed up", priority: "1", test_id: 1729408 do
      date = Time.zone.today.to_s
      create_appointment_group(:new_appointments => [
        [date + ' 12:00:00', date + ' 13:00:00'],
      ])
      ag = AppointmentGroup.first
      student_in_course(course: @course, active_all: true)
      ag.appointments.first.reserve_for(@user, @user, comments: 'this is important')
      load_month_view
      expect(f('.fc-content .fc-title').text).to include('new appointment group')
      f('#week').click
      expect(f('.fc-content .fc-title').text).to include('new appointment group')
      f('#agenda').click
      expect(agenda_item.text).to include('new appointment group')
    end
  end
end
