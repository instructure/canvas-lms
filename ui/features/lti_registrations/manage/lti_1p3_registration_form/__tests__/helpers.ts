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

import type {InternalLtiConfiguration} from '../../model/internal_lti_configuration/InternalLtiConfiguration'
import {LtiScopes} from '@canvas/lti/model/LtiScope'

export const mockInternalConfiguration = (
  overrides?: Partial<InternalLtiConfiguration>,
): InternalLtiConfiguration => {
  return {
    title: 'title',
    description: 'description',
    target_link_uri: 'https://example.com',
    oidc_initiation_url: 'https://example.com/oidc',
    public_jwk_url: 'https://example.com/jwk',
    launch_settings: {
      text: 'Default Title',
    },
    redirect_uris: ['https://example.com/redirect1'],
    oidc_initiation_urls: {},
    privacy_level: 'anonymous',
    tool_id: 'tool_id',
    domain: 'example.com',
    custom_fields: {
      foo: 'bar',
    },
    scopes: [...Object.values(LtiScopes)],
    placements: [{placement: 'course_navigation'}, {placement: 'global_navigation'}],
    ...overrides,
  }
}
