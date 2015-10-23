require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/notifications_common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/calendar2_common')

describe "Notifications" do
  include_context "in-process server selenium tests"

  context "admin" do
    before(:once) do
      course_with_student(active_all: true)
      setup_comm_channel(@student)
    end

    before :each do
      site_admin_logged_in
    end

    it "should send a notification to users that appointment groups are available", priority: "1", test_id: 186566 do
      note_name = 'Appointment Group Published'
      setup_notification(@student, name: note_name)
      create_appointment_group

      get "/users/#{@student.id}/messages"

      # Checks that the notification is there and has the correct "Notification Name" field
      fj('.ui-tabs-anchor:contains("Meta Data")').click
      expect(ff('.table-condensed.grid td').last).to include_text(note_name)
    end
  end
end