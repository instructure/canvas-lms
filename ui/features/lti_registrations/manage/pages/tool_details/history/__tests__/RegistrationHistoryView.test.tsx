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
import {render, screen} from '@testing-library/react'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {RegistrationHistoryView} from '../RegistrationHistoryView'
import {ZAccountId} from '../../../../model/AccountId'
import {ZLtiRegistrationId} from '../../../../model/LtiRegistrationId'
import {ZLtiRegistrationHistoryEntryId} from '../../../../model/LtiRegistrationHistoryEntry'
import {mockUser} from '../../../manage/__tests__/helpers'
import type {
  AvailabilityChangeHistoryEntry,
  ConfigChangeHistoryEntry,
} from '../../../../model/LtiRegistrationHistoryEntry'
import {ZLtiContextControlId} from '../../../../model/LtiContextControl'
import {ZLtiDeploymentId} from '../../../../model/LtiDeploymentId'
import userEvent from '@testing-library/user-event'

const server = setupServer()

const mockConfigChangeEntry = (
  overrides: Partial<ConfigChangeHistoryEntry> &
    Pick<ConfigChangeHistoryEntry, 'old_configuration' | 'new_configuration'>,
): ConfigChangeHistoryEntry => ({
  id: ZLtiRegistrationHistoryEntryId.parse('1'),
  root_account_id: ZAccountId.parse('4'),
  lti_registration_id: ZLtiRegistrationId.parse('1'),
  created_at: new Date('2025-01-15T12:00:00Z'),
  updated_at: new Date('2025-01-15T12:00:00Z'),
  diff: {registration: [['~', 'name', 'Old Name', 'New Name']]},
  update_type: 'manual_edit',
  comment: 'Test update',
  created_by: mockUser({overrides: {name: 'Test User'}}),
  ...overrides,
})

const mockAvailabilityChangeEntry = (
  overrides: Partial<AvailabilityChangeHistoryEntry> &
    Pick<
      AvailabilityChangeHistoryEntry,
      'old_controls_by_deployment' | 'new_controls_by_deployment'
    >,
): AvailabilityChangeHistoryEntry => ({
  id: ZLtiRegistrationHistoryEntryId.parse('2'),
  root_account_id: ZAccountId.parse('4'),
  lti_registration_id: ZLtiRegistrationId.parse('1'),
  created_at: new Date('2025-01-16T12:00:00Z'),
  updated_at: new Date('2025-01-16T12:00:00Z'),
  diff: {},
  update_type: 'control_edit',
  comment: null,
  created_by: mockUser({overrides: {name: 'Admin User'}}),
  ...overrides,
})

const mockConfigSnapshot = () => ({
  internal_config: {
    custom_fields: {},
    placements: [],
    description: '',
    domain: '',
    launch_settings: {},
    oidc_initiation_url: 'https://example.com',
    oidc_initiation_urls: {},
    scopes: [],
    title: 'Test Tool',
    redirect_uris: [],
    target_link_uri: 'https://example.com',
  },
  developer_key: {
    email: 'test@example.com',
    user_name: 'Test User',
    name: 'Test Key',
    redirect_uri: 'https://example.com',
    redirect_uris: [],
    icon_url: null,
    vendor_code: null,
    public_jwk: null,
    oidc_initiation_url: 'https://example.com',
    public_jwk_url: null,
    scopes: [],
  },
  registration: {
    admin_nickname: 'Test Tool',
    name: 'Test Tool',
    vendor: null,
    workflow_state: 'on' as const,
    description: null,
  },
  overlaid_internal_config: {
    custom_fields: {},
    placements: [],
    description: '',
    domain: '',
    launch_settings: {},
    oidc_initiation_url: 'https://example.com',
    oidc_initiation_urls: {},
    scopes: [],
    title: 'Test Tool',
    redirect_uris: [],
    target_link_uri: 'https://example.com',
  },
  overlay: {},
})

const renderWithQueryClient = (component: React.ReactElement) => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
      },
    },
  })
  return render(<QueryClientProvider client={queryClient}>{component}</QueryClientProvider>)
}

