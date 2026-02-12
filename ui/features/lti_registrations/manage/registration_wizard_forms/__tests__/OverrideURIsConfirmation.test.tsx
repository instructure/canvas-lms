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

import {render, waitFor} from '@testing-library/react'
import {OverrideURIsConfirmation} from '../OverrideURIsConfirmation'
import {createLti1p3RegistrationOverlayStore} from '../../registration_overlay/Lti1p3RegistrationOverlayStore'
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

describe('OverrideURIsConfirmation', () => {
  describe('automatic message_type setting', () => {
    it('automatically sets LtiResourceLinkRequest for placements without message_type', async () => {
      const internalConfig = mockInternalConfiguration({
        placements: [{placement: LtiPlacements.CourseNavigation}],
      })
      const overlayStore = createLti1p3RegistrationOverlayStore(internalConfig, '')

      overlayStore.getState().togglePlacement(LtiPlacements.AccountNavigation)

      render(
        <OverrideURIsConfirmation overlayStore={overlayStore} internalConfig={internalConfig} />,
      )

      await waitFor(() => {
        const state = overlayStore.getState().state
        expect(state.override_uris.placements[LtiPlacements.AccountNavigation]?.message_type).toBe(
          LtiResourceLinkRequest,
        )
      })
    })

    it('automatically sets LtiDeepLinkingRequest for deep linking placements without message_type', async () => {
      const internalConfig = mockInternalConfiguration({
        placements: [{placement: LtiPlacements.CourseNavigation}],
      })
      const overlayStore = createLti1p3RegistrationOverlayStore(internalConfig, '')

      overlayStore.getState().togglePlacement(LtiPlacements.EditorButton)

      render(
        <OverrideURIsConfirmation overlayStore={overlayStore} internalConfig={internalConfig} />,
      )

      await waitFor(() => {
        const state = overlayStore.getState().state
        expect(state.override_uris.placements[LtiPlacements.EditorButton]?.message_type).toBe(
          LtiDeepLinkingRequest,
        )
      })
    })

    it('does not override existing message_type', async () => {
      const internalConfig = mockInternalConfiguration({
        placements: [
          {
            placement: LtiPlacements.ModuleMenuModal,
            message_type: LtiResourceLinkRequest,
          },
        ],
      })
      const overlayStore = createLti1p3RegistrationOverlayStore(internalConfig, '')

      render(
        <OverrideURIsConfirmation overlayStore={overlayStore} internalConfig={internalConfig} />,
      )

      await waitFor(() => {
        const state = overlayStore.getState().state
        expect(state.override_uris.placements[LtiPlacements.ModuleMenuModal]?.message_type).toBe(
          LtiResourceLinkRequest,
        )
      })
    })

    it('sets message_type when new placement is added dynamically', async () => {
      const internalConfig = mockInternalConfiguration({
        placements: [{placement: LtiPlacements.CourseNavigation}],
      })
      const overlayStore = createLti1p3RegistrationOverlayStore(internalConfig, '')

      const {rerender} = render(
        <OverrideURIsConfirmation overlayStore={overlayStore} internalConfig={internalConfig} />,
      )

      overlayStore.getState().togglePlacement(LtiPlacements.EditorButton)

      rerender(
        <OverrideURIsConfirmation overlayStore={overlayStore} internalConfig={internalConfig} />,
      )

      await waitFor(() => {
        const state = overlayStore.getState().state
        expect(state.override_uris.placements[LtiPlacements.EditorButton]?.message_type).toBe(
          LtiDeepLinkingRequest,
        )
      })
    })
  })
})
