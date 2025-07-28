/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import $ from 'jquery'
import EditAppointmentGroupDetails from '../EditAppointmentGroupDetails'
import fcUtil from '@canvas/calendar/jquery/fcUtil'

const equal = (x, y) => expect(x).toBe(y)

const container = document.createElement('div')
container.setAttribute('id', 'fixtures')
document.body.appendChild(container)

let $holder
let new_event
let existing_event
let contexts

describe('EditAppointmentGroupDetails', () => {
  beforeEach(() => {
    $holder = $('<table />').appendTo(document.getElementById('fixtures'))
    new_event = {
      // the important bit is to not have an id
      appointments: [],
      participants_per_appointment: 1,
      title: 'Appointment 1',
      possibleContexts() {
        return [
          {
            asset_string: 'course_1',
            course_sections: [{asset_string: 'section_1'}],
          },
        ]
      },
      context_code: 'course_1',
      context_codes: ['course_1'],
      sub_context_codes: ['section_1'],
      startDate() {
        return fcUtil.wrap('2015-08-07T17:00:00Z')
      },
      allDay: false,
    }
    existing_event = {
      id: 1,
      ...new_event,
    }
    contexts = [
      {
        asset_string: 'course_1',
        course_sections: [{asset_string: 'section_1'}],
        can_create_appointment_groups: {all_sections: true},
      },
    ]
  })

  afterEach(() => {
    // tick past any remaining errorBox fade-ins
    $holder.detach()
    document.getElementById('fixtures').innerHTML = ''
  })

  test('disable context and group controls when editing an existing appointment', function () {
    const instance = new EditAppointmentGroupDetails('#fixtures', existing_event, contexts, null)
    equal(instance.form.find('#option_course_1').prop('disabled'), true)
    equal(instance.form.find('.group-signup-checkbox').prop('disabled'), true)
  })
})
