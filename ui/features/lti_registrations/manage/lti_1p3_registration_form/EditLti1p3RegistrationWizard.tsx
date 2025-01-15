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

import GenericErrorPage from '@canvas/generic-error-page/react'
import {useScope as createI18nScope} from '@canvas/i18n'
import errorShipUrl from '@canvas/images/ErrorShip.svg'
import {Flex} from '@instructure/ui-flex'
import {Spinner} from '@instructure/ui-spinner'
import * as React from 'react'
import {formatApiResultError, type ApiResult} from '../../common/lib/apiResult/ApiResult'
import type {AccountId} from '../model/AccountId'
import type {LtiRegistrationWithConfiguration} from '../model/LtiRegistration'
import type {LtiRegistrationId} from '../model/LtiRegistrationId'
import type {UnifiedToolId} from '../model/UnifiedToolId'
import {RegistrationModalBody} from '../registration_wizard/RegistrationModalBody'
import {Lti1p3RegistrationWizard} from './Lti1p3RegistrationWizard'
import type {Lti1p3RegistrationWizardService} from './Lti1p3RegistrationWizardService'

const I18n = createI18nScope('lti_registrations')

export type Lti1p3RegistrationWizardProps = {
  registrationId: LtiRegistrationId
  accountId: AccountId
  service: Lti1p3RegistrationWizardService
  unregister: () => void
  unifiedToolId?: UnifiedToolId
  onSuccessfulRegistration: () => void
}

/**
 * A component that wraps {@link Lti1p3RegistrationWizard}, but fetches
 * the registration and provides it as initial configuration.
 * @param param
 * @returns
 */
export const EditLti1p3RegistrationWizard = ({
  registrationId,
  accountId,
  service,
  unregister,
  unifiedToolId,
  onSuccessfulRegistration,
}: Lti1p3RegistrationWizardProps) => {
  const [reg, setReg] = React.useState<ApiResult<LtiRegistrationWithConfiguration> | null>(null)

  React.useEffect(() => {
    service.fetchLtiRegistration(accountId, registrationId).then(setReg)
  }, [registrationId, setReg, accountId, service])

  if (!reg) {
    return (
      <RegistrationModalBody>
        <Flex
          justifyItems="center"
          alignItems="center"
          height="100%"
          data-testid="dynamic-reg-modal-loading-registration"
        >
          <Flex.Item>
            <Spinner renderTitle={I18n.t('Loading')} />
          </Flex.Item>
          <Flex.Item>{I18n.t('Loading')}</Flex.Item>
        </Flex>
      </RegistrationModalBody>
    )
  } else if (reg._type === 'Success') {
    return (
      <Lti1p3RegistrationWizard
        accountId={accountId}
        internalConfiguration={reg.data.configuration}
        onSuccessfulRegistration={onSuccessfulRegistration}
        service={service}
        unregister={unregister}
        existingRegistration={reg.data}
        unifiedToolId={unifiedToolId}
      />
    )
  } else {
    return (
      <GenericErrorPage
        imageUrl={errorShipUrl}
        errorMessage={formatApiResultError(reg)}
        stack={formatApiResultError(reg)}
        errorCategory="LTI Apps Page"
      />
    )
  }
}
