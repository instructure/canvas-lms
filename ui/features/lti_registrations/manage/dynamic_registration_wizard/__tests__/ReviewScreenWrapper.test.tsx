/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import {cleanup, screen, render, waitFor} from '@testing-library/react'

import {ReviewScreenWrapper} from '../components/ReviewScreenWrapper'
import {mockConfigWithPlacements, mockRegistration, mockToolConfiguration} from './helpers'
import {LtiPlacements, type LtiPlacementWithIcon} from '../../model/LtiPlacement'
import {i18nLtiPlacement} from '../../model/i18nLtiPlacement'
import {createDynamicRegistrationOverlayStore} from '../DynamicRegistrationOverlayState'
import {i18nLtiScope} from '@canvas/lti/model/i18nLtiScope'
import {i18nLtiPrivacyLevelDescription} from '../../model/i18nLtiPrivacyLevel'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import React from 'react'
import fakeENV from '@canvas/test-utils/fakeENV'

const server = setupServer(
  http.get('/api/v1/accounts/:accountId/lti_registrations/check_domain_duplicates', () => {
    return HttpResponse.json({duplicates: []})
  }),
)

const createWrapper = () => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
        staleTime: 0,
        gcTime: 0,
      },
    },
  })
  return ({children}: {children: React.ReactNode}) => (
    <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
  )
}

