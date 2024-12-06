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

import * as React from 'react'
import {type Lti} from '@canvas/lti-apps/models/Product'
import {Button} from '@instructure/ui-buttons'
import {openDynamicRegistrationWizard} from '../manage/registration_wizard/RegistrationWizardModalState'
import {useNavigate} from 'react-router-dom'
import {openInheritedKeyWizard} from '../manage/inherited_key_registration_wizard/InheritedKeyRegistrationWizardState'
import {ZDeveloperKeyId} from '../manage/model/developer_key/DeveloperKeyId'
import {useScope as useI18nScope} from '@canvas/i18n'
import {ZUnifiedToolId} from '../manage/model/UnifiedToolId'

export type ConfigureButtonProps = {
  buttonWidth: 'block' | 'inline-block'
  ltiConfiguration: Lti
}

const I18n = useI18nScope('lti_registrations')

export const ProductConfigureButton = ({buttonWidth, ltiConfiguration}: ConfigureButtonProps) => {
  const navigate = useNavigate()

  const dynamicRegistrationInformation = ltiConfiguration.lti_13?.find(
    configuration => configuration.integration_type === 'lti_13_dynamic_registration'
  )

  const globalInheritedKeyInformation = ltiConfiguration.lti_13?.find(
    configuration => configuration.integration_type === 'lti_13_global_inherited_key'
  )

  return (
    <Button
      display={buttonWidth}
      color="primary"
      interaction={
        dynamicRegistrationInformation ||
        (globalInheritedKeyInformation && window.ENV.FEATURES.lti_registrations_next)
          ? 'enabled'
          : 'disabled'
      }
      onClick={() => {
        if (dynamicRegistrationInformation && dynamicRegistrationInformation.url) {
          openDynamicRegistrationWizard(
            dynamicRegistrationInformation.url,
            ZUnifiedToolId.parse(dynamicRegistrationInformation.unified_tool_id),
            () => {
              // redirect to apps page
              navigate('/manage')
            }
          )
        } else if (
          globalInheritedKeyInformation &&
          globalInheritedKeyInformation.global_inherited_key
        ) {
          openInheritedKeyWizard(
            ZDeveloperKeyId.parse(globalInheritedKeyInformation.global_inherited_key),
            () => {
              // redirect to apps page
              navigate('/manage')
            }
          )
        }
      }}
    >
      {I18n.t('Configure')}
    </Button>
  )
}
