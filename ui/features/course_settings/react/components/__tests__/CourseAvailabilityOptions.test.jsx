/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import React from 'react'
import moment from 'moment'
import {render, fireEvent} from '@testing-library/react'
import CourseAvailabilityOptions from '../CourseAvailabilityOptions'

function pressKey(inputElem, keyOpts) {
  fireEvent.keyDown(inputElem, keyOpts)
  fireEvent.keyUp(inputElem, keyOpts)
}

function createFormField(wrapper, id, value) {
  const field = document.createElement('input')
  field.setAttribute('type', 'hidden')
  field.setAttribute('id', id)
  field.setAttribute('name', id)
  field.setAttribute('value', value)
  wrapper.appendChild(field)
}

function setupWindowEnv() {
  window.ENV.STUDENTS_ENROLLMENT_DATES = {
    start_at: '2021-02-10T00:00:00-07:00',
    end_at: '2021-07-10T00:00:00-07:00',
  }
  window.ENV.TIMEZONE = 'America/Halifax'
  window.ENV.CONTEXT_TIMEZONE = 'America/Denver'
}

function renderComponent(wrapper, overrides = {}) {
  const options = {
    canManage: true,
    viewPastLocked: false,
    viewFutureLocked: false,
    course_start_at: moment('2020-08-14').toISOString(),
    course_conclude_at: '',
    course_restrict_student_past_view: 'false',
    course_restrict_student_future_view: 'false',
    course_restrict_enrollments_to_course_dates: 'false',
    ...overrides,
  }

  createFormField(wrapper, 'course_start_at', options.course_start_at)
  createFormField(wrapper, 'course_conclude_at', options.course_conclude_at)
  createFormField(
    wrapper,
    'course_restrict_student_past_view',
    options.course_restrict_student_past_view
  )
  createFormField(
    wrapper,
    'course_restrict_student_future_view',
    options.course_restrict_student_future_view
  )
  createFormField(
    wrapper,
    'course_restrict_enrollments_to_course_dates',
    options.course_restrict_enrollments_to_course_dates
  )

  return render(<CourseAvailabilityOptions {...options} />, wrapper)
}

