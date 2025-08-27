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

import {render, screen, waitFor} from '@testing-library/react'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import type {LtiOverlayVersion} from '../../../../model/LtiOverlayVersion'
import {
  mockLtiOverlayVersion,
  mockRegistrationWithAllInformation,
  mockUser,
} from '../../../manage/__tests__/helpers'
import {renderWithRouter} from '../../__tests__/helpers'
import {ToolHistory} from '../ToolHistory'
import {ZAccountId} from '@canvas/lti-apps/models/AccountId'

const server = setupServer()

describe('ToolHistory', () => {
  beforeAll(() => server.listen())
  afterEach(() => server.resetHandlers())
  afterAll(() => server.close())

  const accountId = ZAccountId.parse('4')

  it('renders without crashing', async () => {
    const registration = mockRegistrationWithAllInformation({
      n: 'foo',
      i: 1,
      overlayVersions: [
        mockLtiOverlayVersion({user: mockUser({overrides: {name: 'Foo Bar Baz'}})}),
      ],
    })

    server.use(
      http.get(
        `/api/v1/accounts/${accountId}/lti_registrations/${registration.id}/overlay_history`,
        () => {
          return HttpResponse.json([
            mockLtiOverlayVersion({user: mockUser({overrides: {name: 'Foo Bar Baz'}})}),
          ])
        },
      ),
    )

    render(renderWithRouter({child: <ToolHistory accountId={accountId} />, registration}))

    expect(await screen.findByText('Foo Bar Baz')).toBeInTheDocument()
  })

  it('only renders the 5 most recent overlay versions, even if more are included', async () => {
    const allNames = ['foo', 'bar', 'baz', 'qux', 'quux', 'corge']
    const versions: LtiOverlayVersion[] = allNames.map(name => {
      return mockLtiOverlayVersion({user: mockUser({overrides: {name: name}})})
    })

    const registration = mockRegistrationWithAllInformation({
      n: 'foo',
      i: 1,
      overlayVersions: versions,
    })

    server.use(
      http.get(
        `/api/v1/accounts/${accountId}/lti_registrations/${registration.id}/overlay_history`,
        () => {
          return HttpResponse.json(versions)
        },
      ),
    )

    render(renderWithRouter({child: <ToolHistory accountId={accountId} />, registration}))

    await waitFor(() => {
      const renderedNames = screen.getAllByText(new RegExp(allNames.join('|')))
      expect(renderedNames).toHaveLength(6)
    })
  })

  it('limits display to 100 entries and shows message when there are more than 100 history items', async () => {
    // Create 101 overlay versions to exceed the limit
    const versions: LtiOverlayVersion[] = Array.from({length: 101}, (_, index) => {
      return mockLtiOverlayVersion({
        user: mockUser({overrides: {name: `User ${index + 1}`}}),
        id: `${index + 1}`,
      })
    })

    const registration = mockRegistrationWithAllInformation({
      n: 'foo',
      i: 1,
      overlayVersions: versions,
    })

    server.use(
      http.get(
        `/api/v1/accounts/${accountId}/lti_registrations/${registration.id}/overlay_history`,
        () => {
          return HttpResponse.json(versions)
        },
      ),
    )

    render(renderWithRouter({child: <ToolHistory accountId={accountId} />, registration}))

    // Wait for the table to load
    await waitFor(() => {
      expect(screen.getByText('Configuration Update History')).toBeInTheDocument()
    })

    // Check that only 100 entries are displayed (the limit)
    const tableRows = screen.getAllByRole('row')
    // Subtract 1 for the header row
    expect(tableRows).toHaveLength(101) // 100 data rows + 1 header row

    // Check that the limiting message is shown
    expect(screen.getByText(/Showing the most recent 100 updates./)).toBeInTheDocument()

    // Verify the first displayed entry is "User 1" (most recent)
    expect(screen.getByText('User 1')).toBeInTheDocument()

    // Verify the last displayed entry is "User 100"
    expect(screen.getByText('User 100')).toBeInTheDocument()

    // Verify that "User 101" is not displayed (beyond the limit)
    expect(screen.queryByText('User 101')).not.toBeInTheDocument()
  })

  it('renders a different message if the overlay was reset', async () => {
    const registration = mockRegistrationWithAllInformation({
      n: 'foo',
      i: 1,
      overlayVersions: [mockLtiOverlayVersion({overrides: {caused_by_reset: true}})],
    })

    server.use(
      http.get(
        `/api/v1/accounts/${accountId}/lti_registrations/${registration.id}/overlay_history`,
        () => {
          return HttpResponse.json([mockLtiOverlayVersion({overrides: {caused_by_reset: true}})])
        },
      ),
    )

    render(renderWithRouter({child: <ToolHistory accountId={accountId} />, registration}))

    expect(await screen.findByText('Restored to default')).toBeInTheDocument()
  })

  it('renders Instructure as the name if the change was made by a Site Admin', async () => {
    const registration = mockRegistrationWithAllInformation({
      n: 'foo',
      i: 1,
      overlayVersions: [mockLtiOverlayVersion({user: 'Instructure'})],
    })

    server.use(
      http.get(
        `/api/v1/accounts/${accountId}/lti_registrations/${registration.id}/overlay_history`,
        () => {
          return HttpResponse.json([mockLtiOverlayVersion({user: 'Instructure'})])
        },
      ),
    )

    render(renderWithRouter({child: <ToolHistory accountId={accountId} />, registration}))

    expect(await screen.findByText('Instructure')).toBeInTheDocument()
  })
})
