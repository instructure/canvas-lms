/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import {render} from '@testing-library/react'
import React from 'react'

import {DynamicRegistrationModal} from '../DynamicRegistrationModal'
import {useDynamicRegistrationState} from '../DynamicRegistrationState'
import type {LtiRegistration} from '../../../model/LtiRegistration'
import {createRegistrationOverlayStore} from '../../RegistrationSettings/RegistrationOverlayState'
import type {Configuration} from '../../../model/api/LtiToolConfiguration'

describe('DynamicRegistrationModal', () => {
  let error: (...data: any[]) => void
  let warn: (...data: any[]) => void

  beforeAll(() => {
    // instui logs an error when we render a component
    // immediately under Modal

    // eslint-disable-next-line no-console
    error = console.error
    // eslint-disable-next-line no-console
    warn = console.warn

    // eslint-disable-next-line no-console
    console.error = jest.fn()
    // eslint-disable-next-line no-console
    console.warn = jest.fn()
  })

  afterAll(() => {
    // eslint-disable-next-line no-console
    console.error = error
    // eslint-disable-next-line no-console
    console.warn = warn
  })

  describe('default export', () => {
    const store = {
      dispatch: jest.fn(),
    }
    it('opens the modal', async () => {
      useDynamicRegistrationState.getState().open()
      const component = render(<DynamicRegistrationModal contextId="1" store={store as any} />)
      const urlInput = await component.findByTestId('dynamic-reg-modal-url-input')
      expect(urlInput).toBeInTheDocument()
    })

    it('forwards users to the tool', async () => {
      useDynamicRegistrationState.getState().open('http://localhost?foo=bar')
      useDynamicRegistrationState.getState().loadingRegistrationToken()
      useDynamicRegistrationState.getState().register('1', {
        oidc_configuration_url: 'http://canvas.instructure.com',
        token: 'abc',
        uuid: '123',
      })
      const component = render(<DynamicRegistrationModal contextId="1" store={store as any} />)
      const iframe = await component.findByTestId('dynamic-reg-modal-iframe')
      expect(iframe).toBeInTheDocument()
      expect(iframe).toHaveAttribute(
        'src',
        'http://localhost/?foo=bar&openid_configuration=http%3A%2F%2Fcanvas.instructure.com&registration_token=abc'
      )
    })

    it('brings up the confirmation screen', async () => {
      const tool_configuration: Configuration = {
        custom_fields: {},
        description: 'test',
        icon_url: 'http://localhost',
        is_lti_key: true,
        oidc_initiation_url: 'http://localhost',
        public_jwk_url: 'http://localhost',
        scopes: [],
        extensions: [
          {
            platform: 'canvas.instructure.com',
            settings: {
              text: 'Lti Tool',
              icon_url: 'http://localhost',
              placements: [
                {
                  enabled: true,
                  icon_url: 'http://localhost',
                  message_type: 'LtiDeepLinkingRequest',
                  placement: 'course_navigation',
                  target_link_uri: 'http://localhost',
                  text: 'test',
                },
              ],
            },
          },
        ],
        title: 'test',
        target_link_uri: 'http://localhost',
      }
      const registration: LtiRegistration = {
        application_type: 'web',
        client_name: 'test',
        client_uri: 'http://localhost',
        contacts: [],
        grant_types: ['implicit'],
        jwks_uri: 'http://localhost',
        logo_uri: 'http://localhost',
        policy_uri: 'http://localhost',
        redirect_uris: ['http://localhost'],
        created_at: '2023-01-01T00:00:00Z',
        updated_at: '2023-01-01T00:00:00Z',
        developer_key_id: '2',
        guid: '123',
        id: '1',
        initiate_login_uri: 'http://localhost',
        lti_tool_configuration: {
          claims: [],
          domain: 'localhost',
          messages: [
            {
              custom_parameters: {},
              placements: ['global_navigation'],
              type: 'LtiResourceLinkRequest',
              target_link_uri: 'http://localhost/global',
              label: 'Lti Tool (Global)',
              roles: [],
              icon_uri: 'http://localhost/icon.jpg',
            },
          ],
          target_link_uri: 'http://localhost',
        },
        tool_configuration,
        default_configuration: tool_configuration,
        overlay: null,
        response_types: ['id_token'],
        scopes: [],
        token_endpoint_auth_method: 'none',
        tos_uri: null,
      }

      const overlayStore = createRegistrationOverlayStore(registration.client_name, registration)

      useDynamicRegistrationState.getState().confirm(registration, overlayStore)
      const component = render(<DynamicRegistrationModal contextId="1" store={store as any} />)

      const enableAndCloseButton = await component.findByTestId(
        'dynamic-reg-modal-enable-and-close-button'
      )
      expect(enableAndCloseButton).toBeInTheDocument()

      const confirmationScreen = await component.findByTestId('dynamic-reg-modal-confirmation')
      expect(confirmationScreen).toBeInTheDocument()
    })
  })
})
