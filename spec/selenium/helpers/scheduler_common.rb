# frozen_string_literal: true

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

  def scheduler_setup
    create_courses_and_enroll_users
    create_appointment_groups_for_courses
  end

  def create_courses_and_enroll_users
    @course1 = course_model(name: "First Course").tap(&:offer!)
    @course2 = course_model(name: "Second Course").tap(&:offer!)
    @course3 = course_model(name: "Third Course").tap(&:offer!)
    create_users_and_enroll
  end

  def create_users_and_enroll
    @student1 = User.create!(name: 'Student 1')
    @student2 = User.create!(name: 'Student 2')
    @student3 = User.create!(name: 'Student 3')
    @teacher1 = User.create!(name: 'teacher')
    @course1.enroll_student(@student1).accept!
    @course1.enroll_teacher(@teacher1).accept!
    @course1.enroll_student(@student2).accept!
    @course2.enroll_student(@student2).accept!
    @course2.enroll_student(@student1).accept!
    @course3.enroll_student(@student3).accept!
    @course3.enroll_student(@student1).accept!
  end

  def create_appointment_groups_for_courses
    time = Time.zone.now
    time += 1.hour if time.hour == 23 # ensure the appointments are on the same day
    @app1 = AppointmentGroup.create!(title: "Appointment 1", contexts: [@course1],
                                     participant_visibility: 'protected',
                                     new_appointments: [[time, time+30.minutes],
                                                        [time + 30.minutes, time + 1.hour]],
                                     participants_per_appointment: 1, max_appointments_per_participant: 1)
    @app1.publish!
    @app3 = AppointmentGroup.create!(title: "Appointment 3", contexts: [@course1, @course2],
                                                        new_appointments: [[time+1.hour, time+1.hour + 30.minutes]])
    @app3.publish!
  end

  def appointment_params(opts={})
    {
        title: opts[:title],
        contexts: opts[:contexts],
        new_appointments: [
          [opts[:start_at] || Time.zone.now + 1.hour,
           opts[:end_at] || Time.zone.now + 3.hours],
        ],
        participants_per_appointment: opts[:participants] || 4
    }
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

  def reserve_appointment_for(participant, user, appointment_group)
    appointment_group.appointments.first.reserve_for(participant, user)
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

  def open_select_courses_modal(course_name)
    f('#FindAppointmentButton').click
    click_option('.ic-Input', course_name)
    f('[role="dialog"][aria-label="Select Course"] button[type="submit"]').click
  end

  # This method closes the modal only when it is already opened. If not, it will open the modal
  def close_select_courses_modal
    f('#FindAppointmentButton').click
  end

  def click_appointment_link
    f('.view_calendar_link').click
    fj('.agenda-wrapper.active:visible')
    # wait for loading spinner, then wait for it to not be displayed
    wait_for(method: nil, timeout: 3) { f('#refresh_calendar_link').displayed? }
    wait_for(method: nil, timeout: 15) { !f('#refresh_calendar_link').displayed? }
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

  def open_edit_appointment_group_event_dialog
    f('.agenda-event__item .agenda-event__item-container').click
    expect(f('.edit_event_link')).to be_displayed
    f('.edit_event_link').click
    wait_for_ajaximations
  end

  def limit_timeslot_checkbox
    f('[type=checkbox][name="per_slot_option"]')
  end

  def allow_visibility_checkbox
    f('[type=checkbox][name="participant_visibility"]')
  end

  def limit_participation_checkbox
    f('[type=checkbox][name="max_appointments_per_participant_option"]')
  end

  def agenda_item
    f('.agenda-event__item .agenda-event__item-container')
  end

  def scheduler_event
    f('.fc-event.scheduler-event')
  end
end
