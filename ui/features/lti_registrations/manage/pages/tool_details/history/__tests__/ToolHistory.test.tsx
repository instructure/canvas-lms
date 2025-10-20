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
import type {
  AvailabilityChangeHistoryEntry,
  LtiRegistrationHistoryEntry,
} from '../../../../model/LtiRegistrationHistoryEntry'
import {
  mockLtiOverlayVersion,
  mockRegistrationWithAllInformation,
  mockUser,
} from '../../../manage/__tests__/helpers'
import {renderWithRouter} from '../../__tests__/helpers'
import {ToolHistory} from '../ToolHistory'
import {ZAccountId} from '@canvas/lti-apps/models/AccountId'
import {ZLtiRegistrationHistoryEntryId} from '../../../../model/LtiRegistrationHistoryEntry'
import {HISTORY_DISPLAY_LIMIT} from '../useHistory'
import {ZLtiRegistrationId} from '../../../../model/LtiRegistrationId'
import fakeENV from '@canvas/test-utils/fakeENV'
import {ZLtiContextControlId} from '../../../../model/LtiContextControl'

const server = setupServer()

const mockLtiRegistrationHistoryEntry = (
  overrides: Partial<AvailabilityChangeHistoryEntry> = {},
): AvailabilityChangeHistoryEntry => ({
  id: ZLtiRegistrationHistoryEntryId.parse('1'),
  root_account_id: ZAccountId.parse('4'),
  lti_registration_id: ZLtiRegistrationId.parse('1'),
  created_at: new Date('2025-01-15T12:00:00Z'),
  updated_at: new Date('2025-01-15T12:00:00Z'),
  diff: {registration: [['~', 'name', 'Old Name', 'New Name']]},
  update_type: 'control_edit',
  comment: 'Test update',
  created_by: mockUser({overrides: {name: 'Foo Bar Baz'}}),
  old_context_controls: {},
  new_context_controls: {
    [ZLtiContextControlId.parse('1')]: {
      id: ZLtiContextControlId.parse('1'),
      available: false,
      account_id: ZAccountId.parse('4'),
      course_id: null,
      deployment_id: '4',
      workflow_state: 'active',
    },
  },
  ...overrides,
})

