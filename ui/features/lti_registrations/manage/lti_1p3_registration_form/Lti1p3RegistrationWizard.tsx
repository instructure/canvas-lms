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

import {useScope as useI18nScope} from '@canvas/i18n'
import {Button} from '@instructure/ui-buttons'
import {Modal} from '@instructure/ui-modal'
import * as React from 'react'
import type {AccountId} from '../model/AccountId'
import type {InternalLtiConfiguration} from '../model/internal_lti_configuration/InternalLtiConfiguration'
import type {UnifiedToolId} from '../model/UnifiedToolId'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {LaunchSettings} from './components/LaunchSettings'
import {createLti1p3RegistrationWizardState} from './Lti1p3RegistrationWizardState'
import {RegistrationModalBody} from '../registration_wizard/RegistrationModalBody'
import {useValidateLaunchSettings} from './hooks/useValidateLaunchSettings'
import {useOverlayStore} from './hooks/useOverlayStore'

const I18n = useI18nScope('lti_registrations')

export type Lti1p3RegistrationWizardProps = {
  accountId: AccountId
  internalConfiguration?: InternalLtiConfiguration
  unregister: () => void
  unifiedToolId?: UnifiedToolId
  onSuccessfulRegistration: () => void
}

export const Lti1p3RegistrationWizard = (props: Lti1p3RegistrationWizardProps) => {
  const {internalConfiguration} = props
  const useLti1p3RegistrationWizardStore = React.useMemo(() => {
    if (internalConfiguration) {
      return createLti1p3RegistrationWizardState({internalConfig: internalConfiguration})
    } else {
      // TODO: Account for the case where the internalConfiguration is not present
      // to allow for manual configuration
      throw new Error('Not yet implemented')
    }
  }, [internalConfiguration])

  const store = useLti1p3RegistrationWizardStore()

  switch (store.state._step) {
    case 'LaunchSettings':
      return (
        <LaunchSettings
          overlayStore={store.state.overlayStore}
          unregister={props.unregister}
          onNextClicked={() => store.setStep('DataSharing')}
        />
      )
    case 'DataSharing':
    case 'Icons':
    case 'Naming':
    case 'OverrideURIs':
    case 'Permissions':
    case 'Placements':
    case 'Review':
      return (
        <div>
          <RegistrationModalBody>
            <Text>TODO: Implement the rest of the steps</Text>
          </RegistrationModalBody>
          <Modal.Footer>
            <Button onClick={() => store.setStep('LaunchSettings')}>Back</Button>
          </Modal.Footer>
        </div>
      )
  }
}
