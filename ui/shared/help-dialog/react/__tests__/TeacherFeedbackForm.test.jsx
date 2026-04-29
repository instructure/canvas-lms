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

import React from 'react'
import {fireEvent, render, waitFor} from '@testing-library/react'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import TeacherFeedbackForm from '../TeacherFeedbackForm'

const server = setupServer()

describe('TeacherFeedbackForm', () => {
  const onCancel = vi.fn()
  const onSubmit = vi.fn()
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

  beforeAll(() => {
    server.listen()
  })

  beforeEach(() => {
    server.use(
      http.get('/api/v1/courses.json', () => {
        return HttpResponse.json(courses)
      }),
    )
  })

  afterEach(() => {
    onCancel.mockClear()
    onSubmit.mockClear()
    server.resetHandlers()
  })

  afterAll(() => {
    server.close()
  })

  it('renders form label header', () => {
    const {getByText} = render(<TeacherFeedbackForm {...props} />)
    expect(getByText('Which course is this question about?')).toBeVisible()
  })

  it('renders loading text if courses are not loaded', () => {
    server.use(
      http.get('/api/v1/courses.json', async () => {
        await new Promise(() => {}) // Never resolves
      }),
    )
    const {getByText} = render(<TeacherFeedbackForm {...props} />)
    expect(getByText('Loading courses...')).toBeVisible()
  })

  it('disables send message button if courses are not loaded', () => {
    server.use(
      http.get('/api/v1/courses.json', async () => {
        await new Promise(() => {}) // Never resolves
      }),
    )
    const {getByText} = render(<TeacherFeedbackForm {...props} />)
    expect(getByText('Send Message')).toBeDisabled()
  })

  it('renders select options for courses', async () => {
    const {getByText} = render(<TeacherFeedbackForm {...props} />)
    await waitFor(() => {
      expect(getByText('Engineering 101')).toBeVisible()
    })
    expect(getByText('Security 202')).toBeVisible()
  })

  it('sets focus on recipients select options', async () => {
    const {container} = render(<TeacherFeedbackForm {...props} />)
    await waitFor(() => {
      const recipients = container.querySelector("select[name = 'recipients[]']")
      expect(recipients).toHaveFocus()
    })
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
