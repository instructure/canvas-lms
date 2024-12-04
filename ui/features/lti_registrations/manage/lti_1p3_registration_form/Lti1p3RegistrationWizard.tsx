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
import {
  createLti1p3RegistrationWizardState,
  type Lti1p3RegistrationWizardStep,
} from './Lti1p3RegistrationWizardState'
import errorShipUrl from '@canvas/images/ErrorShip.svg'
import {PermissionConfirmationWrapper} from './components/PermissionConfirmationWrapper'
import {PlacementsConfirmationWrapper} from './components/PlacementsConfirmationWrapper'
import {Button} from '@instructure/ui-buttons'
import {Modal} from '@instructure/ui-modal'
import {Text} from '@instructure/ui-text'
import {PrivacyConfirmationWrapper} from './components/PrivacyConfirmationWrapper'
import {OverrideURIsConfirmation} from './components/OverrideURIsConfirmation'
import {NamingConfirmationWrapper} from './components/NamingConfirmationWrapper'
import {IconConfirmationWrapper} from './components/IconConfirmationWrapper'
import {ReviewScreenWrapper} from './components/ReviewScreenWrapper'
import {RegistrationModalBody} from '../registration_wizard/RegistrationModalBody'
import GenericErrorPage from '@canvas/generic-error-page/react'
import {Spinner} from '@instructure/ui-spinner'
import {Flex} from '@instructure/ui-flex'
import type {Lti1p3RegistrationWizardService} from './Lti1p3RegistrationWizardService'
import {Heading} from '@instructure/ui-heading'
import type {LtiRegistrationWithConfiguration} from '../model/LtiRegistration'
import {toUndefined} from '../../common/lib/toUndefined'

const I18n = useI18nScope('lti_registrations')

export type Lti1p3RegistrationWizardProps = {
  existingRegistration?: LtiRegistrationWithConfiguration
  accountId: AccountId
  internalConfiguration: InternalLtiConfiguration
  service: Lti1p3RegistrationWizardService
  unregister: () => void
  unifiedToolId?: UnifiedToolId
  onSuccessfulRegistration: () => void
}

