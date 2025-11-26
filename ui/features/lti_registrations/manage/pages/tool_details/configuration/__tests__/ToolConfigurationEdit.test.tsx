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
import {ZLtiImsRegistrationId} from '../../../../model/lti_ims_registration/LtiImsRegistrationId'
import {ZLtiToolConfigurationId} from '../../../../model/lti_tool_configuration/LtiToolConfigurationId'
import {ToolConfigurationEdit} from '../ToolConfigurationEdit'
import {mockConfiguration, mockOverlay, renderApp} from './helpers'
import {i18nLtiScope} from '@canvas/lti/model/i18nLtiScope'
import {i18nLtiPrivacyLevel} from '../../../../model/i18nLtiPrivacyLevel'
import {getInputIdForField} from '../../../../registration_overlay/validateLti1p3RegistrationOverlayState'
import * as ue from '@testing-library/user-event'
import {Lti1p3RegistrationOverlayState} from 'features/lti_registrations/manage/registration_overlay/Lti1p3RegistrationOverlayState'
import {LtiScopes} from '@canvas/lti/model/LtiScope'
import {LtiPlacements} from '../../../../model/LtiPlacement'
import fakeENV from '@canvas/test-utils/fakeENV'

// Mock use-debounce to provide a flush method
jest.mock('use-debounce', () => ({
  useDebouncedCallback: (callback: any) => {
    const debouncedFn = (...args: any[]) => callback(...args)
    debouncedFn.flush = jest.fn()
    return debouncedFn
  },
}))

const userEvent = ue.userEvent.setup({advanceTimers: jest.advanceTimersByTime})

