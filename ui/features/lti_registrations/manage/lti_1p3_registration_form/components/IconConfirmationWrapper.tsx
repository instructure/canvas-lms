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
import {IconConfirmation} from '../../registration_wizard_forms/IconConfirmation'
import type {InternalLtiConfiguration} from '../../model/internal_lti_configuration/InternalLtiConfiguration'
import type {Lti1p3RegistrationOverlayStore} from '../Lti1p3RegistrationOverlayState'
import {useOverlayStore} from '../hooks/useOverlayStore'

export type IconConfirmationWrapperProps = {
  onNextButtonClicked: () => void
  onPreviousButtonClicked: () => void
  reviewing: boolean
  overlayStore: Lti1p3RegistrationOverlayStore
  config: InternalLtiConfiguration
}
export const IconConfirmationWrapper = ({
  overlayStore,
  config,
  reviewing,
  onNextButtonClicked,
  onPreviousButtonClicked,
}: IconConfirmationWrapperProps) => {
  const [state, actions] = useOverlayStore(overlayStore)

  return (
    <IconConfirmation
      name={state.naming.nickname ?? config.title}
      defaultIconUrl={config.launch_settings?.icon_url}
      allPlacements={state.placements.placements ?? []}
      placementIconOverrides={state.icons.placements}
      reviewing={reviewing}
      setPlacementIconUrl={actions.setPlacementIconUrl}
      onPreviousButtonClicked={onPreviousButtonClicked}
      onNextButtonClicked={onNextButtonClicked}
    />
  )
}
