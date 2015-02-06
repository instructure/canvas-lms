require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/calendar2_common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/scheduler_common')

describe "scheduler" do
  include_examples "in-process server selenium tests"
  context "as a teacher" do

    before (:once) do
      Account.default.tap do |a|
        a.settings[:show_scheduler]   = true
        a.settings[:agenda_view]      = true
        a.save!
      end
    end

    before (:each) do
      course_with_teacher_logged_in
      make_full_screen
    end

    it "should create a new appointment group" do
      get "/calendar2"
      click_scheduler_link
      create_appointment_group_manual
    end

    it "should create appointment group and go back and publish it" do
      get "/calendar2"
      click_scheduler_link

      create_appointment_group_manual(:publish => false)
      new_appointment_group = AppointmentGroup.last
      expect(new_appointment_group.workflow_state).to eq 'pending'
      expect(f('.ag-x-of-x-signed-up')).to include_text('unpublished')
      open_edit_dialog
      edit_form = f('#edit_appointment_form')
      keep_trying_until { expect(edit_form).to be_displayed }
      f('.ui-dialog-buttonset .btn-primary').click
      wait_for_ajaximations
      new_appointment_group.reload
      expect(new_appointment_group.workflow_state).to eq 'active'
    end

    it "should edit an appointment group" do
      create_appointment_group
      get "/calendar2"
      click_scheduler_link

      open_edit_dialog
      edit_appointment_group
    end

    it "should edit an appointment group after clicking appointment group link" do
      create_appointment_group
      get "/calendar2"
      click_scheduler_link
      click_appointment_link
      click_al_option('.edit_link')
      edit_appointment_group
    end

    it "should select the correct course sections when editing an appointment group" do
      section = @course.course_sections.create! :name => 'section1'
      @course.course_sections.create! :name => 'section2'
      get "/calendar2"
      click_scheduler_link
      # first create the group
      create_appointment_group_manual :section_codes => %W(course_section_#{section.id})
      # then open it's edit dialog
      open_edit_dialog
      # expect only section1 to be selected
      f('.ag_contexts_selector').click
      expect(ffj('.ag_sections input:checked').size).to eq 1
    end

    it "should delete an appointment group" do
      create_appointment_group
      get "/calendar2"
      click_scheduler_link

      appointment_group = f('.appointment-group-item')
      driver.action.move_to(appointment_group).perform
      click_al_option('.delete_link')
      delete_appointment_group
      expect(f('.list-wrapper')).to include_text('You have not created any appointment groups')
    end

    it "should delete an appointment group after clicking appointment group link" do
      create_appointment_group
      get "/calendar2"
      click_scheduler_link
      click_appointment_link

      click_al_option('.delete_link')
      delete_appointment_group
      expect(f('.list-wrapper')).to include_text('You have not created any appointment groups')
    end

    it "should delete the appointment group from the calendar" do
      create_appointment_group
      get "/calendar2"
      click_scheduler_link
      click_appointment_link
      fj('.fc-event:visible').click
      wait_for_ajaximations
      driver.execute_script("$('.event-details .delete_event_link').trigger('click')")
      wait_for_ajaximations
      delete_appointment_group
      keep_trying_until { expect(element_exists('.fc-event-bg')).to be_falsey }
    end
  end
end