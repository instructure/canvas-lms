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

    it "shows the find appointment button with feature flag turned on", priority: "1", test_id: 2908326 do
      get "/calendar2"
      expect(f('#select-course-component')).to contain_css("#FindAppointmentButton")
    end

    it "changes the Find Appointment button to a close button once the modal to select courses is closed", priority: "1", test_id: 2916527 do
      get "/calendar2"
      f('#FindAppointmentButton').click
      expect(f('.ReactModalPortal')).to contain_css('.ReactModal__Layout')
      expect(f('.ReactModal__Header').text).to include('Select Course')
      f('.ReactModal__Footer-Actions .btn').click
      expect(f('#FindAppointmentButton')).to include_text('Close')
    end
  end
end



