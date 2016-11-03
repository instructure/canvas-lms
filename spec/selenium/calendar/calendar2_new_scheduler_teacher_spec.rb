require_relative '../common'

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
  end
end