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
import {getByTestId, queryAllByText, render} from '@testing-library/react'
import React from 'react'
import {MemoryRouter, Outlet, Route, Routes} from 'react-router-dom'
import {ZLtiImsRegistrationId} from '../../../../model/lti_ims_registration/LtiImsRegistrationId'
import {ZLtiToolConfigurationId} from '../../../../model/lti_tool_configuration/LtiToolConfigurationId'
import {ToolConfigurationEdit} from '../ToolConfigurationEdit'
import {mockConfiguration, mockOverlay, renderApp} from './helpers'
import {i18nLtiPlacement} from '../../../../model/i18nLtiPlacement'
import {i18nLtiScope} from '@canvas/lti/model/i18nLtiScope'
import {i18nLtiPrivacyLevel} from '../../../../model/i18nLtiPrivacyLevel'
import {screen} from '@testing-library/dom'
import {
  getInputIdForField,
  Lti1p3RegistrationOverlayStateErrorField,
} from '../../../../registration_overlay/validateLti1p3RegistrationOverlayState'
import * as ue from '@testing-library/user-event'
import {Lti1p3RegistrationOverlayState} from 'features/lti_registrations/manage/registration_overlay/Lti1p3RegistrationOverlayState'
import {LtiPlacement} from 'features/developer_keys_v2/model/LtiPlacements'

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
      const updateLtiRegistration = jest.fn()
      const {getByText, getByTestId, container} = renderApp({
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
      })(<ToolConfigurationEdit updateLtiRegistration={updateLtiRegistration} />)

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
      async (field, value) => {
        const updateLtiRegistration = jest.fn()
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
        })(<ToolConfigurationEdit updateLtiRegistration={updateLtiRegistration} />)

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
      const updateLtiRegistration = jest.fn()
      const {getByText, queryAllByText, container} = renderApp({
        n: 'Test App',
        i: 1,
        configuration: {},
        registration: {
          ims_registration_id: ZLtiImsRegistrationId.parse('1'),
          overlaid_configuration: mockConfiguration({}),
        },
      })(<ToolConfigurationEdit updateLtiRegistration={updateLtiRegistration} />)

      expect(getByText('Permissions')).toBeInTheDocument()
      expect(queryAllByText('Launch Settings')).toHaveLength(0)
    })

    it("should only render the registration's scopes", () => {
      const updateLtiRegistration = jest.fn()
      const {getByText, getAllByText, queryAllByText} = renderApp({
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
      })(<ToolConfigurationEdit updateLtiRegistration={updateLtiRegistration} />)

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
      const updateLtiRegistration = jest.fn()
      const {getByText, queryAllByTestId, getByTestId} = renderApp({
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
      })(<ToolConfigurationEdit updateLtiRegistration={updateLtiRegistration} />)

      expect(getByTestId(`placement-checkbox-course_navigation`)).toBeInTheDocument()
      expect(getByTestId(`placement-checkbox-account_navigation`)).toBeInTheDocument()
      expect(getByTestId(`placement-checkbox-assignment_edit`)).toBeInTheDocument()
      expect(queryAllByTestId(`placement-checkbox-assignment_group_menu`)).toHaveLength(0)
    })

    it('should not render the override URIs', () => {
      const updateLtiRegistration = jest.fn()
      const {getByText, queryAllByText} = renderApp({
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
      })(<ToolConfigurationEdit updateLtiRegistration={updateLtiRegistration} />)

      expect(queryAllByText('Override URIs')).toHaveLength(0)
    })
  })

  it("should render the registration's data sharing setting", () => {
    const updateLtiRegistration = jest.fn()
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
    })(<ToolConfigurationEdit updateLtiRegistration={updateLtiRegistration} />)

    expect(getByText('Data Sharing')).toBeInTheDocument()
    expect(getByDisplayValue(i18nLtiPrivacyLevel('email_only'))).toBeInTheDocument()
  })
})