describe('CourseAvailabilityOptions', () => {
  let wrapper
  setupWindowEnv()
  beforeEach(() => {
    wrapper = document.createElement('div')
    document.body.appendChild(wrapper)
  })

  afterEach(() => {
    document.body.removeChild(wrapper)
  })

  it('renders all applicable inputs with default options', () => {
    const {getByLabelText, getByText} = renderComponent(wrapper)
    expect(
      getByLabelText('Limit course participation to term or custom course dates?')
    ).toBeInTheDocument()
    expect(getByText('Course participation is limited to', {exact: false})).toBeInTheDocument()
    expect(
      getByLabelText('Restrict students from viewing course before term start date')
    ).toBeInTheDocument()
    expect(
      getByLabelText('Restrict students from viewing course after term end date')
    ).toBeInTheDocument()
  })

  it('shows the date inputs as editable if course is selected in select', () => {
    const {getByLabelText, getByText} = renderComponent(wrapper, {
      course_restrict_enrollments_to_course_dates: 'true',
    })
    const startDate = getByLabelText('Start')
    const endDate = getByLabelText('End')

    expect(startDate).toBeInTheDocument()
    expect(startDate).not.toBeDisabled()
    expect(endDate).toBeInTheDocument()
    expect(endDate).not.toBeDisabled()
    expect(
      getByText('Any section dates created in the course may override course dates.', {
        exact: false,
      })
    ).toBeInTheDocument()
  })

  it('shows the date inputs as disbaled if term is selected in select', () => {
    const {getByLabelText} = renderComponent(wrapper, {
      course_restrict_enrollments_to_course_dates: 'false',
    })
    const startDate = getByLabelText('Start')
    const endDate = getByLabelText('End')

    expect(startDate).toBeInTheDocument()
    expect(startDate).toBeDisabled()
    expect(endDate).toBeInTheDocument()
    expect(endDate).toBeDisabled()
  })

  it('shows the dates from Student enrollment if Term is selected in select', () => {
    const {getByLabelText} = renderComponent(wrapper, {
      course_restrict_enrollments_to_course_dates: 'false',
    })
    const startDate = getByLabelText('Start')
    const endDate = getByLabelText('End')

    expect(startDate.value).toContain('Feb 10, 2021')
    expect(endDate.value).toContain('Jul 10, 2021')
  })

  it('disables the restrictBefore checkbox if locked by account', () => {
    const {getByLabelText} = renderComponent(wrapper, {
      viewFutureLocked: true,
    })
    expect(
      getByLabelText('Restrict students from viewing course before term start date')
    ).toBeDisabled()
    expect(
      getByLabelText('Restrict students from viewing course after term end date')
    ).toBeEnabled()
  })

  it('disables the restrictAfter checkbox if locked by account', () => {
    const {getByLabelText} = renderComponent(wrapper, {
      viewPastLocked: true,
    })
    expect(
      getByLabelText('Restrict students from viewing course after term end date')
    ).toBeDisabled()
    expect(
      getByLabelText('Restrict students from viewing course before term start date')
    ).toBeEnabled()
  })

  it("disables everything if user doesn't have manage permission", () => {
    const {getByLabelText} = renderComponent(wrapper, {
      canManage: false,
      course_restrict_enrollments_to_course_dates: 'true',
    })
    expect(
      getByLabelText('Limit course participation to term or custom course dates?')
    ).toBeDisabled()
    expect(getByLabelText('Start')).toBeDisabled()
    expect(getByLabelText('End')).toBeDisabled()
    expect(
      getByLabelText('Restrict students from viewing course before course start date')
    ).toBeDisabled()
    expect(
      getByLabelText('Restrict students from viewing course after course end date')
    ).toBeDisabled()
  })

  it('fills start and end inputs with currently set dates on render', () => {
    const {getByLabelText} = renderComponent(wrapper, {
      course_conclude_at: moment('2020-10-16').toISOString(),
      course_restrict_enrollments_to_course_dates: 'true',
    })
    expect(getByLabelText('Start').value).toContain('Aug 14, 2020')
    expect(getByLabelText('End').value).toContain('Oct 16, 2020')
  })

  it('clears course dates when participation setting is changed to Term', () => {
    const {getByText, getByLabelText} = renderComponent(wrapper, {
      course_conclude_at: moment('2020-10-16').toISOString(),
      course_restrict_enrollments_to_course_dates: 'true',
    })
    const select = getByLabelText('Limit course participation to term or custom course dates?')
    expect(select.value).toBe('Course')
    fireEvent.click(select)
    const termOption = getByText('Term')
    fireEvent.click(termOption)

    expect(document.getElementById('course_start_at').value).toBe('')
    expect(document.getElementById('course_conclude_at').value).toBe('')
  })

  it('sets the restriction checkboxes to currently set values on render', () => {
    const {getByLabelText} = renderComponent(wrapper, {
      course_restrict_student_future_view: 'false',
      course_restrict_student_past_view: 'true',
    })
    expect(
      getByLabelText('Restrict students from viewing course before term start date').checked
    ).toBeFalsy()
    expect(
      getByLabelText('Restrict students from viewing course after term end date').checked
    ).toBeTruthy()
  })

  it('updates course end date when DateInput changes', () => {
    const {getByLabelText} = renderComponent(wrapper, {
      course_restrict_enrollments_to_course_dates: 'true',
    })
    const endDate = getByLabelText('End')
    const year = moment().year()
    fireEvent.change(endDate, {target: {value: `Jan 1, ${year} 12:00am`}})
    fireEvent.blur(endDate)
    fireEvent.click(endDate)
    fireEvent.blur(endDate)
    expect(document.getElementById('course_conclude_at').value).toBe(`${year}-01-01T00:00:00.000Z`)
  })

  it('updates course start date when Enter is hit on the DateInput', () => {
    const {getByLabelText} = renderComponent(wrapper, {
      course_restrict_enrollments_to_course_dates: 'true',
    })
    const startDate = getByLabelText('Start')
    const year = moment().year()
    fireEvent.change(startDate, {target: {value: `Jan 1, ${year} 12:00am`}})
    pressKey(startDate, {key: 'Enter'})
    expect(document.getElementById('course_start_at').value).toBe(`${year}-01-01T00:00:00.000Z`)
  })

  it('updates course end date when Enter is hit on the DateInput', () => {
    const {getByLabelText} = renderComponent(wrapper, {
      course_restrict_enrollments_to_course_dates: 'true',
    })
    const endDate = getByLabelText('End')
    const year = moment().year()
    fireEvent.change(endDate, {target: {value: `Feb 1, ${year} 12:00am`}})
    pressKey(endDate, {key: 'Enter'})
    expect(document.getElementById('course_conclude_at').value).toBe(`${year}-02-01T00:00:00.000Z`)
  })

  it('can set the course end date for a different year', () => {
    const {getByLabelText} = renderComponent(wrapper, {
      course_restrict_enrollments_to_course_dates: 'true',
    })
    const endDate = getByLabelText('End')
    const futureYear = moment().year() + 3
    fireEvent.change(endDate, {target: {value: `Jan 1, ${futureYear} 12:00am`}})
    fireEvent.blur(endDate)
    fireEvent.click(endDate)
    fireEvent.blur(endDate)
    expect(document.getElementById('course_conclude_at').value).toBe(
      `${futureYear}-01-01T00:00:00.000Z`
    )
  })

  describe('midnight warning', () => {
    const warningText =
      'Course participation is set to expire at midnight, so the previous day is the last day this course will be active.'

    it('is not shown if end date is not set', () => {
      const {queryByText} = renderComponent(wrapper, {
        course_restrict_enrollments_to_course_dates: 'true',
      })
      expect(queryByText(warningText)).not.toBeInTheDocument()
    })

    it('is not shown if end date is set to midday', () => {
      const {queryByText} = renderComponent(wrapper, {
        course_conclude_at: moment('2020-10-16T12:00:00Z').toISOString(),
        course_restrict_enrollments_to_course_dates: 'true',
      })
      expect(queryByText(warningText)).not.toBeInTheDocument()
    })

    it('is shown if end date is set to midnight', () => {
      const {getByText} = renderComponent(wrapper, {
        course_conclude_at: moment('2020-10-16T00:00:00Z').toISOString(),
        course_restrict_enrollments_to_course_dates: 'true',
      })
      expect(getByText(warningText)).toBeInTheDocument()
    })
  })

  describe('shows local and course time', () => {
    it('shows local and course time for the start date', () => {
      const {getByLabelText, getByText} = renderComponent(wrapper, {
        course_restrict_enrollments_to_course_dates: 'true',
      })
      const startDate = getByLabelText('Start')
      const year = moment().year()
      fireEvent.change(startDate, {target: {value: `Mar 1, ${year} 10:00am`}})
      pressKey(startDate, {key: 'Enter'})
      expect(document.getElementById('course_start_at').value).toBe(`${year}-03-01T10:00:00.000Z`)
      expect(getByText(`Local: Mar 1, ${year} 10:00am`)).toBeInTheDocument()
      expect(getByText(`Course: Mar 1, ${year} 7:00am`)).toBeInTheDocument()
    })

    it('shows local and course time for the end date', () => {
      const {getByLabelText, getByText} = renderComponent(wrapper, {
        course_restrict_enrollments_to_course_dates: 'true',
      })
      const endDate = getByLabelText('End')
      const year = moment().year()
      fireEvent.change(endDate, {target: {value: `Apr 5, ${year} 10:00am`}})
      pressKey(endDate, {key: 'Enter'})
      expect(document.getElementById('course_conclude_at').value).toBe(
        `${year}-04-05T10:00:00.000Z`
      )
      expect(getByText(`Local: Apr 5, ${year} 10:00am`)).toBeInTheDocument()
      expect(getByText(`Course: Apr 5, ${year} 7:00am`)).toBeInTheDocument()
    })
  })
})
