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
import type {LtiImsRegistration} from '../../model/lti_ims_registration/LtiImsRegistration'
import {canvasPlatformSettings} from '../../registration_wizard/registration_settings/RegistrationOverlayState'
import {type LtiPlacement} from '../../model/LtiPlacement'

export const usePlacements = (registration: LtiImsRegistration): LtiPlacement[] => {
  return React.useMemo(() => {
    return (
      canvasPlatformSettings(registration.default_configuration)?.settings.placements.map(
        p => p.placement
      ) ?? []
    )
  }, [registration.default_configuration])
}
