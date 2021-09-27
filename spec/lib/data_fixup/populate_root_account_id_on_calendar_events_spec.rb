# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

require 'spec_helper'

describe DataFixup::PopulateRootAccountIdOnCalendarEvents do
  before(:once) do
    Account.find_or_create_by!(id: 0).update(name: 'Dummy Root Account', workflow_state: 'deleted', root_account_id: nil)
  end

  it 'ignores CalendarEvents with Course context' do
    event = CalendarEvent.create!(context: course_model)
    event.update_column(:root_account_id, nil)
    DataFixup::PopulateRootAccountIdOnCalendarEvents.run(event.id, event.id)
    expect(event.reload.root_account_id).to be_nil
  end

  it 'ignores CalendarEvents with Group context' do
    event = CalendarEvent.create!(context: group_model)
    event.update_column(:root_account_id, nil)
    DataFixup::PopulateRootAccountIdOnCalendarEvents.run(event.id, event.id)
    expect(event.reload.root_account_id).to be_nil
  end

  it 'ignores CalendarEvents with CourseSection context' do
    section = CourseSection.create!(course: course_model)
    event = CalendarEvent.create!(context: section)
    event.update_column(:root_account_id, nil)
    DataFixup::PopulateRootAccountIdOnCalendarEvents.run(event.id, event.id)
    expect(event.reload.root_account_id).to be_nil
  end

  it 'ignores CalendarEvents with User context and no effective context' do
    event = CalendarEvent.create!(context: user_model)
    event.update_column(:root_account_id, nil)
    DataFixup::PopulateRootAccountIdOnCalendarEvents.run(event.id, event.id)
    expect(event.reload.root_account_id).to be_nil
  end

  it 'sets root_account_id from effective context for CalendarEvent with User context' do
    course = course_model
    event = CalendarEvent.create!(context: user_model, effective_context_code: course.asset_string)
    event.update_column(:root_account_id, nil)
    DataFixup::PopulateRootAccountIdOnCalendarEvents.run(event.id, event.id)
    expect(event.reload.root_account_id).to eq course.root_account_id
  end

  it 'sets root_account_id from effective context for CalendarEvent with AppointmentGroup context' do
    course = course_model
    ag = AppointmentGroup.create!
    AppointmentGroupContext.create!(appointment_group: ag, context: course)
    event = CalendarEvent.create!(context: ag.reload)
    event.update_column(:root_account_id, nil)
    DataFixup::PopulateRootAccountIdOnCalendarEvents.run(event.id, event.id)
    expect(event.reload.root_account_id).to eq course.root_account_id
  end

  it 'sets root_account_id from effective context for child CalendarEvent' do
    course = course_model
    parent = CalendarEvent.create!(context: course)
    event = CalendarEvent.create!(context: user_model, parent_event: parent)
    event.update_column(:root_account_id, nil)
    DataFixup::PopulateRootAccountIdOnCalendarEvents.run(event.id, event.id)
    expect(event.reload.root_account_id).to eq course.root_account_id
  end

  it 'sets root_account_id from effective context for multiple CalendarEvents' do
    course = course_model
    e1 = CalendarEvent.create!(context: user_model, effective_context_code: course.asset_string)
    ag = AppointmentGroup.create!
    AppointmentGroupContext.create!(appointment_group: ag, context: course)
    e2 = CalendarEvent.create!(context: ag.reload)
    parent = CalendarEvent.create!(context: course)
    e3 = CalendarEvent.create!(context: user_model, parent_event: parent)
    events = [e1, e2, e3]

    CalendarEvent.where(id: events.map(&:id)).update_all(root_account_id: nil)
    DataFixup::PopulateRootAccountIdOnCalendarEvents.run(e1.id, e3.id)
    events.each do |e|
      expect(e.reload.root_account_id).to eq course.root_account_id
    end
  end
end