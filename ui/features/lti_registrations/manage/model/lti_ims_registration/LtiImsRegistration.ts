/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import * as z from 'zod'
import {ZLtiScope} from '../LtiScope'
import {ZRegistrationOverlay} from '../RegistrationOverlay'
import {ZLtiConfiguration} from '../lti_tool_configuration/LtiConfiguration'
import {ZLtiImsToolConfiguration} from './LtiImsToolConfiguration'
import {ZLtiImsRegistrationId} from './LtiImsRegistrationId'
import {ZDeveloperKeyId} from '../developer_key/DeveloperKeyId'
import {ZLtiRegistrationId} from '../LtiRegistrationId'

export const ZLtiImsRegistration = z.object({
  id: ZLtiImsRegistrationId,
  lti_tool_configuration: ZLtiImsToolConfiguration,
  lti_registration_id: ZLtiRegistrationId,
  developer_key_id: ZDeveloperKeyId,
  overlay: ZRegistrationOverlay.optional().nullable(),
  application_type: z.string().optional().nullable(),
  grant_types: z.array(z.string()),
  response_types: z.array(z.string()),
  redirect_uris: z.array(z.string()),
  initiate_login_uri: z.string(),
  client_name: z.string(),
  jwks_uri: z.string(),
  logo_uri: z.string().optional().nullable(),
  token_endpoint_auth_method: z.string(),
  contacts: z.array(z.string()).optional().nullable(),
  client_uri: z.string().optional().nullable(),
  policy_uri: z.string().optional().nullable(),
  tos_uri: z.string().optional().nullable(),
  scopes: z.array(ZLtiScope),
  created_at: z.string(),
  updated_at: z.string(),
  guid: z.string(),
  /**
   * Tool configuration with overlay applied
   */
  tool_configuration: ZLtiConfiguration,
  /**
   * The configuration without the overlay applied
   */
  default_configuration: ZLtiConfiguration,
})

export interface LtiImsRegistration extends z.infer<typeof ZLtiImsRegistration> {}
