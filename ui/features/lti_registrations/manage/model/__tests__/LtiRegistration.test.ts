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

import {ZLtiLegacyConfiguration} from '../LtiRegistration'
import _ from 'lodash'

describe('LtiRegistration', () => {
  describe('ZLtiLegacyConfiguration', () => {
    // The test data in this file reflects the format of the
    // LTI tools that I have installed locally right now -- there
    // are more than two possible variants of a valid legacy configuration,
    // but most of mine fit one of these two formats.
    const baseConfig = {
      title: "doesn't specify analytics hub",
      custom_fields: {},
      target_link_uri: 'https://example.com/api/registrations/5/launch',
      oidc_initiation_url: 'https://example.com/api/registrations/5/login',
      public_jwk_url: 'https://example.com/api/registrations/5/jwks',
      scopes: [
        'https://purl.imsglobal.org/spec/lti-ags/scope/lineitem',
        'https://purl.imsglobal.org/spec/lti-ags/scope/lineitem.readonly',
        'https://purl.imsglobal.org/spec/lti-ags/scope/result.readonly',
      ],
      extensions: [
        {
          domain: 'example.com',
          privacy_level: 'public',
          platform: 'canvas.instructure.com',
          settings: {
            icon_url: 'https://example.com/api/apps/3/icon.svg',
            text: "doesn't specify analytics hub",
            placements: [
              {
                placement: 'global_navigation',
                enabled: true,
                message_type: 'LtiResourceLinkRequest',
                text: "doesn't specify analytics hub (Global Navigation)",
                icon_url: 'https://example.com/api/apps/3/icon.svg',
                target_link_uri:
                  'https://example.com/api/registrations/5/launch?placement=https://canvas.instructure.com/lti/global_navigation',
              },
            ],
          },
        },
      ],
    }

    it('should allow the fields in a legacy configuration', () => {
      const legacyConfig = _.merge(baseConfig, {
        extensions: [
          {
            settings: {
              placements: [
                {
                  custom_fields: {
                    foo: 'bar',
                    context_id: '$Context.id',
                  },
                },
              ],
            },
          },
        ],
      })

      const result = ZLtiLegacyConfiguration.parse(legacyConfig)
      expect(result).toMatchObject(legacyConfig)
    })

    it('should allow a different configuration with a tool_id', () => {
      const legacyConfig = _.merge(baseConfig, {
        extensions: [
          {
            settings: {
              placements: [
                {
                  canvas_icon_class: 'icon-lti',
                },
              ],
              selection_width: 500,
              selection_height: 500,
            },
            tool_id: 'Tool install name',
          },
        ],
        oidc_initiation_urls: {},
        public_jwk: {
          alg: 'RS256',
          e: 'AQAB',
          kid: 'H29tJEF2lqeV8zEZ53hZqAl6CRUbW9kcB54_nrWGSoo',
          kty: 'RSA',
          n: '7hvQ0KNDznSAhAY3DPV_o-WVDMP5kUwUALsegTEaffznOBkZjJOYM7kTel2FwutMm9ZsZXfqld2RWLUjpon6fTBIsM2voFbpSJ3-DDnQgYN0FuVWNWmi4hH2u_vOcl7W-cygX-BSslHAuBsfs-OMWVn3sX7un9badWd4hL4glwvYrCXKs6gOTl04i4juXlCoxmzrRubW3JQYghBffrnILaZxWi9uje_AP7nbAgltpaeL0amXhhdj9q6OtCJ3ezujyjUYkyAEGgQfZDPORJGprPbyGAzPMJxcIBduiBQXBcJPrTSy9CkLZ0mpY-4gnlOvb10Qj9SQj__jWZIjyTWS4Q',
          use: 'sig',
        },
        public_jwk_url: null,
      })

      const result = ZLtiLegacyConfiguration.parse(legacyConfig)
      expect(result).toMatchObject(legacyConfig)
    })

    it('allows placement-specific settings', () => {
      const extraPlacement = {
        placement: 'ActivityAssetProcessor',
        eula: {
          target_link_uri: 'https://example.com/123',
          custom_fields: {foo: 'bar'},
        },
      }
      const placements = [{}, extraPlacement]
      const legacyConfig = _.merge(baseConfig, {extensions: [{settings: {placements}}]})
      const result = ZLtiLegacyConfiguration.parse(legacyConfig)
      expect(result).toMatchObject(legacyConfig)
    })
  })
})
