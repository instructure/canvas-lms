/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {render, fireEvent} from '@testing-library/react'
import CourseDefaultDueTime from '../CourseDefaultDueTime'

const FORM_ID = 'course'
const FORM_FIELD_NAME = 'default_due_time'
const FORM_FIELD_INPUT_ID = `${FORM_ID}_${FORM_FIELD_NAME}`
const FORM_FIELD_INPUT_NAME = `${FORM_ID}[${FORM_FIELD_NAME}]`

function renderComponent(container: HTMLElement | null, initialValue: string = '17:59:59') {
  if (!container) throw new Error('Container is null (should never happen)')
  return render(
    <CourseDefaultDueTime
      container={container}
      value={initialValue}
      locale="en-US"
      canManage={true}
    />,
    {container},
  )
}

describe('CourseDefaultDueTime', () => {
  let wrapper: HTMLElement | null = null

  beforeEach(() => {
    wrapper = document.createElement('div')
    wrapper.id = 'default_due_time_container'
    document.body.appendChild(wrapper)
  })

  afterEach(() => {
    if (wrapper && wrapper.parentElement) wrapper.parentElement.removeChild(wrapper)
    wrapper = null
  })

  it('renders course default due time from the hidden form field', () => {
    const {getByLabelText, getByTestId} = renderComponent(wrapper)
    expect(getByLabelText('Choose a time')).toBeInTheDocument()
    expect(getByTestId('course-default-due-time')).toHaveAttribute('value', '5:59 PM')
  })

  it('does not create a form field if nothing is touched', () => {
    renderComponent(wrapper)
    const formField = document.getElementById(FORM_FIELD_INPUT_ID)
    expect(formField).toBeNull()
  })

  it('does not create a form field if the time is touched but set to the same initial value', () => {
    const {getByTestId} = renderComponent(wrapper, '15:00:00') // 3:00 PM
    const timeSelect = getByTestId('course-default-due-time')
    fireEvent.change(timeSelect, {target: {value: '3:00 PM'}}) // same value as initial
    const formField = document.getElementById(FORM_FIELD_INPUT_ID)
    expect(formField).toBeNull()
  })

  it('allows a time to be entered and creates the hidden form field in the container', () => {
    const {getByTestId} = renderComponent(wrapper)
    const timeSelect = getByTestId('course-default-due-time')
    fireEvent.change(timeSelect, {target: {value: '3:00 PM'}})
    // Make sure it is actually a child of the container
    const formField = document.querySelector('#default_due_time_container #' + FORM_FIELD_INPUT_ID)
    expect(timeSelect).toHaveAttribute('value', '3:00 PM')
    expect(formField).toHaveAttribute('value', '15:00:00')
    expect(formField).toHaveAttribute('type', 'hidden')
    expect(formField).toHaveAttribute('name', FORM_FIELD_INPUT_NAME)
  })

  it('resets to the last valid value on illegal input', () => {
    const {getByTestId} = renderComponent(wrapper)
    const timeSelect = getByTestId('course-default-due-time')
    fireEvent.change(timeSelect, {target: {value: '3:00 PM'}}) // valid change to 3pm
    fireEvent.blur(timeSelect)
    expect(timeSelect).toHaveAttribute('value', '3:00 PM')
    fireEvent.change(timeSelect, {target: {value: 'fiddle-faddle'}})
    fireEvent.blur(timeSelect)
    expect(timeSelect).toHaveAttribute('value', '3:00 PM') // reset back to 3pm
  })

  it('adds then removes the form field when the value is changed but reset to the original value', () => {
    const {getByTestId} = renderComponent(wrapper, '03:00:00')
    let formField
    const timeSelect = getByTestId('course-default-due-time')
    fireEvent.change(timeSelect, {target: {value: '5:45 PM'}})
    fireEvent.blur(timeSelect)
    formField = document.getElementById(FORM_FIELD_INPUT_ID)
    expect(formField).toHaveAttribute('value', '17:45:00')
    fireEvent.change(timeSelect, {target: {value: '3:00 AM'}}) // back to the initial value
    fireEvent.blur(timeSelect)
    formField = document.getElementById(FORM_FIELD_INPUT_ID)
    expect(formField).toBeNull()
  })
})
