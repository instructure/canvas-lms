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
require_relative '../helpers/calendar2_common'

describe "scheduler" do
  include Calendar2Common
  include_context "in-process server selenium tests"
  include Calendar2Common

  context "as a teacher" do

    before(:once) do
      Account.default.settings[:show_scheduler] = true
      Account.default.save!
    end

    before(:each) do
      course_with_teacher_logged_in
    end

    context 'when the New Scheduler feature flag is turned on' do
      before(:each) do
        Account.default.enable_feature!(:better_scheduler)
      end

      it 'shows Appointment Group tab with new scheduler feature flag turned on', priority: "1", test_id: 2937134 do
        get "/calendar"
        f('#create_new_event_link').click
        expect(f('#edit_event_tabs')).to contain_css('.edit_appointment_group_option')
      end

      it 'shows correct title when editing an appointment group', priority: "1", test_id: 2953905 do
        title = 'Ultimate AG'
        create_appointment_group title: title
        get "/calendar"
        f('.scheduler-event').click
        f('.edit_event_link').click
        expect(fj("span.ui-dialog-title:contains('Edit #{title}')")).not_to be_nil
      end

      it 'creates an Appointment Group with the feature flag ON', priority: "1", test_id: 2981262 do
        title = 'my appt'
        location = 'office'
        start_time_text = '02'
        end_time_text = '05'

        get "/calendar"

        f('#create_new_event_link').click
        f('.edit_appointment_group_option').click

        set_value(f('input[name="title"]'), title)
        set_value(f('input[name="location"]'), location)

        # select the first course calendar
        f('.select-calendar-container .ag_contexts_selector').click
        f('.ag-contexts input[type="checkbox"]').click
        f('.ag_contexts_done').click

        # select a proper appointment group time
        t = Time.zone.local(2016, 11, 7, 1, 0, 0)
        date = Time.zone.today.advance(years: 1).to_s
        Timecop.freeze(t) do
          fj('.ui-datepicker-trigger:visible').click
          datepicker_current
          set_value(fj('.time_field.start_time:visible'), start_time_text)
          set_value(fj('.time_field.end_time:visible'),end_time_text)
          set_value(fj('.date_field:visible'), date)
          find('.scheduler-event-details-footer .btn-primary').click
          wait_for_ajax_requests
        end

        # make sure that the DB record for the Appointment Group is correct
        last_group = AppointmentGroup.last
        expect(last_group.title).to eq title
        expect(last_group.location_name).to eq location
        expect(last_group.start_at.strftime("%I")).to eq start_time_text
        expect(last_group.end_at.strftime("%I")).to eq end_time_text
      end

      it 'shows page for editing Appointment Groups', priority: "1", test_id: 2953905 do
        Account.default.enable_feature!(:better_scheduler)
        create_appointment_group(contexts: [@course])
        get "/calendar2"
        f('.fc-title').click
        f('.pull-right .group_details').click
        expect(f('.EditPage')).to include_text("Edit new appointment group")
      end

      it 'does not show the Find Appointment button for the teacher', priority: "1", test_id: 2936794 do
        create_appointment_group title: "appointment1"
        get "/calendar"
        expect(f('#select-course-component')).not_to contain_css("#FindAppointmentButton")
      end
    end

    context 'when the New Scheduler feature flag is turned off' do
      it 'does not show Appointment Group tab with new scheduler feature flag off', priority: "1", test_id: 2937133 do
        Account.default.disable_feature!(:better_scheduler)
        get "/calendar"
        f('#create_new_event_link').click
        expect(f('#edit_event_tabs')).not_to contain_css('.edit_appointment_group_option')
      end
    end
  end
end
