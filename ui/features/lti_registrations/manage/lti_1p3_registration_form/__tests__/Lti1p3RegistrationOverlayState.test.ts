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

import type {LtiConfigurationOverlay} from '../../model/internal_lti_configuration/LtiConfigurationOverlay'
import {
  createLti1p3RegistrationOverlayStore,
  type Lti1p3RegistrationOverlayStore,
} from '../../registration_overlay/Lti1p3RegistrationOverlayStore'
import {type Lti1p3RegistrationOverlayState} from '../../registration_overlay/Lti1p3RegistrationOverlayState'
import {convertToLtiConfigurationOverlay} from '../../registration_overlay/Lti1p3RegistrationOverlayStateHelpers'
import {mockInternalConfiguration} from './helpers'

describe('Lti1p3RegistrationOverlayState', () => {
  describe('convertToLtiConfigurationOverlay', () => {
    const internalConfig = mockInternalConfiguration()
    const emptyState: Lti1p3RegistrationOverlayState = {
      launchSettings: {},
      data_sharing: {},
      permissions: {},
      override_uris: {
        placements: {},
      },
      icons: {
        placements: {},
      },
      placements: {},
      naming: {
        placements: {},
      },
      dirty: false,
      hasSubmitted: false,
    }
    let state: Lti1p3RegistrationOverlayStore

    beforeEach(() => {
      state = createLti1p3RegistrationOverlayStore(internalConfig, '')

      state.setState(
        prev => ({
          ...prev,
          state: emptyState,
        }),
        true,
      )
    })

    it('handles custom fields properly', () => {
      state.getState().setCustomFields('foo=$bar\nbaz=$qux')

      const {overlay: result} = convertToLtiConfigurationOverlay(
        state.getState().state,
        internalConfig,
      )

      expect(result.custom_fields).toEqual({
        foo: '$bar',
        baz: '$qux',
      })
    })

    it('handles redirect URIs properly', () => {
      state
        .getState()
        .setRedirectURIs('https://example.com/redirect1\nhttps://example.com/redirect2')

      const {config: result} = convertToLtiConfigurationOverlay(
        state.getState().state,
        internalConfig,
      )

      expect(result.redirect_uris).toEqual([
        'https://example.com/redirect1',
        'https://example.com/redirect2',
      ])
    })

    it('handles OIDC initiation URL properly', () => {
      state.getState().setOIDCInitiationURI('https://example.com/oidc')

      const {config: result} = convertToLtiConfigurationOverlay(
        state.getState().state,
        internalConfig,
      )

      expect(result.oidc_initiation_url).toBe('https://example.com/oidc')
    })

    it('handles public JWK URL properly', () => {
      state.getState().setJwkURL('https://example.com/jwk')
      state.getState().setJwkMethod('public_jwk_url')

      const {config: result} = convertToLtiConfigurationOverlay(
        state.getState().state,
        internalConfig,
      )

      expect(result.public_jwk_url).toBe('https://example.com/jwk')
    })

    it('handles public JWK properly', () => {
      const jwk = JSON.stringify({kty: 'RSA', e: 'AQAB', n: '...'})
      state.getState().setJwk(jwk)
      state.getState().setJwkMethod('public_jwk')

      const {config: result} = convertToLtiConfigurationOverlay(
        state.getState().state,
        internalConfig,
      )

      expect(result.public_jwk).toEqual(JSON.parse(jwk))
    })

    it('handles domain properly', () => {
      state.getState().setDomain('example2.com')

      const {overlay: result} = convertToLtiConfigurationOverlay(
        state.getState().state,
        internalConfig,
      )

      expect(result.domain).toBe('example2.com')
    })

    it('handles privacy level properly', () => {
      state.getState().setPrivacyLevel('public')

      const {overlay: result} = convertToLtiConfigurationOverlay(
        state.getState().state,
        internalConfig,
      )

      expect(result.privacy_level).toBe('public')
    })

    it('handles disabled placements properly', () => {
      // internalConfig has both course_navigation and global_navigation placements by default.
      // An empty state should result in both placements being disabled.
      const {overlay: result} = convertToLtiConfigurationOverlay(
        state.getState().state,
        internalConfig,
      )

      expect(result.disabled_placements).toEqual(['course_navigation', 'global_navigation'])
    })

    it('handles placements properly', () => {
      state.getState().togglePlacement('global_navigation')
      state.getState().setOverrideURI('global_navigation', 'https://example.com/global_nav')
      state.getState().setMessageType('global_navigation', 'LtiResourceLinkRequest')
      state.getState().setPlacementLabel('global_navigation', 'Global Navigation')
      state.getState().setPlacementIconUrl('global_navigation', 'https://example.com/icon.png')

      const {overlay: result} = convertToLtiConfigurationOverlay(
        state.getState().state,
        internalConfig,
      )

      expect(result.placements).toEqual({
        global_navigation: {
          text: 'Global Navigation',
          target_link_uri: 'https://example.com/global_nav',
          message_type: 'LtiResourceLinkRequest',
          icon_url: 'https://example.com/icon.png',
        },
      })
    })

    it('handles defaultDisabled properly', () => {
      state.getState().togglePlacement('course_navigation')
      state.getState().toggleCourseNavigationDefaultDisabled()

      const {overlay: result} = convertToLtiConfigurationOverlay(
        state.getState().state,
        internalConfig,
      )

      expect(result.placements?.course_navigation?.default).toBe('disabled')
    })

    it('handles scopes properly', () => {
      state.getState().toggleScope('https://purl.imsglobal.org/spec/lti-ags/scope/lineitem')

      const {config: result} = convertToLtiConfigurationOverlay(
        state.getState().state,
        internalConfig,
      )

      expect(result.scopes).toEqual(['https://purl.imsglobal.org/spec/lti-ags/scope/lineitem'])
    })

    it('removes any undefined properties', () => {
      state.getState().setDefaultTargetLinkURI('https://example.com/edited')
      state.getState().setPrivacyLevel('email_only')

      const {overlay: result} = convertToLtiConfigurationOverlay(
        state.getState().state,
        internalConfig,
      )

      const expectedNonExistentProperties: Omit<keyof LtiConfigurationOverlay, 'title'>[] = [
        'title',
        'description',
        'custom_fields',
        'oidc_initiation_url',
        'redirect_uris',
        'public_jwk',
        'public_jwk_url',
        'domain',
        'placements',
        'scopes',
      ] as const

      expect(result.target_link_uri).toBe('https://example.com/edited')
      expect(result.privacy_level).toBe('email_only')

      expectedNonExistentProperties.forEach(property => {
        expect(Object.hasOwn(result, property as string)).toBeFalsy()
      })
    })

    it('does not include values that are the same as the internal configuration', () => {
      state.getState().setDefaultTargetLinkURI('https://example.com')
      state.getState().setDescription('description')
      state.getState().setDomain('example.com')
      state.getState().setPrivacyLevel('anonymous')
      state.getState().setCustomFields('foo=bar')
      state.getState().setRedirectURIs('https://example.com/redirect')

      const {overlay: result} = convertToLtiConfigurationOverlay(
        state.getState().state,
        internalConfig,
      )

      const expectedNonExistentProperties: Omit<keyof LtiConfigurationOverlay, 'title'>[] = [
        'description',
        'custom_fields',
        'target_link_uri',
        'redirect_uris',
        'domain',
        'placements',
      ] as const

      expectedNonExistentProperties.forEach(property => {
        expect(Object.hasOwn(result, property as string)).toBeFalsy()
      })
    })
  })
})
