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

import React from 'react'
import {render, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import $ from 'jquery'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import GradingPeriodCollection from '../gradingPeriodCollection'
import fakeENV from '@canvas/test-utils/fakeENV'

describe('GradingPeriodCollection', () => {
  const defaultPeriods = {
    grading_periods: [
      {
        id: '1',
        title: 'Spring 2024',
        start_date: '2024-01-01T00:00:00Z',
        end_date: '2024-06-30T23:59:59Z',
        close_date: '2024-06-30T23:59:59Z',
        weight: 50,
        permissions: {
          update: true,
          delete: true,
        },
      },
    ],
    grading_periods_read_only: false,
  }

  const server = setupServer(
    http.get('http://localhost/api/v1/courses/1/grading_periods', () => {
      return HttpResponse.json(defaultPeriods)
    }),
  )

  beforeAll(() => server.listen())
  afterEach(() => server.resetHandlers())
  afterAll(() => server.close())

  beforeEach(() => {
    fakeENV.setup({
      GRADING_PERIODS_URL: 'http://localhost/api/v1/courses/1/grading_periods',
      GRADING_PERIODS_WEIGHTED: true,
      current_user_roles: ['admin'],
      CONTEXT_ID: '1',
    })

    // Mock jQuery's getJSON to use native fetch which MSW intercepts
    $.getJSON = jest.fn(url => {
      const promise = {
        success: function (callback) {
          fetch(url)
            .then(response => {
              if (!response.ok) throw new Error('Network response was not ok')
              return response.json()
            })
            .then(data => {
              callback(data)
            })
            .catch(() => {})
          return promise
        },
        error: function (callback) {
          fetch(url)
            .then(response => {
              if (!response.ok) {
                callback()
              }
            })
            .catch(() => {
              callback()
            })
          return promise
        },
      }
      return promise
    })

    // Mock jQuery's ajax to use native fetch which MSW intercepts
    $.ajax = jest.fn(options => {
      const promise = {
        success: function (callback) {
          fetch(options.url, {
            method: options.type || 'GET',
            headers: {
              'Content-Type': options.contentType || 'application/json',
            },
            body: options.data,
          })
            .then(response => {
              if (!response.ok) throw new Error('Network response was not ok')
              return response.json()
            })
            .then(data => {
              callback.call(options.context || this, data)
            })
            .catch(() => {})
          return promise
        },
        error: function (callback) {
          fetch(options.url, {
            method: options.type || 'GET',
            headers: {
              'Content-Type': options.contentType || 'application/json',
            },
            body: options.data,
          })
            .then(response => {
              if (!response.ok) {
                callback.call(options.context || this)
              }
            })
            .catch(() => {
              callback.call(options.context || this)
            })
          return promise
        },
      }
      return promise
    })

    // Mock jQuery plugins
    $.fn.confirmDelete = jest.fn(({success}) => success())
    $.flashMessage = jest.fn()
    $.flashError = jest.fn()
  })

  afterEach(() => {
    fakeENV.teardown()
    jest.clearAllMocks()
  })

  it('renders grading periods from the server', async () => {
    const {getByTestId} = render(<GradingPeriodCollection />)
    await waitFor(() => {
      expect(getByTestId('grading-periods')).toBeInTheDocument()
    })
  })

  it('shows loading state while fetching grading periods', () => {
    // Use MSW to delay the response
    server.use(
      http.get('http://localhost/api/v1/courses/1/grading_periods', async () => {
        await new Promise(() => {}) // Never resolves
      }),
    )

    const {getByTestId} = render(<GradingPeriodCollection />)
    expect(getByTestId('grading-periods-loading')).toBeInTheDocument()
  })

  it('handles network errors', async () => {
    server.use(
      http.get(
        'http://localhost/api/v1/courses/1/grading_periods',
        () => new HttpResponse(null, {status: 500}),
      ),
    )

    render(<GradingPeriodCollection />)
    await waitFor(() => {
      expect($.flashError).toHaveBeenCalledWith('There was a problem fetching periods')
    })
  })

  it('updates a grading period title', async () => {
    const {getByTestId} = render(<GradingPeriodCollection />)
    await waitFor(() => {
      expect(getByTestId('grading-periods')).toBeInTheDocument()
    })

    const titleInput = getByTestId('period-title-input')
    await userEvent.clear(titleInput)
    await userEvent.type(titleInput, 'Updated Title')
    expect(titleInput).toHaveValue('Updated Title')
  })

  it('deletes a grading period', async () => {
    server.use(
      http.delete('http://localhost/api/v1/courses/1/grading_periods/1', () => {
        return new HttpResponse(null, {status: 204})
      }),
    )

    const user = userEvent.setup()
    const {getByTestId} = render(<GradingPeriodCollection />)

    await waitFor(() => {
      expect(getByTestId('grading-periods')).toBeInTheDocument()
    })

    const deleteButton = getByTestId('delete-grading-period-button')
    await user.click(deleteButton)

    expect($.fn.confirmDelete).toHaveBeenCalled()
    await waitFor(() => {
      expect($.flashMessage).toHaveBeenCalledWith('The grading period was deleted')
    })
  })

  it('validates overlapping dates', async () => {
    const overlappingPeriods = {
      grading_periods: [
        {
          id: '1',
          title: 'Period 1',
          start_date: '2024-01-01T00:00:00Z',
          end_date: '2024-06-30T23:59:59Z',
          permissions: {update: true, delete: true},
        },
        {
          id: '2',
          title: 'Period 2',
          start_date: '2024-06-01T00:00:00Z', // Overlaps with Period 1
          end_date: '2024-12-31T23:59:59Z',
          permissions: {update: true, delete: true},
        },
      ],
      grading_periods_read_only: false,
    }

    server.use(
      http.get('http://localhost/api/v1/courses/1/grading_periods', () => {
        return HttpResponse.json(overlappingPeriods)
      }),
    )

    const {getByTestId} = render(<GradingPeriodCollection />)

    await waitFor(() => {
      expect(getByTestId('grading-periods')).toBeInTheDocument()
    })

    const component = new GradingPeriodCollection()
    component.state = {
      periods: [
        {
          id: '1',
          title: 'Period 1',
          startDate: new Date('2024-01-01'),
          endDate: new Date('2024-06-30'),
        },
        {
          id: '2',
          title: 'Period 2',
          startDate: new Date('2024-06-01'),
          endDate: new Date('2024-12-31'),
        },
      ],
    }

    expect(component.areGradingPeriodsValid()).toBe(false)
    expect($.flashError).toHaveBeenCalledWith('Grading periods must not overlap')
  })
})
