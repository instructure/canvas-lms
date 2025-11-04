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

import {
  createDiffValue,
  countDiff,
  PlacementChanges,
  NamingDiff,
  diffConfigChangeEntry,
  diffHistoryEntry,
} from '../differ'
import type {
  ConfigChangeHistoryEntry,
  AvailabilityChangeHistoryEntry,
} from '../../../../model/LtiRegistrationHistoryEntry'
import type {AvailabilityChangeEntryWithDiff} from '../differ'
import {ZLtiRegistrationHistoryEntryId} from '../../../../model/LtiRegistrationHistoryEntry'
import {ZAccountId} from '../../../../model/AccountId'
import {ZLtiRegistrationId} from '../../../../model/LtiRegistrationId'
import {ZLtiContextControlId} from '../../../../model/LtiContextControl'
import {ZCourseId} from '../../../../model/CourseId'
import {ZLtiDeploymentId} from '../../../../model/LtiDeploymentId'
import type {LtiDeployment} from '../../../../model/LtiDeployment'
import type {InternalLtiConfiguration} from '../../../../model/internal_lti_configuration/InternalLtiConfiguration'
import {mockToolConfiguration} from '../../../../dynamic_registration_wizard/__tests__/helpers'
import {LtiPlacements} from '../../../../model/LtiPlacement'
import {mockDeployment} from '../../../manage/__tests__/helpers'
import {mockContextControl} from '../../availability/__tests__/helpers'

export const createMockConfigEntry = (
  oldConfig: Partial<InternalLtiConfiguration>,
  newConfig: Partial<InternalLtiConfiguration>,
): ConfigChangeHistoryEntry => ({
  id: ZLtiRegistrationHistoryEntryId.parse('1'),
  root_account_id: ZAccountId.parse('1'),
  lti_registration_id: ZLtiRegistrationId.parse('1'),
  created_at: new Date(),
  updated_at: new Date(),
  diff: {},
  update_type: 'manual_edit',
  comment: null,
  created_by: 'Instructure',
  old_configuration: {
    internal_config: mockToolConfiguration(oldConfig),
    developer_key: {
      email: null,
      name: 'Test Key',
      redirect_uri: null,
      redirect_uris: [],
      icon_url: null,
      vendor_code: null,
      public_jwk: null,
      public_jwk_url: null,
      scopes: [],
    },
    registration: {
      admin_nickname: null,
      name: 'Test Tool',
      vendor: 'Test Vendor',
      workflow_state: 'active',
      description: null,
    },
    overlay: {},
    overlaid_internal_config: mockToolConfiguration(oldConfig),
  },
  new_configuration: {
    internal_config: mockToolConfiguration(newConfig),
    developer_key: {
      email: null,
      name: 'Test Key',
      redirect_uri: null,
      redirect_uris: [],
      icon_url: null,
      vendor_code: null,
      public_jwk: null,
      public_jwk_url: null,
      scopes: [],
    },
    registration: {
      admin_nickname: null,
      name: 'Test Tool',
      vendor: 'Test Vendor',
      workflow_state: 'active',
      description: null,
    },
    overlay: {},
    overlaid_internal_config: mockToolConfiguration(newConfig),
  },
})

const createMockAvailabilityEntry = (
  oldDeployments: Array<Partial<LtiDeployment>>,
  newDeployments: Array<Partial<LtiDeployment>>,
): AvailabilityChangeHistoryEntry => {
  return {
    id: ZLtiRegistrationHistoryEntryId.parse('1'),
    root_account_id: ZAccountId.parse('1'),
    lti_registration_id: ZLtiRegistrationId.parse('1'),
    created_at: new Date(),
    updated_at: new Date(),
    diff: {},
    update_type: 'control_edit',
    comment: null,
    created_by: 'Instructure',
    old_controls_by_deployment: oldDeployments.map(mockDeployment),
    new_controls_by_deployment: newDeployments.map(mockDeployment),
  }
}

describe('countDiffValue', () => {
  it('returns 0 additions and 0 removals for null or undefined', () => {
    expect(countDiff(null)).toEqual({additions: 0, removals: 0})
    expect(countDiff(undefined)).toEqual({additions: 0, removals: 0})
  })

  it('counts 1 addition and 1 removal when both values are not nullish', () => {
    expect(countDiff(createDiffValue('old', 'new'))).toEqual({additions: 1, removals: 1})
  })

  it('counts only addition when oldValue is nullish and newValue is truthy', () => {
    expect(countDiff(createDiffValue(null, 'new'))).toEqual({additions: 1, removals: 0})
    expect(countDiff(createDiffValue(undefined, 'new'))).toEqual({additions: 1, removals: 0})
    expect(countDiff(createDiffValue('', 'new'))).toEqual({additions: 1, removals: 1})
    expect(countDiff(createDiffValue(false, true))).toEqual({additions: 1, removals: 1})
  })

  it('counts only removal when oldValue is truthy and newValue is falsy', () => {
    expect(countDiff(createDiffValue('old', null))).toEqual({additions: 0, removals: 1})
    expect(countDiff(createDiffValue('old', undefined))).toEqual({additions: 0, removals: 1})
    expect(countDiff(createDiffValue('old', ''))).toEqual({additions: 1, removals: 1})
    expect(countDiff(createDiffValue(true, false))).toEqual({additions: 1, removals: 1})
  })
})

