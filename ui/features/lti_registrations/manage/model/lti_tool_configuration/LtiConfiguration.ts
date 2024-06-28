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
import * as z from 'zod'
import {ZExtension} from './Extension'
import {ZLtiScope} from '../LtiScope'

export interface LtiConfiguration extends z.infer<typeof ZLtiConfiguration> {}

/**
 * Additional configuration values for an LTI tool.
 */
export const ZLtiConfiguration = z.object({
  title: z.string(),
  description: z.string().optional().nullable(),
  target_link_uri: z.string(),
  oidc_initiation_url: z.string(),
  custom_fields: z.record(z.string()).optional().nullable(),
  oidc_initiation_urls: z.record(z.unknown()).optional().nullable(),
  public_jwk_url: z.string().optional().nullable(),
  is_lti_key: z.boolean().optional().nullable(),
  icon_url: z.string().optional().nullable(),
  scopes: z.array(ZLtiScope),
  extensions: z.array(ZExtension),
})
