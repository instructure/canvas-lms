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

import {createLti1p3RegistrationOverlayStore} from '../Lti1p3RegistrationOverlayStore'
import type {InternalLtiConfiguration} from '../../model/internal_lti_configuration/InternalLtiConfiguration'
import {LtiPlacements} from '../../model/LtiPlacement'
import {LtiDeepLinkingRequest, LtiResourceLinkRequest} from '../../model/LtiMessageType'
import {LtiScopes} from '@canvas/lti/model/LtiScope'

const mockInternalConfiguration = (
  overrides?: Partial<InternalLtiConfiguration>,
): InternalLtiConfiguration => {
  return {
    title: 'Test Tool',
    description: 'Test Description',
    target_link_uri: 'https://example.com',
    oidc_initiation_url: 'https://example.com/oidc',
    public_jwk_url: 'https://example.com/jwk',
    launch_settings: {
      text: 'Default Title',
    },
    redirect_uris: ['https://example.com/redirect'],
    oidc_initiation_urls: {},
    privacy_level: 'anonymous',
    tool_id: 'tool_id',
    domain: 'example.com',
    custom_fields: {},
    scopes: [...Object.values(LtiScopes)],
    placements: [],
    ...overrides,
  }
}

describe('Lti1p3RegistrationOverlayStore', () => {
  describe('togglePlacement', () => {
    it('sets LtiResourceLinkRequest for placements that only support resource link', () => {
      const store = createLti1p3RegistrationOverlayStore(mockInternalConfiguration(), '')

      store.getState().togglePlacement(LtiPlacements.CourseNavigation)

      const state = store.getState().state
      expect(state.override_uris.placements[LtiPlacements.CourseNavigation]?.message_type).toBe(
        LtiResourceLinkRequest,
      )
    })

    it('sets LtiDeepLinkingRequest for placements that support deep linking', () => {
      const store = createLti1p3RegistrationOverlayStore(mockInternalConfiguration(), '')

      store.getState().togglePlacement(LtiPlacements.EditorButton)

      const state = store.getState().state
      expect(state.override_uris.placements[LtiPlacements.EditorButton]?.message_type).toBe(
        LtiDeepLinkingRequest,
      )
    })

    it('does not override an existing message_type', () => {
      const store = createLti1p3RegistrationOverlayStore(mockInternalConfiguration(), '')

      store.getState().setMessageType(LtiPlacements.ModuleMenuModal, LtiResourceLinkRequest)
      store.getState().togglePlacement(LtiPlacements.ModuleMenuModal)

      const state = store.getState().state
      expect(state.override_uris.placements[LtiPlacements.ModuleMenuModal]?.message_type).toBe(
        LtiResourceLinkRequest,
      )
    })

    it('does not set message_type when removing a placement', () => {
      const store = createLti1p3RegistrationOverlayStore(
        mockInternalConfiguration({
          placements: [{placement: LtiPlacements.CourseNavigation}],
        }),
        '',
      )

      store.getState().togglePlacement(LtiPlacements.CourseNavigation)

      const state = store.getState().state
      expect(state.placements.placements).not.toContain(LtiPlacements.CourseNavigation)
    })
  })
})