describe('ToolHistory', () => {
  beforeAll(() => server.listen())
  afterEach(() => {
    server.resetHandlers()
    fakeENV.teardown()
  })
  afterAll(() => server.close())

  const accountId = ZAccountId.parse('4')

  describe('with feature flag disabled (overlay history)', () => {
    beforeEach(() => {
      fakeENV.setup({LTI_REGISTRATIONS_HISTORY: false})
    })

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
      const versions: LtiOverlayVersion[] = Array.from(
        {length: HISTORY_DISPLAY_LIMIT + 1},
        (_, index) => {
          return mockLtiOverlayVersion({
            user: mockUser({overrides: {name: `User ${index + 1}`}}),
            id: `${index + 1}`,
          })
        },
      )

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
        expect(screen.getByText('Configuration Update History')).toBeInTheDocument()
      })

      const tableRows = screen.getAllByRole('row')
      expect(tableRows).toHaveLength(HISTORY_DISPLAY_LIMIT + 1) // 99 data rows + 1 header row

      expect(screen.getByText(/Showing the most recent 99 updates./)).toBeInTheDocument()

      expect(screen.getByText('User 1')).toBeInTheDocument()

      expect(screen.getByText('User 99')).toBeInTheDocument()

      expect(screen.queryByText('User 100')).not.toBeInTheDocument()
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

  // These are almost identical to the tests above, just with different URLs.
  // TODO: Once we switch to always using this flag, we can remove the old
  // tests and the older component.
  describe('with feature flag enabled (registration history)', () => {
    beforeEach(() => {
      fakeENV.setup({LTI_REGISTRATIONS_HISTORY: true})
    })

    it('renders without crashing', async () => {
      const registration = mockRegistrationWithAllInformation({
        n: 'foo',
        i: 1,
      })

      server.use(
        http.get(
          `/api/v1/accounts/${accountId}/lti_registrations/${registration.id}/history`,
          () => {
            return HttpResponse.json([
              mockLtiRegistrationHistoryEntry({
                created_by: mockUser({overrides: {name: 'Foo Bar Baz'}}),
              }),
            ])
          },
        ),
      )

      render(renderWithRouter({child: <ToolHistory accountId={accountId} />, registration}))

      expect(await screen.findByText('Foo Bar Baz')).toBeInTheDocument()
    })

    it('only renders the most recent history entries, even if more are included', async () => {
      const allNames = ['foo', 'bar', 'baz', 'qux', 'quux', 'corge']
      const entries: LtiRegistrationHistoryEntry[] = allNames.map((name, index) => {
        return mockLtiRegistrationHistoryEntry({
          id: ZLtiRegistrationHistoryEntryId.parse(`${index + 1}`),
          created_by: mockUser({overrides: {name: name}}),
        })
      })

      const registration = mockRegistrationWithAllInformation({
        n: 'foo',
        i: 1,
      })

      server.use(
        http.get(
          `/api/v1/accounts/${accountId}/lti_registrations/${registration.id}/history`,
          () => {
            return HttpResponse.json(entries)
          },
        ),
      )

      render(renderWithRouter({child: <ToolHistory accountId={accountId} />, registration}))

      await waitFor(() => {
        const renderedNames = screen.getAllByText(new RegExp(allNames.join('|')))
        expect(renderedNames).toHaveLength(6)
      })
    })

    it('limits display to 99 entries and shows message when there are more than 99 history items', async () => {
      const entries: LtiRegistrationHistoryEntry[] = Array.from(
        {length: HISTORY_DISPLAY_LIMIT + 1},
        (_, index) => {
          return mockLtiRegistrationHistoryEntry({
            id: ZLtiRegistrationHistoryEntryId.parse(`${index + 1}`),
            created_by: mockUser({overrides: {name: `User ${index + 1}`}}),
          })
        },
      )

      const registration = mockRegistrationWithAllInformation({
        n: 'foo',
        i: 1,
      })

      server.use(
        http.get(
          `/api/v1/accounts/${accountId}/lti_registrations/${registration.id}/history`,
          () => {
            return HttpResponse.json(entries)
          },
        ),
      )

      render(renderWithRouter({child: <ToolHistory accountId={accountId} />, registration}))

      await waitFor(() => {
        expect(screen.getByText('Configuration Update History')).toBeInTheDocument()
      })

      const tableRows = screen.getAllByRole('row')
      expect(tableRows).toHaveLength(HISTORY_DISPLAY_LIMIT + 1) // 99 data rows + 1 header row

      expect(screen.getByText(/Showing the most recent 99 updates./)).toBeInTheDocument()

      expect(screen.getByText('User 1')).toBeInTheDocument()

      expect(screen.getByText('User 99')).toBeInTheDocument()

      expect(screen.queryByText('User 100')).not.toBeInTheDocument()
    })

    it('renders Instructure as the name if the change was made by a Site Admin', async () => {
      const registration = mockRegistrationWithAllInformation({
        n: 'foo',
        i: 1,
      })

      server.use(
        http.get(
          `/api/v1/accounts/${accountId}/lti_registrations/${registration.id}/history`,
          () => {
            return HttpResponse.json([
              mockLtiRegistrationHistoryEntry({
                created_by: 'Instructure',
              }),
            ])
          },
        ),
      )

      render(renderWithRouter({child: <ToolHistory accountId={accountId} />, registration}))

      expect(await screen.findByText('Instructure')).toBeInTheDocument()
    })

    it('shows empty state when no history entries exist', async () => {
      const registration = mockRegistrationWithAllInformation({
        n: 'foo',
        i: 1,
      })

      server.use(
        http.get(
          `/api/v1/accounts/${accountId}/lti_registrations/${registration.id}/history`,
          () => {
            return HttpResponse.json([])
          },
        ),
      )

      render(renderWithRouter({child: <ToolHistory accountId={accountId} />, registration}))

      expect(await screen.findByText('No configuration updates found')).toBeInTheDocument()
    })

    it('displays history entries with correct status and formatting', async () => {
      const registration = mockRegistrationWithAllInformation({
        n: 'foo',
        i: 1,
      })

      const historyEntry = mockLtiRegistrationHistoryEntry({
        created_by: mockUser({overrides: {name: 'Test User'}}),
        created_at: new Date('2025-01-15T12:00:00Z'),
      })

      server.use(
        http.get(
          `/api/v1/accounts/${accountId}/lti_registrations/${registration.id}/history`,
          () => {
            return HttpResponse.json([historyEntry])
          },
        ),
      )

      render(renderWithRouter({child: <ToolHistory accountId={accountId} />, registration}))

      expect(await screen.findByText('Configuration Update History')).toBeInTheDocument()
      expect(screen.getByText('Status')).toBeInTheDocument()
      expect(screen.getByText('Updated On')).toBeInTheDocument()
      expect(screen.getByText('Updated By')).toBeInTheDocument()

      expect(screen.getByText('Updated')).toBeInTheDocument()
      expect(screen.getByText('Test User')).toBeInTheDocument()
    })
  })
})
