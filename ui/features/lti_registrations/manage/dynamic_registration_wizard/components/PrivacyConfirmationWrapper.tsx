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

import React from 'react'
import type {DynamicRegistrationOverlayStore} from '../DynamicRegistrationOverlayState'
import {useOverlayStore} from '../hooks/useOverlayStore'
import {PrivacyConfirmation} from '../../registration_wizard_forms/PrivacyConfirmation'
import {LtiPrivacyLevels} from '../../model/LtiPrivacyLevel'

export type PrivacyConfirmationWrapperProps = {
  toolName: string
  overlayStore: DynamicRegistrationOverlayStore
}

export const PrivacyConfirmationWrapper = ({
  toolName,
  overlayStore,
}: PrivacyConfirmationWrapperProps) => {
  const [state, actions] = useOverlayStore(overlayStore)

  return (
    <PrivacyConfirmation
      appName={toolName}
      privacyLevelOnChange={level => actions.updatePrivacyLevel(level)}
      selectedPrivacyLevel={state.overlay.privacy_level || LtiPrivacyLevels.Anonymous}
    />
  )
}