describe('diffConfigChangeEntry', () => {
  describe('Internal Config parsing', () => {
    it('returns null if nothing has changed in the internal config', () => {
      const config: Partial<InternalLtiConfiguration> = {
        oidc_initiation_url: 'https://example.com/oidc',
        description: 'Example description',
        title: 'Example title',
        domain: 'example.com',
        placements: [
          {
            placement: 'course_navigation',
            text: 'Some text',
            message_type: 'LtiResourceLinkRequest',
            target_link_uri: 'https://example.com/redirect?placement=course_navigation',
            custom_fields: {
              foo: 'bar',
            },
          },
          {
            placement: 'course_navigation',
            text: 'Some text',
            message_type: 'LtiResourceLinkRequest',
            target_link_uri: 'https://example.com/redirect?placement=course_navigation',
            custom_fields: {
              other: 'fields',
            },
          },
        ],
        launch_settings: {
          target_link_uri: 'https://example.com/redirect',
          custom_fields: {
            foo: 'bar',
          },
        },
      }
      const entry = createMockConfigEntry(
        {
          ...config,
        },
        {
          ...config,
        },
      )

      const result = diffConfigChangeEntry(entry)

      expect(result.internalConfig).toBeNull()
    })

    describe('Launch Settings', () => {
      describe('redirect_uris', () => {
        it('detects when redirect_uris changes', () => {
          const entry = createMockConfigEntry(
            {redirect_uris: ['https://old.example.com/redirect']},
            {
              redirect_uris: [
                'https://new.example.com/redirect',
                'https://new2.example.com/redirect',
              ],
            },
          )

          const result = diffConfigChangeEntry(entry)

          expect(result.internalConfig!.launchSettings!.redirectUris).toEqual({
            added: ['https://new.example.com/redirect', 'https://new2.example.com/redirect'],
            removed: ['https://old.example.com/redirect'],
          })
        })
      })

      describe('target_link_uri', () => {
        it('detects when target_link_uri changes', () => {
          const entry = createMockConfigEntry(
            {target_link_uri: 'https://old.example.com/launch'},
            {target_link_uri: 'https://new.example.com/launch'},
          )

          const result = diffConfigChangeEntry(entry)

          expect(result.internalConfig!.launchSettings!.targetLinkUri).toEqual(
            createDiffValue('https://old.example.com/launch', 'https://new.example.com/launch'),
          )
        })
      })

      describe('oidc_initiation_url', () => {
        it('detects when oidc_initiation_url changes', () => {
          const entry = createMockConfigEntry(
            {oidc_initiation_url: 'https://old.example.com/oidc'},
            {oidc_initiation_url: 'https://new.example.com/oidc'},
          )

          const result = diffConfigChangeEntry(entry)

          expect(result.internalConfig!.launchSettings!.oidcInitiationUrl).toEqual(
            createDiffValue('https://old.example.com/oidc', 'https://new.example.com/oidc'),
          )
        })
      })

      describe('oidc_initiation_urls', () => {
        it('detects when oidc_initiation_urls changes', () => {
          const entry = createMockConfigEntry(
            {
              oidc_initiation_urls: {
                region1: 'https://old.example.com/oidc',
                region2: 'https://removed.example.com/oidc',
              },
            },
            {
              oidc_initiation_urls: {
                region1: 'https://new.example.com/oidc',
                region3: 'https://added.example.com/oidc',
              },
            },
          )

          const result = diffConfigChangeEntry(entry)

          expect(result.internalConfig!.launchSettings!.oidcInitiationUrls).toEqual({
            added: {
              region1: 'https://new.example.com/oidc',
              region3: 'https://added.example.com/oidc',
            },
            removed: {
              region1: 'https://old.example.com/oidc',
              region2: 'https://removed.example.com/oidc',
            },
          })
        })
      })

      describe('public_jwk', () => {
        it('detects when public_jwk changes', () => {
          const oldJwk = {kty: 'RSA', n: 'old-key', e: 'AQAB'}
          const newJwk = {kty: 'RSA', n: 'new-key', e: 'AQAB'}

          const entry = createMockConfigEntry({public_jwk: oldJwk}, {public_jwk: newJwk})

          const result = diffConfigChangeEntry(entry)

          expect(result.internalConfig!.launchSettings!.publicJwk).toEqual(
            createDiffValue(oldJwk, newJwk),
          )
        })

        it('detects when public_jwk changes from null to value', () => {
          const newJwk = {kty: 'RSA', n: 'new-key', e: 'AQAB'}

          const entry = createMockConfigEntry({public_jwk: null}, {public_jwk: newJwk})

          const result = diffConfigChangeEntry(entry)

          expect(result.internalConfig!.launchSettings!.publicJwk).toEqual(
            createDiffValue(null, newJwk),
          )
        })
      })

      describe('public_jwk_url', () => {
        it('detects when public_jwk_url changes', () => {
          const entry = createMockConfigEntry(
            {public_jwk_url: 'https://old.example.com/jwks'},
            {public_jwk_url: 'https://new.example.com/jwks'},
          )

          const result = diffConfigChangeEntry(entry)

          expect(result.internalConfig!.launchSettings!.publicJwkUrl).toEqual(
            createDiffValue('https://old.example.com/jwks', 'https://new.example.com/jwks'),
          )
        })

        it('detects when public_jwk_url changes from null to value', () => {
          const entry = createMockConfigEntry(
            {public_jwk_url: null},
            {public_jwk_url: 'https://new.example.com/jwks'},
          )

          const result = diffConfigChangeEntry(entry)

          expect(result.internalConfig!.launchSettings!.publicJwkUrl).toEqual(
            createDiffValue(null, 'https://new.example.com/jwks'),
          )
        })
      })

      describe('domain', () => {
        it('detects when domain changes', () => {
          const entry = createMockConfigEntry(
            {domain: 'old.example.com'},
            {domain: 'new.example.com'},
          )

          const result = diffConfigChangeEntry(entry)

          expect(result.internalConfig!.launchSettings!.domain).toEqual(
            createDiffValue('old.example.com', 'new.example.com'),
          )
        })

        it('detects when domain changes from null to value', () => {
          const entry = createMockConfigEntry({domain: null}, {domain: 'new.example.com'})

          const result = diffConfigChangeEntry(entry)

          expect(result.internalConfig!.launchSettings!.domain).toEqual(
            createDiffValue(null, 'new.example.com'),
          )
        })
      })

      describe('custom_fields', () => {
        it('detects changes on a key-by-key basis (added, removed, and modified)', () => {
          const entry = createMockConfigEntry(
            {custom_fields: {key1: 'value1', key2: 'value2'}},
            {custom_fields: {key1: 'changed!', key3: 'foobar'}},
          )

          const result = diffConfigChangeEntry(entry)

          expect(result.internalConfig!.launchSettings!.customFields).toEqual({
            added: {key1: 'changed!', key3: 'foobar'},
            removed: {key1: 'value1', key2: 'value2'},
          })
        })
      })

      describe('multiple changes', () => {
        it('detects multiple launch setting changes at once', () => {
          const entry = createMockConfigEntry(
            {
              redirect_uris: ['https://old.example.com/redirect'],
              target_link_uri: 'https://old.example.com/launch',
              domain: 'old.example.com',
            },
            {
              redirect_uris: ['https://new.example.com/redirect'],
              target_link_uri: 'https://new.example.com/launch',
              domain: 'new.example.com',
            },
          )

          const result = diffConfigChangeEntry(entry)

          expect(result.internalConfig!.launchSettings!.redirectUris).toBeDefined()
          expect(result.internalConfig!.launchSettings!.targetLinkUri).toBeDefined()
          expect(result.internalConfig!.launchSettings!.domain).toBeDefined()
          expect(result.internalConfig!.launchSettings!.oidcInitiationUrl).toBeNull()
        })
      })
    })

    describe('Permissions/Scopes', () => {
      describe('added scopes', () => {
        it('detects when scopes are added', () => {
          const entry = createMockConfigEntry(
            {scopes: ['https://purl.imsglobal.org/spec/lti-ags/scope/lineitem']},
            {
              scopes: [
                'https://purl.imsglobal.org/spec/lti-ags/scope/lineitem',
                'https://purl.imsglobal.org/spec/lti-ags/scope/result.readonly',
              ],
            },
          )

          const result = diffConfigChangeEntry(entry)

          expect(result.internalConfig!.permissions).toEqual({
            added: ['https://purl.imsglobal.org/spec/lti-ags/scope/result.readonly'],
            removed: [],
          })
        })

        it('detects when multiple scopes are added', () => {
          const entry = createMockConfigEntry(
            {scopes: []},
            {
              scopes: [
                'https://purl.imsglobal.org/spec/lti-ags/scope/lineitem',
                'https://purl.imsglobal.org/spec/lti-ags/scope/result.readonly',
                'https://purl.imsglobal.org/spec/lti-ags/scope/score',
              ],
            },
          )

          const result = diffConfigChangeEntry(entry)

          expect(result.internalConfig!.permissions).toEqual({
            added: [
              'https://purl.imsglobal.org/spec/lti-ags/scope/lineitem',
              'https://purl.imsglobal.org/spec/lti-ags/scope/result.readonly',
              'https://purl.imsglobal.org/spec/lti-ags/scope/score',
            ],
            removed: [],
          })
        })
      })

      describe('removed scopes', () => {
        it('detects when scopes are removed', () => {
          const entry = createMockConfigEntry(
            {
              scopes: [
                'https://purl.imsglobal.org/spec/lti-ags/scope/lineitem',
                'https://purl.imsglobal.org/spec/lti-ags/scope/result.readonly',
              ],
            },
            {scopes: ['https://purl.imsglobal.org/spec/lti-ags/scope/lineitem']},
          )

          const result = diffConfigChangeEntry(entry)

          expect(result.internalConfig!.permissions).toEqual({
            added: [],
            removed: ['https://purl.imsglobal.org/spec/lti-ags/scope/result.readonly'],
          })
        })

        it('detects when multiple scopes are removed', () => {
          const entry = createMockConfigEntry(
            {
              scopes: [
                'https://purl.imsglobal.org/spec/lti-ags/scope/lineitem',
                'https://purl.imsglobal.org/spec/lti-ags/scope/result.readonly',
                'https://purl.imsglobal.org/spec/lti-ags/scope/score',
              ],
            },
            {scopes: []},
          )

          const result = diffConfigChangeEntry(entry)

          expect(result.internalConfig!.permissions).toEqual({
            added: [],
            removed: [
              'https://purl.imsglobal.org/spec/lti-ags/scope/lineitem',
              'https://purl.imsglobal.org/spec/lti-ags/scope/result.readonly',
              'https://purl.imsglobal.org/spec/lti-ags/scope/score',
            ],
          })
        })
      })

      describe('added and removed scopes', () => {
        it('detects when some scopes are added and others are removed', () => {
          const entry = createMockConfigEntry(
            {
              scopes: [
                'https://purl.imsglobal.org/spec/lti-ags/scope/lineitem',
                'https://purl.imsglobal.org/spec/lti-ags/scope/result.readonly',
              ],
            },
            {
              scopes: [
                'https://purl.imsglobal.org/spec/lti-ags/scope/lineitem',
                'https://purl.imsglobal.org/spec/lti-ags/scope/score',
              ],
            },
          )

          const result = diffConfigChangeEntry(entry)

          expect(result.internalConfig!.permissions).toEqual({
            added: ['https://purl.imsglobal.org/spec/lti-ags/scope/score'],
            removed: ['https://purl.imsglobal.org/spec/lti-ags/scope/result.readonly'],
          })
        })

        it('detects when all scopes are replaced', () => {
          const entry = createMockConfigEntry(
            {
              scopes: [
                'https://purl.imsglobal.org/spec/lti-ags/scope/lineitem',
                'https://purl.imsglobal.org/spec/lti-ags/scope/result.readonly',
              ],
            },
            {
              scopes: [
                'https://purl.imsglobal.org/spec/lti-ags/scope/score',
                'https://purl.imsglobal.org/spec/lti-nrps/scope/contextmembership.readonly',
              ],
            },
          )

          const result = diffConfigChangeEntry(entry)

          expect(result.internalConfig!.permissions).toEqual({
            added: [
              'https://purl.imsglobal.org/spec/lti-ags/scope/score',
              'https://purl.imsglobal.org/spec/lti-nrps/scope/contextmembership.readonly',
            ],
            removed: [
              'https://purl.imsglobal.org/spec/lti-ags/scope/lineitem',
              'https://purl.imsglobal.org/spec/lti-ags/scope/result.readonly',
            ],
          })
        })
      })

      it('handles scopes in different order as unchanged', () => {
        const entry = createMockConfigEntry(
          {
            scopes: [
              'https://purl.imsglobal.org/spec/lti-ags/scope/result.readonly',
              'https://purl.imsglobal.org/spec/lti-ags/scope/lineitem',
            ],
          },
          {
            scopes: [
              'https://purl.imsglobal.org/spec/lti-ags/scope/lineitem',
              'https://purl.imsglobal.org/spec/lti-ags/scope/result.readonly',
            ],
          },
        )

        const result = diffConfigChangeEntry(entry)

        expect(result.internalConfig).toBeNull()
      })

      describe('edge cases', () => {
        it('handles duplicate scopes in old config', () => {
          const entry = createMockConfigEntry(
            {
              scopes: [
                'https://purl.imsglobal.org/spec/lti-ags/scope/lineitem',
                'https://purl.imsglobal.org/spec/lti-ags/scope/lineitem',
              ],
            },
            {
              scopes: ['https://purl.imsglobal.org/spec/lti-ags/scope/lineitem'],
            },
          )

          const result = diffConfigChangeEntry(entry)

          expect(result.internalConfig).toBeNull()
        })

        it('handles duplicate scopes in new config', () => {
          const entry = createMockConfigEntry(
            {
              scopes: ['https://purl.imsglobal.org/spec/lti-ags/scope/lineitem'],
            },
            {
              scopes: [
                'https://purl.imsglobal.org/spec/lti-ags/scope/lineitem',
                'https://purl.imsglobal.org/spec/lti-ags/scope/lineitem',
              ],
            },
          )

          const result = diffConfigChangeEntry(entry)

          expect(result.internalConfig).toBeNull()
        })
      })
    })

    describe('Privacy Level', () => {
      it('detects when privacy_level changes', () => {
        const entry = createMockConfigEntry({privacy_level: 'anonymous'}, {privacy_level: 'public'})

        const result = diffConfigChangeEntry(entry)

        expect(result.internalConfig!.privacyLevel).toEqual(createDiffValue('anonymous', 'public'))
      })
    })

    describe('Placements', () => {
      describe('added placements', () => {
        it('detects when multiple placements are added', () => {
          const entry = createMockConfigEntry(
            {
              placements: [
                {
                  placement: 'course_navigation',
                  enabled: true,
                  message_type: 'LtiResourceLinkRequest',
                },
              ],
            },
            {
              placements: [
                {
                  placement: 'course_navigation',
                  enabled: true,
                  message_type: 'LtiResourceLinkRequest',
                },
                {
                  placement: 'account_navigation',
                  enabled: true,
                  message_type: 'LtiResourceLinkRequest',
                },
                {
                  placement: 'assignment_selection',
                  enabled: true,
                  message_type: 'LtiResourceLinkRequest',
                },
              ],
            },
          )

          const result = diffConfigChangeEntry(entry)

          expect(result.internalConfig!.placements!.added).toEqual(
            expect.arrayContaining(['account_navigation', 'assignment_selection']),
          )
        })

        it("uses 'enabled' when accounting for added placements", () => {
          const entry = createMockConfigEntry(
            {
              placements: [
                {
                  placement: 'course_navigation',
                  enabled: false,
                  message_type: 'LtiResourceLinkRequest',
                },
              ],
            },
            {
              placements: [
                {
                  placement: 'course_navigation',
                  enabled: true,
                  message_type: 'LtiResourceLinkRequest',
                },
              ],
            },
          )

          const result = diffConfigChangeEntry(entry)

          expect(result.internalConfig!.placements!.added).toEqual(['course_navigation'])
        })

        it('treats undefined enabled as no change when changed to true', () => {
          const entry = createMockConfigEntry(
            {
              placements: [
                {
                  placement: 'account_navigation',
                  message_type: 'LtiResourceLinkRequest',
                },
              ],
            },
            {
              placements: [
                {
                  placement: 'account_navigation',
                  enabled: true,
                  message_type: 'LtiResourceLinkRequest',
                },
              ],
            },
          )

          const result = diffConfigChangeEntry(entry)

          expect(result.internalConfig).toBeNull()
        })
      })

      describe('removed placements', () => {
        it('detects when multiple placements are removed', () => {
          const entry = createMockConfigEntry(
            {
              placements: [
                {
                  placement: 'course_navigation',
                  enabled: true,
                  message_type: 'LtiResourceLinkRequest',
                },
                {
                  placement: 'account_navigation',
                  enabled: true,
                  message_type: 'LtiResourceLinkRequest',
                },
                {
                  placement: 'assignment_selection',
                  enabled: true,
                  message_type: 'LtiResourceLinkRequest',
                },
              ],
            },
            {
              placements: [
                {
                  placement: 'course_navigation',
                  enabled: true,
                  message_type: 'LtiResourceLinkRequest',
                },
              ],
            },
          )

          const result = diffConfigChangeEntry(entry)

          expect(result.internalConfig!.placements!.removed).toEqual(
            expect.arrayContaining(['account_navigation', 'assignment_selection']),
          )
        })

        it("uses 'enabled' when accounting for removed placements", () => {
          const entry = createMockConfigEntry(
            {
              placements: [
                {
                  placement: 'course_navigation',
                  enabled: true,
                  message_type: 'LtiResourceLinkRequest',
                },
              ],
            },
            {
              placements: [
                {
                  placement: 'course_navigation',
                  enabled: false,
                  message_type: 'LtiResourceLinkRequest',
                },
              ],
            },
          )

          const result = diffConfigChangeEntry(entry)

          expect(result.internalConfig!.placements!.removed).toEqual(['course_navigation'])
        })

        it('treats undefined enabled as removal when changed to false', () => {
          const entry = createMockConfigEntry(
            {
              placements: [
                {
                  placement: 'account_navigation',
                  message_type: 'LtiResourceLinkRequest',
                },
              ],
            },
            {
              placements: [
                {
                  placement: 'account_navigation',
                  enabled: false,
                  message_type: 'LtiResourceLinkRequest',
                },
              ],
            },
          )

          const result = diffConfigChangeEntry(entry)

          expect(result.internalConfig!.placements!.removed).toEqual(['account_navigation'])
        })
      })

      describe('course navigation default', () => {
        it('detects when course_navigation default changes', () => {
          const entry = createMockConfigEntry(
            {
              placements: [
                {
                  placement: 'course_navigation',
                  enabled: true,
                  message_type: 'LtiResourceLinkRequest',
                  default: 'disabled',
                },
              ],
            },
            {
              placements: [
                {
                  placement: 'course_navigation',
                  enabled: true,
                  message_type: 'LtiResourceLinkRequest',
                  default: 'enabled',
                },
              ],
            },
          )

          const result = diffConfigChangeEntry(entry)

          expect(result.internalConfig!.placements!.courseNavigationDefault).toEqual(
            createDiffValue('disabled', 'enabled'),
          )
        })

        it('detects when course_navigation default is added', () => {
          const entry = createMockConfigEntry(
            {
              placements: [
                {
                  placement: 'course_navigation',
                  enabled: true,
                  message_type: 'LtiResourceLinkRequest',
                },
              ],
            },
            {
              placements: [
                {
                  placement: 'course_navigation',
                  enabled: true,
                  message_type: 'LtiResourceLinkRequest',
                  default: 'enabled',
                },
              ],
            },
          )

          const result = diffConfigChangeEntry(entry)

          expect(result.internalConfig!.placements!.courseNavigationDefault).toEqual(
            createDiffValue(undefined, 'enabled'),
          )
        })

        it('detects when course_navigation default is removed', () => {
          const entry = createMockConfigEntry(
            {
              placements: [
                {
                  placement: 'course_navigation',
                  enabled: true,
                  message_type: 'LtiResourceLinkRequest',
                  default: 'disabled',
                },
              ],
            },
            {
              placements: [
                {
                  placement: 'course_navigation',
                  enabled: true,
                  message_type: 'LtiResourceLinkRequest',
                },
              ],
            },
          )

          const result = diffConfigChangeEntry(entry)

          expect(result.internalConfig!.placements!.courseNavigationDefault).toEqual(
            createDiffValue('disabled', undefined),
          )
        })

        it('does not include courseNavigationDefault when course_navigation is not present', () => {
          const entry = createMockConfigEntry(
            {
              placements: [
                {
                  placement: 'account_navigation',
                  enabled: true,
                  message_type: 'LtiResourceLinkRequest',
                },
              ],
            },
            {
              placements: [
                {
                  placement: 'account_navigation',
                  enabled: true,
                  message_type: 'LtiResourceLinkRequest',
                },
              ],
            },
          )

          const result = diffConfigChangeEntry(entry)

          expect(result.internalConfig).toBeNull()
        })
      })

      describe('override URIs changed', () => {
        it('detects changes for multiple placements across URIs and message_types', () => {
          const entry = createMockConfigEntry(
            {
              placements: [
                {
                  placement: 'course_navigation',
                  enabled: true,
                  message_type: 'LtiResourceLinkRequest',
                  target_link_uri: 'https://old.example.com/course',
                },
                {
                  placement: 'account_navigation',
                  enabled: true,
                  message_type: 'LtiResourceLinkRequest',
                  target_link_uri: 'https://old.example.com/account',
                },
              ],
            },
            {
              placements: [
                {
                  placement: 'course_navigation',
                  enabled: true,
                  message_type: 'LtiDeepLinkingRequest',
                  target_link_uri: 'https://new.example.com/course',
                },
                {
                  placement: 'account_navigation',
                  enabled: true,
                  message_type: 'LtiResourceLinkRequest',
                  target_link_uri: 'https://new.example.com/account',
                },
              ],
            },
          )

          const result = diffConfigChangeEntry(entry)

          expect(
            result.internalConfig!.placements!.placementChanges.get('course_navigation'),
          ).toEqual({
            targetLinkUri: createDiffValue(
              'https://old.example.com/course',
              'https://new.example.com/course',
            ),
            messageType: createDiffValue('LtiResourceLinkRequest', 'LtiDeepLinkingRequest'),
          })

          expect(
            result.internalConfig!.placements!.placementChanges.get('account_navigation'),
          ).toEqual({
            messageType: null,
            targetLinkUri: createDiffValue(
              'https://old.example.com/account',
              'https://new.example.com/account',
            ),
          })
        })

        it('handles a new placement being added', () => {
          const entry = createMockConfigEntry(
            {
              placements: [
                {
                  placement: 'course_navigation',
                  enabled: true,
                  message_type: 'LtiResourceLinkRequest',
                  target_link_uri: 'https://example.com/launch',
                },
              ],
            },
            {
              placements: [
                {
                  placement: 'course_navigation',
                  enabled: true,
                  message_type: 'LtiResourceLinkRequest',
                  target_link_uri: 'https://example.com/launch',
                },
                {
                  placement: 'account_navigation',
                  enabled: true,
                  message_type: 'LtiResourceLinkRequest',
                  target_link_uri: 'https://example.com/account',
                },
              ],
            },
          )

          const result = diffConfigChangeEntry(entry)

          const expected: PlacementChanges = {
            targetLinkUri: createDiffValue(undefined, 'https://example.com/account'),
            messageType: createDiffValue(undefined, 'LtiResourceLinkRequest'),
          }

          expect(
            result.internalConfig!.placements!.placementChanges.get('account_navigation'),
          ).toEqual(expected)
        })

        it('handles a placement being removed', () => {
          const entry = createMockConfigEntry(
            {
              placements: [
                {
                  placement: 'course_navigation',
                  enabled: true,
                  message_type: 'LtiResourceLinkRequest',
                  target_link_uri: 'https://example.com/launch',
                },
                {
                  placement: 'account_navigation',
                  enabled: true,
                  message_type: 'LtiResourceLinkRequest',
                  target_link_uri: 'https://example.com/account',
                },
              ],
            },
            {
              placements: [
                {
                  placement: 'course_navigation',
                  enabled: true,
                  message_type: 'LtiResourceLinkRequest',
                  target_link_uri: 'https://example.com/launch',
                },
              ],
            },
          )

          const result = diffConfigChangeEntry(entry)

          const expected: PlacementChanges = {
            targetLinkUri: createDiffValue('https://example.com/account', undefined),
            messageType: createDiffValue('LtiResourceLinkRequest', undefined),
          }

          expect(
            result.internalConfig!.placements!.placementChanges.get('account_navigation'),
          ).toEqual(expected)
        })
      })
    })

    describe('Naming', () => {
      it('detects when top level attributes change', () => {
        const entry = createMockConfigEntry(
          {title: 'Old Title', description: 'old'},
          {title: 'New Title', description: 'new'},
        )
        entry.old_configuration.registration.name = 'Old Name'
        entry.new_configuration.registration.name = 'New Name'
        entry.old_configuration.registration.admin_nickname = 'Old Nickname'
        entry.new_configuration.registration.admin_nickname = 'New Nickname'

        const result = diffConfigChangeEntry(entry)

        const expected: NamingDiff = {
          adminNickname: createDiffValue('Old Nickname', 'New Nickname'),
          description: createDiffValue('old', 'new'),
          placementTexts: new Map(),
        }

        expect(result.internalConfig!.naming).toEqual(expected)
      })

      describe('placementText', () => {
        it('detects when placement text changes', () => {
          const entry = createMockConfigEntry(
            {
              placements: [{placement: 'course_navigation', text: 'Old Text'}],
            },
            {
              placements: [{placement: 'course_navigation', text: 'New Text'}],
            },
          )

          const result = diffConfigChangeEntry(entry)

          const expected = new Map([['course_navigation', createDiffValue('Old Text', 'New Text')]])

          expect(result.internalConfig!.naming!.placementTexts).toEqual(expected)
        })

        it('detects when placement text is added', () => {
          const entry = createMockConfigEntry(
            {
              placements: [{placement: 'course_navigation'}],
            },
            {
              placements: [{placement: 'course_navigation', text: 'New Text'}],
            },
          )

          const result = diffConfigChangeEntry(entry)

          const expected = new Map([['course_navigation', createDiffValue(undefined, 'New Text')]])

          expect(result.internalConfig!.naming!.placementTexts).toEqual(expected)
        })

        it('detects when placement text is removed', () => {
          const entry = createMockConfigEntry(
            {
              placements: [{placement: 'course_navigation', text: 'Old Text'}],
            },
            {
              placements: [{placement: 'course_navigation'}],
            },
          )

          const result = diffConfigChangeEntry(entry)

          const expected = new Map([['course_navigation', createDiffValue('Old Text', undefined)]])

          expect(result.internalConfig!.naming!.placementTexts).toEqual(expected)
        })
      })

      describe('multiple naming changes', () => {
        it('detects multiple naming changes at once', () => {
          const entry = createMockConfigEntry(
            {
              title: 'Old Title',
              description: 'Old description',
              placements: [
                {placement: 'course_navigation', text: 'Old Text'},
                {placement: 'assignment_selection', text: 'Old Text'},
              ],
            },
            {
              title: 'New Title',
              description: 'New description',
              placements: [
                {placement: 'course_navigation', text: 'New Text'},
                {placement: 'account_navigation', text: 'New Text'},
              ],
            },
          )
          entry.old_configuration.registration.name = 'Old Tool Name'
          entry.new_configuration.registration.name = 'New Tool Name'
          entry.old_configuration.registration.vendor = 'Old Vendor'
          entry.new_configuration.registration.vendor = 'New Vendor'
          entry.old_configuration.registration.admin_nickname = 'Old Nickname'
          entry.new_configuration.registration.admin_nickname = 'New Nickname'

          const result = diffConfigChangeEntry(entry)

          const naming = result.internalConfig!.naming!
          const expected: NamingDiff = {
            adminNickname: createDiffValue('Old Nickname', 'New Nickname'),
            description: createDiffValue('Old description', 'New description'),
            placementTexts: new Map([
              ['course_navigation', createDiffValue('Old Text', 'New Text')],
              ['assignment_selection', createDiffValue('Old Text', undefined)],
              ['account_navigation', createDiffValue(undefined, 'New Text')],
            ]),
          }
          expect(naming).toEqual(expected)
        })
      })
    })

    describe('Icons', () => {
      it('detects top-level icon_url changes', () => {
        const entry = createMockConfigEntry(
          {
            launch_settings: {
              icon_url: 'https://example.com/old-icon.png',
            },
          },
          {
            launch_settings: {
              icon_url: 'https://example.com/new-icon.png',
            },
          },
        )

        const result = diffConfigChangeEntry(entry)

        expect(result.internalConfig!.icons!.iconUrl).toEqual(
          createDiffValue('https://example.com/old-icon.png', 'https://example.com/new-icon.png'),
        )
      })

      it('detects placement icon changes including added/removed placements', () => {
        const entry = createMockConfigEntry(
          {
            placements: [
              {
                placement: 'course_navigation',
                enabled: true,
                icon_url: 'https://example.com/old-course.png',
              },
              {
                placement: 'account_navigation',
                enabled: true,
                icon_url: 'https://example.com/removed.png',
              },
            ],
          },
          {
            placements: [
              {
                placement: 'course_navigation',
                enabled: true,
                icon_url: 'https://example.com/new-course.png',
              },
              {
                placement: 'global_navigation',
                enabled: true,
                icon_url: 'https://example.com/added.png',
              },
            ],
          },
        )

        const result = diffConfigChangeEntry(entry)

        const expectedPlacementIcons = new Map([
          [
            'course_navigation',
            createDiffValue(
              'https://example.com/old-course.png',
              'https://example.com/new-course.png',
            ),
          ],
          ['account_navigation', createDiffValue('https://example.com/removed.png', undefined)],
          ['global_navigation', createDiffValue(undefined, 'https://example.com/added.png')],
        ])

        expect(result.internalConfig!.icons!.placementIcons).toEqual(expectedPlacementIcons)
      })
    })

    describe('Addition and Removal Counting', () => {
      it('correctly counts multiple types of changes in a single entry', () => {
        const entry = createMockConfigEntry(
          {
            target_link_uri: 'https://old.example.com/launch', // 1 removal, 1 addition
            oidc_initiation_url: undefined, // 1 addition
            domain: 'old.example.com', // 1 removal
            title: 'Old Title', // shouldn't affect count
            privacy_level: 'public', // 1 removal, 1 addition
            custom_fields: {key1: 'oldvalue', key2: 'value2'}, // 2 removals, 2 additions
            launch_settings: {
              icon_url: 'https://old.example.com/icon.png', // 1 removal, 1 addition
            },
            placements: [
              {
                placement: LtiPlacements.CourseNavigation,
                enabled: true,
                message_type: 'LtiResourceLinkRequest', // 1 removal, 1 addition
                target_link_uri: 'https://old.example.com/placement', // 1 removal, 1 addition
                default: 'disabled', // 1 removal, 1 addition
              },
              // 2 removals (Change message type, remove placement)
              {
                placement: LtiPlacements.AccountNavigation,
                enabled: true,
                message_type: 'LtiResourceLinkRequest',
              },
            ],
          },
          {
            target_link_uri: 'https://new.example.com/launch',
            oidc_initiation_url: 'https://new.example.com/oidc',
            domain: undefined,
            title: 'New Title',
            privacy_level: 'anonymous',
            custom_fields: {key1: 'newvalue', key3: 'value3'},
            launch_settings: {
              icon_url: 'https://new.example.com/icon.png',
            },
            placements: [
              {
                placement: LtiPlacements.CourseNavigation,
                enabled: true,
                message_type: 'LtiDeepLinkingRequest',
                target_link_uri: 'https://new.example.com/placement',
                default: 'enabled',
              },
            ],
          },
        )

        const result = diffConfigChangeEntry(entry)

        expect(result.totalAdditions).toBe(9)
        expect(result.totalRemovals).toBe(11)
      })

      // We already add the added/removed placements count, this would just double count stuff.
      it("doesn't count setting enabled: true on a placement as a change", () => {
        const entry = createMockConfigEntry(
          {
            placements: [
              {
                placement: LtiPlacements.CourseNavigation,
                enabled: false,
              },
            ],
          },
          {
            placements: [
              {
                placement: LtiPlacements.CourseNavigation,
                enabled: true,
              },
            ],
          },
        )

        const result = diffConfigChangeEntry(entry)

        // Should count 1 addition (placement added) and 0 removals
        // The "enabled" change itself shouldn't be counted separately
        expect(result.totalAdditions).toBe(1)
        expect(result.totalRemovals).toBe(0)
      })

      it("doesn't count a removal of a placement with an icon URL and placement text as an addition", () => {
        const entry = createMockConfigEntry(
          {
            placements: [
              {
                placement: LtiPlacements.CourseNavigation,
                enabled: true,
                text: 'Old Text',
                icon_url: 'https://old.example.com/icon.png',
              },
            ],
          },
          {
            placements: [],
          },
        )

        const result = diffConfigChangeEntry(entry)

        // Should count 3 removals (text, icon_url, and the placement itself) and 0 additions
        expect(result.totalAdditions).toBe(0)
        expect(result.totalRemovals).toBe(3)
      })
    })
  })
})

