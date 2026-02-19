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
import {ZLtiRegistrationId} from '../../../../../model/LtiRegistrationId'
import {clickOrFail} from '../../../../__tests__/interactionHelpers'

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
  http.get(
    '/api/v1/accounts/:accountId/lti_registrations/:registrationId/deployments/:deploymentId/context_search',
    () => {
      const accounts = mockContexts.accounts
      const courses = mockContexts.courses
      return HttpResponse.json({accounts, courses})
    },
  ),
)

beforeAll(() => server.listen())
afterEach(() => server.resetHandlers())
afterAll(() => server.close())

describe('ExceptionModal', () => {
  function renderWithQueryClient(ui: React.ReactElement) {
    const queryClient = new QueryClient()
    return render(<QueryClientProvider client={queryClient}>{ui}</QueryClientProvider>)
  }

  it('does not render when open is false', () => {
    renderWithQueryClient(
      <ExceptionModal
        accountId={ZAccountId.parse('1')}
        registrationId={ZLtiRegistrationId.parse('1')}
        openState={{open: false}}
        onClose={vi.fn()}
        onConfirm={vi.fn()}
      />,
    )
    expect(screen.queryByText('Add Availability and Exceptions')).not.toBeInTheDocument()
  })

  it('renders when open is true', () => {
    renderWithQueryClient(
      <ExceptionModal
        accountId={ZAccountId.parse('1')}
        registrationId={ZLtiRegistrationId.parse('1')}
        openState={{open: true, deployment: mockDeployment({})}}
        onClose={vi.fn()}
        onConfirm={vi.fn()}
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

  it('calls onClose when CloseButton is clicked', async () => {
    const onClose = vi.fn()
    renderWithQueryClient(
      <ExceptionModal
        accountId={ZAccountId.parse('1')}
        registrationId={ZLtiRegistrationId.parse('1')}
        openState={{open: true, deployment: mockDeployment({})}}
        onClose={onClose}
        onConfirm={vi.fn()}
      />,
    )
    const closeBtn = screen.getByText('Close').closest('button')
    await clickOrFail(closeBtn)
    expect(onClose).toHaveBeenCalled()
  })

  it('allows searching for multiple contexts and adding them', async () => {
    const accountId = ZAccountId.parse('1')
    const openState = {open: true, deployment: mockDeployment({})}
    const onClose = vi.fn()
    renderWithQueryClient(
      <ExceptionModal
        accountId={accountId}
        registrationId={ZLtiRegistrationId.parse('1')}
        openState={openState}
        onClose={onClose}
        onConfirm={vi.fn()}
      />,
    )

    const input = screen.getByPlaceholderText(/search by sub-accounts or courses/i)

    input.focus()
    await userEvent.paste('Subaccount')
    const subaccount_1 = await screen.findByText('Subaccount 101', {}, {timeout: 3000})
    await screen.findByText('Subaccount 102')

    await userEvent.click(subaccount_1)

    expect(screen.getAllByText('Subaccount 101').length).toBeGreaterThan(0)

    await userEvent.clear(input)
    await userEvent.paste('Course')
    await screen.findByText('Course 201')
    await screen.findByText('Course 202')

    await userEvent.click(screen.getByText('Course 201'))
    expect(screen.getAllByText('Course 201').length).toBeGreaterThan(0)

    expect(screen.getAllByText('Subaccount 101').length).toBeGreaterThan(0)
    expect(screen.getAllByText('Course 201').length).toBeGreaterThan(0)

    await clickOrFail(screen.getByText('Close').closest('button'))
    expect(onClose).toHaveBeenCalled()
  })

  it.skip('removes an added exception when the delete button is clicked', async () => {
    const accountId = ZAccountId.parse('1')
    const openState = {open: true, deployment: mockDeployment({})}
    const onClose = vi.fn()
    renderWithQueryClient(
      <ExceptionModal
        accountId={accountId}
        registrationId={ZLtiRegistrationId.parse('1')}
        openState={openState}
        onClose={onClose}
        onConfirm={vi.fn()}
      />,
    )

    const input = screen.getByPlaceholderText(/search by sub-accounts or courses/i)
    await userEvent.click(input)
    await userEvent.paste('Subaccount')
    const subaccount_1 = await screen.findByText('Subaccount 101', {}, {timeout: 5000})
    fireEvent.click(subaccount_1)
    await waitFor(
      () => {
        const addedItems = screen.getAllByText('Subaccount 101')
        expect(addedItems.length).toBeGreaterThan(1)
      },
      {timeout: 5000},
    )

    const removeBtn = screen.getByText(/delete exception.*subaccount 101/i).closest('button')
    await clickOrFail(removeBtn)

    expect(screen.queryByText('Subaccount 101')).not.toBeInTheDocument()
  })

  it('updates the availability status when the select option is changed', async () => {
    const accountId = ZAccountId.parse('1')
    const openState = {open: true, deployment: mockDeployment({})}
    const onClose = vi.fn()
    renderWithQueryClient(
      <ExceptionModal
        accountId={accountId}
        registrationId={ZLtiRegistrationId.parse('1')}
        openState={openState}
        onClose={onClose}
        onConfirm={vi.fn()}
      />,
    )

    const input = screen.getByPlaceholderText(/search by sub-accounts or courses/i)
    input.focus()
    await userEvent.paste('Subaccount')
    const subaccount_1 = await screen.findByText('Subaccount 101', {}, {timeout: 3000})
    await userEvent.click(subaccount_1)
    await waitFor(() => expect(screen.getAllByText('Subaccount 101').length).toBeGreaterThan(0))

    const select = screen.getByDisplayValue(/not available/i)

    select.click()

    const availableOption = screen.getByText('Available')
    await userEvent.click(availableOption)

    expect(select).toHaveDisplayValue(/available/i)

    select.click()
    const notAvailableOption = screen.getByText('Not Available')
    await userEvent.click(notAvailableOption)
    expect(select).toHaveDisplayValue(/not available/i)
  })

  it('calls onConfirm with selected controls when Save is clicked', async () => {
    const accountId = ZAccountId.parse('1')
    const openState = {open: true, deployment: mockDeployment({})}
    const onClose = vi.fn()
    const onConfirm = vi.fn()
    renderWithQueryClient(
      <ExceptionModal
        accountId={accountId}
        registrationId={ZLtiRegistrationId.parse('1')}
        openState={openState}
        onClose={onClose}
        onConfirm={onConfirm}
      />,
    )

    const input = screen.getByPlaceholderText(/search by sub-accounts or courses/i)
    input.focus()
    await userEvent.paste('Subaccount')
    const subaccount_1 = await screen.findByText('Subaccount 101', {}, {timeout: 3000})
    await userEvent.click(subaccount_1)
    await waitFor(() => expect(screen.getAllByText('Subaccount 101').length).toBeGreaterThan(0))

    const saveBtn = screen.getByText('Save').closest('button')
    await clickOrFail(saveBtn)

    expect(onConfirm).toHaveBeenCalledTimes(1)
    expect(onConfirm.mock.calls[0][0]).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          available: false,
          account_id: expect.anything(),
          deployment_id: openState.deployment.id,
        }),
      ]),
    )
  })

  it('allows adding exceptions via the browse popover for subaccount and course contexts', async () => {
    const accountId = ZAccountId.parse('1')
    const openState = {open: true, deployment: mockDeployment({})}
    const onClose = vi.fn()
    const onConfirm = vi.fn()
    renderWithQueryClient(
      <ExceptionModal
        accountId={accountId}
        registrationId={ZLtiRegistrationId.parse('1')}
        openState={openState}
        onClose={onClose}
        onConfirm={onConfirm}
      />,
    )

    const browseBtn = screen.getByText(/browse sub-accounts or courses/i).closest('button')
    await clickOrFail(browseBtn)

    const browseSearchInput = await screen.findByPlaceholderText(/search\.\.\./i)

    browseSearchInput.focus()
    await userEvent.paste('Subaccount')

    const subaccountOption = await screen.findByText('Subaccount 101')
    await userEvent.click(subaccountOption)

    const selectSubaccount = await screen.findByText('Select')
    await userEvent.click(selectSubaccount)

    expect(screen.getAllByText('Subaccount 101').length).toBeGreaterThan(0)

    await clickOrFail(browseBtn)
    browseSearchInput.focus()
    await userEvent.paste('Course')
    const courseOption = await screen.findByText('Course 201')
    await userEvent.click(courseOption)

    expect(screen.getAllByText('Course 201').length).toBeGreaterThan(0)

    const saveBtn = screen.getByText('Save').closest('button')
    await clickOrFail(saveBtn)

    expect(onConfirm).toHaveBeenCalledTimes(1)
    const calledArgs = onConfirm.mock.calls[0][0]
    expect(calledArgs).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          available: false,
          account_id: expect.anything(),
          deployment_id: openState.deployment.id,
        }),
        expect.objectContaining({
          available: false,
          course_id: expect.anything(),
          deployment_id: openState.deployment.id,
        }),
      ]),
    )
  })

  it('displays subaccounts before courses in the browse popover', async () => {
    const accountId = ZAccountId.parse('1')
    const openState = {open: true, deployment: mockDeployment({})}
    const onClose = vi.fn()
    const onConfirm = vi.fn()
    renderWithQueryClient(
      <ExceptionModal
        accountId={accountId}
        registrationId={ZLtiRegistrationId.parse('1')}
        openState={openState}
        onClose={onClose}
        onConfirm={onConfirm}
      />,
    )

    const browseBtn = screen.getByText(/browse sub-accounts or courses/i).closest('button')
    await clickOrFail(browseBtn)

    await screen.findByPlaceholderText(/search\.\.\./i)

    const courseOption = await screen.findByText('Course 201')
    const subaccountOption = await screen.findByText('Subaccount 101')

    expect(subaccountOption.compareDocumentPosition(courseOption)).toBe(
      Node.DOCUMENT_POSITION_FOLLOWING,
    )
  })

  it('does not call onConfirm when Save is clicked with no selected exceptions, but does call onClose', async () => {
    const accountId = ZAccountId.parse('1')
    const openState = {open: true, deployment: mockDeployment({})}
    const onClose = vi.fn()
    const onConfirm = vi.fn()
    renderWithQueryClient(
      <ExceptionModal
        accountId={accountId}
        registrationId={ZLtiRegistrationId.parse('1')}
        openState={openState}
        onClose={onClose}
        onConfirm={onConfirm}
      />,
    )

    const saveBtn = screen.getByText('Save').closest('button')
    await clickOrFail(saveBtn)

    expect(onConfirm).not.toHaveBeenCalled()
    expect(onClose).toHaveBeenCalled()
  })

  it('clears the search filter after a context is selected', async () => {
    const accountId = ZAccountId.parse('1')
    const openState = {open: true, deployment: mockDeployment({})}
    renderWithQueryClient(
      <ExceptionModal
        accountId={accountId}
        registrationId={ZLtiRegistrationId.parse('1')}
        openState={openState}
        onClose={vi.fn()}
        onConfirm={vi.fn()}
      />,
    )

    const input = screen.getByPlaceholderText(/search by sub-accounts or courses/i)
    input.focus()
    await userEvent.paste('Subaccount')
    await screen.findByText('Subaccount 101')

    await userEvent.click(screen.getByText('Subaccount 101'))

    expect(input).toHaveValue('')

    await userEvent.click(input)
    expect(await screen.findByText('Subaccount 102')).toBeInTheDocument()
  })
})
