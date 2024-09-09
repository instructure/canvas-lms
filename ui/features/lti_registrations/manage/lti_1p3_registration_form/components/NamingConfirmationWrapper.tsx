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
import type {InternalLtiConfiguration} from '../../model/internal_lti_configuration/InternalLtiConfiguration'
import {NamingConfirmation} from '../../registration_wizard_forms/NamingConfirmation'
import type {Lti1p3RegistrationOverlayStore} from '../Lti1p3RegistrationOverlayState'
import {useOverlayStore} from '../hooks/useOverlayStore'
import {RegistrationModalBody} from '../../registration_wizard/RegistrationModalBody'

export type NamingConfirmationWrapperProps = {
  overlayStore: Lti1p3RegistrationOverlayStore
  config: InternalLtiConfiguration
}

export const NamingConfirmationWrapper = ({
  overlayStore,
  config,
}: NamingConfirmationWrapperProps) => {
  const [state, actions] = useOverlayStore(overlayStore)

  const placements = (state.placements.placements ?? []).map(p => ({
    placement: p,
    label: state.naming.placements[p] ?? '',
  }))

  return (
    <RegistrationModalBody>
      <NamingConfirmation
        toolName={config.title}
        adminNickname={state.naming.nickname}
        onUpdateAdminNickname={actions.setAdminNickname}
        description={state.naming.description ?? config.description}
        onUpdateDescription={actions.setDescription}
        placements={placements}
        onUpdatePlacementLabel={actions.setPlacementLabel}
      />
    </RegistrationModalBody>
  )
}