export const Lti1p3RegistrationWizard = ({
  existingRegistration,
  accountId,
  internalConfiguration,
  service,
  unregister,
  unifiedToolId,
  onSuccessfulRegistration,
}: Lti1p3RegistrationWizardProps) => {
  const existingAdminNickname = existingRegistration?.admin_nickname
  const existingOverlayData = existingRegistration?.overlay?.data

  const useLti1p3RegistrationWizardStore = React.useMemo(() => {
    return createLti1p3RegistrationWizardState({
      adminNickname: existingAdminNickname ?? '',
      internalConfig: internalConfiguration,
      service,
      existingOverlay: toUndefined(existingOverlayData),
    })
  }, [internalConfiguration, service, existingAdminNickname, existingOverlayData])

  const store = useLti1p3RegistrationWizardStore()

  const handlePreviousClicked = (prevStep: Lti1p3RegistrationWizardStep) => () => {
    store.setReviewing(false)
    store.setStep(prevStep)
  }

  const handleNextClicked = (nextStep: Lti1p3RegistrationWizardStep) => () => {
    if (store.state.reviewing) {
      store.setStep('Review')
    } else {
      if (nextStep === 'Review') {
        store.setReviewing(true)
      }
      store.setStep(nextStep)
    }
  }

  const nextButtonLabel = store.state.reviewing ? I18n.t('Back to Review') : I18n.t('Next')

  switch (store.state._step) {
    case 'LaunchSettings':
      return (
        <LaunchSettings
          internalConfig={internalConfiguration}
          overlayStore={store.state.overlayStore}
          unregister={unregister}
          reviewing={store.state.reviewing}
          onNextClicked={handleNextClicked('Permissions')}
        />
      )
    case 'Permissions':
      // TODO: Handle the case where the internal config is undefined and allow for manual configuration
      return (
        <>
          <PermissionConfirmationWrapper
            overlayStore={store.state.overlayStore}
            internalConfig={internalConfiguration}
          />
          <Modal.Footer>
            <Button onClick={handlePreviousClicked('LaunchSettings')} margin="small">
              {I18n.t('Previous')}
            </Button>
            <Button onClick={handleNextClicked('DataSharing')} color="primary" margin="small">
              {nextButtonLabel}
            </Button>
          </Modal.Footer>
        </>
      )
    case 'DataSharing':
      return (
        <>
          <PrivacyConfirmationWrapper
            internalConfig={internalConfiguration}
            appName={internalConfiguration.title}
            overlayStore={store.state.overlayStore}
          />
          <Modal.Footer>
            <Button onClick={handlePreviousClicked('Permissions')} margin="small">
              {I18n.t('Previous')}
            </Button>
            <Button onClick={handleNextClicked('Placements')} color="primary" margin="small">
              {nextButtonLabel}
            </Button>
          </Modal.Footer>
        </>
      )
    case 'Placements':
      return (
        <>
          <PlacementsConfirmationWrapper
            internalConfig={internalConfiguration}
            overlayStore={store.state.overlayStore}
          />
          <Modal.Footer>
            <Button onClick={handlePreviousClicked('DataSharing')} margin="small">
              {I18n.t('Previous')}
            </Button>
            <Button onClick={handleNextClicked('OverrideURIs')} color="primary" margin="small">
              {nextButtonLabel}
            </Button>
          </Modal.Footer>
        </>
      )
    case 'OverrideURIs':
      return (
        <OverrideURIsConfirmation
          overlayStore={store.state.overlayStore}
          internalConfig={internalConfiguration}
          reviewing={store.state.reviewing}
          onPreviousClicked={handlePreviousClicked('Placements')}
          onNextClicked={handleNextClicked('Naming')}
        />
      )
    case 'Naming':
      return (
        <>
          <NamingConfirmationWrapper
            internalConfig={internalConfiguration}
            overlayStore={store.state.overlayStore}
          />
          <Modal.Footer>
            <Button onClick={handlePreviousClicked('OverrideURIs')} margin="small">
              {I18n.t('Previous')}
            </Button>
            <Button onClick={handleNextClicked('Icons')} color="primary" margin="small">
              {nextButtonLabel}
            </Button>
          </Modal.Footer>
        </>
      )
    case 'Icons':
      return (
        <IconConfirmationWrapper
          internalConfig={internalConfiguration}
          reviewing={store.state.reviewing}
          overlayStore={store.state.overlayStore}
          onPreviousButtonClicked={handlePreviousClicked('Naming')}
          onNextButtonClicked={handleNextClicked('Review')}
        />
      )
    case 'Review':
      return (
        <>
          <ReviewScreenWrapper
            overlayStore={store.state.overlayStore}
            internalConfig={internalConfiguration}
            transitionTo={store.setStep}
          />
          <Modal.Footer>
            <Button onClick={handlePreviousClicked('Icons')} margin="small">
              {I18n.t('Previous')}
            </Button>
            <Button
              onClick={() => {
                if (existingRegistration) {
                  store.update(
                    onSuccessfulRegistration,
                    accountId,
                    existingRegistration.id,
                    unifiedToolId
                  )
                } else {
                  store.install(onSuccessfulRegistration, accountId, unifiedToolId)
                }
              }}
              color="primary"
              margin="small"
            >
              {existingRegistration ? I18n.t('Update App') : I18n.t('Install App')}
            </Button>
          </Modal.Footer>
        </>
      )
    case 'Installing':
      return (
        <RegistrationModalBody>
          <Flex justifyItems="center" alignItems="center" height="100%">
            <Flex.Item>
              <Spinner renderTitle={I18n.t('Installing App')} />
            </Flex.Item>
            <Flex.Item>{I18n.t('Installing App')}</Flex.Item>
          </Flex>
        </RegistrationModalBody>
      )
    case 'Updating':
      return (
        <RegistrationModalBody>
          <Flex justifyItems="center" alignItems="center" height="100%">
            <Flex.Item>
              <Spinner renderTitle={I18n.t('Updating App')} />
            </Flex.Item>
            <Flex.Item>{I18n.t('Updating App')}</Flex.Item>
          </Flex>
        </RegistrationModalBody>
      )
    case 'Error':
      return (
        <RegistrationModalBody>
          <GenericErrorPage
            imageUrl={errorShipUrl}
            errorSubject={I18n.t('Dynamic Registration error')}
            errorCategory="Dynamic Registration"
            errorMessage={store.state.errorMessage}
          />
        </RegistrationModalBody>
      )
    case 'Success':
      return (
        <RegistrationModalBody>
          <Heading>{I18n.t('App Installed Successfully')}</Heading>
          <Text>
            {I18n.t(
              'Your app has been successfully installed. This modal should close in a moment.'
            )}
          </Text>
        </RegistrationModalBody>
      )
  }
}
