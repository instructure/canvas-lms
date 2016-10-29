require File.expand_path(File.dirname(__FILE__) + '/../common')

module SchedulerCommon
  def fill_out_appointment_group_form(new_appointment_text, opts = {})
    f('.create_link').click
    edit_form = f('#edit_appointment_form')
    expect(edit_form).to be_displayed
    replace_content(f('input[name="title"]'), new_appointment_text)
    unless opts[:skip_contexts]
      f('.ag_contexts_selector').click
      f('.ag_sections_toggle').click
      if opts[:section_codes]
        opts[:section_codes].each { |code| f("[name='sections[]'][value='#{code}']").click }
      else
        f('[name="context_codes[]"]').click
      end
      f('.ag_contexts_done').click
    end
    if opts[:checkable_options]
      if opts[:checkable_options].has_key?(:per_slot_option)
        set_value f('[type=checkbox][name="per_slot_option"]'), true
      end
      if opts[:checkable_options].has_key?(:participant_visibility)
        set_value f('[type=checkbox][name="participant_visibility"]'), true
      end
      if opts[:checkable_options].has_key?(:max_appointments_per_participant_option)
        set_value f('[type=checkbox][name="max_appointments_per_participant_option"]'), true
      end
    end
    date_field = edit_form.find_element(:css, '.date_field')
    date_field.click
    wait_for_ajaximations
    fj('.ui-datepicker-trigger:visible').click
    datepicker_next
    replace_content(edit_form.find_element(:css, '.start_time'), '1')
    replace_content(edit_form.find_element(:css, '.end_time'), '3')
  end

  def submit_appointment_group_form(publish = true)
    save, save_and_publish = ff('.ui-dialog-buttonset .ui-button')
    if publish
      save_and_publish.click
    else
      save.click
    end
    wait_for_ajaximations
  end

  def create_appointment_group_manual(opts = {})
    opts = {
        :publish => true,
        :new_appointment_text => 'new appointment group'
    }.with_indifferent_access.merge(opts)

    expect {
      fill_out_appointment_group_form(opts[:new_appointment_text], opts)
      submit_appointment_group_form(opts[:publish])
      expect(f('.view_calendar_link').text).to eq opts[:new_appointment_text]
    }.to change(AppointmentGroup, :count).by(1)
  end

  def click_scheduler_link
    f('button#scheduler').click
    wait_for_ajaximations
  end

  def click_appointment_link
    f('.view_calendar_link').click
    expect(f('.agenda-wrapper.active')).to be_displayed
    wait_for_ajaximations
  end

  def click_al_option(option_selector, offset=0)
    ffj('.al-trigger')[offset].click
    options = ffj('.al-options')[offset]
    expect(options).to be_displayed
    options.find_element(:css, option_selector).click
  end

  def delete_appointment_group
    driver.execute_script("$('.ui-dialog-buttonset .btn-primary').trigger('click')")
    wait_for_ajaximations
  end

  def edit_appointment_group(appointment_name = 'edited appointment', location_name = 'edited location')
    expect(f('#edit_appointment_form')).to be_displayed
    replace_content(fj('input[name="title"]'), appointment_name)
    replace_content(fj('input[name="location"]'), location_name)
    driver.execute_script("$('.ui-dialog-buttonset .Button--primary').trigger('click')")
    wait_for_ajaximations
    expect(f('.view_calendar_link').text).to eq appointment_name
    expect(f('.ag-location')).to include_text(location_name)
  end

  def open_edit_dialog
    driver.action.move_to(f('.appointment-group-item')).perform
    click_al_option('.edit_link')
    wait_for_ajaximations
  end

  def open_edit_appointment_group_event_dialog
    f('.agenda-event .ig-row').click
    expect(f('.edit_event_link')).to be_displayed
    f('.edit_event_link').click
    wait_for_ajaximations
  end
end
