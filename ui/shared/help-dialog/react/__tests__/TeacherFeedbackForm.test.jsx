// Copyright (C) 2020 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import $ from 'jquery'
import React from 'react'
import {fireEvent, render} from '@testing-library/react'
import TeacherFeedbackForm from '../TeacherFeedbackForm'

describe('TeacherFeedbackForm', () => {
  const originalGetJSON = $.getJSON
  const onCancel = jest.fn()
  const onSubmit = jest.fn()
  const courses = [
    {
      id: '1',
      name: 'Engineering 101',
    },
    {
      id: '2',
      name: 'Security 202',
    },
  ]

  const props = {
    onCancel,
    onSubmit,
  }

  beforeEach(() => {
    $.getJSON = jest.fn((_url, successCallback) => successCallback(courses))
  })

  afterEach(() => {
    onCancel.mockClear()
    onSubmit.mockClear()
    $.getJSON = originalGetJSON
  })

  it('renders form label header', () => {
    const {getByText} = render(<TeacherFeedbackForm {...props} />)
    expect(getByText('Which course is this question about?')).toBeVisible()
  })

  it('renders loading text if courses are not loaded', () => {
    $.getJSON.mockRestore()
    const {getByText} = render(<TeacherFeedbackForm {...props} />)
    expect(getByText('Loading courses...')).toBeVisible()
  })

  it('disables send message button if courses are not loaded', () => {
    $.getJSON.mockRestore()
    const {getByText} = render(<TeacherFeedbackForm {...props} />)
    expect(getByText('Send Message')).toBeDisabled()
  })

  it('renders select options for courses', () => {
    const {getByText} = render(<TeacherFeedbackForm {...props} />)
    expect(getByText('Engineering 101')).toBeVisible()
    expect(getByText('Security 202')).toBeVisible()
  })

  it('sets focus on recipients select options', () => {
    const {container} = render(<TeacherFeedbackForm {...props} />)
    const recipients = container.querySelector("select[name = 'recipients[]']")
    expect(recipients).toHaveFocus()
  })

  it('only submits form if required fields are provided', () => {
    const {getByText, queryByText} = render(<TeacherFeedbackForm {...props} />)
    fireEvent.click(getByText('Send Message'))
    expect(queryByText('Message sent.')).toBeNull()
    expect(onSubmit).not.toHaveBeenCalled()
  })

  it('cancels form submit', () => {
    const {getByText} = render(<TeacherFeedbackForm {...props} />)
    fireEvent.click(getByText('Cancel'))
    expect(onCancel).toHaveBeenCalled()
  })
})
