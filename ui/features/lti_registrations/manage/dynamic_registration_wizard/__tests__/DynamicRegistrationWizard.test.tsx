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
import React from 'react'
import {fireEvent, render, screen, waitFor} from '@testing-library/react'
import {ZAccountId} from '../../model/AccountId'
import {DynamicRegistrationWizard} from '../DynamicRegistrationWizard'
import type {DynamicRegistrationWizardService} from '../DynamicRegistrationWizardService'
import {success} from '../../../common/lib/apiResult/ApiResult'
import type {LtiImsRegistration} from '../../model/lti_ims_registration/LtiImsRegistration'
import {ZLtiImsRegistrationId} from '../../model/lti_ims_registration/LtiImsRegistrationId'
import {ZDeveloperKeyId} from '../../model/developer_key/DeveloperKeyId'
import type {LtiConfiguration} from '../../model/lti_tool_configuration/LtiConfiguration'

const mockService = (
  mocked?: Partial<DynamicRegistrationWizardService>
): DynamicRegistrationWizardService => ({
  fetchRegistrationToken: jest.fn(),
  deleteDeveloperKey: jest.fn(),
  getRegistrationByUUID: jest.fn(),
  updateDeveloperKeyWorkflowState: jest.fn(),
  updateRegistrationOverlay: jest.fn(),
  ...mocked,
})

const mockToolConfiguration = (config?: Partial<LtiConfiguration>): LtiConfiguration => ({
  title: '',
  target_link_uri: '',
  oidc_initiation_url: '',
  custom_fields: {},
  is_lti_key: true,
  scopes: [],
  extensions: [],
  ...config,
})

const mockRegistration = (
  reg?: Partial<LtiImsRegistration>,
  config?: LtiConfiguration
): LtiImsRegistration => ({
  id: ZLtiImsRegistrationId.parse('1'),
  lti_tool_configuration: {
    claims: [],
    domain: '',
    messages: [],
    target_link_uri: '',
  },
  developer_key_id: ZDeveloperKeyId.parse('1'),
  overlay: null,
  grant_types: [],
  response_types: [],
  redirect_uris: [],
  initiate_login_uri: '',
  client_name: '',
  jwks_uri: '',
  token_endpoint_auth_method: '',
  contacts: [],
  scopes: [],
  created_at: '',
  updated_at: '',
  guid: '',
  /**
   * Tool configuration with overlay applied
   */
  tool_configuration: mockToolConfiguration(config),
  /**
   * The configuration without the overlay applied
   */
  default_configuration: mockToolConfiguration(config),
  ...reg,
})

describe('DynamicRegistrationWizard', () => {
  it('forwards users to the tool', async () => {
    const accountId = ZAccountId.parse('123')
    const fetchRegistrationToken = jest.fn().mockResolvedValue(
      success({
        token: 'reg_token_value',
        oidc_configuration_url: 'oidc_config_url_value',
        uuid: 'uuid_value',
      })
    )
    const getRegistrationByUUID = jest.fn().mockResolvedValue(success(mockRegistration()))
    const service = mockService({fetchRegistrationToken, getRegistrationByUUID})

    render(
      <DynamicRegistrationWizard
        dynamicRegistrationUrl="https://example.com?foo=bar"
        service={service}
        accountId={accountId}
        unregister={() => {}}
      />
    )
    expect(fetchRegistrationToken).toHaveBeenCalledWith(accountId)
    const headerText = screen.getByText(/Requesting Token/i)
    expect(headerText).toBeInTheDocument()

    const frame = await waitFor(() => screen.getByTestId('dynamic-reg-wizard-iframe'))
    expect(frame).toBeInTheDocument()
    if (frame instanceof HTMLIFrameElement) {
      expect(frame.src).toBe(
        'https://example.com/?foo=bar&openid_configuration=oidc_config_url_value&registration_token=reg_token_value'
      )
    } else {
      throw new Error('frame is not an instance of HTMLIFrameElement')
    }
  })

  it('retrieves the registration when the tool returns', async () => {
    const accountId = ZAccountId.parse('123')
    const fetchRegistrationToken = jest.fn().mockResolvedValue(
      success({
        token: 'reg_token_value',
        oidc_configuration_url: 'oidc_config_url_value',
        uuid: 'uuid_value',
      })
    )
    const getRegistrationByUUID = jest.fn().mockResolvedValue(success(mockRegistration()))
    const service = mockService({fetchRegistrationToken, getRegistrationByUUID})

    const component = render(
      <DynamicRegistrationWizard
        service={service}
        dynamicRegistrationUrl="https://example.com/"
        accountId={accountId}
        unregister={() => {}}
      />
    )

    const iframe = await component.findByTestId('dynamic-reg-wizard-iframe')
    expect(iframe).toBeInTheDocument()
    expect(iframe).toHaveAttribute(
      'src',
      'https://example.com/?openid_configuration=oidc_config_url_value&registration_token=reg_token_value'
    )

    fireEvent(
      window,
      new MessageEvent('message', {
        data: {
          subject: 'org.imsglobal.lti.close',
        },
        origin: 'https://example.com',
      })
    )

    await waitFor(() => screen.getByText(/Loading Registration/i))

    await waitFor(() => screen.findByText(/Permission Confirmation/i))

    expect(getRegistrationByUUID).toHaveBeenCalledWith('123', 'uuid_value')
  })
})
