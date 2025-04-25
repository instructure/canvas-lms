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
import {AllLtiScopes} from '@canvas/lti/model/LtiScope'
import {i18nLtiScope} from '@canvas/lti/model/i18nLtiScope'
import {render, screen} from '@testing-library/react'
import {clickOrFail} from '../../../__tests__/interactionHelpers'
import {createMemoryRouter, RouterProvider, Outlet, Route, Routes} from 'react-router-dom'
import {AllLtiPlacements} from '../../../../model/LtiPlacement'
import {AllLtiPrivacyLevels} from '../../../../model/LtiPrivacyLevel'
import {i18nLtiPlacement} from '../../../../model/i18nLtiPlacement'
import {i18nLtiPrivacyLevel} from '../../../../model/i18nLtiPrivacyLevel'
import {ZLtiImsRegistrationId} from '../../../../model/lti_ims_registration/LtiImsRegistrationId'
import {ZLtiToolConfigurationId} from '../../../../model/lti_tool_configuration/LtiToolConfigurationId'
import {ToolConfigurationView} from '../ToolConfigurationView'
import {mockConfiguration, renderApp} from './helpers'
import {
  mockRegistrationWithAllInformation,
  mockSiteAdminRegistration,
  mockNonDynamicRegistration,
} from '../../../manage/__tests__/helpers'
import fetchMock from 'fetch-mock'

describe('Tool Configuration View Launch Settings', () => {
  it('should render the Launch Settings for manual registrations', () => {
    const {getByText} = renderApp({
      n: 'Test App',
      i: 1,
      registration: {
        overlaid_configuration: mockConfiguration({
          redirect_uris: ['http://example.com/redirect_uri_1', 'http://example.com/redirect_uri_2'],
          target_link_uri: 'https://example.com/target_link_uri',
          oidc_initiation_url: 'http://example.com/oidc_initiation_url',
          domain: 'domain.com',
          public_jwk_url: 'http://example.com/public_jwk_url',
          custom_fields: {
            foo: 'bar',
          },
        }),
        manual_configuration_id: ZLtiToolConfigurationId.parse('1'),
      },
    })(<ToolConfigurationView />)

    expect(getByText('Launch Settings')).toBeInTheDocument()
    expect(getByText('https://example.com/target_link_uri')).toBeInTheDocument()

    expect(getByText('http://example.com/redirect_uri_1')).toBeInTheDocument()
    expect(getByText('http://example.com/redirect_uri_2')).toBeInTheDocument()
    expect(getByText('http://example.com/public_jwk_url')).toBeInTheDocument()

    expect(getByText('domain.com')).toBeInTheDocument()
    expect(getByText('foo=bar')).toBeInTheDocument()
  })

  it('should render empty values for manual registrations', () => {
    const {getByText} = renderApp({
      n: 'Test App',
      i: 1,
      registration: {
        overlaid_configuration: mockConfiguration({
          redirect_uris: ['http://example.com/redirect_uri_1', 'http://example.com/redirect_uri_2'],
          target_link_uri: 'https://example.com/target_link_uri',
          oidc_initiation_url: 'http://example.com/oidc_initiation_url',
          public_jwk_url: 'http://example.com/public_jwk_url',
        }),
        manual_configuration_id: ZLtiToolConfigurationId.parse('1'),
      },
    })(<ToolConfigurationView />)

    expect(getByText('Launch Settings')).toBeInTheDocument()
    expect(getByText('No domain configured.')).toBeInTheDocument()
    expect(getByText('No custom fields configured.')).toBeInTheDocument()
  })

  it('should not render the Launch Settings for non-manual registrations', () => {
    const {getByText, queryAllByText} = renderApp({
      n: 'Test App',
      i: 1,
      registration: {
        ims_registration_id: ZLtiImsRegistrationId.parse('1'),
        overlaid_configuration: mockConfiguration({}),
      },
    })(<ToolConfigurationView />)

    expect(getByText('Test App')).toBeInTheDocument()
    expect(queryAllByText('Launch Settings')).toHaveLength(0)
  })
})

describe('Tool Configuration View Permissions', () => {
  it('should render an empty permissions list', () => {
    const {getByText, queryAllByText, getByTestId} = renderApp({
      n: 'Test App',
      i: 1,
      configuration: {
        scopes: [],
      },
    })(<ToolConfigurationView />)
    expect(getByTestId('permissions')).toHaveTextContent('This app has no permissions configured.')
  })

  it('should render the permissions list', () => {
    const {getByText} = renderApp({
      n: 'Test App',
      i: 1,
      registration: {
        ims_registration_id: ZLtiImsRegistrationId.parse('1'),
        overlaid_configuration: mockConfiguration({
          scopes: Array.from(AllLtiScopes),
        }),
      },
    })(<ToolConfigurationView />)

    AllLtiScopes.forEach(scope => {
      expect(getByText(i18nLtiScope(scope))).toBeInTheDocument()
    })
  })
})

