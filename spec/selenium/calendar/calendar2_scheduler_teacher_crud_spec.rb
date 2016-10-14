require File.expand_path(File.dirname(__FILE__) + '/../common')
require File.expand_path(File.dirname(__FILE__) + '/../helpers/calendar2_common')
require File.expand_path(File.dirname(__FILE__) + '/../helpers/scheduler_common')

describe "scheduler" do
  include_context "in-process server selenium tests"
  include Calendar2Common
  include SchedulerCommon

  context "as a teacher" do

    before(:once) do
      Account.default.tap do |a|
        a.settings[:show_scheduler]   = true
        a.settings[:agenda_view]      = true
        a.save!
      end
    end

    before(:each) do
      course_with_teacher_logged_in
      make_full_screen
    end

    it "should create a new appointment group" do
      get "/calendar2"
      click_scheduler_link
      create_appointment_group_manual
    end

    it "should create appointment group and go back and publish it", priority: "1", test_id: 85934 do
      get "/calendar2"
      click_scheduler_link

      create_appointment_group_manual(:publish => false)
      new_appointment_group = AppointmentGroup.last
      expect(new_appointment_group.workflow_state).to eq 'pending'
      expect(f('.ag-x-of-x-signed-up')).to include_text('unpublished')
      open_edit_dialog
      edit_form = f('#edit_appointment_form')
      expect(edit_form).to be_displayed
      f('.ui-dialog-buttonset .Button--primary').click
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

    it "should allow section limited teachers to create appointment groups for their own sections" do
      course_with_teacher_logged_in(:limit_privileges_to_course_section => true)
      @course.course_sections.create! :name => 'other section'

      section_name = "seeable section"
      section = @course.default_section
      section.name = section_name
      section.save!

      get "/calendar2"
      click_scheduler_link
      fill_out_appointment_group_form("blah", :skip_contexts => true)
      f('.ag_contexts_selector').click
      expect(f('.ag_sections_toggle.ag-sections-expanded')).to_not be_nil # should already be expanded
      expect(f('[name="context_codes[]"]')).to be_disabled # course checkbox should be disabled
      expect(ff("[name='sections[]']")).to have_size 1 # should only show one section

      f("[name='sections[]'][value='#{section.asset_string}']").click
      f('.ag_contexts_done').click

      submit_appointment_group_form

      @course.reload
      new_group = @course.appointment_groups.first
      expect(new_group.sub_contexts.first).to eq section
    end

    it "should delete an appointment group", priority: "1", test_id: 140216 do
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
      fj('.agenda-event .ig-row').click
      wait_for_ajaximations
      driver.execute_script("$('.event-details .delete_event_link').trigger('click')")
      wait_for_ajaximations
      delete_appointment_group
      expect(f("#content")).not_to contain_css('.fc-event-bg')
    end

    it "should check index page for correct element", priority: "1", test_id: 85949 do
      title = "blarg"
      location = "brighton"

      create_appointment_group(:location_name => location, :title => title)
      get "/calendar2"
      click_scheduler_link

      # Index page should show correct elements for appointment groups
      expect(f(".view_calendar_link")).to include_text(title)
      expect(f(".ag-context")).to include_text @course.name.to_s
      expect(f(".ag-location")).to include_text location
      expect(f(".ag-x-of-x-signed-up")).to include_text "people have signed up"
      expect(f(".icon-settings")).not_to be_nil #Gear icon present
    end
  end
end