describe('RegistrationHistoryView', () => {
  const accountId = ZAccountId.parse('4')
  const registrationId = ZLtiRegistrationId.parse('1')

  beforeAll(() => server.listen())
  afterEach(() => server.resetHandlers())
  afterAll(() => server.close())

  describe('rendering', () => {
    it('renders successfully with history data', async () => {
      const mockSnapshot = mockConfigSnapshot()
      const entries: ConfigChangeHistoryEntry[] = [
        mockConfigChangeEntry({
          id: ZLtiRegistrationHistoryEntryId.parse('1'),
          old_configuration: mockSnapshot,
          new_configuration: {
            ...mockSnapshot,
            overlaid_internal_config: {
              ...mockSnapshot.overlaid_internal_config,
              title: 'Updated Title',
            },
          },
          created_by: mockUser({overrides: {name: 'John Doe'}}),
        }),
      ]

      server.use(
        http.get(`/api/v1/accounts/${accountId}/lti_registrations/${registrationId}/history`, () =>
          HttpResponse.json(entries),
        ),
      )

      renderWithQueryClient(
        <RegistrationHistoryView accountId={accountId} registrationId={registrationId} />,
      )

      expect(await screen.findByText('Configuration Update History')).toBeInTheDocument()
      expect(screen.getByText('Status')).toBeInTheDocument()
      expect(screen.getByText('Updated On')).toBeInTheDocument()
      expect(screen.getByText('Updated By')).toBeInTheDocument()
      expect(screen.getByText('Affected Fields')).toBeInTheDocument()
      expect(screen.getByText('John Doe')).toBeInTheDocument()
    })

    it('renders empty state when no history entries exist', async () => {
      server.use(
        http.get(`/api/v1/accounts/${accountId}/lti_registrations/${registrationId}/history`, () =>
          HttpResponse.json([]),
        ),
      )

      renderWithQueryClient(
        <RegistrationHistoryView accountId={accountId} registrationId={registrationId} />,
      )

      expect(await screen.findByText('No configuration updates found')).toBeInTheDocument()
    })

    it('renders Instructure as creator when created_by is "Instructure"', async () => {
      const mockSnapshot = mockConfigSnapshot()
      const entries: ConfigChangeHistoryEntry[] = [
        mockConfigChangeEntry({
          old_configuration: mockSnapshot,
          new_configuration: mockSnapshot,
          created_by: 'Instructure',
        }),
      ]

      server.use(
        http.get(`/api/v1/accounts/${accountId}/lti_registrations/${registrationId}/history`, () =>
          HttpResponse.json(entries),
        ),
      )

      renderWithQueryClient(
        <RegistrationHistoryView accountId={accountId} registrationId={registrationId} />,
      )

      expect(await screen.findByText('Instructure')).toBeInTheDocument()
    })
  })

  describe('affected fields', () => {
    it('shows "Launch Settings" when launch settings change', async () => {
      const mockSnapshot = mockConfigSnapshot()
      const entries: ConfigChangeHistoryEntry[] = [
        mockConfigChangeEntry({
          old_configuration: mockSnapshot,
          new_configuration: {
            ...mockSnapshot,
            overlaid_internal_config: {
              ...mockSnapshot.overlaid_internal_config,
              domain: 'new-domain.example.com',
            },
          },
        }),
      ]

      server.use(
        http.get(`/api/v1/accounts/${accountId}/lti_registrations/${registrationId}/history`, () =>
          HttpResponse.json(entries),
        ),
      )

      renderWithQueryClient(
        <RegistrationHistoryView accountId={accountId} registrationId={registrationId} />,
      )

      expect(await screen.findByText(/Launch Settings/)).toBeInTheDocument()
    })

    it('shows "Permissions" when permissions change', async () => {
      const mockSnapshot = mockConfigSnapshot()
      const entries: ConfigChangeHistoryEntry[] = [
        mockConfigChangeEntry({
          old_configuration: mockSnapshot,
          new_configuration: {
            ...mockSnapshot,
            overlaid_internal_config: {
              ...mockSnapshot.overlaid_internal_config,
              scopes: ['https://purl.imsglobal.org/spec/lti-ags/scope/lineitem'],
            },
          },
        }),
      ]

      server.use(
        http.get(`/api/v1/accounts/${accountId}/lti_registrations/${registrationId}/history`, () =>
          HttpResponse.json(entries),
        ),
      )

      renderWithQueryClient(
        <RegistrationHistoryView accountId={accountId} registrationId={registrationId} />,
      )

      expect(await screen.findByText(/Permissions/)).toBeInTheDocument()
    })

    it('shows "Privacy Level" when privacy level changes', async () => {
      const mockSnapshot = mockConfigSnapshot()
      const entries: ConfigChangeHistoryEntry[] = [
        mockConfigChangeEntry({
          old_configuration: {
            ...mockSnapshot,
            overlaid_internal_config: {
              ...mockSnapshot.overlaid_internal_config,
              privacy_level: 'public',
            },
          },
          new_configuration: {
            ...mockSnapshot,
            overlaid_internal_config: {
              ...mockSnapshot.overlaid_internal_config,
              privacy_level: 'anonymous',
            },
          },
        }),
      ]

      server.use(
        http.get(`/api/v1/accounts/${accountId}/lti_registrations/${registrationId}/history`, () =>
          HttpResponse.json(entries),
        ),
      )

      renderWithQueryClient(
        <RegistrationHistoryView accountId={accountId} registrationId={registrationId} />,
      )

      expect(await screen.findByText(/Privacy Level/)).toBeInTheDocument()
    })

    it('shows "Placements" when placements change', async () => {
      const mockSnapshot = mockConfigSnapshot()
      const entries: ConfigChangeHistoryEntry[] = [
        mockConfigChangeEntry({
          old_configuration: mockSnapshot,
          new_configuration: {
            ...mockSnapshot,
            overlaid_internal_config: {
              ...mockSnapshot.overlaid_internal_config,
              placements: [
                {
                  placement: 'course_navigation',
                  enabled: true,
                },
              ],
            },
          },
        }),
      ]

      server.use(
        http.get(`/api/v1/accounts/${accountId}/lti_registrations/${registrationId}/history`, () =>
          HttpResponse.json(entries),
        ),
      )

      renderWithQueryClient(
        <RegistrationHistoryView accountId={accountId} registrationId={registrationId} />,
      )

      expect(await screen.findByText(/Placements/)).toBeInTheDocument()
    })

    it('shows "Naming" when naming fields change', async () => {
      const mockSnapshot = mockConfigSnapshot()
      const entries: ConfigChangeHistoryEntry[] = [
        mockConfigChangeEntry({
          old_configuration: {
            ...mockSnapshot,
            registration: {
              ...mockSnapshot.registration,
              admin_nickname: 'Old Nickname',
            },
          },
          new_configuration: {
            ...mockSnapshot,
            registration: {
              ...mockSnapshot.registration,
              admin_nickname: 'New Nickname',
            },
          },
        }),
      ]

      server.use(
        http.get(`/api/v1/accounts/${accountId}/lti_registrations/${registrationId}/history`, () =>
          HttpResponse.json(entries),
        ),
      )

      renderWithQueryClient(
        <RegistrationHistoryView accountId={accountId} registrationId={registrationId} />,
      )

      expect(await screen.findByText(/Naming/)).toBeInTheDocument()
    })

    it('shows "Icons" when icon_url changes', async () => {
      const mockSnapshot = mockConfigSnapshot()
      const entries: ConfigChangeHistoryEntry[] = [
        mockConfigChangeEntry({
          old_configuration: mockSnapshot,
          new_configuration: {
            ...mockSnapshot,
            overlaid_internal_config: {
              ...mockSnapshot.overlaid_internal_config,
              launch_settings: {
                icon_url: 'https://example.com/icon.png',
              },
            },
          },
        }),
      ]

      server.use(
        http.get(`/api/v1/accounts/${accountId}/lti_registrations/${registrationId}/history`, () =>
          HttpResponse.json(entries),
        ),
      )

      renderWithQueryClient(
        <RegistrationHistoryView accountId={accountId} registrationId={registrationId} />,
      )

      expect(await screen.findByText(/Icons/)).toBeInTheDocument()
    })

    it('shows "Availability & Exceptions" for context control changes', async () => {
      const entries = [
        mockAvailabilityChangeEntry({
          old_controls_by_deployment: [],
          new_controls_by_deployment: [
            {
              id: ZLtiDeploymentId.parse('1'),
              registration_id: ZLtiRegistrationId.parse('1'),
              deployment_id: '1',
              context_id: '1',
              context_type: 'Account',
              context_name: 'Test Account',
              root_account_deployment: false,
              workflow_state: 'active',
              context_controls: [
                {
                  id: ZLtiContextControlId.parse('1'),
                  registration_id: ZLtiRegistrationId.parse('1'),
                  deployment_id: ZLtiDeploymentId.parse('1'),
                  account_id: ZAccountId.parse('1'),
                  course_id: null,
                  available: false,
                  path: '/1',
                  display_path: ['Test Account'],
                  context_name: 'Test Account',
                  depth: 0,
                  child_control_count: 0,
                  course_count: 0,
                  subaccount_count: 0,
                  workflow_state: 'active',
                  created_at: new Date('2025-01-16T12:00:00Z'),
                  updated_at: new Date('2025-01-16T12:00:00Z'),
                  created_by: null,
                  updated_by: null,
                },
              ],
            },
          ],
        }),
      ]

      server.use(
        http.get(`/api/v1/accounts/${accountId}/lti_registrations/${registrationId}/history`, () =>
          HttpResponse.json(entries),
        ),
      )

      renderWithQueryClient(
        <RegistrationHistoryView accountId={accountId} registrationId={registrationId} />,
      )

      expect(await screen.findByText('Availability & Exceptions')).toBeInTheDocument()
    })

    it('shows multiple affected fields when multiple categories change', async () => {
      const mockSnapshot = mockConfigSnapshot()
      const entries: ConfigChangeHistoryEntry[] = [
        mockConfigChangeEntry({
          old_configuration: {
            ...mockSnapshot,
            registration: {
              ...mockSnapshot.registration,
              admin_nickname: 'Old Name',
            },
            overlaid_internal_config: {
              ...mockSnapshot.overlaid_internal_config,
              privacy_level: 'anonymous',
            },
          },
          new_configuration: {
            ...mockSnapshot,
            registration: {
              ...mockSnapshot.registration,
              admin_nickname: 'New Name',
            },
            overlaid_internal_config: {
              ...mockSnapshot.overlaid_internal_config,
              privacy_level: 'public',
              placements: [
                {
                  placement: 'course_navigation',
                  enabled: true,
                },
              ],
            },
          },
        }),
      ]

      server.use(
        http.get(`/api/v1/accounts/${accountId}/lti_registrations/${registrationId}/history`, () =>
          HttpResponse.json(entries),
        ),
      )

      renderWithQueryClient(
        <RegistrationHistoryView accountId={accountId} registrationId={registrationId} />,
      )

      expect(await screen.findByText(/Naming/)).toBeInTheDocument()
      expect(await screen.findByText(/Privacy Level/)).toBeInTheDocument()
      expect(await screen.findByText(/Placements/)).toBeInTheDocument()
    })
  })

  describe('pagination', () => {
    it('renders table with multiple pages of data', async () => {
      const mockSnapshot = mockConfigSnapshot()
      const firstPageEntries: ConfigChangeHistoryEntry[] = [
        mockConfigChangeEntry({
          id: ZLtiRegistrationHistoryEntryId.parse('1'),
          old_configuration: mockSnapshot,
          new_configuration: mockSnapshot,
          created_by: mockUser({overrides: {name: 'User 1'}}),
        }),
      ]

      const secondPageEntries: ConfigChangeHistoryEntry[] = [
        mockConfigChangeEntry({
          id: ZLtiRegistrationHistoryEntryId.parse('2'),
          old_configuration: mockSnapshot,
          new_configuration: mockSnapshot,
          created_by: mockUser({overrides: {name: 'User 2'}}),
        }),
      ]

      server.use(
        http.get(
          `/api/v1/accounts/${accountId}/lti_registrations/${registrationId}/history`,
          ({request}) => {
            const url = new URL(request.url)
            const page = url.searchParams.get('page')

            if (page === '2') {
              return HttpResponse.json(secondPageEntries)
            }

            return HttpResponse.json(firstPageEntries, {
              headers: {
                Link: `</api/v1/accounts/${accountId}/lti_registrations/${registrationId}/history?page=2>; rel="next"`,
              },
            })
          },
        ),
      )

      renderWithQueryClient(
        <RegistrationHistoryView accountId={accountId} registrationId={registrationId} />,
      )

      expect(await screen.findByText('User 1')).toBeInTheDocument()
      expect(screen.queryByText('User 2')).not.toBeInTheDocument()

      userEvent.click(screen.getByText('Load More').closest('button')!)
      expect(await screen.findByText('User 2')).toBeInTheDocument()
      expect(screen.queryByText('Load More')).not.toBeInTheDocument()
    })

    it('renders all entries when there is only one page', async () => {
      const mockSnapshot = mockConfigSnapshot()
      const entries: ConfigChangeHistoryEntry[] = [
        mockConfigChangeEntry({
          id: ZLtiRegistrationHistoryEntryId.parse('1'),
          old_configuration: mockSnapshot,
          new_configuration: mockSnapshot,
          created_by: mockUser({overrides: {name: 'Single User'}}),
        }),
      ]

      server.use(
        http.get(`/api/v1/accounts/${accountId}/lti_registrations/${registrationId}/history`, () =>
          HttpResponse.json(entries),
        ),
      )

      renderWithQueryClient(
        <RegistrationHistoryView accountId={accountId} registrationId={registrationId} />,
      )

      expect(await screen.findByText('Single User')).toBeInTheDocument()
      expect(screen.queryByText('Load More')).not.toBeInTheDocument()
    })
  })
})