describe('ToolConfigurationEdit', () => {
  beforeEach(() => {
    jest.resetAllMocks()
    jest.useFakeTimers()
  })

  afterEach(() => {
    jest.runAllTimers()
    jest.useRealTimers()
  })

  describe('Manual Registrations', () => {
    it('should render the Launch Settings', () => {
      const {getByText, container} = renderApp({
        n: 'Test App',
        i: 1,
        configuration: {
          target_link_uri: 'https://example.com/target_link_uri',
          redirect_uris: ['https://example.com/target_link_uri'],
        },
        registration: {
          configuration: mockConfiguration({
            target_link_uri: 'https://example.com/target_link_uri',
            redirect_uris: ['https://example.com/target_link_uri'],
          }),
          overlay: mockOverlay({}, {}),
          manual_configuration_id: ZLtiToolConfigurationId.parse('1'),
        },
      })(<ToolConfigurationEdit />)

      expect(getByText('Launch Settings')).toBeInTheDocument()
      getInputIdForField(`redirectURIs`)

      const element = container.querySelector(`#${getInputIdForField('redirectURIs')}`)
      expect(element).toHaveDisplayValue('https://example.com/target_link_uri')
    })

    it.each([
      ['redirectURIs', 'invalid-url'],
      ['JwkURL', 'invalid-url'],
      ['customFields', 'invalid-custom-fields'],
    ] satisfies [keyof Lti1p3RegistrationOverlayState['launchSettings'], string][])(
      'should focus on the %s field when the form is submitted with an invalid value',
      async (field, _) => {
        const {getByText, container} = renderApp({
          n: 'Test App',
          i: 1,
          configuration: {
            target_link_uri: 'https://example.com/target_link_uri',
            redirect_uris: ['https://example.com/target_link_uri'],
            public_jwk_url: 'https://example.com/public_jwk_url',
          },
          registration: {
            configuration: mockConfiguration({
              target_link_uri: 'https://example.com/target_link_uri',
              redirect_uris: ['https://example.com/target_link_uri'],
              public_jwk_url: 'https://example.com/public_jwk_url',
            }),
            overlay: mockOverlay({}, {}),
            manual_configuration_id: ZLtiToolConfigurationId.parse('1'),
          },
        })(<ToolConfigurationEdit />)

        const element = container.querySelector(`#${getInputIdForField('redirectURIs')}`)
        if (element) {
          await userEvent.click(element)
          await userEvent.clear(element)
          await userEvent.paste('invalid-url')
        } else {
          throw new Error(`Could not find input element for ${field}`)
        }

        const submitBtn = getByText('Update Configuration')
        submitBtn.focus()
        submitBtn.click()

        expect(element).toHaveFocus()
      },
    )
  })

  describe('Non-Manual Registrations', () => {
    it('should not render the Launch Settings', () => {
      const {getByText, queryAllByText} = renderApp({
        n: 'Test App',
        i: 1,
        configuration: {},
        registration: {
          ims_registration_id: ZLtiImsRegistrationId.parse('1'),
          overlaid_configuration: mockConfiguration({}),
        },
      })(<ToolConfigurationEdit />)

      expect(getByText('Permissions')).toBeInTheDocument()
      expect(queryAllByText('Launch Settings')).toHaveLength(0)
    })

    it("should only render the registration's scopes", () => {
      const {getByText, queryAllByText} = renderApp({
        n: 'Test App',
        i: 1,
        configuration: {
          scopes: [
            'https://canvas.instructure.com/lti-ags/progress/scope/show',
            'https://canvas.instructure.com/lti/account_external_tools/scope/list',
          ],
        },
        registration: {
          ims_registration_id: ZLtiImsRegistrationId.parse('1'),
          overlaid_configuration: mockConfiguration({
            scopes: [
              'https://canvas.instructure.com/lti-ags/progress/scope/show',
              'https://canvas.instructure.com/lti/account_external_tools/scope/list',
            ],
          }),
        },
      })(<ToolConfigurationEdit />)

      expect(
        getByText(i18nLtiScope('https://canvas.instructure.com/lti-ags/progress/scope/show')),
      ).toBeInTheDocument()
      expect(
        getByText(
          i18nLtiScope('https://canvas.instructure.com/lti/account_external_tools/scope/list'),
        ),
      ).toBeInTheDocument()

      expect(
        queryAllByText(
          i18nLtiScope('https://canvas.instructure.com/lti/account_external_tools/scope/create'),
        ),
      ).toHaveLength(0)
    })

    it("should only render the registration's placements", () => {
      const {queryAllByTestId, getByTestId} = renderApp({
        n: 'Test App',
        i: 1,
        configuration: {
          placements: [
            {
              placement: 'course_navigation',
              enabled: true,
              icon_url: 'http://example.com/icon.png',
              text: 'Course Nav',
            },
            {
              placement: 'account_navigation',
              enabled: true,
              text: 'Account Nav',
            },
            {
              placement: 'assignment_edit',
              enabled: false,
              text: 'Assignment Edit',
            },
          ],
        },
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
                placement: 'account_navigation',
                enabled: true,
                text: 'Account Nav',
              },
              {
                placement: 'assignment_edit',
                enabled: false,
                text: 'Assignment Edit',
              },
            ],
          }),
        },
      })(<ToolConfigurationEdit />)

      expect(getByTestId(`placement-checkbox-course_navigation`)).toBeInTheDocument()
      expect(getByTestId(`placement-checkbox-account_navigation`)).toBeInTheDocument()
      expect(getByTestId(`placement-checkbox-assignment_edit`)).toBeInTheDocument()
      expect(queryAllByTestId(`placement-checkbox-assignment_group_menu`)).toHaveLength(0)
    })

    it('should not render the override URIs', () => {
      const {queryAllByText} = renderApp({
        n: 'Test App',
        i: 1,
        configuration: {},
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
                placement: 'account_navigation',
                enabled: true,
                text: 'Account Nav',
              },
              {
                placement: 'assignment_edit',
                enabled: false,
                text: 'Assignment Edit',
              },
            ],
          }),
        },
      })(<ToolConfigurationEdit />)

      expect(queryAllByText('Override URIs')).toHaveLength(0)
    })

    describe('when the top_navigation_placement ff is disabled', () => {
      beforeEach(() => {
        fakeENV.setup({
          FEATURES: {
            top_navigation_placement: false,
          },
        })
      })

      afterEach(() => {
        fakeENV.teardown()
      })

      it('should not render top_navigation placement in placements list', () => {
        const {queryAllByTestId} = renderApp({
          n: 'Test App',
          i: 1,
          configuration: {
            placements: [
              {
                placement: 'top_navigation',
                enabled: true,
                icon_url: 'http://example.com/icon.png',
                text: 'Top Nav',
              },
              {
                placement: 'course_navigation',
                enabled: true,
                icon_url: 'http://example.com/icon.png',
                text: 'Course Nav',
              },
            ],
          },
          registration: {
            ims_registration_id: ZLtiImsRegistrationId.parse('1'),
            overlaid_configuration: mockConfiguration({
              placements: [
                {
                  placement: 'top_navigation',
                  enabled: true,
                  icon_url: 'http://example.com/icon.png',
                  text: 'Top Nav',
                },
                {
                  placement: 'course_navigation',
                  enabled: true,
                  icon_url: 'http://example.com/icon.png',
                  text: 'Course Nav',
                },
              ],
            }),
          },
        })(<ToolConfigurationEdit />)

        expect(queryAllByTestId(`placement-checkbox-top_navigation`)).toHaveLength(0)
        expect(queryAllByTestId(`placement-checkbox-course_navigation`)).toHaveLength(1)
      })

      it('should not render top_navigation in icon URLs section', () => {
        const {container} = renderApp({
          n: 'Test App',
          i: 1,
          configuration: {
            placements: [
              {
                placement: 'top_navigation',
                enabled: true,
                icon_url: 'http://example.com/icon.png',
                text: 'Top Nav',
              },
              {
                placement: 'global_navigation',
                enabled: true,
                icon_url: 'http://example.com/icon.png',
                text: 'Global Nav',
              },
            ],
          },
          registration: {
            ims_registration_id: ZLtiImsRegistrationId.parse('1'),
            overlaid_configuration: mockConfiguration({
              placements: [
                {
                  placement: 'top_navigation',
                  enabled: true,
                  icon_url: 'http://example.com/icon.png',
                  text: 'Top Nav',
                },
                {
                  placement: 'global_navigation',
                  enabled: true,
                  icon_url: 'http://example.com/icon.png',
                  text: 'Global Nav',
                },
              ],
            }),
          },
        })(<ToolConfigurationEdit />)

        // Top navigation should not have an icon input field
        expect(
          container.querySelector(`#${getInputIdForField('icon_uri_top_navigation')}`),
        ).not.toBeInTheDocument()
        // Global navigation should have an icon input field
        expect(
          container.querySelector(`#${getInputIdForField('icon_uri_global_navigation')}`),
        ).toBeInTheDocument()
      })

      it('should not render top_navigation in placement names section', () => {
        const {getAllByLabelText} = renderApp({
          n: 'Test App',
          i: 1,
          configuration: {
            placements: [
              {
                placement: 'top_navigation',
                enabled: true,
                text: 'Top Nav',
              },
              {
                placement: 'global_navigation',
                enabled: true,
                icon_url: 'http://example.com/icon.png',
                text: 'Global Nav',
              },
            ],
          },
          registration: {
            ims_registration_id: ZLtiImsRegistrationId.parse('1'),
            overlaid_configuration: mockConfiguration({
              placements: [
                {
                  placement: 'top_navigation',
                  enabled: true,
                  text: 'Top Nav',
                },
                {
                  placement: 'global_navigation',
                  enabled: true,
                  icon_url: 'http://example.com/icon.png',
                  text: 'Global Nav',
                },
              ],
            }),
          },
        })(<ToolConfigurationEdit />)

        // Global Navigation appears in: checkbox, placement name input, and icon input
        const globalNavInputs = getAllByLabelText('Global Navigation')
        expect(globalNavInputs).toHaveLength(3)

        expect(() => getAllByLabelText('Top Navigation')).toThrow()
      })
    })
  })

  it("should render the registration's data sharing setting", () => {
    const {getByText, getByDisplayValue} = renderApp({
      n: 'Test App',
      i: 1,
      configuration: {
        privacy_level: 'email_only',
      },
      registration: {
        ims_registration_id: ZLtiImsRegistrationId.parse('1'),
        overlaid_configuration: mockConfiguration({
          privacy_level: 'email_only',
        }),
      },
    })(<ToolConfigurationEdit />)

    expect(getByText('Data Sharing')).toBeInTheDocument()
    expect(getByDisplayValue(i18nLtiPrivacyLevel('email_only'))).toBeInTheDocument()
  })
})

