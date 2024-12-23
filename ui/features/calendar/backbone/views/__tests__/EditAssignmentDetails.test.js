/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
import 'jquery-migrate'
import EditAssignmentDetails from '../EditAssignmentDetails'
import fcUtil from '@canvas/calendar/jquery/fcUtil'
import timezone from 'timezone'
import tzInTest from '@instructure/moment-utils/specHelpers'
import detroit from 'timezone/America/Detroit'
import french from 'timezone/fr_FR'
import fakeENV from '@canvas/test-utils/fakeENV'
import commonEventFactory from '@canvas/calendar/jquery/CommonEvent/index'
import {getI18nFormats} from '@canvas/datetime/configureDateTime'

describe('EditAssignmentDetails', () => {
  let $holder
  let event
  let fixtures

  beforeAll(() => {
    fixtures = document.createElement('div')
    fixtures.id = 'fixtures'
    document.body.appendChild(fixtures)
  })

  afterAll(() => {
    fixtures.remove()
  })

  beforeEach(() => {
    fixtures.innerHTML = '<div id="test_area"></div>'
    $holder = $('#test_area')
    event = {
      possibleContexts() {
        return [
          {
            name: 'k5 Course',
            asset_string: 'course_1',
            id: '1',
            concluded: false,
            k5_course: true,
            can_create_assignments: true,
            assignment_groups: [{id: '9', name: 'Assignments'}],
          },
          {
            name: 'Normal Course',
            asset_string: 'course_2',
            id: '2',
            concluded: false,
            k5_course: false,
            can_create_assignments: true,
            assignment_groups: [{id: '9', name: 'Assignments'}],
          },
          {
            name: 'Course Pacing',
            asset_string: 'course_3',
            id: '3',
            concluded: false,
            course_pacing_enabled: true,
            k5_course: false,
            can_create_assignments: true,
            assignment_groups: [{id: '9', name: 'Assignments'}],
          },
        ]
      },
      isNewEvent() {
        return true
      },
      startDate() {
        return fcUtil.wrap('2015-08-07T17:00:00Z')
      },
    }
    fakeENV.setup()
  })

  afterEach(() => {
    $holder.detach()
    fixtures.innerHTML = ''
    fakeENV.teardown()
    tzInTest.restore()
  })

  const createView = (model, event) => {
    const view = new EditAssignmentDetails('#test_area', event, null, null)
    return view.render()
  }

  const commonEvent = () =>
    commonEventFactory({assignment: {due_at: '2016-02-25T23:30:00Z'}}, ['course_1'])

  const nameLengthHelper = (
    view,
    length,
    maxNameLengthRequiredForAccount,
    maxNameLength,
    postToSis,
  ) => {
    const name = 'a'.repeat(length)
    ENV.MAX_NAME_LENGTH_REQUIRED_FOR_ACCOUNT = maxNameLengthRequiredForAccount
    ENV.MAX_NAME_LENGTH = maxNameLength
    return view.validateBeforeSave(
      {
        assignment: {
          name,
          post_to_sis: postToSis,
        },
      },
      [],
    )
  }

  test('should initialize input with start date and time', () => {
    const view = createView(commonEvent(), event)
    expect(view.$('.datetime_field').val()).toBe('Fri Aug 7, 2015 5:00pm')
  })

  test('should have blank input when no start date', () => {
    const modifiedEvent = {...event, startDate: () => null}
    const view = createView(commonEvent(), modifiedEvent)
    expect(view.$('.datetime_field').val()).toBe('')
  })

  test('should treat start date as fudged', () => {
    tzInTest.configureAndRestoreLater({
      tz: timezone(detroit, 'America/Detroit'),
      tzData: {
        'America/Detroit': detroit,
      },
      formats: getI18nFormats(),
    })
    const view = createView(commonEvent(), event)
    expect(view.$('.datetime_field').val()).toBe('Fri Aug 7, 2015 1:00pm')
  })

  test('should localize start date', () => {
    tzInTest.configureAndRestoreLater({
      tz: timezone(french, 'fr_FR'),
      momentLocale: 'fr',
      formats: {
        'date.formats.full_with_weekday': '%a %-d %b %Y %-k:%M',
        'date.formats.medium_with_weekday': '%a %-d %b %Y',
        'date.month_names': ['août'],
        'date.abbr_month_names': ['août'],
      },
    })
    const view = createView(commonEvent(), event)
    expect(view.$('.datetime_field').val()).toBe('ven. 7 août 2015 17:00')
  })

  test('requires name to save assignment event', () => {
    const view = createView(commonEvent(), event)
    const data = {
      assignment: {
        name: '',
        post_to_sis: '',
      },
    }
    const errors = view.validateBeforeSave(data, [])
    expect(errors['assignment[name]']).toBeTruthy()
    expect(errors['assignment[name]']).toHaveLength(1)
    expect(errors['assignment[name]'][0].message).toBe('Name is required!')
  })

  test('has an error when a name has 257 chars', () => {
    const view = createView(commonEvent(), event)
    const errors = nameLengthHelper(view, 257, false, 30, '1')
    expect(errors['assignment[name]']).toBeTruthy()
    expect(errors['assignment[name]']).toHaveLength(1)
    expect(errors['assignment[name]'][0].message).toBe(
      'Name is too long, must be under 257 characters',
    )
  })

  test('allows assignment event to save when a name has 256 chars, MAX_NAME_LENGTH is not required and post_to_sis is true', () => {
    const view = createView(commonEvent(), event)
    const errors = nameLengthHelper(view, 256, false, 30, '1')
    expect(errors).toHaveLength(0)
  })

  test('allows assignment event to save when a name has 15 chars, MAX_NAME_LENGTH is 10 and is required, post_to_sis is true and grading_type is not_graded', () => {
    const modifiedEvent = {...event, grading_type: 'not_graded'}
    const view = createView(commonEvent(), modifiedEvent)
    const errors = nameLengthHelper(view, 15, true, 10, '1')
    expect(errors).toHaveLength(0)
  })

  test('has an error when a name has 11 chars, MAX_NAME_LENGTH is 10 and is required, and post_to_sis is true', () => {
    const view = createView(commonEvent(), event)
    const errors = nameLengthHelper(view, 11, true, 10, '1')
    expect(errors['assignment[name]']).toBeTruthy()
    expect(errors['assignment[name]']).toHaveLength(1)
    expect(errors['assignment[name]'][0].message).toBe(
      `Name is too long, must be under ${ENV.MAX_NAME_LENGTH + 1} characters`,
    )
  })

  test('allows assignment event to save when name has 11 chars, MAX_NAME_LENGTH is 10 and required, but post_to_sis is false', () => {
    const view = createView(commonEvent(), event)
    const errors = nameLengthHelper(view, 11, true, 10, '0')
    expect(errors).toHaveLength(0)
  })

  test('allows assignment event to save when name has 10 chars, MAX_NAME_LENGTH is 10 and required, and post_to_sis is true', () => {
    const view = createView(commonEvent(), event)
    const errors = nameLengthHelper(view, 10, true, 10, '1')
    expect(errors).toHaveLength(0)
  })

  test('requires due_at to save assignment event if there is no date and post_to_sis is true', () => {
    ENV.DUE_DATE_REQUIRED_FOR_ACCOUNT = true
    const view = createView(commonEvent(), event)
    const data = {
      assignment: {
        name: 'Too much tuna',
        post_to_sis: '1',
        due_at: '',
      },
    }
    const errors = view.validateBeforeSave(data, [])
    expect(errors['assignment[due_at]']).toBeTruthy()
    expect(errors['assignment[due_at]']).toHaveLength(1)
    expect(errors['assignment[due_at]'][0].message).toBe('Due Date is required!')
  })

  test('allows assignment event to save if there is no date and post_to_sis is false', () => {
    const view = createView(commonEvent(), event)
    const data = {
      assignment: {
        name: 'Too much tuna',
        post_to_sis: '0',
        due_at: '',
      },
    }
    const errors = view.validateBeforeSave(data, [])
    expect(errors).toHaveLength(0)
  })

  test('Should not show the important date checkbox if the context is not a k5 subject', () => {
    const view = createView(commonEvent(), event)
    view.setContext('course_2')
    view.contextChange({target: '#assignment_context'}, false)
    expect(view.$('#important_dates').css('display')).toBe('none')
  })

  test('Should show the important date checkbox if the context is a k5 subject', () => {
    const view = createView(commonEvent(), event)
    view.setContext('course_1')
    view.contextChange({target: '#assignment_context'}, false)
    expect(view.$('#important_dates').css('display')).toBe('block')
  })

  test('Should include the important date value when submitting', () => {
    const view = createView(commonEvent(), event)
    view.$('#calendar_event_important_dates').click()
    const dataToSubmit = view.getFormData()
    expect(dataToSubmit.assignment.important_dates).toBe(true)
  })

  test('Should disable changing the date if course pacing is enabled', () => {
    const modifiedEvent = {...event, contextInfo: {course_pacing_enabled: true}}
    const view = createView(commonEvent(), modifiedEvent)
    view.setContext('course_3')
    view.contextChange({target: '#assignment_context'}, false)
    expect(view.$('#assignment_due_at').prop('disabled')).toBe(true)
  })
})
