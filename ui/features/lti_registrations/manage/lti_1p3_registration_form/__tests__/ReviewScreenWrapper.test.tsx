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

import {render, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {ReviewScreenWrapper} from '../components/ReviewScreenWrapper'
import {mockInternalConfiguration} from './helpers'
import {createLti1p3RegistrationOverlayStore} from '../../registration_overlay/Lti1p3RegistrationOverlayStore'
import {type Lti1p3RegistrationOverlayState} from '../../registration_overlay/Lti1p3RegistrationOverlayState'
import type {InternalLtiConfiguration} from '../../model/internal_lti_configuration/InternalLtiConfiguration'
import {i18nLtiPrivacyLevelDescription} from '../../model/i18nLtiPrivacyLevel'
import {i18nLtiScope} from '@canvas/lti/model/i18nLtiScope'
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

describe('Review Screen Wrapper', () => {
  beforeAll(() => server.listen({onUnhandledRequest: 'error'}))
  afterAll(() => server.close())

  beforeEach(() => {
    userEvent.setup()
    fakeENV.setup({
      ACCOUNT_ID: '123',
    })
  })
  afterEach(() => {
    server.resetHandlers()
    fakeENV.teardown()
  })
  const renderComponent = async (
    internalConfigOverrides: Partial<InternalLtiConfiguration> = {},
    stateOverrides: Partial<Lti1p3RegistrationOverlayState> = {},
  ) => {
    const internalConfig = mockInternalConfiguration(internalConfigOverrides)
    const overlayStore = createLti1p3RegistrationOverlayStore(internalConfig, '')
    const state = overlayStore.getState()
    overlayStore.setState({...state, state: {...state.state, ...stateOverrides}})

    const transitionTo = vi.fn()

    render(
      <ReviewScreenWrapper
        overlayStore={overlayStore}
        internalConfig={internalConfig}
        transitionTo={transitionTo}
      />,
      {wrapper: createWrapper()},
    )

    // Wait for loading spinner to disappear
    await waitFor(() => {
      expect(screen.queryByTestId('duplicate-domain-spinner')).not.toBeInTheDocument()
    })

    return {transitionTo}
  }

  it('renders the ReviewScreen with default settings', async () => {
    await renderComponent()

    expect(screen.getByText('Review')).toBeInTheDocument()
    expect(screen.getByText('Review your changes before finalizing.')).toBeInTheDocument()
  })

  it('renders the launch settings section', async () => {
    await renderComponent()

    expect(screen.getByText('Launch Settings')).toBeInTheDocument()
    expect(screen.getByText('Redirect URIs')).toBeInTheDocument()
    expect(screen.getByText('Default Target Link URI')).toBeInTheDocument()
    expect(screen.getByText('OpenID Connect Initiation URL')).toBeInTheDocument()
    expect(screen.getByText('JWK Method')).toBeInTheDocument()
    expect(screen.getByText('Domain')).toBeInTheDocument()
    expect(screen.getByText('Custom Fields')).toBeInTheDocument()
  })

  it('says that no redirect uris are present when none are configured', async () => {
    await renderComponent({redirect_uris: undefined})

    expect(screen.getByText(/no redirect uris specified/i)).toBeInTheDocument()
  })

  it('displays all redirect URIs', async () => {
    await renderComponent({
      redirect_uris: ['https://example.com/redirect1', 'https://example.com/redirect2'],
    })

    expect(screen.getByText('https://example.com/redirect1')).toBeInTheDocument()
    expect(screen.getByText('https://example.com/redirect2')).toBeInTheDocument()
  })

  it('says that no custom fields are present when none are configured', async () => {
    await renderComponent({custom_fields: undefined})

    expect(screen.getByText(/no custom fields specified/i)).toBeInTheDocument()
  })

  it('renders the relevant information for the JWK Method', async () => {
    await renderComponent({public_jwk_url: 'https://example.com/jwk'})

    expect(screen.getByRole('heading', {name: /Public JWK URL/i})).toBeInTheDocument()
    expect(screen.getByText('https://example.com/jwk')).toBeInTheDocument()
  })

  it('renders an interactable show more button when more than 3 custom fields are configured', async () => {
    await renderComponent({
      custom_fields: {
        field1: 'value1',
        field2: 'value2',
        field3: 'value3',
        field4: 'value4',
      },
    })

    expect(screen.queryByText('field4=value4')).not.toBeInTheDocument()
    expect(screen.getByText('Show more')).toBeInTheDocument()

    await userEvent.click(screen.getByText('Show more'))

    expect(screen.getByText('field4=value4')).toBeInTheDocument()
  })

  it('renders the permissions section', async () => {
    await renderComponent()

    expect(screen.getByText('Permissions')).toBeInTheDocument()
  })

  it('renders the data sharing section', async () => {
    await renderComponent()

    expect(screen.getByText('Data Sharing')).toBeInTheDocument()
  })

  it('renders the placements section', async () => {
    await renderComponent()

    expect(screen.getByText('Placements')).toBeInTheDocument()
  })

  it('renders the naming section', async () => {
    await renderComponent()

    expect(screen.getByText('Naming')).toBeInTheDocument()
  })

  it('renders appropriate text when no nickname is defined', async () => {
    await renderComponent(
      {},
      {
        naming: {
          nickname: undefined,
          placements: {},
        },
      },
    )

    expect(screen.getByText(/no nickname provided/i)).toBeInTheDocument()
  })

  it('renders the icon URLs section', async () => {
    await renderComponent()

    expect(screen.getByText('Icon URLs')).toBeInTheDocument()
  })

  it('does not render icon URLs section when includeIconUrls is false', () => {
    const internalConfig = mockInternalConfiguration({})
    const overlayStore = createLti1p3RegistrationOverlayStore(internalConfig, '')

    render(
      <ReviewScreenWrapper
        overlayStore={overlayStore}
        internalConfig={internalConfig}
        transitionTo={vi.fn()}
        includeIconUrls={false}
      />,
      {wrapper: createWrapper()},
    )

    expect(screen.queryByText('Icon URLs')).not.toBeInTheDocument()
    expect(screen.queryByRole('button', {name: /Edit Icon URLs/i})).not.toBeInTheDocument()
  })

  it('transitions to the correct step when edit buttons are clicked', async () => {
    const {transitionTo} = await renderComponent()

    await userEvent.click(screen.getByText(/Edit Launch Settings/i).closest('button')!)
    expect(transitionTo).toHaveBeenCalledWith('LaunchSettings')

    await userEvent.click(screen.getByText(/Edit Permissions/i).closest('button')!)
    expect(transitionTo).toHaveBeenCalledWith('Permissions')

    await userEvent.click(screen.getByText(/Edit Data Sharing/i).closest('button')!)
    expect(transitionTo).toHaveBeenCalledWith('DataSharing')

    await userEvent.click(screen.getByText(/Edit Placements/i).closest('button')!)
    expect(transitionTo).toHaveBeenCalledWith('Placements')

    await userEvent.click(screen.getByText(/Edit Naming/i).closest('button')!)
    expect(transitionTo).toHaveBeenCalledWith('Naming')

    await userEvent.click(screen.getByText(/Edit Icon URLs/i).closest('button')!)
    expect(transitionTo).toHaveBeenCalledWith('Icons')
  })

  it('renders custom fields correctly', async () => {
    await renderComponent({}, {launchSettings: {customFields: 'field1=value1\nfield2=value2'}})

    expect(screen.getByText('field1=value1')).toBeInTheDocument()
    expect(screen.getByText('field2=value2')).toBeInTheDocument()
  })

  it('renders placements with icons correctly', async () => {
    await renderComponent(
      {
        placements: [
          {placement: 'editor_button', icon_url: 'https://example.com/icon1.png'},
          {placement: 'global_navigation', icon_url: 'https://example.com/icon2.png'},
        ],
      },
      {
        icons: {
          placements: {
            editor_button: 'https://example.com/foobarbaz',
            global_navigation: 'https://example.com/icon2.png',
          },
        },
      },
    )

    expect(screen.getByText('Default Icon')).toBeInTheDocument()
    expect(screen.getByText('Custom Icon')).toBeInTheDocument()
  })

  it('renders privacy level correctly', async () => {
    await renderComponent({}, {data_sharing: {privacy_level: 'name_only'}})

    expect(screen.getByText(i18nLtiPrivacyLevelDescription('name_only'))).toBeInTheDocument()
  })

  it('renders scopes correctly', async () => {
    await renderComponent(
      {},
      {permissions: {scopes: ['https://purl.imsglobal.org/spec/lti-ags/scope/lineitem']}},
    )

    expect(
      screen.getByText(i18nLtiScope('https://purl.imsglobal.org/spec/lti-ags/scope/lineitem')),
    ).toBeInTheDocument()
  })

  describe('EULA Settings', () => {
    it('renders EULA Settings section when enabled', async () => {
      await renderComponent(
        {
          launch_settings: {
            message_settings: [
              {
                type: 'LtiEulaRequest',
                enabled: true,
                target_link_uri: 'https://example.com/eula',
                custom_fields: {
                  eula_field1: 'value1',
                  eula_field2: 'value2',
                },
              },
            ],
          },
        },
        {},
      )

      expect(screen.getByText('EULA Settings')).toBeInTheDocument()
      expect(screen.getByText('Enable EULA Request')).toBeInTheDocument()
      expect(screen.getByText('Yes')).toBeInTheDocument()
    })

    it('renders EULA target link URI when provided', async () => {
      await renderComponent(
        {
          launch_settings: {
            message_settings: [
              {
                type: 'LtiEulaRequest',
                enabled: true,
                target_link_uri: 'https://example.com/eula',
              },
            ],
          },
        },
        {},
      )

      expect(screen.getByText('EULA Target Link URI')).toBeInTheDocument()
      expect(screen.getByText('https://example.com/eula')).toBeInTheDocument()
    })

    it('renders EULA custom fields when provided', async () => {
      await renderComponent(
        {
          launch_settings: {
            message_settings: [
              {
                type: 'LtiEulaRequest',
                enabled: true,
                custom_fields: {
                  eula_field1: 'value1',
                  eula_field2: 'value2',
                  eula_field3: 'value3',
                },
              },
            ],
          },
        },
        {},
      )

      expect(screen.getByText('EULA Custom Fields:')).toBeInTheDocument()
      expect(screen.getByText('eula_field1=value1')).toBeInTheDocument()
      expect(screen.getByText('eula_field2=value2')).toBeInTheDocument()
      expect(screen.getByText('eula_field3=value3')).toBeInTheDocument()
    })

    it('shows disabled state when EULA is not enabled', async () => {
      await renderComponent(
        {
          launch_settings: {
            message_settings: [
              {
                type: 'LtiEulaRequest',
                enabled: false,
                target_link_uri: 'https://example.com/eula',
              },
            ],
          },
        },
        {},
      )

      expect(screen.getByText('EULA Settings')).toBeInTheDocument()
      expect(screen.getByText('Enable EULA Request')).toBeInTheDocument()
      expect(screen.getByText('No')).toBeInTheDocument()
    })

    it('does not render EULA Settings section when no message settings exist', async () => {
      await renderComponent({}, {})

      expect(screen.queryByText('EULA Settings')).not.toBeInTheDocument()
      expect(screen.queryByText('Enable EULA Request')).not.toBeInTheDocument()
    })

    it('does not render EULA Settings section when message settings array is empty', async () => {
      await renderComponent(
        {
          launch_settings: {
            message_settings: [],
          },
        },
        {},
      )

      expect(screen.queryByText('EULA Settings')).not.toBeInTheDocument()
      expect(screen.queryByText('Enable EULA Request')).not.toBeInTheDocument()
    })

    it('does not render target link URI section when not provided', async () => {
      await renderComponent(
        {
          launch_settings: {
            message_settings: [
              {
                type: 'LtiEulaRequest',
                enabled: true,
              },
            ],
          },
        },
        {},
      )

      expect(screen.getByText('EULA Settings')).toBeInTheDocument()
      expect(screen.queryByText('EULA Target Link URI')).not.toBeInTheDocument()
    })

    it('does not render custom fields section when empty', async () => {
      await renderComponent(
        {
          launch_settings: {
            message_settings: [
              {
                type: 'LtiEulaRequest',
                enabled: true,
                custom_fields: {},
              },
            ],
          },
        },
        {},
      )

      expect(screen.getByText('EULA Settings')).toBeInTheDocument()
      expect(screen.queryByText('EULA Custom Fields:')).not.toBeInTheDocument()
    })

    it('includes edit button for EULA Settings and transitions correctly', async () => {
      const {transitionTo} = await renderComponent(
        {
          launch_settings: {
            message_settings: [
              {
                type: 'LtiEulaRequest',
                enabled: true,
                target_link_uri: 'https://example.com/eula',
              },
            ],
          },
        },
        {},
      )

      const editButton = screen.getByRole('button', {name: /Edit EULA Settings/i})
      await userEvent.click(editButton)

      expect(transitionTo).toHaveBeenCalledWith('EulaSettings')
    })
  })

  describe('Duplicate Domain Alerts', () => {
    it('shows a warning with clickable links when duplicate domains are found', async () => {
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

      await renderComponent({domain: 'example.com'})

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

      await renderComponent({domain: 'example.com'})

      const link = screen.getByRole('link', {name: /Admin Nickname Only/i})
      expect(link).toBeInTheDocument()
    })

    it('does not show duplicate alert when no duplicates are found', async () => {
      await renderComponent({domain: 'example.com'})

      expect(
        screen.queryByText(/Another tool configuration uses this domain/i),
      ).not.toBeInTheDocument()
      expect(
        screen.queryByText(/Other tool configurations use this domain/i),
      ).not.toBeInTheDocument()
    })
  })
})
