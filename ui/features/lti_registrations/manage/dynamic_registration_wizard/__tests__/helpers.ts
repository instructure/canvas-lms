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

import {LtiScopes} from '../../model/LtiScope'
import {ZDeveloperKeyId} from '../../model/developer_key/DeveloperKeyId'
import type {LtiImsRegistration} from '../../model/lti_ims_registration/LtiImsRegistration'
import {ZLtiImsRegistrationId} from '../../model/lti_ims_registration/LtiImsRegistrationId'
import type {LtiImsToolConfiguration} from '../../model/lti_ims_registration/LtiImsToolConfiguration'
import type {LtiConfiguration} from '../../model/lti_tool_configuration/LtiConfiguration'

export const mockToolConfiguration = (config?: Partial<LtiConfiguration>): LtiConfiguration => ({
  title: '',
  target_link_uri: '',
  oidc_initiation_url: '',
  custom_fields: {},
  is_lti_key: true,
  scopes: [],
  extensions: [],
  ...config,
})

export const mockRegistration = (
  reg?: Partial<LtiImsRegistration>,
  config?: Partial<LtiConfiguration>
): LtiImsRegistration => ({
  id: ZLtiImsRegistrationId.parse('1'),
  lti_tool_configuration: {
    claims: [],
    domain: '',
    messages: [],
    target_link_uri: '',
    'https://canvas.instructure.com/lti/privacy_level': 'anonymous',
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
  scopes: [...Object.values(LtiScopes)],
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