describe('Tool Configuration View Data Sharing', () => {
  it.each(AllLtiPrivacyLevels)(
    "should render %p the registration's privacy level",
    privacyLevel => {
      const {getByText} = renderApp({
        n: 'Test App',
        i: 1,
        registration: {
          ims_registration_id: ZLtiImsRegistrationId.parse('1'),
          overlaid_configuration: mockConfiguration({
            privacy_level: privacyLevel,
          }),
        },
      })(<ToolConfigurationView />)

      expect(getByText(i18nLtiPrivacyLevel(privacyLevel))).toBeInTheDocument()
    },
  )
})

describe('Tool Configuration View Placements', () => {
  it.each(AllLtiPlacements)('should render the %p placement', placement => {
    const {getByText} = renderApp({
      n: 'Test App',
      i: 1,
      registration: {
        ims_registration_id: ZLtiImsRegistrationId.parse('1'),
        overlaid_configuration: mockConfiguration({
          placements: [
            {
              placement,
              enabled: true,
              text: 'Test Placement',
            },
          ],
        }),
      },
    })(<ToolConfigurationView />)

    expect(getByText(i18nLtiPlacement(placement))).toBeInTheDocument()
  })

  it.each(AllLtiPlacements)('should not render a disabled %p placement', placement => {
    const {queryAllByText} = renderApp({
      n: 'Test App',
      i: 1,
      registration: {
        ims_registration_id: ZLtiImsRegistrationId.parse('1'),
        overlaid_configuration: mockConfiguration({
          placements: [
            {
              placement,
              enabled: false,
              text: 'Test Placement',
            },
          ],
        }),
      },
    })(<ToolConfigurationView />)

    expect(queryAllByText(i18nLtiPlacement(placement))).toHaveLength(0)
  })
})

describe('Tool Configuration View Nickname and Description', () => {
  it('should render the nickname and description', () => {
    const {getByText} = renderApp({
      n: 'Test App',
      i: 1,
      registration: {
        ims_registration_id: ZLtiImsRegistrationId.parse('1'),
        admin_nickname: 'Test Nickname',
        overlaid_configuration: mockConfiguration({
          description: 'Test Description',
        }),
      },
    })(<ToolConfigurationView />)

    expect(getByText('Test Nickname')).toBeInTheDocument()
    expect(getByText('Test Description')).toBeInTheDocument()
  })

  it.each(AllLtiPlacements)('should render the %p placement name', placement => {
    const {getByText} = renderApp({
      n: 'Test App',
      i: 1,
      registration: {
        ims_registration_id: ZLtiImsRegistrationId.parse('1'),
        overlaid_configuration: mockConfiguration({
          placements: [
            {
              placement,
              enabled: true,
              text: `Test Placement (${placement})`,
            },
          ],
        }),
      },
    })(<ToolConfigurationView />)

    expect(getByText(`Test Placement (${placement})`)).toBeInTheDocument()
  })

  it.each(AllLtiPlacements)('should render no text for a missing %p placement name', placement => {
    const {queryByText} = renderApp({
      n: 'Test App',
      i: 1,
      registration: {
        ims_registration_id: ZLtiImsRegistrationId.parse('1'),
        overlaid_configuration: mockConfiguration({
          placements: [
            {
              placement,
              enabled: true,
            },
          ],
        }),
      },
    })(<ToolConfigurationView />)

    expect(queryByText(`No text`)).toBeInTheDocument()
  })
})