describe('ReviewScreen', () => {
  beforeAll(() => server.listen({onUnhandledRequest: 'error'}))
  beforeEach(() => {
    fakeENV.setup({
      ACCOUNT_ID: '123',
    })
  })
  afterEach(() => {
    cleanup()
    server.resetHandlers()
    fakeENV.teardown()
  })
  afterAll(() => server.close())

  it('renders without error', async () => {
    const config = mockConfigWithPlacements([
      LtiPlacements.CourseNavigation,
      LtiPlacements.GlobalNavigation,
    ])
    const reg = mockRegistration({}, config)
    const overlayStore = createDynamicRegistrationOverlayStore('Foo', reg)

    render(
      <ReviewScreenWrapper
        registration={reg}
        overlayStore={overlayStore}
        transitionToConfirmationState={vi.fn()}
      />,
      {wrapper: createWrapper()},
    )
    await waitFor(() => {
      expect(screen.queryByText(/checking for duplicate domains/i)).not.toBeInTheDocument()
    })

    expect(screen.getByText('Review')).toBeInTheDocument()
  })

  it('renders a summary of requested permissions', async () => {
    const config = mockConfigWithPlacements([
      LtiPlacements.CourseNavigation,
      LtiPlacements.GlobalNavigation,
    ])
    const reg = mockRegistration({}, config)
    const overlayStore = createDynamicRegistrationOverlayStore('Foo', reg)

    render(
      <ReviewScreenWrapper
        registration={reg}
        overlayStore={overlayStore}
        transitionToConfirmationState={vi.fn()}
      />,
      {wrapper: createWrapper()},
    )
    await waitFor(() => {
      expect(screen.queryByText(/checking for duplicate domains/i)).not.toBeInTheDocument()
    })

    expect(screen.getByText('Permissions')).toBeInTheDocument()

    for (const scope of reg.configuration.scopes) {
      expect(screen.getByText(i18nLtiScope(scope))).toBeInTheDocument()
    }
    expect(screen.getByRole('button', {name: 'Edit Permissions'})).toBeInTheDocument()
  })

  it('renders a summary of the configured privacy level', async () => {
    const config = mockConfigWithPlacements([
      LtiPlacements.CourseNavigation,
      LtiPlacements.GlobalNavigation,
    ])
    config.privacy_level = 'public'
    const reg = mockRegistration({}, config)
    const overlayStore = createDynamicRegistrationOverlayStore('Foo', reg)
    render(
      <ReviewScreenWrapper
        registration={reg}
        overlayStore={overlayStore}
        transitionToConfirmationState={vi.fn()}
      />,
      {wrapper: createWrapper()},
    )
    await waitFor(() => {
      expect(screen.queryByText(/checking for duplicate domains/i)).not.toBeInTheDocument()
    })

    expect(screen.getByText('Data Sharing')).toBeInTheDocument()
    expect(
      screen.getByText(i18nLtiPrivacyLevelDescription(reg.configuration.privacy_level!)),
    ).toBeInTheDocument()
    expect(screen.getByRole('button', {name: 'Edit Data Sharing'})).toBeInTheDocument()
  })

  it('renders a summary of the configured placements', async () => {
    const placements = [
      LtiPlacements.CourseNavigation,
      LtiPlacements.GlobalNavigation,
      LtiPlacements.FileIndexMenu,
    ]
    const config = mockConfigWithPlacements(placements)

    const reg = mockRegistration({}, config)
    const overlayStore = createDynamicRegistrationOverlayStore('Foo', reg)

    render(
      <ReviewScreenWrapper
        registration={reg}
        overlayStore={overlayStore}
        transitionToConfirmationState={vi.fn()}
      />,
      {wrapper: createWrapper()},
    )
    await waitFor(() => {
      expect(screen.queryByText(/checking for duplicate domains/i)).not.toBeInTheDocument()
    })

    expect(screen.getByText('Placements')).toBeInTheDocument()
    placements.forEach(p => {
      expect(screen.getByText(i18nLtiPlacement(p))).toBeInTheDocument()
    })
    expect(screen.queryByText('File Index Menu')).not.toBeInTheDocument()
    expect(screen.getByRole('button', {name: 'Edit Placements'})).toBeInTheDocument()
  })

  it('renders a summary of the configured names', async () => {
    const nickname = 'a great nickname'
    const description = 'a great description'
    const placementLabel = 'a great placement nickname'
    const config = mockConfigWithPlacements([
      LtiPlacements.CourseNavigation,
      LtiPlacements.GlobalNavigation,
    ])
    const reg = mockRegistration({}, config)
    const overlayStore = createDynamicRegistrationOverlayStore('Foo', reg)
    overlayStore.setState(s => {
      return {
        ...s,
        state: {
          ...s.state,
          adminNickname: nickname,
          overlay: {
            ...s.state.overlay,
            description,
            placements: Object.fromEntries(
              Object.entries(s.state.overlay.placements!).map(([k, p]) => [
                k,
                {
                  ...p,
                  text: placementLabel,
                },
              ]),
            ),
          },
        },
      }
    })
    render(
      <ReviewScreenWrapper
        registration={reg}
        overlayStore={overlayStore}
        transitionToConfirmationState={vi.fn()}
      />,
      {wrapper: createWrapper()},
    )
    await waitFor(() => {
      expect(screen.queryByText(/checking for duplicate domains/i)).not.toBeInTheDocument()
    })

    expect(screen.getByText('Naming')).toBeInTheDocument()
    expect(screen.getByText(nickname)).toBeInTheDocument()
    expect(screen.getByText(description)).toBeInTheDocument()
    expect(screen.getAllByText(placementLabel)).toHaveLength(reg.configuration.placements.length)
    expect(screen.getByText('Edit Naming')).toBeInTheDocument()
  })

  describe('Icon URLs summary', () => {
    it("says the 'Default' icon is being used if the user hasn't changed anything", async () => {
      const config = mockConfigWithPlacements([
        LtiPlacements.CourseNavigation,
        LtiPlacements.GlobalNavigation,
      ])
      config.placements!.forEach(p => {
        p.icon_url = 'https://example.com/icon.png'
      })

      const reg = mockRegistration({}, config)

      const overlayStore = createDynamicRegistrationOverlayStore('Foo', reg)

      render(
        <ReviewScreenWrapper
          registration={reg}
          overlayStore={overlayStore}
          transitionToConfirmationState={vi.fn()}
        />,
        {wrapper: createWrapper()},
      )
      await waitFor(() => {
        expect(screen.queryByTestId('duplicate-domain-spinner')).not.toBeInTheDocument()
      })

      expect(screen.getByText('Icon URLs')).toBeInTheDocument()

      expect(screen.getByText('Default Icon')).toBeInTheDocument()
    })

    it("says a 'Default Icon' is being used if the configured url is blank and the tool has a top-level icon", async () => {
      const placements: LtiPlacementWithIcon[] = [
        LtiPlacements.GlobalNavigation,
        LtiPlacements.FileIndexMenu,
        LtiPlacements.EditorButton,
      ]
      const config = mockConfigWithPlacements(placements)
      config.placements!.forEach(p => {
        p.icon_url = ''
      })

      const reg = mockRegistration({
        configuration: mockToolConfiguration({
          ...config,
          launch_settings: {
            icon_url: 'https://example.com/icon.png',
          },
        }),
      })

      const overlayStore = createDynamicRegistrationOverlayStore('Foo', reg)

      render(
        <ReviewScreenWrapper
          registration={reg}
          overlayStore={overlayStore}
          transitionToConfirmationState={vi.fn()}
        />,
        {wrapper: createWrapper()},
      )
      await waitFor(() => {
        expect(screen.queryByTestId('duplicate-domain-spinner')).not.toBeInTheDocument()
      })

      expect(screen.getByText('Icon URLs')).toBeInTheDocument()
      expect(screen.getAllByText('Default Icon')).toHaveLength(placements.length)
    })

    it("says a 'Custom Icon' is being used if the user added their own custom icon url", async () => {
      const placements: LtiPlacementWithIcon[] = [
        LtiPlacements.GlobalNavigation,
        LtiPlacements.FileIndexMenu,
      ]
      const config = mockConfigWithPlacements(placements)
      config.placements!.forEach(p => {
        p.icon_url = 'https://example.com/icon.png'
      })

      const reg = mockRegistration({}, config)

      const overlayStore = createDynamicRegistrationOverlayStore('Foo', reg)

      overlayStore.setState(s => {
        return {
          ...s,
          state: {
            ...s.state,
            overlay: {
              ...s.state.overlay,
              placements: Object.fromEntries(
                Object.entries(s.state.overlay.placements!).map(([k, p]) => [
                  k,
                  {
                    ...p,
                    icon_url: 'https://example.com/custom-icon.png',
                  },
                ]),
              ),
            },
          },
        }
      })

      render(
        <ReviewScreenWrapper
          registration={reg}
          overlayStore={overlayStore}
          transitionToConfirmationState={vi.fn()}
        />,
        {wrapper: createWrapper()},
      )
      await waitFor(() => {
        expect(screen.queryByText('duplicate-domain-spinner')).not.toBeInTheDocument()
      })

      expect(screen.getByText('Icon URLs')).toBeInTheDocument()
      expect(screen.getAllByText('Custom Icon')).toHaveLength(placements.length)
    })

    it("says that a 'Generated Icon' is being used if the configured icon is blank, the tool doesn't have a top-level icon, and the placement is the editor button", async () => {
      const placements: LtiPlacementWithIcon[] = [
        LtiPlacements.GlobalNavigation,
        LtiPlacements.FileIndexMenu,
        LtiPlacements.EditorButton,
      ]
      const config = mockConfigWithPlacements(placements)
      config.placements!.forEach(p => {
        p.icon_url = ''
      })

      const reg = mockRegistration({}, config)
      reg.configuration.launch_settings!.icon_url = ''

      const overlayStore = createDynamicRegistrationOverlayStore('Foo', reg)

      render(
        <ReviewScreenWrapper
          registration={reg}
          overlayStore={overlayStore}
          transitionToConfirmationState={vi.fn()}
        />,
        {wrapper: createWrapper()},
      )
      await waitFor(() => {
        expect(screen.queryByTestId('duplicate-domain-spinner')).not.toBeInTheDocument()
      })

      expect(screen.getByText('Icon URLs')).toBeInTheDocument()
      expect(screen.getByText('Generated Icon')).toBeInTheDocument()
    })

    it("says 'No Icon' is being used if the configured icon is blank and the tool doesn't have a top-level icon", async () => {
      const placements: LtiPlacementWithIcon[] = [
        LtiPlacements.GlobalNavigation,
        LtiPlacements.FileIndexMenu,
      ]
      const config = mockConfigWithPlacements(placements)
      config.placements!.forEach(p => {
        p.icon_url = ''
      })

      const reg = mockRegistration({}, config)
      reg.configuration.launch_settings!.icon_url = ''

      const overlayStore = createDynamicRegistrationOverlayStore('Foo', reg)

      render(
        <ReviewScreenWrapper
          registration={reg}
          overlayStore={overlayStore}
          transitionToConfirmationState={vi.fn()}
        />,
        {wrapper: createWrapper()},
      )
      await waitFor(() => {
        expect(screen.queryByTestId('duplicate-domain-spinner')).not.toBeInTheDocument()
      })

      expect(screen.getByText('Icon URLs')).toBeInTheDocument()
      expect(screen.getAllByText('No Icon')).toHaveLength(placements.length)
    })
  })

  describe('Duplicate Domain Alerts', () => {
    it('shows a warning with clickable links duplicate domains are found', async () => {
      server.use(
        http.get('/api/v1/accounts/:accountId/lti_registrations/check_domain_duplicates', () => {
          return HttpResponse.json({
            duplicates: [
              {
                id: '456',
                name: 'First Tool',
              },
              {
                id: '789',
                name: 'Second Tool',
              },
              {
                id: '101',
                name: 'Third Tool',
              },
              {
                id: '112',
                name: 'Fourth Tool',
              },
            ],
          })
        }),
      )

      const config = mockConfigWithPlacements([LtiPlacements.CourseNavigation])
      const reg = mockRegistration({}, {...config, domain: 'example.com'})
      const overlayStore = createDynamicRegistrationOverlayStore('Foo', reg)

      render(
        <ReviewScreenWrapper
          registration={reg}
          overlayStore={overlayStore}
          transitionToConfirmationState={vi.fn()}
        />,
        {wrapper: createWrapper()},
      )

      await waitFor(() => {
        expect(screen.queryByText(/checking for duplicate domains/i)).not.toBeInTheDocument()
      })

      expect(
        screen.getByText(/Other tool configurations use this domain including/i),
      ).toBeInTheDocument()

      const firstLink = screen.getByRole('link', {name: /First Tool/i})
      expect(firstLink).toHaveAttribute('href', '/accounts/123/apps/manage/456')

      const secondLink = screen.getByRole('link', {name: /Second Tool/i})
      expect(secondLink).toHaveAttribute('href', '/accounts/123/apps/manage/789')

      const thirdLink = screen.getByRole('link', {name: /Third Tool/i})
      expect(thirdLink).toHaveAttribute('href', '/accounts/123/apps/manage/101')

      expect(screen.queryByText(/Fourth Tool/i)).not.toBeInTheDocument()
    })

    it('uses admin_nickname when name is not available', async () => {
      server.use(
        http.get('/api/v1/accounts/:accountId/lti_registrations/check_domain_duplicates', () => {
          return HttpResponse.json({
            duplicates: [
              {
                id: '456',
                name: '',
                admin_nickname: 'Admin Nickname Only',
              },
            ],
          })
        }),
      )

      const config = mockConfigWithPlacements([LtiPlacements.CourseNavigation])
      const reg = mockRegistration({}, {...config, domain: 'example.com'})
      const overlayStore = createDynamicRegistrationOverlayStore('Foo', reg)

      render(
        <ReviewScreenWrapper
          registration={reg}
          overlayStore={overlayStore}
          transitionToConfirmationState={vi.fn()}
        />,
        {wrapper: createWrapper()},
      )

      await waitFor(() => {
        expect(screen.queryByText(/checking for duplicate domains/i)).not.toBeInTheDocument()
      })

      const link = screen.getByRole('link', {name: /Admin Nickname Only/i})
      expect(link).toBeInTheDocument()
    })

    it('does not show duplicate alert when no duplicates are found', async () => {
      const config = mockConfigWithPlacements([LtiPlacements.CourseNavigation])
      const reg = mockRegistration({}, {...config, domain: 'example.com'})
      const overlayStore = createDynamicRegistrationOverlayStore('Foo', reg)

      render(
        <ReviewScreenWrapper
          registration={reg}
          overlayStore={overlayStore}
          transitionToConfirmationState={vi.fn()}
        />,
        {wrapper: createWrapper()},
      )

      await waitFor(() => {
        expect(screen.queryByText(/checking for duplicate domains/i)).not.toBeInTheDocument()
      })

      expect(
        screen.queryByText(/Another tool configuration uses this domain/i),
      ).not.toBeInTheDocument()
      expect(
        screen.queryByText(/Other tool configurations use this domain/i),
      ).not.toBeInTheDocument()
    })
  })
})
