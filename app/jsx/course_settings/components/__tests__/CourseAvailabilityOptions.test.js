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
import {render} from '@testing-library/react'
import CourseAvailabilityOptions from '../CourseAvailabilityOptions'

function createFormField(wrapper, id, value) {
  const field = document.createElement('input')
  field.setAttribute('type', 'hidden')
  field.setAttribute('id', id)
  field.setAttribute('name', id)
  field.setAttribute('value', value)
  wrapper.appendChild(field)
}

function renderComponent(wrapper, overrides = {}) {
  const options = {
    canManage: true,
    viewPastLocked: false,
    viewFutureLocked: false,
    course_start_at: moment('2020-08-14').toISOString(),
    course_conclude_at: null,
    course_restrict_student_past_view: 'false',
    course_restrict_student_future_view: 'false',
    course_restrict_enrollments_to_course_dates: 'false',
    ...overrides
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

  it('shows the date inputs if course is selected in select', () => {
    const {getByLabelText, getByText} = renderComponent(wrapper, {
      course_restrict_enrollments_to_course_dates: 'true'
    })
    expect(getByLabelText('Start')).toBeInTheDocument()
    expect(getByLabelText('End')).toBeInTheDocument()
    expect(
      getByText('Any section dates created in the course may override course dates.', {
        exact: false
      })
    ).toBeInTheDocument()
  })

  it('disables the restrictBefore checkbox if locked by account', () => {
    const {getByLabelText} = renderComponent(wrapper, {
      viewFutureLocked: true
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
      viewPastLocked: true
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
      course_restrict_enrollments_to_course_dates: 'true'
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
      course_restrict_enrollments_to_course_dates: 'true'
    })
    expect(getByLabelText('Start').value).toContain('Aug 14 at')
    expect(getByLabelText('End').value).toContain('Oct 16 at')
  })

  it('sets the restriction checkboxes to currently set values on render', () => {
    const {getByLabelText} = renderComponent(wrapper, {
      course_restrict_student_future_view: 'false',
      course_restrict_student_past_view: 'true'
    })
    expect(
      getByLabelText('Restrict students from viewing course before term start date').checked
    ).toBeFalsy()
    expect(
      getByLabelText('Restrict students from viewing course after term end date').checked
    ).toBeTruthy()
  })
})
