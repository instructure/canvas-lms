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
import {ZDeveloperKeyAccountBinding} from './DeveloperKeyAccountBinding'
import {ZDeveloperKeyId} from './DeveloperKeyId'
import * as z from 'zod'
import {ZLtiScope} from '../LtiScope'
import {ZLtiConfiguration} from '../lti_tool_configuration/LtiConfiguration'
import {ZLtiImsRegistration} from '../lti_ims_registration/LtiImsRegistration'

export const ZDeveloperKey = z.object({
  id: ZDeveloperKeyId,
  access_token_count: z.number(),
  account_name: z.string(),
  allow_includes: z.boolean(),
  api_key: z.string(),
  created_at: z.string(),
  developer_key_account_binding: ZDeveloperKeyAccountBinding.optional().nullable(),
  scopes: z.array(ZLtiScope),
  inherited_from: ZDeveloperKeyId.optional().nullable(),
  notes: z.string().nullable(),
  icon_url: z.string().nullable(),
  vendor_code: z.string().nullable(),
  redirect_uri: z.string().nullable(),
  redirect_uris: z.string().nullable(),
  public_jwk_url: z.string().nullable(),
  public_jwk: z.string().nullable(),
  email: z.string().nullable(),
  name: z.string().nullable(),
  require_scopes: z.boolean().nullable(),
  tool_configuration: ZLtiConfiguration.optional().nullable(),
  test_cluster_only: z.boolean().optional().nullable(),
  client_credentials_audience: z.string().nullable(),
  is_lti_key: z.boolean(),
  is_lti_registration: z.boolean(),
  lti_registration: ZLtiImsRegistration.optional().nullable(),
})

export interface DeveloperKey extends z.infer<typeof ZDeveloperKey> {}
