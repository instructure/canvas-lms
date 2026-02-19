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

import {useScope as createI18nScope} from '@canvas/i18n'
import GenericErrorPage from '@canvas/generic-error-page/react'
import errorShipUrl from '@canvas/images/ErrorShip.svg'
import {Flex} from '@instructure/ui-flex'
import {Spinner} from '@instructure/ui-spinner'
import React from 'react'
import type {AccountId} from '../model/AccountId'
import type {LtiRegistrationUpdateRequestId} from '../model/lti_ims_registration/LtiRegistrationUpdateRequestId'
import {RegistrationModalBody} from '../registration_wizard/RegistrationModalBody'
import {Header} from '../registration_wizard_forms/Header'
import {useRegistrationUpdateRequest} from '../api/ltiImsRegistration'
import {useRegistrationWithConfig} from '../api/registrations'
import {RegistrationUpdateWizardInner} from './RegistrationUpdateWizardInner'
import {LtiRegistration} from '../model/LtiRegistration'

const I18n = createI18nScope('lti_registrations')

export interface RegistrationUpdateWizardProps {
  accountId: AccountId
  registration: LtiRegistration
  ltiRegistrationUpdateRequestId: LtiRegistrationUpdateRequestId
  onDismiss: () => void
  onSuccess: () => void
}

export const RegistrationUpdateWizard = ({
  accountId,
  registration,
  ltiRegistrationUpdateRequestId,
  onDismiss,
  onSuccess,
}: RegistrationUpdateWizardProps) => {
  const registrationUpdateRequestQuery = useRegistrationUpdateRequest(
    accountId,
    registration.id,
    ltiRegistrationUpdateRequestId,
  )

  const registrationWithConfigQuery = useRegistrationWithConfig(registration.id, accountId)

  // Handle loading states - both requests need to complete
  if (registrationUpdateRequestQuery.isPending || registrationWithConfigQuery.isPending) {
    return (
      <>
        <Header onClose={onDismiss} headerText={I18n.t('Review Updates')} />
        <RegistrationModalBody>
          <Flex justifyItems="center" alignItems="center" height="100%">
            <Flex.Item>
              <Spinner renderTitle={I18n.t('Loading')} />
            </Flex.Item>
            <Flex.Item>{I18n.t('Loading registration data')}</Flex.Item>
          </Flex>
        </RegistrationModalBody>
      </>
    )
  }

  // Handle error states - either request failing should show error
  if (
    registrationUpdateRequestQuery.status === 'error' ||
    registrationWithConfigQuery.status === 'error'
  ) {
    const errorMessage =
      registrationUpdateRequestQuery.error?.message ||
      registrationWithConfigQuery.error?.message ||
      I18n.t('Failed to load registration data')
    return (
      <>
        <Header onClose={onDismiss} headerText={I18n.t('Review Updates')} />
        <RegistrationModalBody>
          <GenericErrorPage
            imageUrl={errorShipUrl}
            errorSubject={I18n.t('Registration Update Wizard Error')}
            errorCategory="Registration Update Wizard"
            errorMessage={errorMessage}
          />
        </RegistrationModalBody>
      </>
    )
  }

  return (
    <RegistrationUpdateWizardInner
      accountId={accountId}
      registrationUpdateRequest={registrationUpdateRequestQuery.data.json}
      registration={registrationWithConfigQuery.data.json}
      onDismiss={onDismiss}
      onSuccess={onSuccess}
    />
  )
}
