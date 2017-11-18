#
# Copyright (C) 2016 - present Instructure, Inc.
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

RSpec.describe DataFixup::PopulateCalendarEventContexts do
  it 'must create a calendar event context for each effective context' do
    course_with_student
    group = AppointmentGroup.create!({
      title: 'foo',
      contexts: [@course],
    })
    ce = CalendarEvent.create!(context: group)
    CalendarEventContext.delete_all # because we have code in place to create them automatically
    expect(ce.calendar_event_contexts.count).to eq 0
    expect {
      DataFixup::PopulateCalendarEventContexts.run
    }.to change { ce.calendar_event_contexts.count }.by(1)
  end
end
