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

import {validateLti1p3RegistrationOverlayState} from '../validateLti1p3RegistrationOverlayState'
import type {Lti1p3RegistrationOverlayState} from '../Lti1p3RegistrationOverlayState'

const mockOverlayState = (
  overrides?: Partial<Lti1p3RegistrationOverlayState>,
): Lti1p3RegistrationOverlayState => {
  return {
    naming: {
      placements: {},
      nickname: 'Test Tool',
      description: 'A tool for testing',
    },
    launchSettings: {
      redirectURIs: 'https://example.com/redirect',
      targetLinkURI: 'https://example.com/launch',
      openIDConnectInitiationURL: 'https://example.com/oidc',
      JwkMethod: 'public_jwk_url',
      JwkURL: 'https://example.com/jwk',
      Jwk: undefined,
      domain: 'example.com',
      customFields: 'key=value',
    },
    permissions: {
      scopes: [],
    },
    placements: {
      placements: [],
    },
    override_uris: {
      placements: {},
    },
    icons: {
      defaultIconUrl: '',
      placements: {},
    },
    data_sharing: {
      privacy_level: 'anonymous',
    },
    dirty: false,
    hasSubmitted: false,
    ...overrides,
  }
}

describe('validateLti1p3RegistrationOverlayState', () => {
  describe('validateLaunchSettings parameter', () => {
    it('validates launch settings when validateLaunchSettings is true', () => {
      const state = mockOverlayState({
        launchSettings: {
          redirectURIs: '', // Invalid - empty
          targetLinkURI: '',
          openIDConnectInitiationURL: '',
          JwkMethod: 'public_jwk_url',
          JwkURL: '',
          Jwk: undefined,
          domain: '',
          customFields: '',
        },
      })

      const errors = validateLti1p3RegistrationOverlayState({
        state,
        validateLaunchSettings: true,
      })

      expect(errors.length).toBeGreaterThan(0)
      expect(errors.some(e => e.field === 'redirectURIs')).toBe(true)
      expect(errors.some(e => e.field === 'targetLinkURI')).toBe(true)
      expect(errors.some(e => e.field === 'openIDConnectInitiationURL')).toBe(true)
      expect(errors.some(e => e.field === 'JwkURL')).toBe(true)
    })

    it('skips launch settings validation when validateLaunchSettings is false', () => {
      const state = mockOverlayState({
        launchSettings: {
          redirectURIs: '', // Invalid - empty
          targetLinkURI: '',
          openIDConnectInitiationURL: '',
          JwkMethod: 'public_jwk_url',
          JwkURL: '',
          Jwk: undefined,
          domain: '',
          customFields: '',
        },
      })

      const errors = validateLti1p3RegistrationOverlayState({
        state,
        validateLaunchSettings: false,
      })

      expect(errors.some(e => e.field === 'redirectURIs')).toBe(false)
      expect(errors.some(e => e.field === 'targetLinkURI')).toBe(false)
      expect(errors.some(e => e.field === 'openIDConnectInitiationURL')).toBe(false)
      expect(errors.some(e => e.field === 'JwkURL')).toBe(false)
    })
  })

  describe('validateOverrideUris', () => {
    it('returns no errors for valid override URIs', () => {
      const state = mockOverlayState({
        override_uris: {
          placements: {
            course_navigation: {
              uri: 'https://example.com/course_nav',
              message_type: 'LtiResourceLinkRequest',
            },
            account_navigation: {
              uri: 'https://example.com/account_nav',
              message_type: 'LtiResourceLinkRequest',
            },
          },
        },
      })

      const errors = validateLti1p3RegistrationOverlayState({
        state,
        validateLaunchSettings: false,
      })

      expect(errors).toHaveLength(0)
    })

    it('returns errors for invalid override URI', () => {
      const state = mockOverlayState({
        override_uris: {
          placements: {
            course_navigation: {
              uri: 'not-a-valid-url',
              message_type: 'LtiResourceLinkRequest',
            },
          },
        },
      })

      const errors = validateLti1p3RegistrationOverlayState({
        state,
        validateLaunchSettings: false,
      })

      expect(errors).toHaveLength(1)
      expect(errors[0].field).toBe('override_uri_course_navigation')
      expect(errors[0].type).toBe('error')
      expect(errors[0].text).toBe('Invalid URL')
    })

    it('returns multiple errors for multiple invalid override URIs', () => {
      const state = mockOverlayState({
        override_uris: {
          placements: {
            course_navigation: {
              uri: 'invalid-url',
              message_type: 'LtiResourceLinkRequest',
            },
            account_navigation: {
              uri: 'also-invalid',
              message_type: 'LtiResourceLinkRequest',
            },
            editor_button: {
              uri: 'ftp://not-http',
              message_type: 'LtiDeepLinkingRequest',
            },
          },
        },
      })

      const errors = validateLti1p3RegistrationOverlayState({
        state,
        validateLaunchSettings: false,
      })

      expect(errors).toHaveLength(3)
      expect(errors.some(e => e.field === 'override_uri_course_navigation')).toBe(true)
      expect(errors.some(e => e.field === 'override_uri_account_navigation')).toBe(true)
      expect(errors.some(e => e.field === 'override_uri_editor_button')).toBe(true)
    })

    it('returns no errors for empty override URIs', () => {
      const state = mockOverlayState({
        override_uris: {
          placements: {
            course_navigation: {
              uri: '',
              message_type: 'LtiResourceLinkRequest',
            },
          },
        },
      })

      const errors = validateLti1p3RegistrationOverlayState({
        state,
        validateLaunchSettings: false,
      })

      expect(errors).toHaveLength(0)
    })

    it('returns no errors for undefined override URIs', () => {
      const state = mockOverlayState({
        override_uris: {
          placements: {
            course_navigation: {
              uri: undefined,
              message_type: 'LtiResourceLinkRequest',
            },
          },
        },
      })

      const errors = validateLti1p3RegistrationOverlayState({
        state,
        validateLaunchSettings: false,
      })

      expect(errors).toHaveLength(0)
    })

    it('returns no errors for whitespace-only override URIs (treated as empty)', () => {
      const state = mockOverlayState({
        override_uris: {
          placements: {
            course_navigation: {
              uri: '   ',
              message_type: 'LtiResourceLinkRequest',
            },
          },
        },
      })

      const errors = validateLti1p3RegistrationOverlayState({
        state,
        validateLaunchSettings: false,
      })

      // Whitespace-only strings are treated as empty, which is valid
      expect(errors).toHaveLength(0)
    })
  })

  describe('validateIconUris', () => {
    it('returns no errors for valid default icon URL', () => {
      const state = mockOverlayState({
        icons: {
          defaultIconUrl: 'https://example.com/icon.png',
          placements: {},
        },
      })

      const errors = validateLti1p3RegistrationOverlayState({
        state,
        validateLaunchSettings: false,
      })

      expect(errors).toHaveLength(0)
    })

    it('returns error for invalid default icon URL', () => {
      const state = mockOverlayState({
        icons: {
          defaultIconUrl: 'not-a-valid-url',
          placements: {},
        },
      })

      const errors = validateLti1p3RegistrationOverlayState({
        state,
        validateLaunchSettings: false,
      })

      expect(errors).toHaveLength(1)
      expect(errors[0].field).toBe('default_icon_url')
      expect(errors[0].type).toBe('error')
      expect(errors[0].text).toBe('Invalid URL')
    })

    it('returns no errors for empty default icon URL', () => {
      const state = mockOverlayState({
        icons: {
          defaultIconUrl: '',
          placements: {},
        },
      })

      const errors = validateLti1p3RegistrationOverlayState({
        state,
        validateLaunchSettings: false,
      })

      expect(errors).toHaveLength(0)
    })

    it('returns no errors for valid placement icon URLs', () => {
      const state = mockOverlayState({
        icons: {
          defaultIconUrl: '',
          placements: {
            file_index_menu: 'https://example.com/course_nav_icon.png',
            ActivityAssetProcessor: 'https://example.com/account_nav_icon.png',
            editor_button: 'https://example.com/editor_icon.png',
          },
        },
      })

      const errors = validateLti1p3RegistrationOverlayState({
        state,
        validateLaunchSettings: false,
      })

      expect(errors).toHaveLength(0)
    })

    it('returns error for invalid placement icon URL', () => {
      const state = mockOverlayState({
        icons: {
          defaultIconUrl: '',
          placements: {
            editor_button: 'invalid-url',
          },
        },
      })

      const errors = validateLti1p3RegistrationOverlayState({
        state,
        validateLaunchSettings: false,
      })

      expect(errors).toHaveLength(1)
      expect(errors[0].field).toBe('icon_uri_editor_button')
      expect(errors[0].type).toBe('error')
      expect(errors[0].text).toBe('Invalid URL')
    })

    it('returns multiple errors for multiple invalid placement icon URLs', () => {
      const state = mockOverlayState({
        icons: {
          defaultIconUrl: 'bad-default-url',
          placements: {
            ActivityAssetProcessor: 'invalid-course-nav',
            discussion_topic_menu: 'invalid-account-nav',
            editor_button: 'ftp://not-http',
          },
        },
      })

      const errors = validateLti1p3RegistrationOverlayState({
        state,
        validateLaunchSettings: false,
      })

      expect(errors).toHaveLength(4)
      expect(errors.some(e => e.field === 'default_icon_url')).toBe(true)
      expect(errors.some(e => e.field === 'icon_uri_ActivityAssetProcessor')).toBe(true)
      expect(errors.some(e => e.field === 'icon_uri_discussion_topic_menu')).toBe(true)
      expect(errors.some(e => e.field === 'icon_uri_editor_button')).toBe(true)
    })

    it('returns no errors for empty placement icon URLs', () => {
      const state = mockOverlayState({
        icons: {
          defaultIconUrl: '',
          placements: {
            ActivityAssetProcessor: '',
            discussion_topic_index_menu: '',
          },
        },
      })

      const errors = validateLti1p3RegistrationOverlayState({
        state,
        validateLaunchSettings: false,
      })

      expect(errors).toHaveLength(0)
    })

    it('validates both default and placement icons together', () => {
      const state = mockOverlayState({
        icons: {
          defaultIconUrl: 'https://example.com/default.png',
          placements: {
            ActivityAssetProcessor: 'invalid-url',
            discussion_topic_index_menu: 'https://example.com/account.png',
          },
        },
      })

      const errors = validateLti1p3RegistrationOverlayState({
        state,
        validateLaunchSettings: false,
      })

      expect(errors).toHaveLength(1)
      expect(errors[0].field).toBe('icon_uri_ActivityAssetProcessor')
    })

    it('returns no errors for whitespace-only icon URL (treated as empty)', () => {
      const state = mockOverlayState({
        icons: {
          defaultIconUrl: '   ',
          placements: {},
        },
      })

      const errors = validateLti1p3RegistrationOverlayState({
        state,
        validateLaunchSettings: false,
      })

      // Whitespace-only strings are treated as empty, which is valid
      expect(errors).toHaveLength(0)
    })
  })

  describe('combined validation', () => {
    it('validates override URIs and icon URLs together', () => {
      const state = mockOverlayState({
        override_uris: {
          placements: {
            course_navigation: {
              uri: 'invalid-override-uri',
              message_type: 'LtiResourceLinkRequest',
            },
          },
        },
        icons: {
          defaultIconUrl: 'invalid-icon-url',
          placements: {
            ActivityAssetProcessorContribution: 'another-invalid-url',
          },
        },
      })

      const errors = validateLti1p3RegistrationOverlayState({
        state,
        validateLaunchSettings: false,
      })

      expect(errors).toHaveLength(3)
      expect(errors.some(e => e.field === 'override_uri_course_navigation')).toBe(true)
      expect(errors.some(e => e.field === 'default_icon_url')).toBe(true)
      expect(errors.some(e => e.field === 'icon_uri_ActivityAssetProcessorContribution')).toBe(true)
    })

    it('validates all three validation groups together', () => {
      const state = mockOverlayState({
        launchSettings: {
          redirectURIs: '', // Invalid
          targetLinkURI: '',
          openIDConnectInitiationURL: '',
          JwkMethod: 'public_jwk_url',
          JwkURL: '',
          Jwk: undefined,
          domain: '',
          customFields: '',
        },
        override_uris: {
          placements: {
            course_navigation: {
              uri: 'invalid-uri',
              message_type: 'LtiResourceLinkRequest',
            },
          },
        },
        icons: {
          defaultIconUrl: 'invalid-icon',
          placements: {},
        },
      })

      const errors = validateLti1p3RegistrationOverlayState({
        state,
        validateLaunchSettings: true,
      })

      // Should have errors from all three validation groups
      expect(errors.length).toBeGreaterThan(4)
      expect(errors.some(e => e.field === 'redirectURIs')).toBe(true)
      expect(errors.some(e => e.field === 'override_uri_course_navigation')).toBe(true)
      expect(errors.some(e => e.field === 'default_icon_url')).toBe(true)
    })
  })
})
