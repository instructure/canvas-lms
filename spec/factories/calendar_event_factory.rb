#
# Copyright (C) 2011 Instructure, Inc.
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
#

def calendar_event_model(opts={})
  @course ||= course_model(:reusable => true)
  @event = @course.calendar_events.create!(valid_calendar_event_attributes.merge(opts))
end

def appointment_participant_model(opts={})
  participant = opts.delete(:participant) || user_model
  @course = opts[:course] ||= course_model
  @course.offer! unless @course.available?
  if participant.is_a?(User)
    @course.enroll_student(participant).update_attribute(:workflow_state, 'active')
  else
    opts[:sub_context] ||= participant.group_category
  end
  parent_event = opts.delete(:parent_event) || appointment_model(opts)
  parent_event.context.publish! unless opts[:no_publish]
  @appointment_group.reload #why!?
  updating_user = opts.delete(:updating_user) || user_model
  @event = parent_event.reserve_for(participant, updating_user)
end

def appointment_model(opts={})
  appointment_group = opts[:appointment_group] || appointment_group_model(:sub_context => opts.delete(:sub_context))
  appointment_group.update_attributes(:new_appointments => [[opts[:start_at] || Time.now.utc + 1.hour, opts[:end_at] || Time.now.utc + 1.hour]])
  @appointment = appointment_group.new_appointments.first
  appointment_group.reload
  @appointment
end

def appointment_group_model(opts={})
  @course ||= opts.delete(:course) || course_model
  if sub_context = opts.delete(:sub_context)
    opts[:sub_context_codes] = [sub_context.asset_string]
  end
  @appointment_group = AppointmentGroup.create!(valid_appointment_group_attributes.merge(opts))
  @appointment_group
end

def valid_calendar_event_attributes
  {
    :title => "some title"
  }
end

def valid_appointment_group_attributes
  {
    :title => "some title",
    :contexts => [@course]
  }
end