describe('diffAvailabilityChangeEntry', () => {
  describe('context control additions', () => {
    it('detects when a new context control is added', () => {
      const entry = createMockAvailabilityEntry(
        [],
        [
          {
            id: ZLtiDeploymentId.parse('1'),
            deployment_id: '1',
            context_id: '100',
            context_type: 'Account',
            context_name: 'Main Account',
            context_controls: [
              mockContextControl({
                deployment_id: ZLtiDeploymentId.parse('1'),
                id: ZLtiContextControlId.parse('1'),
                account_id: ZAccountId.parse('100'),
                available: true,
              }),
            ],
          },
        ],
      )

      const result = diffHistoryEntry(entry) as AvailabilityChangeEntryWithDiff

      expect(result.totalAdditions).toBe(1)
      expect(result.totalRemovals).toBe(0)
      expect(result.deploymentDiffs).toHaveLength(1)

      const deploymentDiff = result.deploymentDiffs[0]!
      expect(deploymentDiff.context_name).toBe('Main Account')
      expect(deploymentDiff.context_type).toBe('Account')
      expect(deploymentDiff.controlDiffs).toHaveLength(1)

      const controlDiff = deploymentDiff.controlDiffs[0]!
      expect(controlDiff.availabilityChange).toEqual({
        oldValue: undefined,
        newValue: true,
      })
    })

    it('detects when a context control is made available', () => {
      const entry = createMockAvailabilityEntry(
        [
          {
            id: ZLtiDeploymentId.parse('1'),
            deployment_id: '1',
            context_id: '100',
            context_type: 'Account',
            context_name: 'Main Account',
            context_controls: [
              mockContextControl({
                id: ZLtiContextControlId.parse('1'),
                deployment_id: ZLtiDeploymentId.parse('1'),
                account_id: ZAccountId.parse('100'),
                available: false,
              }),
            ],
          },
        ],
        [
          {
            id: ZLtiDeploymentId.parse('1'),
            deployment_id: '1',
            context_id: '100',
            context_type: 'Account',
            context_name: 'Main Account',
            context_controls: [
              mockContextControl({
                id: ZLtiContextControlId.parse('1'),
                deployment_id: ZLtiDeploymentId.parse('1'),
                account_id: ZAccountId.parse('100'),
                available: true,
              }),
            ],
          },
        ],
      )

      const result = diffHistoryEntry(entry) as AvailabilityChangeEntryWithDiff

      expect(result.totalAdditions).toBe(1)
      expect(result.totalRemovals).toBe(1)
      expect(result.deploymentDiffs).toHaveLength(1)
      expect(result.deploymentDiffs[0]!.controlDiffs).toHaveLength(1)

      const diff = result.deploymentDiffs[0]!.controlDiffs[0]!
      expect(diff.availabilityChange).toEqual({
        oldValue: false,
        newValue: true,
      })
    })
  })

  describe('context control removals', () => {
    it('detects when a context control is deleted', () => {
      const entry = createMockAvailabilityEntry(
        [
          {
            id: ZLtiDeploymentId.parse('1'),
            deployment_id: '1',
            context_id: '200',
            context_type: 'Course',
            context_name: 'Test Course',
            context_controls: [
              mockContextControl({
                id: ZLtiContextControlId.parse('1'),
                deployment_id: ZLtiDeploymentId.parse('1'),
                course_id: ZCourseId.parse('200'),
                available: true,
              }),
            ],
          },
        ],
        [],
      )

      const result = diffHistoryEntry(entry) as AvailabilityChangeEntryWithDiff

      expect(result.totalAdditions).toBe(0)
      expect(result.totalRemovals).toBe(1)
      expect(result.deploymentDiffs).toHaveLength(1)

      const deploymentDiff = result.deploymentDiffs[0]!
      expect(deploymentDiff.context_name).toBe('Test Course')
      expect(deploymentDiff.context_type).toBe('Course')
      expect(deploymentDiff.controlDiffs).toHaveLength(1)

      const diff = deploymentDiff.controlDiffs[0]!
      expect(diff.availabilityChange.oldValue).toBe(true)
      expect(diff.availabilityChange.newValue).toBe(undefined)
    })

    it('detects when a context control is made unavailable', () => {
      const entry = createMockAvailabilityEntry(
        [
          {
            id: ZLtiDeploymentId.parse('1'),
            deployment_id: '1',
            context_id: '100',
            context_type: 'Account',
            context_name: 'Main Account',
            context_controls: [
              mockContextControl({
                id: ZLtiContextControlId.parse('1'),
                account_id: ZAccountId.parse('100'),
                available: true,
                deployment_id: ZLtiDeploymentId.parse('1'),
              }),
            ],
          },
        ],
        [
          {
            id: ZLtiDeploymentId.parse('1'),
            deployment_id: '1',
            context_id: '100',
            context_type: 'Account',
            context_name: 'Main Account',
            context_controls: [
              mockContextControl({
                id: ZLtiContextControlId.parse('1'),
                deployment_id: ZLtiDeploymentId.parse('1'),
                account_id: ZAccountId.parse('100'),
                available: false,
              }),
            ],
          },
        ],
      )

      const result = diffHistoryEntry(entry) as AvailabilityChangeEntryWithDiff

      expect(result.totalAdditions).toBe(1)
      expect(result.totalRemovals).toBe(1)
      expect(result.deploymentDiffs).toHaveLength(1)
      expect(result.deploymentDiffs[0]!.controlDiffs).toHaveLength(1)

      const diff = result.deploymentDiffs[0]!.controlDiffs[0]!
      expect(diff.availabilityChange.oldValue).toBe(true)
      expect(diff.availabilityChange.newValue).toBe(false)
    })
  })

  describe('context control modifications', () => {
    it('handles multiple context control changes', () => {
      const entry = createMockAvailabilityEntry(
        [
          {
            id: ZLtiDeploymentId.parse('1'),
            deployment_id: '1',
            context_id: '100',
            context_type: 'Account',
            context_name: 'Account A',
            context_controls: [
              mockContextControl({
                id: ZLtiContextControlId.parse('1'),
                deployment_id: ZLtiDeploymentId.parse('1'),
                account_id: ZAccountId.parse('100'),
                available: true,
              }),
            ],
          },
          {
            id: ZLtiDeploymentId.parse('2'),
            deployment_id: '2',
            context_id: '200',
            context_type: 'Course',
            context_name: 'Course B',
            context_controls: [
              mockContextControl({
                id: ZLtiContextControlId.parse('2'),
                deployment_id: ZLtiDeploymentId.parse('2'),
                course_id: ZCourseId.parse('200'),
                available: false,
              }),
            ],
          },
        ],
        [
          {
            id: ZLtiDeploymentId.parse('1'),
            deployment_id: '1',
            context_id: '100',
            context_type: 'Account',
            context_name: 'Account A',
            context_controls: [
              mockContextControl({
                id: ZLtiContextControlId.parse('1'),
                deployment_id: ZLtiDeploymentId.parse('1'),
                account_id: ZAccountId.parse('100'),
                available: false,
              }),
            ],
          },
          {
            id: ZLtiDeploymentId.parse('2'),
            deployment_id: '2',
            context_id: '200',
            context_type: 'Course',
            context_name: 'Course B',
            context_controls: [
              mockContextControl({
                id: ZLtiContextControlId.parse('2'),
                deployment_id: ZLtiDeploymentId.parse('2'),
                course_id: ZCourseId.parse('200'),
                available: true,
              }),
            ],
          },
        ],
      )

      const result = diffHistoryEntry(entry) as AvailabilityChangeEntryWithDiff

      // Two modifications, mods are counted for both
      expect(result.totalAdditions).toBe(2)
      expect(result.totalRemovals).toBe(2)
      expect(result.deploymentDiffs).toHaveLength(2)

      const accountDeployment = result.deploymentDiffs.find(d => d.context_type === 'Account')!
      expect(accountDeployment.controlDiffs).toHaveLength(1)
      expect(accountDeployment.controlDiffs[0]!.availabilityChange.oldValue).toBe(true)
      expect(accountDeployment.controlDiffs[0]!.availabilityChange.newValue).toBe(false)

      const courseDeployment = result.deploymentDiffs.find(d => d.context_type === 'Course')!
      expect(courseDeployment.controlDiffs).toHaveLength(1)
      expect(courseDeployment.controlDiffs[0]!.availabilityChange.oldValue).toBe(false)
      expect(courseDeployment.controlDiffs[0]!.availabilityChange.newValue).toBe(true)
    })

    it('handles mixed additions, removals, and no-changes', () => {
      const entry = createMockAvailabilityEntry(
        [
          {
            id: ZLtiDeploymentId.parse('1'),
            deployment_id: '1',
            context_id: '100',
            context_type: 'Account',
            context_name: 'Existing Available',
            context_controls: [
              mockContextControl({
                id: ZLtiContextControlId.parse('1'),
                deployment_id: ZLtiDeploymentId.parse('1'),
                account_id: ZAccountId.parse('100'),
                available: true,
              }),
            ],
          },
          {
            id: ZLtiDeploymentId.parse('2'),
            deployment_id: '2',
            context_id: '200',
            context_type: 'Account',
            context_name: 'To Be Removed',
            context_controls: [
              mockContextControl({
                id: ZLtiContextControlId.parse('2'),
                deployment_id: ZLtiDeploymentId.parse('2'),
                account_id: ZAccountId.parse('200'),
                available: true,
              }),
            ],
          },
        ],
        [
          {
            id: ZLtiDeploymentId.parse('1'),
            deployment_id: '1',
            context_id: '100',
            context_type: 'Account',
            context_name: 'Existing Available',
            context_controls: [
              mockContextControl({
                id: ZLtiContextControlId.parse('1'),
                deployment_id: ZLtiDeploymentId.parse('1'),
                account_id: ZAccountId.parse('100'),
                available: true,
              }),
            ],
          },
          {
            id: ZLtiDeploymentId.parse('3'),
            deployment_id: '3',
            context_id: '300',
            context_type: 'Account',
            context_name: 'Newly Added',
            context_controls: [
              mockContextControl({
                id: ZLtiContextControlId.parse('3'),
                deployment_id: ZLtiDeploymentId.parse('3'),
                account_id: ZAccountId.parse('300'),
                available: true,
              }),
            ],
          },
        ],
      )

      const result = diffHistoryEntry(entry) as AvailabilityChangeEntryWithDiff

      expect(result.totalAdditions).toBe(1) // New account 300
      expect(result.totalRemovals).toBe(1) // Removed account 200
      expect(result.deploymentDiffs).toHaveLength(2) // Only changed deployments

      // no change - deployment 1 should not be included
      expect(result.deploymentDiffs.find(d => d.context_id === '100')).toBeUndefined()

      // deleted - deployment 2
      const deployment200 = result.deploymentDiffs.find(d => d.context_id === '200')!
      expect(deployment200.controlDiffs).toHaveLength(1)
      expect(deployment200.controlDiffs[0]!.availabilityChange.oldValue).toBe(true)
      expect(deployment200.controlDiffs[0]!.availabilityChange.newValue).toBe(undefined)

      // added - deployment 3
      const deployment300 = result.deploymentDiffs.find(d => d.context_id === '300')!
      expect(deployment300.controlDiffs).toHaveLength(1)
      expect(deployment300.controlDiffs[0]!.availabilityChange.oldValue).toBe(undefined)
      expect(deployment300.controlDiffs[0]!.availabilityChange.newValue).toBe(true)
    })
  })

  describe('multiple controls per deployment', () => {
    it('groups multiple control changes within the same deployment', () => {
      const entry = createMockAvailabilityEntry(
        [
          {
            id: ZLtiDeploymentId.parse('1'),
            deployment_id: '1',
            context_id: '100',
            context_type: 'Account',
            context_name: 'Main Account',
            context_controls: [
              mockContextControl({
                id: ZLtiContextControlId.parse('1'),
                deployment_id: ZLtiDeploymentId.parse('1'),
                account_id: ZAccountId.parse('100'),
                available: true,
              }),
              mockContextControl({
                id: ZLtiContextControlId.parse('2'),
                deployment_id: ZLtiDeploymentId.parse('1'),
                account_id: ZAccountId.parse('100'),
                available: false,
              }),
            ],
          },
        ],
        [
          {
            id: ZLtiDeploymentId.parse('1'),
            deployment_id: '1',
            context_id: '100',
            context_type: 'Account',
            context_name: 'Main Account',
            context_controls: [
              mockContextControl({
                id: ZLtiContextControlId.parse('1'),
                deployment_id: ZLtiDeploymentId.parse('1'),
                account_id: ZAccountId.parse('100'),
                available: false,
              }),
              mockContextControl({
                id: ZLtiContextControlId.parse('2'),
                deployment_id: ZLtiDeploymentId.parse('1'),
                account_id: ZAccountId.parse('100'),
                available: true,
              }),
            ],
          },
        ],
      )

      const result = diffHistoryEntry(entry) as AvailabilityChangeEntryWithDiff

      expect(result.deploymentDiffs).toHaveLength(1)
      expect(result.deploymentDiffs[0]!.controlDiffs).toHaveLength(2)
      expect(result.totalAdditions).toBe(2)
      expect(result.totalRemovals).toBe(2)

      const deployment = result.deploymentDiffs[0]!
      expect(deployment.context_name).toBe('Main Account')

      const control1 = deployment.controlDiffs.find(c => c.id === ZLtiContextControlId.parse('1'))!
      expect(control1.availabilityChange.oldValue).toBe(true)
      expect(control1.availabilityChange.newValue).toBe(false)

      const control2 = deployment.controlDiffs.find(c => c.id === ZLtiContextControlId.parse('2'))!
      expect(control2.availabilityChange.oldValue).toBe(false)
      expect(control2.availabilityChange.newValue).toBe(true)
    })

    it('only includes controls that changed within a deployment', () => {
      const entry = createMockAvailabilityEntry(
        [
          {
            id: ZLtiDeploymentId.parse('1'),
            deployment_id: '1',
            context_id: '100',
            context_type: 'Account',
            context_name: 'Main Account',
            context_controls: [
              mockContextControl({
                id: ZLtiContextControlId.parse('1'),
                deployment_id: ZLtiDeploymentId.parse('1'),
                account_id: ZAccountId.parse('100'),
                available: true,
              }),
              mockContextControl({
                id: ZLtiContextControlId.parse('2'),
                deployment_id: ZLtiDeploymentId.parse('1'),
                account_id: ZAccountId.parse('100'),
                available: false,
              }),
            ],
          },
        ],
        [
          {
            id: ZLtiDeploymentId.parse('1'),
            deployment_id: '1',
            context_id: '100',
            context_type: 'Account',
            context_name: 'Main Account',
            context_controls: [
              mockContextControl({
                id: ZLtiContextControlId.parse('1'),
                deployment_id: ZLtiDeploymentId.parse('1'),
                account_id: ZAccountId.parse('100'),
                available: false,
              }),
              mockContextControl({
                id: ZLtiContextControlId.parse('2'),
                deployment_id: ZLtiDeploymentId.parse('1'),
                account_id: ZAccountId.parse('100'),
                available: false,
              }),
            ],
          },
        ],
      )

      const result = diffHistoryEntry(entry) as AvailabilityChangeEntryWithDiff

      expect(result.deploymentDiffs).toHaveLength(1)
      expect(result.deploymentDiffs[0]!.controlDiffs).toHaveLength(1)
      expect(result.totalAdditions).toBe(1)
      expect(result.totalRemovals).toBe(1)

      const control1 = result.deploymentDiffs[0]!.controlDiffs[0]!
      expect(control1.id).toBe(ZLtiContextControlId.parse('1'))
      expect(control1.availabilityChange.oldValue).toBe(true)
      expect(control1.availabilityChange.newValue).toBe(false)
    })
  })

  describe('edge cases', () => {
    it('handles empty old and new deployments', () => {
      const entry = createMockAvailabilityEntry([], [])

      const result = diffHistoryEntry(entry) as AvailabilityChangeEntryWithDiff

      expect(result.totalAdditions).toBe(0)
      expect(result.totalRemovals).toBe(0)
      expect(result.deploymentDiffs).toHaveLength(0)
    })

    it('distinguishes between accounts and courses with same ID', () => {
      const entry = createMockAvailabilityEntry(
        [],
        [
          {
            id: ZLtiDeploymentId.parse('1'),
            deployment_id: '1',
            context_id: '100',
            context_type: 'Account',
            context_name: 'Account 100',
            context_controls: [
              mockContextControl({
                id: ZLtiContextControlId.parse('1'),
                deployment_id: ZLtiDeploymentId.parse('1'),
                account_id: ZAccountId.parse('100'),
                available: true,
              }),
            ],
          },
          {
            id: ZLtiDeploymentId.parse('2'),
            deployment_id: '2',
            context_id: '100',
            context_type: 'Course',
            context_name: 'Course 100',
            context_controls: [
              mockContextControl({
                id: ZLtiContextControlId.parse('2'),
                deployment_id: ZLtiDeploymentId.parse('2'),
                course_id: ZCourseId.parse('100'),
                available: true,
              }),
            ],
          },
        ],
      )

      const result = diffHistoryEntry(entry) as AvailabilityChangeEntryWithDiff

      expect(result.totalAdditions).toBe(2)
      expect(result.deploymentDiffs).toHaveLength(2)

      expect(result.deploymentDiffs.find(d => d.context_type === 'Account')!.context_name).toBe(
        'Account 100',
      )

      expect(result.deploymentDiffs.find(d => d.context_type === 'Course')!.context_name).toBe(
        'Course 100',
      )
    })
  })

  describe('workflow_state transitions', () => {
    // Accounts for cases where someone deletes the control, then sets it to a value again
    it('treats a context control with workflow_state deleted as having no value', () => {
      const entry = createMockAvailabilityEntry(
        [
          {
            id: ZLtiDeploymentId.parse('1'),
            deployment_id: '1',
            context_id: '100',
            context_type: 'Account',
            context_name: 'Main Account',
            context_controls: [
              mockContextControl({
                id: ZLtiContextControlId.parse('1'),
                deployment_id: ZLtiDeploymentId.parse('1'),
                account_id: ZAccountId.parse('100'),
                available: true,
                workflow_state: 'deleted',
              }),
            ],
          },
        ],
        [
          {
            id: ZLtiDeploymentId.parse('1'),
            deployment_id: '1',
            context_id: '100',
            context_type: 'Account',
            context_name: 'Main Account',
            context_controls: [
              mockContextControl({
                id: ZLtiContextControlId.parse('1'),
                deployment_id: ZLtiDeploymentId.parse('1'),
                account_id: ZAccountId.parse('100'),
                available: true,
                workflow_state: 'active',
              }),
            ],
          },
        ],
      )

      const result = diffHistoryEntry(entry) as AvailabilityChangeEntryWithDiff

      expect(result.totalAdditions).toBe(1)
      expect(result.totalRemovals).toBe(0)
      expect(result.deploymentDiffs).toHaveLength(1)

      const controlDiff = result.deploymentDiffs[0]!.controlDiffs[0]!
      expect(controlDiff.availabilityChange).toEqual({
        oldValue: undefined,
        newValue: true,
      })
    })
  })
})