describe('Tool Configuration Edit EULA Settings', () => {
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
    jest.resetAllMocks()
    jest.useFakeTimers()
  })

  afterEach(() => {
    jest.runAllTimers()
    jest.useRealTimers()
  })

  it('should render EULA settings for manual registrations when feature flag is enabled', () => {
    window.ENV.FEATURES.lti_asset_processor = true

    const {getByText, getByLabelText} = renderApp({
      n: 'Test App',
      i: 1,
      configuration: {
        launch_settings: {
          message_settings: mockEulaMessageSettings,
        },
      },
      registration: {
        configuration: mockConfiguration({
          launch_settings: {
            message_settings: mockEulaMessageSettings,
          },
        }),
        overlay: mockOverlay({}, {}),
        manual_configuration_id: ZLtiToolConfigurationId.parse('1'),
      },
    })(<ToolConfigurationEdit />)

    expect(getByText('EULA Settings')).toBeInTheDocument()
    expect(getByLabelText('Enable EULA Request')).toBeInTheDocument()
    expect(getByLabelText('EULA Target Link URI')).toBeInTheDocument()
    expect(getByLabelText('EULA Custom Fields')).toBeInTheDocument()
  })

  it('should render EULA settings when message settings contain LtiEulaRequest', () => {
    const {getByText} = renderApp({
      n: 'Test App',
      i: 1,
      configuration: {
        launch_settings: {
          message_settings: mockEulaMessageSettings,
        },
      },
      registration: {
        configuration: mockConfiguration({
          launch_settings: {
            message_settings: mockEulaMessageSettings,
          },
        }),
        overlay: mockOverlay({}, {}),
        manual_configuration_id: ZLtiToolConfigurationId.parse('1'),
      },
    })(<ToolConfigurationEdit />)

    expect(getByText('EULA Settings')).toBeInTheDocument()
    expect(getByText('Enable EULA Request')).toBeInTheDocument()
  })

  it('should render EULA settings when tool has EulaUser scope and asset processor placements', () => {
    const {getByText} = renderApp({
      n: 'Test App',
      i: 1,
      configuration: {
        scopes: [LtiScopes.EulaUser],
        placements: [
          {
            placement: LtiPlacements.ActivityAssetProcessor,
            enabled: true,
            text: 'Activity Asset Processor',
          },
        ],
      },
      registration: {
        configuration: mockConfiguration({
          scopes: [LtiScopes.EulaUser],
          placements: [
            {
              placement: LtiPlacements.ActivityAssetProcessor,
              enabled: true,
              text: 'Activity Asset Processor',
            },
          ],
        }),
        overlay: mockOverlay({}, {}),
        manual_configuration_id: ZLtiToolConfigurationId.parse('1'),
      },
    })(<ToolConfigurationEdit />)

    expect(getByText('EULA Settings')).toBeInTheDocument()
  })

  it('should not render EULA settings for non-manual registrations', () => {
    const {queryByText} = renderApp({
      n: 'Test App',
      i: 1,
      configuration: {
        launch_settings: {
          message_settings: mockEulaMessageSettings,
        },
      },
      registration: {
        ims_registration_id: ZLtiImsRegistrationId.parse('1'),
        overlaid_configuration: mockConfiguration({
          launch_settings: {
            message_settings: mockEulaMessageSettings,
          },
        }),
      },
    })(<ToolConfigurationEdit />)

    expect(queryByText('EULA Settings')).not.toBeInTheDocument()
  })

  it('should not render EULA settings when no message settings and no EULA scope/placements', () => {
    const {queryByText} = renderApp({
      n: 'Test App',
      i: 1,
      configuration: {
        // No launch_settings with EULA message settings
        // No scopes that include EulaUser
        // No placements that include ActivityAssetProcessor
      },
      registration: {
        configuration: mockConfiguration({
          // No launch_settings, no EULA-related scopes or placements
        }),
        overlay: mockOverlay({}, {}),
        manual_configuration_id: ZLtiToolConfigurationId.parse('1'),
      },
    })(<ToolConfigurationEdit />)

    expect(queryByText('EULA Settings')).not.toBeInTheDocument()
  })

  it('should show EULA settings in the correct order after Placements', () => {
    const {container} = renderApp({
      n: 'Test App',
      i: 1,
      configuration: {
        target_link_uri: 'https://example.com/target_link_uri',
        redirect_uris: ['https://example.com/target_link_uri'],
        launch_settings: {
          message_settings: mockEulaMessageSettings,
        },
      },
      registration: {
        configuration: mockConfiguration({
          target_link_uri: 'https://example.com/target_link_uri',
          redirect_uris: ['https://example.com/target_link_uri'],
          launch_settings: {
            message_settings: mockEulaMessageSettings,
          },
        }),
        overlay: mockOverlay({}, {}),
        manual_configuration_id: ZLtiToolConfigurationId.parse('1'),
      },
    })(<ToolConfigurationEdit />)

    const sections = container.querySelectorAll('h3')
    const sectionTexts = Array.from(sections).map(section => section.textContent)

    const placementsIndex = sectionTexts.indexOf('Placements')
    const eulaSettingsIndex = sectionTexts.indexOf('EULA Settings')
    const overrideURIsIndex = sectionTexts.indexOf('Override URIs')

    expect(placementsIndex).not.toBe(-1)
    expect(eulaSettingsIndex).not.toBe(-1)
    expect(overrideURIsIndex).not.toBe(-1)
    expect(eulaSettingsIndex).toBeGreaterThan(placementsIndex)
    expect(overrideURIsIndex).toBeGreaterThan(eulaSettingsIndex)
  })
})
