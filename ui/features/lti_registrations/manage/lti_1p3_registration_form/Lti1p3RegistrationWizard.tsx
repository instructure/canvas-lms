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
import * as React from 'react'
import type {AccountId} from '../model/AccountId'
import type {InternalLtiConfiguration} from '../model/internal_lti_configuration/InternalLtiConfiguration'
import type {UnifiedToolId} from '../model/UnifiedToolId'
import {LaunchSettings} from './components/LaunchSettings'
import {createLti1p3RegistrationWizardState} from './Lti1p3RegistrationWizardState'
import {PermissionConfirmationWrapper} from './components/PermissionConfirmationWrapper'
import {Button} from '@instructure/ui-buttons'
import {Modal} from '@instructure/ui-modal'
import {Text} from '@instructure/ui-text'
import {RegistrationModalBody} from '../registration_wizard/RegistrationModalBody'

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
          onNextClicked={() => store.setStep('Permissions')}
        />
      )
    case 'Permissions':
      // TODO: Handle the case where the internal config is undefined and allow for manual configuration
      return (
        <>
          <PermissionConfirmationWrapper
            overlayStore={store.state.overlayStore}
            internalConfig={props.internalConfiguration!}
          />
          <Modal.Footer>
            <Button onClick={() => store.setStep('LaunchSettings')} margin="small">
              {I18n.t('Previous')}
            </Button>
            <Button onClick={() => store.setStep('DataSharing')} color="primary" margin="small">
              {I18n.t('Next')}
            </Button>
          </Modal.Footer>
        </>
      )
    case 'DataSharing':
    case 'Icons':
    case 'Naming':
    case 'OverrideURIs':
    case 'Placements':
    case 'Review':
      return (
        <div>
          <RegistrationModalBody>
            <Text>TODO: Implement the rest of the steps</Text>
          </RegistrationModalBody>
          <Modal.Footer>
            <Button onClick={() => store.setStep('Permissions')}>Back</Button>
          </Modal.Footer>
        </div>
      )
  }
}