describe('Tool Configuration View Icon Placements', () => {
  const renderIconPlacements = () =>
    renderApp({
      n: 'Test App',
      i: 1,
      registration: {
        ims_registration_id: ZLtiImsRegistrationId.parse('1'),
        overlaid_configuration: mockConfiguration({
          placements: [
            {
              placement: 'course_navigation',
              enabled: true,
              icon_url: 'http://example.com/icon.png',
              text: 'Course Nav',
            },
            {
              placement: 'assignment_index_menu',
              enabled: false,
              text: 'Assignment Index Menu',
            },
            {
              placement: 'editor_button',
              enabled: true,
              text: 'Editor Button',
            },
            {
              placement: 'file_index_menu',
              enabled: true,
              text: 'File Index Menu',
            },
            {
              placement: 'global_navigation',
              enabled: true,
              text: 'Global Navigation',
              icon_url: 'http://example.com/global_nav.png',
            },
          ],
        }),
      },
    })(<ToolConfigurationView />)

  it('should not render icon URLs for non-icon placements', () => {
    const {queryByTestId} = renderIconPlacements()
    expect(queryByTestId('icon-url-course_navigation')).not.toBeInTheDocument()
  })
  it('should not render icons for disabled placements', () => {
    const {queryByTestId} = renderIconPlacements()
    expect(queryByTestId('icon-url-assignment_index_menu')).not.toBeInTheDocument()
  })
  it('should render icons for enabled placements', () => {
    const {getByTestId} = renderIconPlacements()
    expect(getByTestId('icon-url-file_index_menu')).toHaveTextContent('Not Included')
  })
  it('should render icons for enabled placements', () => {
    const {getByTestId} = renderIconPlacements()
    expect(getByTestId('icon-url-global_navigation')).toHaveTextContent(
      'http://example.com/global_nav.png',
    )
  })
  it('should render "Not Included" icons for enabled placements w/o an icon', () => {
    const {getByTestId} = renderIconPlacements()
    expect(getByTestId('icon-url-editor_button')).toHaveTextContent('Default Icon')
  })
})

describe('Tool Configuration Restore Default Button', () => {
  it('should disable the button on a site admin inherited tool', () => {
    const registration = mockSiteAdminRegistration('site admin reg', 1)
    const router = createMemoryRouter([
      {
        path: '*',
        element: (
          <Routes>
            <Route
              path="/"
              element={
                <Outlet
                  context={{
                    registration,
                    refreshRegistration: jest.fn(),
                  }}
                />
              }
            >
              <Route index element={<ToolConfigurationView />} />
            </Route>
          </Routes>
        ),
      },
    ])
    const wrapper = render(<RouterProvider router={router} />)

    expect(wrapper.getByText('Restore Default').closest('button')).toHaveAttribute('disabled')
  })

  it('should call the delete endpoint when clicked', async () => {
    fetchMock.put('/api/v1/accounts/1/lti_registrations/1/reset', {
      __type: 'Success',
      data: {},
    })

    const {getByText} = renderApp({
      n: 'Test App',
      i: 1,
      registration: {
        overlaid_configuration: mockConfiguration({
          redirect_uris: ['http://example.com/redirect_uri_1'],
          target_link_uri: 'https://example.com/target_link_uri',
          oidc_initiation_url: 'http://example.com/oidc_initiation_url',
          domain: 'domain.com',
          public_jwk_url: 'http://example.com/public_jwk_url',
          custom_fields: {
            foo: 'bar',
          },
        }),
      },
    })(<ToolConfigurationView />)

    const restoreBtn = getByText('Restore Default').closest('button')
    expect(restoreBtn).not.toHaveAttribute('disabled')
    await clickOrFail(restoreBtn)
    const resetModalBtn = getByText('Reset').closest('button')
    await clickOrFail(resetModalBtn)

    const response = fetchMock.calls()[0]
    const responseUrl = response[0]
    const responseHeaders = response[1]
    expect(responseUrl).toBe('/api/v1/accounts/1/lti_registrations/1/reset')
    expect(responseHeaders).toMatchObject({
      method: 'PUT',
    })
  })
})

describe('Tool Configuration Copy JSON Code button', () => {
  it('renders the button on a non-dynamic-reg tool', () => {
    const registration = mockNonDynamicRegistration('non-dr reg', 1)
    const router = createMemoryRouter([
      {
        path: '*',
        element: (
          <Routes>
            <Route
              path="/"
              element={
                <Outlet
                  context={{
                    registration,
                    refreshRegistration: jest.fn(),
                  }}
                />
              }
            >
              <Route index element={<ToolConfigurationView />} />
            </Route>
          </Routes>
        ),
      },
    ])
    const wrapper = render(<RouterProvider router={router} />)

    expect(wrapper.getByText('Copy JSON Code').closest('button')).toBeInTheDocument()
  })

  it('does not show the Copy JSON Code button for a dynamic reg tool', async () => {
    const {queryByText} = renderApp({
      n: 'Test App',
      i: 1,
      registration: {
        overlaid_configuration: mockConfiguration({
          redirect_uris: ['http://example.com/redirect_uri_1'],
          target_link_uri: 'https://example.com/target_link_uri',
          oidc_initiation_url: 'http://example.com/oidc_initiation_url',
          domain: 'domain.com',
          public_jwk_url: 'http://example.com/public_jwk_url',
          custom_fields: {
            foo: 'bar',
          },
        }),
      },
    })(<ToolConfigurationView />)

    expect(queryByText('Copy JSON Code')).not.toBeInTheDocument()
  })
})
