/*
 * Copyright (C) 2022 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import moment from 'moment'

const context = {
  asset_string: 'user_1',
  name: 'user_1@instructure.com',
  new_calendar_event_url: '',
  k5_course: false,
  can_create_calendar_events: true
}

const context2 = {
  asset_string: 'course_1',
  name: 'Geometry',
  new_calendar_event_url: '',
  k5_course: false,
  can_create_calendar_events: true
}

const formHolder = document.getElementById('edit_calendar_event_form_holder')

const event = {
  title: 'title',
  contextInfo: context,
  allPossibleContexts: [context, context2],
  location_name: '',
  date: new Date(),
  allDay: false,
  calendarEvent: {start_at: null, end_at: null},
  important_dates: false,
  lockedTitle: false,
  fullDetailsURL: jest.fn(),
  isNewEvent: () => false,
  possibleContexts: jest.fn(() => [context, context2]),
  startDate: () => moment(),
  save: jest.fn(),
  removeClass: jest.fn(),
  start: null,
  end: null,
  important_info: false,
  can_change_context: true,
  object: {context_code: 'user_1'},
  old_context_code: null
}

export const conference = {
  name: 'BigBlueButton',
  title: 'BigBlueButton',
  conference_type: 'BigBlueButton'
}

export const eventFormProps = () => {
  return {
    formHolder,
    event,
    isChild: false,
    closeCB: jest.fn(),
    contextChangeCB: jest.fn(),
    setSetContextCB: jest.fn(),
    timezone: 'Etc/UTC'
  }
}
