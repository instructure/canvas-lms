/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {render, screen, fireEvent, waitFor} from '@testing-library/react'
import {ExceptionModal} from '../ExceptionModal'
import {mockDeployment} from '../../__tests__/helpers'
import {ZAccountId} from '@canvas/lti-apps/models/AccountId'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import userEvent from '@testing-library/user-event'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {SearchableContexts} from '../../../../../model/SearchableContext'
import {ZCourseId} from '../../../../../model/CourseId'

const mockContexts: SearchableContexts = {
  accounts: [
    {
      id: ZAccountId.parse('101'),
      name: 'Subaccount 101',
      display_path: ['Subaccount A', 'Subaccount B'],
    },
    {
      id: ZAccountId.parse('102'),
      name: 'Subaccount 102',
      display_path: ['Subaccount C', 'Subaccount D'],
    },
  ],
  courses: [
    {
      id: ZCourseId.parse('201'),
      name: 'Course 201',
      display_path: ['Subaccount A', 'Subaccount B'],
    },
    {
      id: ZCourseId.parse('202'),
      name: 'Course 202',
      display_path: ['Subaccount C', 'Subaccount D'],
    },
  ],
}

const server = setupServer(
  http.get('/api/v1/accounts/:accountId/lti_registrations/context_search', () => {
    const accounts = mockContexts.accounts
    const courses = mockContexts.courses
    return HttpResponse.json({accounts, courses})
  }),
)

beforeAll(() => server.listen())
afterEach(() => server.resetHandlers())
afterAll(() => server.close())

describe('ExceptionModal', () => {
  // Utility to wrap render with QueryClientProvider
  function renderWithQueryClient(ui: React.ReactElement) {
    const queryClient = new QueryClient()
    return render(<QueryClientProvider client={queryClient}>{ui}</QueryClientProvider>)
  }

  it('does not render when open is false', () => {
    renderWithQueryClient(
      <ExceptionModal
        accountId={ZAccountId.parse('1')}
        openState={{open: false}}
        onClose={jest.fn()}
      />,
    )
    expect(screen.queryByText('Add Availability and Exceptions')).not.toBeInTheDocument()
  })

  it('renders when open is true', () => {
    renderWithQueryClient(
      <ExceptionModal
        accountId={ZAccountId.parse('1')}
        openState={{open: true, deployment: mockDeployment({})}}
        onClose={jest.fn()}
      />,
    )
    expect(screen.getByText('Add Availability and Exceptions')).toBeInTheDocument()
    expect(screen.getByText('Availability and Exceptions')).toBeInTheDocument()
    expect(
      screen.queryByText(
        'You have not added any availability or exceptions. Search or browse to add one.',
      ),
    ).toBeInTheDocument()
  })

  it('calls onClose when CloseButton is clicked', () => {
    const onClose = jest.fn()
    renderWithQueryClient(
      <ExceptionModal
        accountId={ZAccountId.parse('1')}
        openState={{open: true, deployment: mockDeployment({})}}
        onClose={onClose}
      />,
    )
    const closeBtn = screen.getByRole('button', {name: /close/i})
    fireEvent.click(closeBtn)
    expect(onClose).toHaveBeenCalled()
  })

  it('allows searching for multiple contexts and adding them', async () => {
    const accountId = ZAccountId.parse('1')
    const openState = {open: true, deployment: mockDeployment({})}
    const onClose = jest.fn()
    renderWithQueryClient(
      <ExceptionModal accountId={accountId} openState={openState} onClose={onClose} />,
    )

    // Search for "Subaccount"
    const input = screen.getByPlaceholderText(/search by sub-accounts or courses/i)

    input.focus()
    await userEvent.paste('Subaccount')
    // Wait for options to appear
    const subaccount_1 = await waitFor(() => screen.findByText('Subaccount 101'), {timeout: 3000})
    await waitFor(() => screen.queryByText('Subaccount 102'))

    // Select first subaccount
    await userEvent.click(subaccount_1)

    expect(screen.getByText('Subaccount 101')).toBeInTheDocument()

    // Search for "Course"
    await userEvent.clear(input)
    await userEvent.paste('Course')
    await screen.findByText('Course 201')
    await screen.findByText('Course 202')

    // Select first course
    await userEvent.click(screen.getByText('Course 201'))
    expect(screen.getByText('Course 201')).toBeInTheDocument()

    // Both contexts should be listed
    expect(screen.getByText('Subaccount 101')).toBeInTheDocument()
    expect(screen.getByText('Course 201')).toBeInTheDocument()

    // Close the modal
    await userEvent.click(screen.getByRole('button', {name: /close/i}))
    expect(onClose).toHaveBeenCalled()
  })
})
