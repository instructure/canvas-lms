require_relative '../common'
require_relative '../helpers/calendar2_common'

describe "scheduler" do
  include_context "in-process server selenium tests"

  context "as a teacher" do

    before(:once) do
      Account.default.settings[:show_scheduler] = true
      Account.default.save!
    end

    before(:each) do
      course_with_teacher_logged_in
    end

    it 'shows Appointment Group tab with new scheduler feature flag turned on', priority: "1", test_id: 2937134 do
      Account.default.enable_feature!(:better_scheduler)
      get "/calendar"
      f('#create_new_event_link').click
      expect(f('#edit_event_tabs')).to contain_css('.edit_appointment_group_option')
    end

    it 'does not show Appointment Group tab with new scheduler feature flag off', priority: "1", test_id: 2937133 do
      Account.default.disable_feature!(:better_scheduler)
      get "/calendar"
      f('#create_new_event_link').click
      expect(f('#edit_event_tabs')).not_to contain_css('.edit_appointment_group_option')
    end

    it 'creates an Appointment Group with the feature flag ON', priority: "1", test_id: 2981262 do
      Account.default.enable_feature!(:better_scheduler)

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
      end

      # make sure that the DB record for the Appointment Group is correct
      last_group = AppointmentGroup.last
      expect(last_group.title).to eq title # spec breaks here
      expect(last_group.location_name).to eq location
      expect(last_group.start_at.strftime("%I")).to eq start_time_text
      expect(last_group.end_at.strftime("%I")).to eq end_time_text
    end
  end
end
