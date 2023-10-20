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

export const userContext = {
  asset_string: 'user_1',
  name: 'user_1@instructure.com',
  new_calendar_event_url: '',
  k5_course: false,
  can_create_calendar_events: true,
  type: 'user',
  course_pacing_enabled: false,
}

export const courseContext = {
  asset_string: 'course_1',
  name: 'Geometry',
  new_calendar_event_url: '',
  k5_course: false,
  can_create_calendar_events: true,
  type: 'course',
  course_pacing_enabled: true,
}

export const accountContext = {
  asset_string: 'account_1',
  name: 'Boss',
  new_calendar_event_url: '',
  k5_course: false,
  can_create_calendar_events: true,
  type: 'account',
  course_pacing_enabled: true,
}

const formHolder = document.getElementById('edit_calendar_event_form_holder')

const event = {
  title: 'title',
  contextInfo: userContext,
  allPossibleContexts: [userContext, courseContext],
  location_name: '',
  date: new Date(),
  allDay: false,
  calendarEvent: {start_at: null, end_at: null},
  important_dates: false,
  blackout_date: false,
  lockedTitle: false,
  fullDetailsURL: jest.fn(),
  isNewEvent: () => false,
  possibleContexts: jest.fn(() => [userContext, courseContext]),
  startDate: () => moment(),
  save: jest.fn(),
  removeClass: jest.fn(),
  start: null,
  end: null,
  important_info: false,
  can_change_context: true,
  object: {context_code: 'user_1'},
  old_context_code: null,
}

export const conference = {
  name: 'BigBlueButton',
  title: 'BigBlueButton',
  conference_type: 'BigBlueButton',
}

export const defaultEvent = event

export const eventFormProps = () => {
  const closeCB = jest.fn()
  const eventSave = jest.fn(() => closeCB())
  return {
    formHolder,
    event: {...event, save: eventSave},
    closeCB,
    contextChangeCB: jest.fn(),
    setSetContextCB: jest.fn(),
    timezone: 'Etc/UTC',
  }
}

export const accountCalendarsAPIPage1Response = {
  account_calendars: [
    {
      id: '5',
      name: 'Elementary courses',
      parent_account_id: '1',
      root_account_id: '0',
      visible: true,
      asset_string: 'account_5',
      type: 'account',
    },
    {
      id: '4',
      name: 'High school courses',
      parent_account_id: '1',
      root_account_id: '2',
      visible: true,
      asset_string: 'account_4',
      type: 'account',
    },
  ],
  total_results: 4,
}

export const accountCalendarsAPIPage2Response = {
  account_calendars: [
    {
      id: '1',
      name: 'School A',
      parent_account_id: null,
      root_account_id: '0',
      visible: true,
      asset_string: 'account_1',
      type: 'account',
    },
    {
      id: '2',
      name: 'Super Courses',
      parent_account_id: '1',
      root_account_id: '0',
      visible: true,
      asset_string: 'account_2',
      type: 'account',
    },
  ],
  total_results: 4,
}

export const accountCalendarsAPISearchResponse = {
  account_calendars: [
    {
      id: '1',
      name: 'Test',
      parent_account_id: null,
      root_account_id: '0',
      visible: true,
      asset_string: 'account_1',
      type: 'account',
    },
  ],
  total_results: 1,
}

export const allAccountCalendarsResponse = {
  account_calendars: [
    ...accountCalendarsAPIPage1Response.account_calendars,
    ...accountCalendarsAPIPage2Response.account_calendars,
  ],
  total_results: 4,
}

export const emptyResponse = {
  account_calendars: [],
  total_results: 0,
}
