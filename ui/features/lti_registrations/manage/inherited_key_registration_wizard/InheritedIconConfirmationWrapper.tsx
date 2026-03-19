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
import {useScope as createI18nScope} from '@canvas/i18n'
import {Heading} from '@instructure/ui-heading'
import {RegistrationModalBody} from '../registration_wizard/RegistrationModalBody'
import type {InternalLtiConfiguration} from '../model/internal_lti_configuration/InternalLtiConfiguration'
import type {Lti1p3RegistrationOverlayStore} from '../registration_overlay/Lti1p3RegistrationOverlayStore'
import {ReadOnlyAlert} from './helpers'
import {IconUrlsReadOnlyView} from '../components/IconUrlsReadOnlyView'
import {isLtiPlacementWithIcon} from '../model/LtiPlacement'

const I18n = createI18nScope('lti_registration.wizard')

export type InheritedIconConfirmationWrapperProps = {
  overlayStore: Lti1p3RegistrationOverlayStore
  internalConfig: InternalLtiConfiguration
}

export const InheritedIconConfirmationWrapper = ({
  internalConfig,
}: InheritedIconConfirmationWrapperProps) => {
  const placementsWithIcons = internalConfig.placements.filter(p =>
    isLtiPlacementWithIcon(p.placement),
  )

  return (
    <RegistrationModalBody>
      <Heading level="h3" margin="0 0 x-small 0">
        {I18n.t('Icon URLs')}
      </Heading>

      <ReadOnlyAlert />

      <Heading level="h4" margin="0 0 x-small 0">
        {I18n.t('Default Icon URL')}
      </Heading>
      <IconUrlsReadOnlyView
        toolIconUrl={internalConfig.launch_settings?.icon_url}
        placements={placementsWithIcons}
        registrationName={internalConfig.title}
      />
    </RegistrationModalBody>
  )
}
