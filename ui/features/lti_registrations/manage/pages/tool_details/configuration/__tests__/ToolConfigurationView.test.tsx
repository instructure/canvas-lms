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
import {clickOrFail} from '../../../__tests__/interactionHelpers'
import {createMemoryRouter, Outlet, Route, Routes, useNavigate} from 'react-router-dom'
import {AllLtiPlacements} from '../../../../model/LtiPlacement'
import {AllLtiPrivacyLevels} from '../../../../model/LtiPrivacyLevel'
import {i18nLtiPlacement} from '../../../../model/i18nLtiPlacement'
import {i18nLtiPrivacyLevel} from '../../../../model/i18nLtiPrivacyLevel'
import {ZLtiImsRegistrationId} from '../../../../model/lti_ims_registration/LtiImsRegistrationId'
import {ZLtiToolConfigurationId} from '../../../../model/lti_tool_configuration/LtiToolConfigurationId'
import {ToolConfigurationView} from '../ToolConfigurationView'
import {mockConfiguration, renderApp} from './helpers'
import {
  mockSiteAdminRegistration,
  mockNonDynamicRegistration,
  mockRegistrationWithAllInformation,
} from '../../../manage/__tests__/helpers'
import fetchMock from 'fetch-mock'
import fakeENV from '@canvas/test-utils/fakeENV'
import {userEvent} from '@testing-library/user-event'
import {fireEvent} from '@testing-library/react'

vi.mock('react-router-dom', async () => {
  const actual = await vi.importActual('react-router-dom')
  return {
    ...actual,
    useNavigate: vi.fn(),
  }
})

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
  beforeEach(() => {
    fakeENV.setup({
      FEATURES: {
        top_navigation_placement: true,
        lti_asset_processor: true,
        lti_asset_processor_discussions: true,
      },
    })
  })

  afterEach(() => {
    fakeENV.teardown()
  })

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

  describe('when top_navigation feature flag is disabled', () => {
    const allLtiPlacements = AllLtiPlacements.filter(p => p !== 'top_navigation')

    it('should not render top_navigation placement', () => {
      fakeENV.setup({
        FEATURES: {
          top_navigation_placement: false,
        },
      })
      const {queryAllByText} = renderApp({
        n: 'Test App',
        i: 1,
        registration: {
          ims_registration_id: ZLtiImsRegistrationId.parse('1'),
          overlaid_configuration: mockConfiguration({
            placements: [
              {
                placement: 'top_navigation',
                enabled: true,
                text: 'Top Navigation',
              },
              {
                placement: 'course_navigation',
                enabled: true,
                text: 'Course Navigation',
              },
            ],
          }),
        },
      })(<ToolConfigurationView />)

      // top_navigation should be filtered out
      expect(queryAllByText(i18nLtiPlacement('top_navigation'))).toHaveLength(0)
      // course_navigation should still be visible
      expect(queryAllByText(i18nLtiPlacement('course_navigation')).length).toBeGreaterThan(0)
    })

    it('should render top_navigation placement', () => {
      fakeENV.setup({
        FEATURES: {
          top_navigation_placement: true,
        },
      })

      const {queryAllByText} = renderApp({
        n: 'Test App',
        i: 1,
        registration: {
          ims_registration_id: ZLtiImsRegistrationId.parse('1'),
          overlaid_configuration: mockConfiguration({
            placements: [
              {
                placement: 'top_navigation',
                enabled: true,
                text: 'Top Navigation',
              },
            ],
          }),
        },
      })(<ToolConfigurationView />)

      // top_navigation should be visible
      expect(queryAllByText(i18nLtiPlacement('top_navigation')).length).toBeGreaterThan(0)
    })
  })
})

describe('Tool Configuration View Nickname and Description', () => {
  beforeEach(() => {
    fakeENV.setup({
      FEATURES: {
        top_navigation_placement: true,
        lti_asset_processor: true,
        lti_asset_processor_discussions: true,
      },
    })
  })

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

  describe('when the top_navigation_placement ff is disabled', () => {
    beforeEach(() => {
      fakeENV.setup({
        FEATURES: {
          top_navigation_placement: false,
        },
      })
    })

    it('should not render top_navigation placement name', () => {
      const {queryByText} = renderApp({
        n: 'Test App',
        i: 1,
        registration: {
          ims_registration_id: ZLtiImsRegistrationId.parse('1'),
          overlaid_configuration: mockConfiguration({
            placements: [
              {
                placement: 'top_navigation',
                enabled: true,
                text: 'Test Placement (top_navigation)',
              },
            ],
          }),
        },
      })(<ToolConfigurationView />)

      expect(queryByText('Test Placement (top_navigation)')).not.toBeInTheDocument()
    })
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

describe('Tool Configuration View Tool Icon URL', () => {
  it('should render message when no default icon URL is configured', () => {
    const {getByText} = renderApp({
      n: 'Test App',
      i: 1,
      registration: {
        ims_registration_id: ZLtiImsRegistrationId.parse('1'),
        overlaid_configuration: mockConfiguration({
          launch_settings: {},
        }),
      },
    })(<ToolConfigurationView />)

    expect(getByText('Tool Icon URL')).toBeInTheDocument()
    expect(getByText('No tool icon URL configured.')).toBeInTheDocument()
  })

  it('should render both the tool icon URL and placement-specific icons', () => {
    const {getByText, getByTestId} = renderApp({
      n: 'Test App',
      i: 1,
      registration: {
        ims_registration_id: ZLtiImsRegistrationId.parse('1'),
        overlaid_configuration: mockConfiguration({
          launch_settings: {
            icon_url: 'http://example.com/default-icon.png',
          },
          placements: [
            {
              placement: 'editor_button',
              enabled: true,
              text: 'Editor Button',
              icon_url: 'http://example.com/editor-icon.png',
            },
          ],
        }),
      },
    })(<ToolConfigurationView />)

    expect(getByText('Tool Icon URL')).toBeInTheDocument()
    expect(getByText('http://example.com/default-icon.png')).toBeInTheDocument()
    expect(getByText('Placement Icon URLs')).toBeInTheDocument()
    expect(getByTestId('icon-url-editor_button')).toHaveTextContent(
      'http://example.com/editor-icon.png',
    )
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
                    refreshRegistration: vi.fn(),
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
    const wrapper = renderApp({
      n: 'Test App',
      i: 1,
      registration: mockSiteAdminRegistration('site admin reg', 1),
    })(<ToolConfigurationView />)

    expect(wrapper.getByText('Restore Default').closest('button')).toHaveAttribute('disabled')
  })

  it('should call the delete endpoint when clicked', async () => {
    fetchMock.put(
      '/api/v1/accounts/1/lti_registrations/1/reset',
      mockRegistrationWithAllInformation({
        n: 'Test App',
        i: 1,
      }),
    )

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
                    refreshRegistration: vi.fn(),
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
    const wrapper = renderApp({
      n: 'Test App',
      i: 1,
      registration,
    })(<ToolConfigurationView />)

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

describe('Tool Configuration View EULA Settings', () => {
  const mockEulaMessageSettings = [
    {
      type: 'LtiEulaRequest' as const,
      enabled: true,
      target_link_uri: 'https://example.com/eula',
      custom_fields: {
        eula_field1: 'value1',
        eula_field2: 'value2',
      },
    },
  ]

  beforeEach(() => {
    // Ensure window.ENV exists
    if (!window.ENV) {
      ;(window as any).ENV = {}
    }
    if (!window.ENV.FEATURES) {
      window.ENV.FEATURES = {}
    }
  })

  it('should render EULA settings when feature flag is enabled and message settings are present', () => {
    // Mock the feature flag
    window.ENV.FEATURES.lti_asset_processor = true

    const {getByText} = renderApp({
      n: 'Test App',
      i: 1,
      registration: {
        overlaid_configuration: mockConfiguration({
          launch_settings: {
            message_settings: mockEulaMessageSettings,
          },
        }),
      },
    })(<ToolConfigurationView />)

    expect(getByText('EULA Settings')).toBeInTheDocument()
    expect(getByText('https://example.com/eula')).toBeInTheDocument()
    expect(getByText(/eula_field1=value1/)).toBeInTheDocument()
    expect(getByText(/eula_field2=value2/)).toBeInTheDocument()
  })

  it('should render EULA settings when message settings contain LtiEulaRequest', () => {
    const {getByText} = renderApp({
      n: 'Test App',
      i: 1,
      registration: {
        overlaid_configuration: mockConfiguration({
          launch_settings: {
            message_settings: mockEulaMessageSettings,
          },
        }),
      },
    })(<ToolConfigurationView />)

    expect(getByText('EULA Settings')).toBeInTheDocument()
    expect(getByText('https://example.com/eula')).toBeInTheDocument()
  })

  it('should not render EULA settings when no message settings and no EULA scope/placements', () => {
    const {queryByText} = renderApp({
      n: 'Test App',
      i: 1,
      registration: {
        overlaid_configuration: mockConfiguration({
          // No launch_settings with EULA message settings
          // No scopes that include EulaUser
          // No placements that include ActivityAssetProcessor
        }),
      },
    })(<ToolConfigurationView />)

    expect(queryByText('EULA Settings')).not.toBeInTheDocument()
  })

  it('should render proper labels for EULA settings', () => {
    ;(window as any).ENV = {
      FEATURES: {
        lti_asset_processor: true,
      },
    }

    const {getByText} = renderApp({
      n: 'Test App',
      i: 1,
      registration: {
        overlaid_configuration: mockConfiguration({
          launch_settings: {
            message_settings: mockEulaMessageSettings,
          },
        }),
      },
    })(<ToolConfigurationView />)

    expect(getByText('EULA Settings')).toBeInTheDocument()
    expect(getByText('EULA Target Link URI')).toBeInTheDocument()
    expect(getByText('EULA Custom Fields')).toBeInTheDocument()
  })

  it('should handle empty EULA custom fields', () => {
    ;(window as any).ENV = {
      FEATURES: {
        lti_asset_processor: true,
      },
    }

    const eulaWithoutCustomFields = [
      {
        type: 'LtiEulaRequest' as const,
        enabled: true,
        target_link_uri: 'https://example.com/eula',
        custom_fields: {},
      },
    ]

    const {getByText} = renderApp({
      n: 'Test App',
      i: 1,
      registration: {
        overlaid_configuration: mockConfiguration({
          launch_settings: {
            message_settings: eulaWithoutCustomFields,
          },
        }),
      },
    })(<ToolConfigurationView />)

    expect(getByText('EULA Settings')).toBeInTheDocument()
    expect(getByText('No custom fields configured.')).toBeInTheDocument()
  })
})

describe('Tool Configuration Edit button, keyboard navigation', () => {
  const mockNavigate = vi.fn()

  beforeEach(() => {
    mockNavigate.mockClear()
    vi.mocked(useNavigate).mockReturnValue(mockNavigate)
  })

  it('calls navigate when Edit button is activated with Enter key', async () => {
    const user = userEvent.setup()
    const {getByText} = renderApp({
      n: 'Test App',
      i: 1,
      registration: {
        overlaid_configuration: mockConfiguration({}),
      },
    })(<ToolConfigurationView />)

    const editButton = getByText('Edit').closest('button')!

    await user.type(editButton, '{Enter}')

    // Button should navigate to the edit configuration page
    expect(mockNavigate).toHaveBeenCalledWith('/manage/1/configuration/edit')
  })

  it('calls navigate when Edit button is activated with Space key', async () => {
    const user = userEvent.setup()
    const {getByText} = renderApp({
      n: 'Test App',
      i: 1,
      registration: {
        overlaid_configuration: mockConfiguration({}),
      },
    })(<ToolConfigurationView />)

    const editButton = getByText('Edit').closest('button')!

    await user.type(editButton, '{Space}')

    // Button should navigate to the edit configuration page
    expect(mockNavigate).toHaveBeenCalledWith('/manage/1/configuration/edit')
  })
})
